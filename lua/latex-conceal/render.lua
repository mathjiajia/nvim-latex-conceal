local api = vim.api
local ts = vim.treesitter
-- Register after native highlighting so equal-priority capture colors keep their order.
local highlighter = ts.highlighter
local namespace = api.nvim_create_namespace("latex-conceal")
local M = {}
local margin = 20
local change_limit = 256
local windows = {}
local parsers = setmetatable({}, { __mode = "k" })
local highlights = {}
local serial = 0
local initialized = false

-- Each parser keeps a version counter and the row ranges that changed since
-- any window last looked. Neovim reports every replaced or dropped tree
-- through on_changedtree before it goes, so rows outside those ranges keep
-- their completed results across injection parses, which happen constantly
-- while scrolling Markdown.
local function parser_state(parser)
	local state = parsers[parser]
	if not state then
		state = { version = 0, reset = 0, changes = {}, index = {}, index_version = -1, has_latex = false }
		local function changed(ranges, tree)
			local version = state.version + 1
			state.version = version
			local changes = state.changes
			-- A hidden window can retain an old generation indefinitely, even when
			-- reparsing does not change the buffer tick. Bound the history and make
			-- older windows rebuild instead of retaining every intervening change.
			if #changes + 1 + #(ranges or {}) > change_limit then
				state.reset = version
				state.changes = {}
				return
			end
			local first, _, last = tree:root():range()
			changes[#changes + 1] = { version = version, first = first, last = last }
			for _, range in ipairs(ranges or {}) do
				changes[#changes + 1] = { version = version, first = range[1], last = range[#range == 4 and 3 or 4] }
			end
		end
		local function bump()
			state.version = state.version + 1
		end
		local function reset()
			state.version = state.version + 1
			state.reset = state.version
			state.changes = {}
		end
		parser:register_cbs({
			on_changedtree = changed,
			on_child_added = bump,
			on_child_removed = reset,
			on_detach = reset
		}, true)
		parsers[parser] = state
	end
	return state
end

-- Windows with an obsolete buffer tick or generation must rebuild anyway.
local function trim_changes(state, tick)
	local low = state.version
	for _, cached in pairs(windows) do
		if cached.parser_state == state and cached.tick == tick and cached.version >= state.reset and cached.version < low then
			low = cached.version
		end
	end
	local kept, n = {}, 0
	for _, change in ipairs(state.changes) do
		if change.version > low then
			n = n + 1
			kept[n] = change
		end
	end
	state.changes = kept
end

local function has_latex(parser)
	if parser:lang() == "latex" then
		return true
	end
	for _, child in pairs(parser:children()) do
		if has_latex(child) then
			return true
		end
	end
	return false
end

-- One pass over the language trees, reused until the parser changes them.
-- Native highlighting numbers the visible trees in this order to break ties
-- between equal priorities, and conceals must follow the same numbering.
local function build_index(state, active)
	local index, n, has_query = {}, 0, {}
	active.tree:for_each_tree(function (tree, language_tree)
		local lang = language_tree:lang()
		local counted = has_query[lang]
		if counted == nil then
			counted = active:get_query(lang):query() ~= nil
			has_query[lang] = counted
		end
		local first, _, last = tree:root():range()
		n = n + 1
		index[n] = { first = first, last = last, tree = tree, latex = lang == "latex", counted = counted }
	end)
	state.index, state.index_version = index, state.version
	state.has_latex = has_latex(active.tree)
end

local function tree_priorities(index, top, bottom)
	local priorities, n = {}, 0
	for i = 1, #index do
		local entry = index[i]
		if entry.counted and entry.first <= bottom and entry.last >= top then
			n = n + 1
			priorities[entry.tree] = n
		end
	end
	return priorities
end

local function latex_trees(index, first, last)
	local trees, n = {}, 0
	for i = 1, #index do
		local entry = index[i]
		if entry.latex and entry.first < last and entry.last >= first then
			local tree = entry.tree
			n = n + 1
			trees[n] = {
				tree = tree,
				root = tree:root(),
				first = entry.first,
				last = entry.last,
				included = tree:included_ranges(true)
			}
		end
	end
	return trees
end

local function highlight(name)
	local id = highlights[name]
	if id == nil then
		id = name:sub(1, 1) == "_" and 0 or api.nvim_get_hl_id_by_name("@" .. name .. ".latex")
		highlights[name] = id
	end
	return id
end

-- Both ranges contain byte offsets, including when a directive changes the range.
local function intersection(a, b)
	if a[3] >= b[6] or b[3] >= a[6] then
		return
	end
	local first = a[3] >= b[3] and a or b
	local last = a[6] <= b[6] and a or b
	return first[1], first[2], last[4], last[5]
end

local function collect(buf, cached, first, last)
	local rows = {}
	local query = cached.query
	local names = query.captures
	local line_count = cached.line_count
	local default_priority = vim.hl.priorities.treesitter
	for _, entry in ipairs(cached.trees) do
		if entry.first < last and entry.last >= first then
			local included = entry.included
			local tree = entry.tree
			for id, node, metadata in query:iter_captures(entry.root, buf, first, last) do
				local capture = metadata[id]
				local conceal = metadata.conceal
				if conceal == nil and capture then
					conceal = capture.conceal
				end
				local hl_group = highlight(names[id])
				if conceal ~= nil or hl_group ~= 0 then
					local priority = tonumber(metadata.priority or capture and capture.priority) or default_priority
					local range = ts.get_range(node, buf, capture)
					for _, region in ipairs(included) do
						local sr, sc, er, ec = intersection(range, region)
						if sr and er + (ec > 0 and 1 or 0) <= line_count then
							local mark = {
								sr,
								sc,
								{
									end_row = er,
									end_col = ec,
									conceal = conceal,
									hl_group = hl_group,
									priority = priority,
									ephemeral = true
								},
								tree
							}
							for row = math.max(first, sr), math.min(last - 1, er - (ec == 0 and 1 or 0)) do
								local marks = rows[row]
								if not marks then
									marks = {}
									rows[row] = marks
								end
								marks[#marks + 1] = mark
							end
						end
					end
				end
			end
		end
	end
	return rows
end

-- Forget the rows that changed trees cover; other rows stay complete.
local function apply_changes(cached, state)
	local first, last = cached.first, cached.last
	local changes = state.changes
	for i = #changes, 1, -1 do
		local change = changes[i]
		if change.version <= cached.version then
			break
		end
		local low, high = math.max(change.first, first), math.min(change.last, last - 1)
		if low <= high then
			local ready = cached.ready
			if not ready then
				ready = {}
				for row = first, last - 1 do
					ready[row] = true
				end
				cached.ready = ready
			end
			local rows = cached.rows
			for row = low, high do
				rows[row] = nil
				ready[row] = nil
			end
		end
	end
	cached.trees = latex_trees(state.index, first, last)
	cached.version = state.version
end

local function on_win(_, win, buf, top, bottom)
	local active = highlighter.active[buf]
	if not active then
		windows[win] = nil
		return false
	end
	-- Keep the cache while native highlighting still parses an edit, so the
	-- redraw that follows refills only the rows it repaints.
	if active.parsing then
		return false
	end
	local parser = active.tree
	local state = parser_state(parser)
	if state.index_version ~= state.version then
		build_index(state, active)
	end
	local query = state.has_latex and ts.query.get("latex", "conceals")
	if not query then
		windows[win] = nil
		return false
	end
	local line_count = api.nvim_buf_line_count(buf)
	local last = math.min(line_count, bottom + 1)
	local sparse = last - top > api.nvim_win_get_height(win) + 1
	local tick = api.nvim_buf_get_changedtick(buf)
	-- Replaced trees arrive through the parser callbacks, so only an invalidated
	-- root (a buffer reload) can leave results stale without changing the version.
	local cached = windows[win]
	if cached and cached.buf == buf and cached.parser == parser and cached.tick == tick and cached.query == query
		and cached.default_priority == vim.hl.priorities.treesitter
		and cached.version >= state.reset and cached.first <= top and cached.last >= last
		and (not cached.sparse or cached.view_first == top and cached.view_last == last) and parser:is_valid(true) then
		if cached.version ~= state.version then
			apply_changes(cached, state)
			if #state.changes > change_limit / 2 then
				trim_changes(state, tick)
			end
		end
		if cached.priorities_version ~= state.version or cached.top ~= top or cached.bottom ~= bottom then
			cached.priorities = tree_priorities(state.index, top, bottom)
			cached.priorities_version, cached.top, cached.bottom = state.version, top, bottom
		end
		return true
	end

	-- Edits discard every result, then refill only ranges Neovim actually repaints.
	local edited = cached and cached.buf == buf and cached.tick ~= tick
	local nearby = not cached or top < cached.last and last > cached.first
	-- A folded window can span thousands of hidden lines; query only its repainted rows.
	local deferred = edited or sparse
	local padding = not deferred and nearby and margin or 0
	local first = math.max(0, top - padding)
	local view_last = last
	last = math.min(line_count, last + padding)
	-- Reparse only the requested region, including injections, rather than the entire document.
	-- Keep the other splits' regions valid too: a parse replaces the injection-validity range.
	local ranges = { { first, last } }
	local tab = api.nvim_win_get_tabpage(win)
	for other, cache in pairs(windows) do
		if other ~= win and cache.parser == parser and api.nvim_win_is_valid(other) and api.nvim_win_get_buf(other) == buf
			and api.nvim_win_get_tabpage(other) == tab then
			ranges[#ranges + 1] = { cache.first, cache.last }
		end
	end
	table.sort(ranges, function (a, b)
		return a[1] < b[1]
	end)
	parser:parse(ranges)
	if state.index_version ~= state.version then
		build_index(state, active)
	end
	local next_cache = {
		buf = buf,
		parser = parser,
		parser_state = state,
		query = query,
		default_priority = vim.hl.priorities.treesitter,
		version = state.version,
		tick = tick,
		first = first,
		last = last,
		line_count = line_count,
		trees = latex_trees(state.index, first, last),
		priorities = tree_priorities(state.index, top, bottom),
		priorities_version = state.version,
		top = top,
		bottom = bottom,
		ready = deferred and {} or nil,
		sparse = sparse,
		view_first = top,
		view_last = view_last
	}
	next_cache.rows = deferred and {} or collect(buf, next_cache, first, last)
	windows[win] = next_cache
	if #state.changes > change_limit / 2 then
		trim_changes(state, tick)
	end
	return true
end

local function on_range(_, win, buf, first_row, _, last_row, last_col)
	local cached = windows[win]
	if not cached or cached.buf ~= buf then
		return
	end
	local first = math.max(first_row, cached.first)
	local last = math.min(last_row + (last_col > 0 and 1 or 0), cached.last)
	local ready = cached.ready
	if ready then
		local row = first
		while row < last do
			if ready[row] then
				row = row + 1
			else
				local start = row
				repeat
					row = row + 1
				until row == last or ready[row]
				local rows = collect(buf, cached, start, row)
				for line = start, row - 1 do
					cached.rows[line] = rows[line]
					ready[line] = true
				end
			end
		end
	end
	serial = serial + 1
	local rows, priorities = cached.rows, cached.priorities
	for row = first, last - 1 do
		local marks = rows[row]
		if marks then
			for i = 1, #marks do
				local mark = marks[i]
				local priority = priorities[mark[4]]
				if priority and mark.serial ~= serial then
					mark.serial = serial
					mark[3]._subpriority = priority
					api.nvim_buf_set_extmark(buf, namespace, mark[1], mark[2], mark[3])
				end
			end
		end
	end
end

function M.setup()
	if initialized then
		return
	end
	initialized = true
	api.nvim_set_decoration_provider(namespace, { on_win = on_win, on_range = on_range })
	local group = api.nvim_create_augroup("latex-conceal", {})
	api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
		group = group,
		callback = function (event)
			for win, cached in pairs(windows) do
				if cached.buf == event.buf then
					windows[win] = nil
				end
			end
		end
	})
	api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function (event)
			windows[tonumber(event.match)] = nil
		end
	})
	api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function ()
			highlights = {}
			windows = {}
		end
	})
end

return M
