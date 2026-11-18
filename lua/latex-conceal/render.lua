local api = vim.api
local ts = vim.treesitter
-- Register after native highlighting so equal-priority capture colors keep their order.
local highlighter = ts.highlighter
local namespace = api.nvim_create_namespace("latex-conceal")
-- Neovim draws ephemeral inline virtual text only in buffers that also hold a
-- stored inline mark, so a buffer with overflowing replacements gets one.
local anchor_namespace = api.nvim_create_namespace("latex-conceal-inline")
local M = {}
local margin = 20
local change_limit = 256
local windows = {}
local parsers = setmetatable({}, { __mode = "k" })
local highlights = {}
local graphemes = {}
local anchored = {}
local serial = 0
local initialized = false
local conceallevel_opts = { win = 0 }
local concealcursor_opts = { win = 0 }
local math_kinds = { inline_formula = true, displayed_equation = true, math_environment = true }
local mode_letters = { n = "n", v = "v", V = "v", ["\22"] = "v", i = "i", R = "i", c = "c" }

-- Each parser keeps a version counter and the row ranges that changed since
-- any window last looked. Neovim reports every replaced or dropped tree
-- through on_changedtree before it goes, so rows outside those ranges keep
-- their completed results across injection parses, which happen constantly
-- while scrolling Markdown.
local function parser_state(parser)
	local state = parsers[parser]
	if not state then
		state = { version = 0, reset = 0, changes = {}, index = {}, index_version = -1 }
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
		local root = tree:root()
		local first, _, last = root:range()
		n = n + 1
		index[n] = {
			first = first,
			last = last,
			tree = tree,
			root = root,
			latex = lang == "latex",
			counted = counted,
			included = lang == "latex" and tree:included_ranges(true) or nil
		}
	end)
	state.index, state.index_version = index, state.version
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
			n = n + 1
			trees[n] = entry
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

