local api = vim.api
local ts = vim.treesitter
local context = require("latex-conceal.context")
-- Register after native highlighting so equal-priority capture colors keep their order.
local highlighter = ts.highlighter
local namespace = api.nvim_create_namespace("latex-conceal")
-- Neovim draws ephemeral inline virtual text only in buffers that also hold a
-- stored inline mark.
local anchor_namespace = api.nvim_create_namespace("latex-conceal-inline")
local M = {}
local margin = 20
local change_limit = 256
local windows = {}
local parsers = setmetatable({}, { __mode = "k" })
local queries = setmetatable({}, { __mode = "k" })
local graphemes = {}
local anchored = {}
local serial = 0
local initialized = false
local following = false
local conceallevel_opts = { win = 0 }
local concealcursor_opts = { win = 0 }
local math_kinds = { inline_formula = true, displayed_equation = true, math_environment = true }
local mode_letters = { n = "n", v = "v", V = "v", ["\22"] = "v", i = "i", R = "i", c = "c" }

-- Neovim reports every replaced or dropped tree through on_changedtree before
-- it goes.
local function parser_state(parser)
	local state = parsers[parser]
	if not state then
		state = { version = 0, reset = 0, changes = {}, index = {}, index_version = -1 }
		local function changed(ranges, tree)
			local version = state.version + 1
			state.version = version
			local changes = state.changes
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

-- Native highlighting numbers the visible trees in this order to break ties
-- between equal priorities.
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

local function capture_info(query)
	local info = queries[query]
	if not info then
		local groups, regions, kinds = {}, {}, 0
		for id, name in ipairs(query.captures) do
			groups[id] = name:sub(1, 1) == "_" and 0 or api.nvim_get_hl_id_by_name("@" .. name .. ".latex")
			regions[id] = context.captures[name]
			kinds = kinds + (regions[id] and 1 or 0)
		end
		info = { groups = groups, regions = kinds == 3 and regions or {}, placed = kinds == 3 }
		queries[query] = info
	end
	return info
end

---@param a Range6
---@param b Range6
local function intersection(a, b)
	if a[3] >= b[6] or b[3] >= a[6] then
		return
	end
	local first = a[3] >= b[3] and a or b
	local last = a[6] <= b[6] and a or b
	return first[1], first[2], last[4], last[5]
end

-- Included ranges are ordered and disjoint.
local function first_included(ranges, byte)
	local low, high = 1, #ranges + 1
	while low < high do
		local middle = math.floor((low + high) / 2)
		if ranges[middle][6] <= byte then
			low = middle + 1
		else
			high = middle
		end
	end
	return low
end

---@class latex_conceal.Mark
---@field [1] integer first row
---@field [2] integer column
---@field [3] vim.api.keyset.set_extmark
---@field [4] TSTree
---@field [5] integer last row
---@field span? integer[] the columns of the capture a spread mark belongs to
---@field inline? true
---@field shown? vim.api.keyset.set_extmark|false

---@param mark latex_conceal.Mark
local function add(rows, first, last, mark)
	for row = math.max(first, mark[1]), math.min(last - 1, mark[5]) do
		local marks = rows[row]
		if not marks then
			marks = {}
			rows[row] = marks
		end
		if mark[1] ~= mark[5] then
			marks.multiline = true
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

