local api = vim.api
local ts = vim.treesitter
-- Register after native highlighting so equal-priority capture colors keep their order.
local highlighter = ts.highlighter
local namespace = api.nvim_create_namespace("latex-conceal")
local M = {}
local margin = 20
local windows = {}
local parsers = setmetatable({}, { __mode = "k" })
local highlights = {}
local serial = 0
local initialized = false

local function parser_state(parser)
	local state = parsers[parser]
	if not state then
		state = { version = 0 }
		local function invalidate()
			state.version = state.version + 1
		end
		parser:register_cbs({
			on_changedtree = invalidate,
			on_child_added = invalidate,
			on_child_removed = invalidate,
			on_detach = invalidate,
		}, true)
		parsers[parser] = state
	end
	return state
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

-- Reuse tree geometry while deferred repaint ranges fill this cache generation.
local function latex_trees(parser, first, last)
	local trees = {}
	parser:for_each_tree(function(tree, language)
		if language:lang() ~= "latex" then
			return
		end
		local root = tree:root()
		local start_row, _, end_row = root:range()
		if start_row >= last or end_row < first then
			return
		end
		trees[#trees + 1] = {
			tree = tree, root = root, first = start_row, last = end_row,
			included = tree:included_ranges(true),
		}
	end)
	return trees
end

local function collect(buf, cached, first, last)
	local rows = {}
	local query = cached.query
	for _, entry in ipairs(cached.trees) do
		if entry.first < last and entry.last >= first then
			for id, node, metadata in query:iter_captures(entry.root, buf, first, last) do
				local capture = metadata[id]
				local conceal = metadata.conceal
				if conceal == nil and capture then
					conceal = capture.conceal
				end
				local hl_group = highlight(query.captures[id])
				if conceal ~= nil or hl_group ~= 0 then
					local priority = tonumber(metadata.priority or capture and capture.priority) or vim.hl.priorities.treesitter
					local range = ts.get_range(node, buf, capture)
					for _, region in ipairs(entry.included) do
						local sr, sc, er, ec = intersection(range, region)
						if sr and er + (ec > 0 and 1 or 0) <= cached.line_count then
							local mark = { sr, sc, {
								end_row = er, end_col = ec,
								conceal = conceal, hl_group = hl_group, priority = priority,
								ephemeral = true,
							}, entry.tree }
							for row = math.max(first, sr), math.min(last - 1, er - (ec == 0 and 1 or 0)) do
								rows[row] = rows[row] or {}
								rows[row][#rows[row] + 1] = mark
							end
						end
					end
				end
			end
		end
	end
	return rows
end

-- Native highlighting orders visible language trees, not every parsed injection.
local function tree_priorities(active, first, last)
	local priorities, index = {}, 0
	active.tree:for_each_tree(function(tree, language)
		local start_row, _, end_row = tree:root():range()
		if start_row <= last and end_row >= first and active:get_query(language:lang()):query() then
			index = index + 1
			priorities[tree] = index
		end
	end)
	return priorities
end

local function on_win(_, win, buf, top, bottom)
	local active = highlighter.active[buf]
	if not active or active.parsing or not has_latex(active.tree) then
		windows[win] = nil
		return false
	end
	local parser = active.tree
	local state = parser_state(parser)
	local query = ts.query.get("latex", "conceals")
	if not query then
		windows[win] = nil
		return false
	end
	local line_count = api.nvim_buf_line_count(buf)
	local last = math.min(line_count, bottom + 1)
	local sparse = last - top > api.nvim_win_get_height(win) + 1
	local tick = api.nvim_buf_get_changedtick(buf)
	local cached = windows[win]
	if cached and cached.buf == buf and cached.parser == parser and cached.version == state.version
		and cached.tick == tick and cached.query == query and cached.first <= top and cached.last >= last
		and (not cached.sparse or cached.view_first == top and cached.view_last == last)
		and parser:is_valid(false, { cached.first, cached.last }) then
		cached.priorities = tree_priorities(active, top, bottom)
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
		if other ~= win and cache.parser == parser and api.nvim_win_is_valid(other)
			and api.nvim_win_get_buf(other) == buf and api.nvim_win_get_tabpage(other) == tab then
			ranges[#ranges + 1] = { cache.first, cache.last }
		end
	end
	table.sort(ranges, function(a, b)
		return a[1] < b[1]
	end)
	parser:parse(ranges)
	local next_cache = {
		buf = buf, parser = parser, query = query, version = state.version, tick = tick,
		first = first, last = last, line_count = line_count, trees = latex_trees(parser, first, last),
		priorities = tree_priorities(active, top, bottom),
		ready = deferred and {} or nil,
		sparse = sparse, view_first = top, view_last = view_last,
	}
	next_cache.rows = deferred and {} or collect(buf, next_cache, first, last)
	windows[win] = next_cache
	return true
end

local function on_range(_, win, buf, first_row, _, last_row, last_col)
	local cached = windows[win]
	if not cached or cached.buf ~= buf then
		return
	end
	local first = math.max(first_row, cached.first)
	local last = math.min(last_row + (last_col > 0 and 1 or 0), cached.last)
	if cached.ready then
		local row = first
		while row < last do
			if cached.ready[row] then
				row = row + 1
			else
				local start = row
				repeat
					row = row + 1
				until row == last or cached.ready[row]
				local rows = collect(buf, cached, start, row)
				for line = start, row - 1 do
					cached.rows[line] = rows[line]
					cached.ready[line] = true
				end
			end
		end
	end
	serial = serial + 1
	for row = first, last - 1 do
		local marks = cached.rows[row]
		if marks then
			for _, mark in ipairs(marks) do
				local priority = cached.priorities[mark[4]]
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
		callback = function(event)
			for win, cached in pairs(windows) do
				if cached.buf == event.buf then
					windows[win] = nil
				end
			end
		end,
	})
	api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(event)
			windows[tonumber(event.match)] = nil
		end,
	})
	api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			highlights = {}
			windows = {}
		end,
	})
end

return M