-- A mark is { row, col, opts, tree, last row }; spread marks also carry the
-- columns of the capture they belong to.
local function add(rows, first, last, mark)
	for row = math.max(first, mark[1]), math.min(last - 1, mark[5]) do
		local marks = rows[row]
		if not marks then
			marks = {}
			rows[row] = marks
		end
		marks[#marks + 1] = mark
	end
end

---@return string[]|false parts the graphemes, or false for at most one
local function split(replacement)
	local parts = graphemes[replacement]
	if parts == nil then
		parts = vim.fn.split(replacement, [[\zs]])
		parts = #parts > 1 and parts
		graphemes[replacement] = parts
	end
	return parts
end

local function anchor(buf)
	if anchored[buf] then
		return
	end
	anchored[buf] = true
	vim.schedule(function ()
		-- Reloading a buffer keeps its extmarks.
		if anchored[buf] and api.nvim_buf_is_valid(buf)
			and #api.nvim_buf_get_extmarks(buf, anchor_namespace, 0, -1, { limit = 1 }) == 0 then
			api.nvim_buf_set_extmark(buf, anchor_namespace, 0, 0, { virt_text = { { "", "Normal" } }, virt_text_pos = "inline" })
			api.nvim__redraw({ buf = buf, valid = false })
		end
	end)
end

-- Neovim conceals a range with at most one character, so a longer replacement
-- is spread over the source characters. Characters shared at either end stay
-- visible, each remaining source character shows one replacement character,
-- surplus source is hidden and surplus replacement follows as inline text.
-- Returns true when the replacement overflows its source.
local function spread(rows, first, last, line, row, sc, ec, parts, hl_group, priority, tree)
	local source = line:sub(sc + 1, ec)
	local starts = vim.str_utf_pos(source)
	local n, m = #starts, #parts
	local function char(i)
		return source:sub(starts[i], (starts[i + 1] or #source + 1) - 1)
	end
	local function column(i)
		return i > n and ec or sc + starts[i] - 1
	end
	local head, tail = 0, 0
	while head < n and head < m and char(head + 1) == parts[head + 1] do
		head = head + 1
	end
	while tail < n - head and tail < m - head and char(n - tail) == parts[m - tail] do
		tail = tail + 1
	end
	local span = { sc, ec }
	local function piece(i, j, conceal)
		add(rows, first, last, {
			row,
			column(i),
			{ end_row = row, end_col = column(j), conceal = conceal, hl_group = hl_group, priority = priority, ephemeral = true },
			tree,
			row,
			span = span
		})
	end
	local paired = math.min(n, m) - tail
	for i = head + 1, paired do
		if char(i) ~= parts[i] then
			piece(i, i + 1, parts[i])
		end
	end
	if paired < n - tail then
		piece(paired + 1, n - tail + 1, "")
	elseif paired < m - tail then
		add(rows, first, last, {
			row,
			column(n - tail + 1),
			{
				virt_text = { { table.concat(parts, "", paired + 1, m - tail), hl_group ~= 0 and hl_group or "Conceal" } },
				virt_text_pos = "inline",
				priority = priority,
				ephemeral = true
			},
			tree,
			row,
			span = span,
			inline = true
		})
		return true
	end
	return false
end

local function collect(buf, cached, first, last)
	local rows = {}
	for i, line in ipairs(api.nvim_buf_get_lines(buf, first, last, false)) do
		cached.lines[first + i - 1] = line
	end
	local query = cached.query
	local names = query.captures
	local line_count = cached.line_count
	local default_priority = vim.hl.priorities.treesitter
	local overflow = false
	for _, entry in ipairs(cached.trees) do
		if entry.first < last and entry.last >= first then
			local included = entry.included
			local contiguous = #included == 1
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
					local range, sr, sc, er, ec
					if contiguous and not (capture and (capture.range or capture.offset)) then
						-- Unmodified nodes already lie inside a contiguous tree. Avoid
						-- allocating byte ranges just to intersect them with that tree.
						sr, sc, er, ec = node:range()
					else
						range = ts.get_range(node, buf, capture)
					end
					for i = 1, range and #included or 1 do
						if range then
							sr, sc, er, ec = intersection(range, included[i])
						end
						if sr and (er > sr or ec > sc) and er + (ec > 0 and 1 or 0) <= line_count then
							local parts = sr == er and type(conceal) == "string" and graphemes[conceal]
							if parts == nil then
								parts = split(conceal)
							end
							local line = parts and cached.lines[sr]
							if line then
								overflow = spread(rows, first, last, line, sr, sc, ec, parts, hl_group, priority, tree) or overflow
							else
								local final = er - (ec == 0 and 1 or 0)
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
									tree,
									final
								}
								for row = math.max(first, sr), math.min(last - 1, final) do
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
	end
	if overflow then
		anchor(buf)
	end
	return rows
end

-- Keep whole captures together when a cache boundary cuts through a multiline
-- mark. Recollecting that viewport avoids replaying the same capture twice.
local function crosses_boundary(marks, boundary)
	if not marks then
		return false
	end
	for _, mark in ipairs(marks) do
		if mark[1] < boundary and mark[5] >= boundary then
			return true
		end
	end
	return false
end

-- A small scroll keeps the completed overlap and queries only the missing
-- strips. The new viewport replaces the old one so the cache stays bounded.
local function collect_viewport(buf, cached, previous)
	local first, last = cached.first, cached.last
	if not previous then
		return collect(buf, cached, first, last)
	end
	local low, high = math.max(first, previous.first), math.min(last, previous.last)
	if crosses_boundary(previous.rows[low], low) or crosses_boundary(previous.rows[high - 1], high) then
		return collect(buf, cached, first, last)
	end
	local rows = first < low and collect(buf, cached, first, low) or {}
	for row = low, high - 1 do
		rows[row] = previous.rows[row]
		cached.lines[row] = previous.lines[row]
	end
	if high < last then
		for row, marks in pairs(collect(buf, cached, high, last)) do
			rows[row] = marks
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

-- Native highlighting keeps its previous trees while an asynchronous parse
-- yields. Keep completed conceals too, but only where their source still
-- matches: save-time formatting may have changed or moved some of the rows.
local function pending_rows(buf, cached)
	local unchanged, valid, rows = {}, {}, {}
	if cached.sparse then
		-- Folded viewports can span thousands of hidden rows. Read only the
		-- source rows collected when Neovim actually painted them.
		for row, line in pairs(cached.lines) do
			unchanged[row] = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] == line
		end
	else
		for i, line in ipairs(api.nvim_buf_get_lines(buf, cached.first, cached.last, false)) do
			local row = cached.first + i - 1
			unchanged[row] = line == cached.lines[row]
		end
	end
	for row, marks in pairs(cached.rows) do
		for _, mark in ipairs(marks) do
			if valid[mark] == nil then
				local same = true
				for line = mark[1], mark[5] do
					if not unchanged[line] then
						same = false
						break
					end
				end
				valid[mark] = same
			end
			if valid[mark] then
				rows[row] = rows[row] or {}
				rows[row][#rows[row] + 1] = mark
			end
		end
	end
	return rows
end

-- Neovim conceals the current window's cursor line only in the modes listed
-- in 'concealcursor'.
local function cursor_line_concealed(win)
	local letter = mode_letters[api.nvim_get_mode().mode:sub(1, 1)]
	concealcursor_opts.win = win
	return letter ~= nil and api.nvim_get_option_value("concealcursor", concealcursor_opts):find(letter, 1, true) ~= nil
end

-- The columns of the cursor row that formula reveal shows as source: the
-- innermost formula around the cursor or, outside math, the conceal under it.
local function cursor_unit(cached, rows, row, col)
	for _, entry in ipairs(cached.trees) do
		if entry.first <= row and entry.last >= row then
			local node = entry.root:named_descendant_for_range(row, col, row, col + 1)
			while node do
				if math_kinds[node:type()] then
					local sr, sc, er, ec = node:range()
					return sr < row and 0 or sc, er > row and math.huge or ec
				end
				node = node:parent()
			end
		end
	end
	for _, mark in ipairs(rows[row] or {}) do
		local span, opts = mark.span, mark[3]
		local first, last
		if span then
			first, last = span[1], span[2]
		elseif opts.conceal ~= nil and mark[1] == row and opts.end_row == row then
			first, last = mark[2], opts.end_col
		end
		if first and first <= col and col < last then
			return first, last
		end
	end
end

local function within(mark, first, last)
	local span = mark.span
	if span then
		return span[1] >= first and span[2] <= last
	end
	local opts = mark[3]
	return mark[1] == opts.end_row and mark[2] >= first and opts.end_col <= last
end

-- A revealed capture keeps its highlight, as on Neovim's revealed cursor line.
local function shown(mark)
	local opts = mark.shown
	if opts == nil then
		opts = mark[3]
		if opts.conceal ~= nil then
			opts = opts.hl_group ~= 0 and {
				end_row = opts.end_row,
				end_col = opts.end_col,
				hl_group = opts.hl_group,
				priority = opts.priority,
				ephemeral = true
			}
		end
		mark.shown = opts
	end
	return opts
end

-- Neovim places the cursor without counting ephemeral inline text, and formula
-- reveal follows the cursor, so both need the current window's cursor row.
local function track_cursor(win, buf, cached, level)
	cached.level = level
	local formula = vim.g.latex_conceal_reveal == "formula"
	if not (formula or anchored[buf]) or win ~= api.nvim_get_current_win() then
		cached.cursor_row, cached.drawn = nil, nil
		return
	end
	local cursor = api.nvim_win_get_cursor(win)
	cached.cursor_row, cached.cursor_col = cursor[1] - 1, cursor[2]
	cached.reveal = formula and cursor_line_concealed(win)
end

local function redraw_row(win, row)
	api.nvim__redraw({ win = win, range = { row, row + 1 } })
end

-- Neovim repaints no rows for cursor motion within a concealed cursor line, so
-- repaint those whose revealed formula or suppressed overflow changes.
local function follow_cursor()
	local win = api.nvim_get_current_win()
	local cached = windows[win]
	if not cached then
		return
	end
	local formula, overflow = vim.g.latex_conceal_reveal == "formula", anchored[cached.buf]
	if not (formula or overflow) then
		return
	end
	local cursor = api.nvim_win_get_cursor(win)
	local row, first, last = cursor[1] - 1, false, false
	if formula and cursor_line_concealed(win) then
		first, last = cursor_unit(cached, cached.pending or cached.rows, row, cursor[2])
		first, last = first or false, last or false
	end
	local drawn = cached.drawn
	if drawn and drawn[1] == row and drawn[2] == first and drawn[3] == last then
		return
	end
	if drawn and (overflow or drawn[2]) then
		redraw_row(win, drawn[1])
	end
	if overflow or first then
		redraw_row(win, row)
	end
end

local function leave_window()
	local win = api.nvim_get_current_win()
	local cached = windows[win]
	local drawn = cached and cached.drawn
	if drawn and (drawn[2] or anchored[cached.buf]) then
		redraw_row(win, drawn[1])
	end
end

local function on_win(_, win, buf, top, bottom)
	local active = highlighter.active[buf]
	if not active then
		windows[win] = nil
		return false
	end
	-- Nothing is concealed at level 0, so skip the query and the replay entirely.
	conceallevel_opts.win = win
	local level = api.nvim_get_option_value("conceallevel", conceallevel_opts)
	if level == 0 then
		windows[win] = nil
		return false
	end
	local cached = windows[win]
	if active.parsing then
		if cached and cached.buf == buf and cached.parser == active.tree then
			local tick = api.nvim_buf_get_changedtick(buf)
			if cached.pending_tick ~= tick then
				cached.pending = cached.tick == tick and cached.rows or pending_rows(buf, cached)
				cached.pending_tick = tick
			end
			track_cursor(win, buf, cached, level)
			return true
		end
		return false
	end
	if cached then
		cached.pending, cached.pending_tick = nil, nil
	end
	local parser = active.tree
	-- Other highlighted buffers need neither parser callbacks nor a tree index.
	local query = has_latex(parser) and ts.query.get("latex", "conceals")
	if not query then
		windows[win] = nil
		return false
	end
	local state = parser_state(parser)
	if state.index_version ~= state.version then
		build_index(state, active)
	end
	local line_count = api.nvim_buf_line_count(buf)
	local last = math.min(line_count, bottom + 1)
	local sparse = last - top > api.nvim_win_get_height(win) + 1
	local tick = api.nvim_buf_get_changedtick(buf)
	-- Replaced trees arrive through the parser callbacks, so only an invalidated
	-- root (a buffer reload) can leave results stale without changing the version.
	local reusable = cached and cached.buf == buf and cached.parser == parser and cached.tick == tick and cached.query == query
		and cached.default_priority == vim.hl.priorities.treesitter
		and cached.version >= state.reset and parser:is_valid(true)
	if reusable and cached.first <= top and cached.last >= last
		and (not cached.sparse or cached.view_first == top and cached.view_last == last) then
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
		track_cursor(win, buf, cached, level)
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
	local previous
	if reusable and nearby and not sparse and not cached.sparse and cached.version >= state.reset then
		if cached.version ~= state.version then
			apply_changes(cached, state)
		end
		if not cached.ready then
			previous = cached
		end
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
		lines = {},
		trees = latex_trees(state.index, first, last),
		priorities = tree_priorities(state.index, top, bottom),
		priorities_version = state.version,
		top = top,
		bottom = bottom,
		ready = deferred and {} or nil,
		sparse = sparse,
		view_first = top,
		view_last = view_last,
		drawn = cached and cached.buf == buf and cached.drawn or nil
	}
	next_cache.rows = deferred and {} or collect_viewport(buf, next_cache, previous)
	track_cursor(win, buf, next_cache, level)
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
	local ready = not cached.pending and cached.ready
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
	local rows, priorities = cached.pending or cached.rows, cached.priorities
	local cursor_row, reveal_first, reveal_last = cached.cursor_row, false, false
	if cursor_row and cursor_row >= first and cursor_row < last then
		if cached.reveal then
			reveal_first, reveal_last = cursor_unit(cached, rows, cursor_row, cached.cursor_col)
			reveal_first, reveal_last = reveal_first or false, reveal_last or false
		end
		cached.drawn = { cursor_row, reveal_first, reveal_last }
	end
	-- Inline text would misplace the cursor, and conceallevel 3 hides replacements.
	local overflow = cached.level ~= 3
	for row = first, last - 1 do
		local marks = rows[row]
		if marks then
			local cursor = row == cursor_row
			for i = 1, #marks do
				local mark = marks[i]
				local priority = priorities[mark[4]]
				if priority and mark.serial ~= serial then
					mark.serial = serial
					local opts = mark[3]
					if mark.inline then
						opts = overflow and not cursor and opts
					elseif cursor and reveal_first and within(mark, reveal_first, reveal_last) then
						opts = shown(mark)
					end
					if opts then
						opts._subpriority = priority
						api.nvim_buf_set_extmark(buf, namespace, mark[1], mark[2], opts)
					end
				end
			end
		end
	end
	-- All columns of each collected row have already been emitted. Skip the
	-- remainder of wrapped rows and any completed empty rows in this redraw.
	local next_row = last
	while next_row < cached.last and not rows[next_row] and (not ready or ready[next_row]) do
		next_row = next_row + 1
	end
	return math.max(next_row, last_row + (last_col > 0 and 1 or 0))
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
			anchored[event.buf] = nil
			for win, cached in pairs(windows) do
				if cached.buf == event.buf then
					windows[win] = nil
				end
			end
		end
	})
	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter" }, { group = group, callback = follow_cursor })
	api.nvim_create_autocmd("WinLeave", { group = group, callback = leave_window })
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