-- Neovim conceals a range with at most one character.
---@return boolean overflowed
local function spread(rows, first, last, line, row, sc, ec, parts, hl_group, priority, tree)
	local boundaries = vim.str_utf_pos(line:sub(sc + 1, ec))
	local n, m = #boundaries, #parts
	for i = 1, n do
		boundaries[i] = sc + boundaries[i] - 1
	end
	boundaries[n + 1] = ec
	local head, tail = 0, 0
	while head < n and head < m and line:sub(boundaries[head + 1] + 1, boundaries[head + 2]) == parts[head + 1] do
		head = head + 1
	end
	while tail < n - head and tail < m - head and line:sub(boundaries[n - tail] + 1, boundaries[n - tail + 1]) == parts[m - tail] do
		tail = tail + 1
	end
	local span = { sc, ec }
	local paired = math.min(n, m) - tail
	local i = head + 1
	while i <= n - tail do
		local j, conceal = i + 1, parts[i]
		if i > paired then
			j, conceal = n - tail + 1, ""
		end
		if line:sub(boundaries[i] + 1, boundaries[j]) ~= conceal then
			add(rows, first, last, {
				row,
				boundaries[i],
				{ end_row = row, end_col = boundaries[j], conceal = conceal, hl_group = hl_group, priority = priority, ephemeral = true },
				tree,
				row,
				span = span
			})
		end
		i = j
	end
	if paired >= n - tail and paired < m - tail then
		add(rows, first, last, {
			row,
			boundaries[n - tail + 1],
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

---@return boolean overflowed
local function scan(buf, cached, first, last, rows)
	local query = cached.query
	local info = capture_info(query)
	local groups, regions, placed = info.groups, info.regions, info.placed
	local line_count = cached.line_count
	local default_priority = vim.hl.priorities.treesitter
	local overflow = false
	local first_byte, last_byte
	for _, entry in ipairs(cached.trees) do
		if entry.first < last and entry.last >= first then
			local included = entry.included
			local contiguous = #included == 1
			if #included > 1 and not first_byte then
				first_byte, last_byte = api.nvim_buf_get_offset(buf, first), api.nvim_buf_get_offset(buf, last)
			end
			local tree = entry.tree
			if placed then
				context.first, context.last, context.depth = first, last, 0
			end
			for id, node, metadata in query:iter_captures(entry.root, buf, first, last) do
				local region = regions[id]
				local capture = metadata[id]
				local conceal = metadata.conceal
				if conceal == nil and capture then
					conceal = capture.conceal
				end
				local hl_group = groups[id]
				if region then
					context.record(region, node)
				elseif conceal ~= nil or (hl_group ~= 0 and not metadata["latex.conceal-only"]) then
					local priority = metadata.priority or capture and capture.priority
					priority = priority and tonumber(priority) or default_priority
					local range, sr, sc, er, ec
					local narrowed = capture and capture.range
					if narrowed and #narrowed == 6 then
						-- A directive's byte range is what the general lookup would return.
						range = narrowed
					elseif not (capture and (narrowed or capture.offset)) then
						if contiguous then
							-- Unmodified nodes already lie inside a contiguous tree.
							sr, sc, er, ec = node:range()
						else
							range = { node:range(true) }
						end
					else
						range = ts.get_range(node, buf, capture)
					end
					local start, stop = 1, nil
					if #included > 1 then
						start = first_included(included, math.max(first_byte, range[3]))
						stop = math.min(last_byte, range[6])
					end
					for i = start, range and #included or 1 do
						if range then
							local span = included[i]
							if stop and span[3] >= stop then
								break
							end
							sr, sc, er, ec = intersection(range, span)
						end
						local final = sr and er - (ec == 0 and 1 or 0)
						if sr and (er > sr or ec > sc) and er + (ec > 0 and 1 or 0) <= line_count
							and sr < last and final >= first then
							local parts = sr == er and type(conceal) == "string" and graphemes[conceal]
							if parts == nil then
								parts = split(conceal)
							end
							local line = parts and cached.lines[sr]
							if line then
								overflow = spread(rows, first, last, line, sr, sc, ec, parts, hl_group, priority, tree) or overflow
							else
								add(rows, first, last, {
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
								})
							end
						end
					end
				end
			end
		end
	end
	return overflow
end

local function collect(buf, cached, first, last)
	local rows = {}
	if #cached.trees == 0 then
		return rows
	end
	for i, line in ipairs(api.nvim_buf_get_lines(buf, first, last, false)) do
		cached.lines[first + i - 1] = line
	end
	context.buf, context.lines = buf, cached.lines
	local ok, overflow = pcall(scan, buf, cached, first, last, rows)
	context.buf, context.lines, context.last = nil, nil, 0
	if not ok then
		error(overflow, 0)
	end
	if overflow then
		anchor(buf)
	end
	return rows
end

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

local function collect_viewport(buf, cached, previous)
	local first, last = cached.first, cached.last
	if cached.ready then
		local rows = {}
		if previous then
			for row = math.max(first, previous.first), math.min(last, previous.last) - 1 do
				local marks = previous.rows[row]
				if previous.ready[row] and not (marks and marks.multiline) then
					cached.ready[row], rows[row], cached.lines[row] = true, marks, previous.lines[row]
				end
			end
		end
		return rows
	end
	if not previous then
		return collect(buf, cached, first, last)
	end
	if first == previous.first and last == previous.last then
		cached.lines = previous.lines
		return previous.rows
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
			if cached.sparse and low < high then
				for row in pairs(ready) do
					if row >= low and row <= high then
						rows[row], ready[row], cached.lines[row] = nil, nil, nil
					end
				end
			else
				for row = low, high do
					rows[row], ready[row], cached.lines[row] = nil, nil, nil
				end
			end
		end
	end
	cached.trees = latex_trees(state.index, first, last)
	cached.version = state.version
end

-- Native highlighting keeps its previous trees while an asynchronous parse
-- yields.
local function pending_rows(buf, cached)
	if not next(cached.rows) then
		return cached.rows
	end
	local run_start, rows = {}, {}
	local function compare(first, last)
		for index, line in ipairs(api.nvim_buf_get_lines(buf, first, last, false)) do
			local row = first + index - 1
			if line == cached.lines[row] then
				run_start[row] = run_start[row - 1] or row
			end
		end
	end
	if cached.sparse then
		for row in pairs(cached.lines) do
			if not cached.lines[row - 1] then
				local last = row + 1
				while cached.lines[last] do
					last = last + 1
				end
				compare(row, last)
			end
		end
	else
		compare(cached.first, cached.last)
	end
	for row, marks in pairs(cached.rows) do
		if run_start[row] and not marks.multiline then
			rows[row] = marks
		elseif run_start[row] then
			for _, mark in ipairs(marks) do
				local start = run_start[mark[5]]
				if start and start <= mark[1] then
					rows[row] = rows[row] or { multiline = true }
					rows[row][#rows[row] + 1] = mark
				end
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

---@return integer? first
---@return integer? last
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

local function redraw_row(win, row)
	api.nvim__redraw({ win = win, range = { row, row + 1 } })
end

-- Neovim repaints no rows for cursor motion within a concealed cursor line.
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
		if drawn[1] == row then
			return
		end
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

local function follow()
	following = true
	local group = api.nvim_create_augroup("latex-conceal-cursor", {})
	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter" }, { group = group, callback = follow_cursor })
	api.nvim_create_autocmd("WinLeave", { group = group, callback = leave_window })
end

-- Neovim places the cursor without counting ephemeral inline text.
local function track_cursor(win, buf, cached, level)
	cached.level = level
	local formula = vim.g.latex_conceal_reveal == "formula"
	local tracked = formula or anchored[buf]
	if tracked and not following then
		follow()
	end
	if not tracked or win ~= api.nvim_get_current_win() then
		cached.cursor_row, cached.drawn = nil, nil
		return
	end
	local cursor = api.nvim_win_get_cursor(win)
	cached.cursor_row, cached.cursor_col = cursor[1] - 1, cursor[2]
	cached.reveal = formula and cursor_line_concealed(win)
end

local function on_win(_, win, buf, top, bottom)
	local active = highlighter.active[buf]
	if not active then
		windows[win] = nil
		return false
	end
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
	local query = has_latex(parser) and ts.query.get("latex", "conceals")
	if not query then
		windows[win] = nil
		return false
	end
	local state = parser_state(parser)
	local line_count = api.nvim_buf_line_count(buf)
	local last = math.min(line_count, bottom + 1)
	local sparse = last - top > api.nvim_win_get_height(win) + 1
	local tick = api.nvim_buf_get_changedtick(buf)
	local reusable = cached and cached.buf == buf and cached.parser == parser and cached.tick == tick and cached.query == query
		and cached.default_priority == vim.hl.priorities.treesitter
		and cached.version >= state.reset and parser:is_valid(true)
	if reusable and cached.first <= top and cached.last >= last
		and (not cached.sparse or cached.view_first == top and cached.view_last == last) then
		if cached.version ~= state.version then
			cached.jumped_from = nil
			if state.index_version ~= state.version then
				build_index(state, active)
			end
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

	local edited = cached and cached.buf == buf and cached.tick ~= tick
	local nearby = not cached or top < cached.last and last > cached.first
	local deferred = edited or sparse
	local padding = not deferred and nearby and margin or 0
	local first = math.max(0, top - padding)
	local view_last = last
	last = math.min(line_count, last + padding)
	-- A parse replaces the injection-validity range.
	local range = { first, last }
	if not parser:is_valid(false, range) then
		local ranges = { range }
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
	end
	if state.index_version ~= state.version then
		build_index(state, active)
	end
	local previous, jumped_from
	if reusable and not sparse and not cached.sparse and cached.version >= state.reset then
		jumped_from = cached.jumped_from
		if jumped_from and jumped_from.version ~= state.version then
			jumped_from = nil
		end
		if nearby then
			if cached.version ~= state.version then
				apply_changes(cached, state)
			end
			previous = cached
		else
			if jumped_from and jumped_from.first <= first and jumped_from.last >= last then
				previous, first, last = jumped_from, jumped_from.first, jumped_from.last
			end
			if cached.version == state.version then
				jumped_from = {
					first = cached.first, last = cached.last, rows = cached.rows, lines = cached.lines,
					ready = cached.ready, version = cached.version
				}
			else
				jumped_from = nil
			end
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
		jumped_from = jumped_from,
		trees = latex_trees(state.index, first, last),
		priorities = tree_priorities(state.index, top, bottom),
		priorities_version = state.version,
		top = top,
		bottom = bottom,
		ready = (deferred or previous and previous.ready) and {} or nil,
		sparse = sparse,
		view_first = top,
		view_last = view_last,
		drawn = cached and cached.buf == buf and cached.drawn or nil
	}
	next_cache.rows = collect_viewport(buf, next_cache, previous)
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
			local cursor, multiline = row == cursor_row, marks.multiline
			for i = 1, #marks do
				local mark = marks[i]
				local priority = priorities[mark[4]]
				if priority and (not multiline or mark.serial ~= serial) then
					if multiline then
						mark.serial = serial
					end
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
	local function link_closing()
		api.nvim_set_hl(0, "@conceal.close.latex", { default = true, link = "@conceal.latex" })
	end
	link_closing()
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
	api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function (event)
			windows[tonumber(event.match)] = nil
		end
	})
	api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function ()
			link_closing()
			queries = setmetatable({}, { __mode = "k" })
			windows = {}
		end
	})
end

return M
