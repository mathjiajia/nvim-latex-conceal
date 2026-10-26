-- Run: nvim --headless -u NONE -i NONE -l tests/render.lua
-- Requires an installed latex parser. Set NVIM_TREESITTER to test another checkout.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(root .. "/after")
if vim.env.NVIM_TREESITTER then
	vim.opt.runtimepath:prepend(vim.env.NVIM_TREESITTER .. "/runtime")
end

local api = vim.api
require("vim.treesitter.highlighter")
local namespace = api.nvim_create_namespace("latex-conceal")
local provider, registrations, marks = nil, 0, {}
local set_provider = api.nvim_set_decoration_provider
local set_extmark = api.nvim_buf_set_extmark
api.nvim_set_decoration_provider = function (ns, callbacks)
	if ns == namespace then
		provider = callbacks
		registrations = registrations + 1
	else
		return set_provider(ns, callbacks)
	end
end
api.nvim_buf_set_extmark = function (buf, ns, row, column, opts)
	if ns == namespace then
		marks[#marks + 1] = { buf = buf, row = row, column = column, opts = vim.deepcopy(opts) }
		return #marks
	end
	return set_extmark(buf, ns, row, column, opts)
end

-- Count real query evaluations, leaving the actual parser and query predicates intact.
local query_calls = {}
local wrapped = setmetatable({}, { __mode = "k" })
local get_query = vim.treesitter.query.get
local function observe_query(language, name)
	local query = get_query(language, name)
	if language == "latex" and name == "conceals" and query and not wrapped[query] then
		wrapped[query] = true
		local iter_captures = query.iter_captures
		query.iter_captures = function (self, node, source, first, last, ...)
			query_calls[#query_calls + 1] = { first = first, last = last }
			return iter_captures(self, node, source, first, last, ...)
		end
	end
	return query
end
vim.treesitter.query.get = setmetatable({
	clear = function (_, ...)
		return get_query:clear(...)
	end,
}, {
	__index = get_query,
	__call = function (_, ...)
		return observe_query(...)
	end,
})

vim.cmd.runtime("plugin/latex-conceal.lua")
-- Keep installed copies of the plugin out of the query under test.
local conceal_query = table.concat(vim.fn.readfile(root .. "/queries/latex/conceals.scm"), "\n"):gsub("^; extends\n", "")
vim.treesitter.query.set("latex", "conceals", conceal_query)
local renderer = require("latex-conceal.render")
renderer.setup()
assert(provider and provider.on_win and provider.on_range, "renderer did not register its decoration provider")

local tests, assertions, skipped, failures = 0, 0, 0, {}
local original_win = api.nvim_get_current_win()
local original_buf = api.nvim_get_current_buf()
local original_conceallevel = vim.wo[original_win][0].conceallevel
local original_priority = vim.hl.priorities.treesitter
local buffers, windows = {}, {}

local function eq(expected, actual, message)
	assertions = assertions + 1
	assert(
		vim.deep_equal(expected, actual),
		(message or "unexpected result") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
	)
end

local function cleanup()
	vim.treesitter.query.set("latex", "conceals", conceal_query)
	for _, win in ipairs(windows) do
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
	end
	api.nvim_set_current_win(original_win)
	api.nvim_win_set_buf(original_win, original_buf)
	vim.wo[original_win][0].conceallevel = original_conceallevel
	vim.hl.priorities.treesitter = original_priority
	for _, buf in ipairs(buffers) do
		if api.nvim_buf_is_valid(buf) then
			api.nvim_buf_delete(buf, { force = true })
		end
	end
	buffers, windows, query_calls = {}, {}, {}
end

local function test(name, fn)
	local ok, result = xpcall(fn, debug.traceback)
	cleanup()
	if not ok then
		failures[#failures + 1] = name .. ": " .. result
	elseif result then
		skipped = skipped + 1
		print("SKIP " .. name .. ": " .. result)
	else
		tests = tests + 1
	end
end

local function buffer(lines, language)
	local buf = api.nvim_create_buf(false, true)
	buffers[#buffers + 1] = buf
	api.nvim_buf_set_lines(buf, 0, -1, false, type(lines) == "string" and vim.split(lines, "\n") or lines)
	api.nvim_win_set_buf(original_win, buf)
	vim.wo[original_win][0].conceallevel = 2
	vim.treesitter.start(buf, language or "latex")
	return buf, vim.treesitter.get_parser(buf, language or "latex")
end

local function draw(win, buf, first, last)
	marks = {}
	first, last = first or 0, last or api.nvim_buf_line_count(buf)
	local result = provider.on_win(nil, win, buf, first, last)
	eq("boolean", type(result), "on_win explicitly enables or skips range rendering")
	if result then
		provider.on_range(nil, win, buf, first, 0, last + 1, 0)
	end
	return vim.deepcopy(marks)
end

local function conceals(drawn)
	local result = {}
	for _, mark in ipairs(drawn) do
		if mark.opts.conceal ~= nil then
			local text = api.nvim_buf_get_text(mark.buf, mark.row, mark.column,
				mark.opts.end_row or mark.row, mark.opts.end_col, {})
			result[table.concat(text, "\n")] = mark.opts.conceal
		end
	end
	return result
end

-- Inspect retained history without adding a diagnostic API to the renderer.
local function parser_cache(parser)
	for i = 1, 100 do
		local name, value = debug.getupvalue(provider.on_win, i)
		if name == "parser_state" then
			return value(parser)
		end
		if not name then
			break
		end
	end
	error("renderer parser state was not found")
end

test("completed results are reused on an unchanged redraw", function ()
	renderer.setup()
	eq(1, registrations, "setup is idempotent")
	local buf = buffer([[$\alpha + x_1 + \mathbb{R}$]])
	local first = draw(original_win, buf)
	local count = #query_calls
	eq(true, count > 0, "the first redraw evaluates the conceal query")
	local replacements = conceals(first)
	eq("α", replacements["\\alpha"])
	eq("₁", replacements["_1"])
	eq("ℝ", replacements["\\mathbb{R}"])
	for _, mark in ipairs(first) do
		eq(true, mark.opts.ephemeral, "the cache replays ephemeral decorations")
	end
	eq(first, draw(original_win, buf), "cached decorations preserve ranges and metadata")
	eq(count, #query_calls, "unchanged redraws do not evaluate conceal queries")
end)

test("save-time rewrites retain unchanged conceals while native parsing yields", function ()
	local lines = { [[$\alpha + x_1$]], [[$\beta + \mathbb{R}$]] }
	local buf, parser = buffer(lines)
	local first = draw(original_win, buf)
	local active = vim.treesitter.highlighter.active[buf]
	local parse = parser.parse
	parser.parse = function (self, ...)
		assert(not active.parsing, "conceal redraws must not interrupt an asynchronous parse")
		return parse(self, ...)
	end
	local count = #query_calls
	-- A formatter can replace the whole buffer even when its text is unchanged.
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	active.parsing = true
	eq(first, draw(original_win, buf), "a pending parse must not expose the whole source")
	eq(first, draw(original_win, buf), "conceals survive every intermediate redraw")
	eq(count, #query_calls, "pending parses replay completed results without evaluating queries")

	api.nvim_buf_set_text(buf, 0, 1, 0, 7, { [[\gamma]] })
	local replacements = conceals(draw(original_win, buf))
	eq(nil, replacements["\\alpha"], "changed rows cannot replay old byte ranges")
	eq(nil, replacements["\\gamma"], "changed rows wait for the new syntax tree")
	eq("β", replacements["\\beta"], "unchanged rows remain concealed")
	eq("ℝ", replacements["\\mathbb{R}"])
	eq(count, #query_calls)

	active.parsing = false
	replacements = conceals(draw(original_win, buf))
	eq("γ", replacements["\\gamma"], "the completed parse refreshes changed rows")
	eq("β", replacements["\\beta"])
	eq(true, #query_calls > count)
end)

test("pending multiline conceals require every source row to match", function ()
	vim.treesitter.query.set("latex", "conceals", conceal_query .. [[
		((generic_command
		  command: (command_name) @_command) @conceal
		  (#eq? @_command "\\foo")
		  (#set! conceal "X"))
	]])
	local buf = buffer({ [[\foo{]], "alpha", "}", [[$\beta$]] })
	eq("X", conceals(draw(original_win, buf))["\\foo{\nalpha\n}"])
	local count = #query_calls
	local active = vim.treesitter.highlighter.active[buf]
	active.parsing = true
	api.nvim_buf_set_lines(buf, 1, 2, false, { "gamma" })
	local replacements = conceals(draw(original_win, buf))
	eq(nil, replacements["\\foo{\ngamma\n}"], "a changed interior row invalidates the entire mark")
	eq("β", replacements["\\beta"], "other conceals remain visible")
	eq(count, #query_calls)
	active.parsing = false
	eq("X", conceals(draw(original_win, buf))["\\foo{\ngamma\n}"])
end)

test("same-shape command edits invalidate completed results", function ()
	local buf = buffer([[$\alpha$]])
	eq("α", conceals(draw(original_win, buf))["\\alpha"])
	local count = #query_calls
	api.nvim_buf_set_text(buf, 0, 1, 0, 7, { [[\gamma]] })
	local replacements = conceals(draw(original_win, buf))
	eq("γ", replacements["\\gamma"])
	eq(nil, replacements["\\alpha"])
	eq(true, #query_calls > count, "text changes invalidate even when node types are unchanged")
	count = #query_calls
	draw(original_win, buf)
	eq(count, #query_calls, "the edited result is cached")
end)

test("font commands inside scripts retain a single replacement across edits", function ()
	local buf = buffer([[\(m_{\mathbb{R}}\)]])
	local first = draw(original_win, buf)
	local replacements = conceals(first)
	eq("ℝ", replacements["\\mathbb{R}"])
	eq(nil, replacements.R, "the font argument must not also become a subscript")
	eq(first, draw(original_win, buf), "cached redraws retain the same font replacement")
	api.nvim_buf_set_lines(buf, 0, -1, false, { [[\(m^{\mathbb{Q}}\)]] })
	replacements = conceals(draw(original_win, buf))
	eq("ℚ", replacements["\\mathbb{Q}"])
	eq(nil, replacements.Q, "the edited font argument must not also become a superscript")
end)

test("after an edit only repainted rows refill and empty results are cached", function ()
	local lines = {}
	for i = 1, 100 do
		lines[i] = [[$\alpha + \beta$]]
	end
	lines[21], lines[22] = "", "ordinary text"
	local buf = buffer(lines)
	draw(original_win, buf, 0, 39)
	api.nvim_buf_set_text(buf, 10, 1, 10, 7, { [[\gamma]] })
	local count = #query_calls
	eq(true, provider.on_win(nil, original_win, buf, 0, 39))
	eq(count, #query_calls, "an edit does not eagerly evaluate the whole viewport")

	local function repaint(first_row, first_col, last_row, last_col)
		marks = {}
		provider.on_range(nil, original_win, buf, first_row, first_col, last_row, last_col)
		return vim.deepcopy(marks)
	end

	local changed = repaint(10, 2, 10, 5)
	eq(count + 1, #query_calls, "a partial-line redraw evaluates one row")
	eq({ first = 10, last = 11 }, query_calls[#query_calls])
	local replacements = conceals(changed)
	eq("γ", replacements["\\gamma"], "the edited replacement is current")
	eq(nil, replacements["\\alpha"], "old replacements were discarded")
	eq("β", replacements["\\beta"], "a partial-column redraw caches the complete row")
	count = #query_calls
	eq(changed, repaint(10, 12, 10, 14), "another column range replays the complete row")
	eq(count, #query_calls, "same-row redraws reuse their results")

	eq("α", conceals(repaint(15, 0, 16, 0))["\\alpha"])
	eq(count + 1, #query_calls, "another row is computed when first repainted")
	eq({ first = 15, last = 16 }, query_calls[#query_calls])
	count = #query_calls
	repaint(15, 0, 16, 0)
	eq(count, #query_calls, "the later row is also cached")

	eq({}, repaint(20, 0, 22, 0), "blank and nonmatching rows produce no decorations")
	eq(count + 1, #query_calls)
	eq({ first = 20, last = 22 }, query_calls[#query_calls])
	count = #query_calls
	eq({}, repaint(20, 0, 22, 0))
	eq(count, #query_calls, "empty results do not trigger repeated query evaluation")
end)

test("math and text context changes remove stale conceals", function ()
	local buf = buffer([[$\alpha$]])
	eq("α", conceals(draw(original_win, buf))["\\alpha"])
	api.nvim_buf_set_lines(buf, 0, -1, false, { [[\alpha]] })
	eq(nil, conceals(draw(original_win, buf))["\\alpha"], "removing math delimiters restores source")
	api.nvim_buf_set_lines(buf, 0, -1, false, { [[$\text{\alpha}$]] })
	eq(nil, conceals(draw(original_win, buf))["\\alpha"], "enclosing text suppresses a math symbol")
	api.nvim_buf_set_lines(buf, 0, -1, false, { [[$\unknown{\alpha}$]] })
	eq("α", conceals(draw(original_win, buf))["\\alpha"], "restoring math context rebuilds the cache")
end)

test("off-screen environment edits invalidate visible results", function ()
	local lines = { [[\begin{equation}]] }
	for i = 2, 100 do
		lines[i] = [[\alpha]]
	end
	lines[101] = [[\end{equation}]]
	local buf = buffer(lines)
	eq("α", conceals(draw(original_win, buf, 60, 70))["\\alpha"])
	api.nvim_buf_set_lines(buf, 100, 101, false, { [[\end{quote}]] })
	api.nvim_buf_set_lines(buf, 0, 1, false, { [[\begin{quote}]] })
	eq(nil, conceals(draw(original_win, buf, 60, 70))["\\alpha"],
		"an enclosing environment can change visible semantics from outside the cache")
end)

test("parser invalidation rebuilds without a changed buffer tick", function ()
	local buf, parser = buffer([[$\alpha$]])
	draw(original_win, buf)
	local count, tick = #query_calls, api.nvim_buf_get_changedtick(buf)
	parser:invalidate(true)
	eq(tick, api.nvim_buf_get_changedtick(buf))
	eq("α", conceals(draw(original_win, buf))["\\alpha"])
	eq(true, #query_calls > count, "an invalid tree cannot reuse completed results")
	count = #query_calls
	parser:invalidate(true)
	parser:parse(true)
	eq(tick, api.nvim_buf_get_changedtick(buf))
	eq("α", conceals(draw(original_win, buf))["\\alpha"])
	eq(true, #query_calls > count, "a tree rebuilt before redraw invalidates completed results")
end)

test("query replacement invalidates cached metadata", function ()
	local buf = buffer([[$\alpha$]])
	draw(original_win, buf)
	local tick = api.nvim_buf_get_changedtick(buf)
	vim.treesitter.query.set("latex", "conceals", [[
		((command_name) @replacement (#eq? @replacement "\\alpha") (#set! conceal "Q"))
	]])
	eq(tick, api.nvim_buf_get_changedtick(buf))
	eq("Q", conceals(draw(original_win, buf))["\\alpha"], "query.set takes effect on the next redraw")
	vim.treesitter.query.set("latex", "conceals", "")
	eq({}, conceals(draw(original_win, buf)), "removing query patterns clears previous results")
end)

test("custom queries preserve highlights, offsets and metadata precedence", function ()
	vim.treesitter.query.set("latex", "conceals", [[
		((command_name) @keyword
		  (#eq? @keyword "\\alpha")
		  (#offset! @keyword 0 1 0 0)
		  (#set! @keyword priority 140))
		((command_name) @conceal
		  (#eq? @conceal "\\beta")
		  (#set! conceal "B")
		  (#set! @conceal conceal "C")
		  (#set! priority 151)
		  (#set! @conceal priority 150))
		(generic_command
		  command: (command_name) @_command
		  arg: (curly_group) @number
		  (#eq? @_command "\\foo")
		  (#offset! @number 0 1 0 -1)
		  (#set! @number conceal "N")
		  (#set! @number priority 152))
	]])
	local source = [[$\alpha + \beta + \foo{42}$]]
	local buf = buffer(source)
	local first = draw(original_win, buf)
	local visible = {}
	for _, mark in ipairs(first) do
		-- Internal helper captures may be omitted because they have no display effect.
		if mark.opts.hl_group ~= 0 or mark.opts.conceal ~= nil then
			visible[mark.opts.hl_group] = mark
		end
	end
	local function check(name, text, conceal, priority)
		local mark = visible[api.nvim_get_hl_id_by_name("@" .. name .. ".latex")]
		eq(true, mark ~= nil, name .. " retains its decoration")
		local start, finish = source:find(text, 1, true)
		eq({ 0, start - 1, 0, finish },
			{ mark.row, mark.column, mark.opts.end_row, mark.opts.end_col }, "offsets preserve byte ranges")
		eq(conceal, mark.opts.conceal)
		eq(priority, mark.opts.priority)
	end
	check("keyword", "alpha", nil, 140)
	check("conceal", [[\beta]], "B", 151)
	check("number", "42", "N", 152)
	eq(3, vim.tbl_count(visible), "helper captures introduce no visible decoration")
	eq(first, draw(original_win, buf), "cached results preserve custom highlight and conceal metadata")
end)

test("default priority changes refresh generated and cached priorities", function ()
	vim.hl.priorities.treesitter = original_priority + 75
	vim.treesitter.query.set("latex", "conceals", conceal_query .. [[
		((command_name) @conceal (#eq? @conceal "\\beta") (#set! conceal "B") (#set! priority 101))
	]])
	local buf = buffer([[$\alpha + \beta + \mathbf{A} + \hat{\alpha}$]])
	local tick = api.nvim_buf_get_changedtick(buf)
	local function check_priorities()
		local drawn, priorities = draw(original_win, buf), {}
		for _, mark in ipairs(drawn) do
			if mark.opts.conceal then
				priorities[mark.opts.conceal] = mark.opts.priority
			end
		end
		eq(vim.hl.priorities.treesitter, priorities["α"], "ordinary captures use the configured native priority")
		eq(vim.hl.priorities.treesitter + 1, priorities["𝐀"], "whole fonts outrank ordinary captures")
		eq(vim.hl.priorities.treesitter + 1, priorities["α̂"], "whole accents outrank their argument captures")
		eq(101, priorities.B, "explicit query priorities remain authoritative, including the old generated value")
		return drawn
	end
	local first = check_priorities()
	local count = #query_calls
	eq(first, draw(original_win, buf), "unchanged priorities reuse identical decorations")
	eq(count, #query_calls, "unchanged priorities do not evaluate the query again")

	vim.hl.priorities.treesitter = original_priority + 125
	check_priorities()
	eq(tick, api.nvim_buf_get_changedtick(buf), "the priority change requires no buffer edit")
	eq(true, #query_calls > count, "changing the default invalidates cached priorities")
	count = #query_calls
	check_priorities()
	eq(count, #query_calls, "updated priorities are cached for later redraws")
end)

test("viewport caches remain bounded and reuse their scroll margin", function ()
	local lines = {}
	for i = 1, 400 do
		lines[i] = [[$\alpha + x_1$]]
	end
	local buf, parser = buffer(lines)
	local parse_ranges = {}
	local parse = parser.parse
	parser.parse = function (self, range, ...)
		parse_ranges[#parse_ranges + 1] = vim.deepcopy(range)
		return parse(self, range, ...)
	end
	local first = draw(original_win, buf, 100, 110)
	eq(true, #first > 0)
	for _, call in ipairs(query_calls) do
		eq(true, call.first >= 80 and call.last <= 131, "query evaluation stays near the viewport")
	end
	for _, range in ipairs(parse_ranges) do
		eq("table", type(range), "parsing requests a viewport instead of the entire document")
		for _, region in ipairs(type(range[1]) == "table" and range or { range }) do
			eq(true, region[1] >= 80 and region[2] <= 131, "injection parsing stays near the viewport")
		end
	end
	local count = #query_calls
	draw(original_win, buf, 105, 115)
	eq(count, #query_calls, "small scrolls reuse the cached margin")
	local distant = draw(original_win, buf, 250, 260)
	eq(true, #query_calls > count, "distant scrolls compute a new viewport")
	for _, mark in ipairs(distant) do
		eq(true, mark.row >= 230 and mark.row < 281, "marks from the old viewport are not replayed")
	end
end)

test("folded viewports query visible rows and discard results when their span changes", function ()
	local lines = {}
	for i = 1, 1000 do
		lines[i] = [[$\alpha$]]
	end
	local buf = buffer(lines)
	eq(true, provider.on_win(nil, original_win, buf, 0, 900))
	eq(0, #query_calls, "a folded viewport does not query hundreds of hidden rows")
	local function repaint(row)
		marks = {}
		provider.on_range(nil, original_win, buf, row, 0, row + 1, 0)
		return vim.deepcopy(marks)
	end
	eq("α", conceals(repaint(0))["\\alpha"])
	eq("α", conceals(repaint(900))["\\alpha"])
	eq({ { first = 0, last = 1 }, { first = 900, last = 901 } }, query_calls,
		"only repainted rows are queried on either side of the fold")
	eq(true, provider.on_win(nil, original_win, buf, 0, 900))
	repaint(0)
	repaint(900)
	eq(2, #query_calls, "the same folded viewport reuses both rows")
	local active = vim.treesitter.highlighter.active[buf]
	active.parsing = true
	eq(true, provider.on_win(nil, original_win, buf, 0, 900))
	eq("α", conceals(repaint(0))["\\alpha"])
	eq("α", conceals(repaint(900))["\\alpha"], "distant visible rows retain their own source snapshots")
	eq(2, #query_calls, "pending parses also preserve sparse results")
	active.parsing = false

	eq(true, provider.on_win(nil, original_win, buf, 0, 800))
	eq(2, #query_calls, "moving a folded viewport still defers query evaluation")
	eq({}, repaint(900), "rows outside the new viewport are not replayed")
	eq(2, #query_calls)
	eq("α", conceals(repaint(0))["\\alpha"])
	eq(3, #query_calls, "changing the logical span discards old row results instead of accumulating them")
	eq({ first = 0, last = 1 }, query_calls[#query_calls])
end)

test("splits retain independent viewport results", function ()
	local lines = {}
	for i = 1, 200 do
		lines[i] = i < 100 and [[$\alpha$]] or [[$\beta$]]
	end
	local buf = buffer(lines)
	eq("α", conceals(draw(original_win, buf, 0, 10))["\\alpha"])
	vim.cmd.vsplit()
	local other = api.nvim_get_current_win()
	windows[#windows + 1] = other
	vim.wo[other][0].conceallevel = 2
	eq("β", conceals(draw(other, buf, 150, 160))["\\beta"])
	local count = #query_calls
	eq("α", conceals(draw(original_win, buf, 0, 10))["\\alpha"])
	eq(count, #query_calls, "drawing another split does not evict this window's cache")
	api.nvim_win_close(other, true)
	eq("α", conceals(draw(original_win, buf, 0, 10))["\\alpha"], "closing a split preserves surviving windows")
end)

test("hidden tabs do not retain unbounded edit history", function ()
	local buf, parser = buffer([[$\alpha$]])
	draw(original_win, buf)
	vim.cmd.tabnew()
	local other = api.nvim_get_current_win()
	windows[#windows + 1] = other
	api.nvim_win_set_buf(other, buf)
	draw(other, buf)
	local state = parser_cache(parser)
	for i = 1, 301 do
		api.nvim_buf_set_text(buf, 0, 1, 0, 7, { i % 2 == 0 and [[\alpha]] or [[\gamma]] })
		draw(other, buf)
	end
	eq(true, #state.changes <= 256, "an obsolete hidden cache cannot retain every edit")
	api.nvim_set_current_win(original_win)
	local replacements = conceals(draw(original_win, buf))
	eq("γ", replacements["\\gamma"], "returning to the hidden tab renders the current buffer")
	eq(nil, replacements["\\alpha"], "old tab results are discarded")
end)

test("same-tick reparses keep bounded history and rebuild older tabs", function ()
	local buf, parser = buffer([[$\alpha$]])
	local first = draw(original_win, buf)
	vim.cmd.tabnew()
	local other = api.nvim_get_current_win()
	windows[#windows + 1] = other
	api.nvim_win_set_buf(other, buf)
	draw(other, buf)
	local tick, state = api.nvim_buf_get_changedtick(buf), parser_cache(parser)
	-- Parser clients may rebuild trees repeatedly before either tab is drawn.
	for i = 1, 600 do
		parser:invalidate()
		parser:parse(true)
		if i % 100 == 0 then
			eq(true, #state.changes <= 256, "pending parser history is bounded even without redraws")
		end
	end
	eq(tick, api.nvim_buf_get_changedtick(buf), "reparses do not advance the buffer tick")
	eq(first, draw(other, buf), "the current tab rebuilds after history has been discarded")
	api.nvim_set_current_win(original_win)
	eq(first, draw(original_win, buf), "the older hidden tab also rebuilds its decorations")
end)

test("window buffer changes and buffer deletion cannot replay stale marks", function ()
	local first = buffer([[$\alpha$]])
	draw(original_win, first)
	local second = buffer([[$\beta$]])
	local replacements = conceals(draw(original_win, second))
	eq("β", replacements["\\beta"])
	eq(nil, replacements["\\alpha"])
	api.nvim_buf_delete(first, { force = true })
	eq("β", conceals(draw(original_win, second))["\\beta"])
	api.nvim_buf_delete(second, { force = true })
	local third = buffer([[$\gamma$]])
	eq("γ", conceals(draw(original_win, third))["\\gamma"])
end)

test("conceal options remain native and stopping highlighting disables rendering", function ()
	local buf = buffer([[$\alpha$]])
	local first = draw(original_win, buf)
	local count = #query_calls
	vim.wo[original_win][0].conceallevel = 0
	eq(first, draw(original_win, buf), "native conceallevel controls visibility while highlights are preserved")
	eq(0, vim.wo[original_win][0].conceallevel, "the renderer preserves window options")
	eq(count, #query_calls, "changing conceallevel does not reevaluate the query")
	vim.wo[original_win][0].conceallevel = 2
	eq("α", conceals(draw(original_win, buf))["\\alpha"])
	vim.treesitter.stop(buf)
	count = #query_calls
	eq({}, draw(original_win, buf))
	eq(count, #query_calls, "stopping the native highlighter disables conceal rendering")
	api.nvim_buf_set_lines(buf, 0, -1, false, { [[$\beta$]] })
	vim.treesitter.start(buf, "latex")
	eq("β", conceals(draw(original_win, buf))["\\beta"], "restarting restores current results")
end)

test("Markdown injections are cached and respond to edits", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			return "missing " .. language .. " parser"
		end
	end
	local buf, parser = buffer({ [[Inline $\alpha + x_1$.]], "", [[$$\beta$$]] }, "markdown")
	-- Native highlighting discovers injections before this provider runs.
	parser:parse({ 0, 3 })
	local replacements = conceals(draw(original_win, buf))
	eq("α", replacements["\\alpha"])
	eq("₁", replacements["_1"])
	eq("β", replacements["\\beta"])
	local count = #query_calls
	draw(original_win, buf)
	eq(count, #query_calls, "unchanged injected trees reuse completed results")
	api.nvim_buf_set_lines(buf, 0, 1, false, { [[Inline \alpha + x_1.]] })
	replacements = conceals(draw(original_win, buf))
	eq(nil, replacements["\\alpha"], "removing an injection clears its conceals")
	eq(nil, replacements["_1"])
	eq("β", replacements["\\beta"], "other injections remain concealed")
	api.nvim_buf_set_lines(buf, 0, 1, false, { [[Inline $\gamma$.]] })
	eq("γ", conceals(draw(original_win, buf))["\\gamma"], "new injections are discovered")
end)

test("custom ranges stay inside separate Markdown math injections", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			return "missing " .. language .. " parser"
		end
	end
	vim.treesitter.query.set("latex", "conceals", [[
		((source_file) @conceal
		  (#offset! @conceal 0 -2 0 2)
		  (#set! conceal "X")
		  (#set! priority 143))
	]])
	local source = [[Before $\alpha$ between $\beta$ after.]]
	local buf, parser = buffer(source, "markdown")
	parser:parse({ 0, 1 })
	local first = draw(original_win, buf)
	eq(2, #first, "each injected formula receives one decoration")
	for i, formula in ipairs({ [[$\alpha$]], [[$\beta$]] }) do
		local start, finish = source:find(formula, 1, true)
		local mark = first[i]
		eq({ 0, start - 1, 0, finish },
			{ mark.row, mark.column, mark.opts.end_row, mark.opts.end_col },
			"offsets cannot conceal the prose surrounding an injection")
		eq("X", mark.opts.conceal)
		eq(143, mark.opts.priority)
	end
	eq(first, draw(original_win, buf), "cached ranges remain clipped to their injections")
end)

test("scrolling discovers newly exposed Markdown injections", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			return "missing " .. language .. " parser"
		end
	end
	local lines = {}
	for row = 1, 100 do
		lines[row] = row % 2 == 0 and "" or "Ordinary text."
	end
	lines[1], lines[71] = [[$\alpha$]], [[$\beta$]]
	local buf, parser = buffer(lines, "markdown")
	parser:parse({ 0, 3 })
	eq("α", conceals(draw(original_win, buf, 0, 2))["\\alpha"])
	-- Native highlighting discovers the newly visible injections before this provider.
	parser:parse({ 70, 73 })
	local shown = conceals(draw(original_win, buf, 70, 72))
	eq("β", shown["\\beta"], "newly exposed formulas are included after scrolling")
	eq(nil, shown["\\alpha"], "the previous viewport's formulas are not replayed")
	local count = #query_calls
	eq(shown, conceals(draw(original_win, buf, 70, 72)))
	eq(count, #query_calls, "newly discovered injection results are cached")
	parser:parse({ 0, 3 })
	eq("α", conceals(draw(original_win, buf, 0, 2))["\\alpha"], "scrolling back restores the earlier formula")
end)

test("parsing injections elsewhere keeps completed rows", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			return "missing " .. language .. " parser"
		end
	end
	local lines = {}
	for row = 1, 100 do
		lines[row] = row % 2 == 0 and "" or "Ordinary text."
	end
	lines[1], lines[3], lines[71] = [[$\alpha$]], [[$\beta$]], [[$\gamma$]]
	local buf, parser = buffer(lines, "markdown")
	parser:parse({ 0, 4 })
	local first = draw(original_win, buf, 0, 3)
	local replacements = conceals(first)
	eq("α", replacements["\\alpha"])
	eq("β", replacements["\\beta"])
	local count = #query_calls
	-- Scrolling another split discovers injections elsewhere, and native
	-- highlighting parses this window again before the provider runs. Neovim may
	-- rebuild the visible formulas' trees while doing so, but the prose rows stay complete.
	parser:parse({ 70, 73 })
	parser:parse({ 0, 4 })
	eq(first, draw(original_win, buf, 0, 3), "unrelated trees preserve completed decorations")
	for i = count + 1, #query_calls do
		local call = query_calls[i]
		eq(true, call.last - call.first == 1 and (call.first == 0 or call.first == 2),
			"only rows covered by rebuilt trees are evaluated again: " .. vim.inspect(call))
	end
	-- Rebuilt trees invalidate exactly the rows they cover, even without an edit.
	count = #query_calls
	parser:children().markdown_inline:children().latex:invalidate()
	parser:parse({ 0, 4 })
	eq(first, draw(original_win, buf, 0, 3), "rebuilt trees reproduce the same decorations")
	eq({ { first = 0, last = 1 }, { first = 2, last = 3 } }, { query_calls[count + 1], query_calls[count + 2] },
		"rows between rebuilt trees are not evaluated again")
	eq(count + 2, #query_calls)
end)

test("conceals follow the native highlighter's tree order", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			return "missing " .. language .. " parser"
		end
	end
	local buf, parser = buffer({ [[Inline $\alpha$ and $\beta$ then $\gamma$.]], "", [[$$\delta$$]] }, "markdown")
	parser:parse({ 0, 3 })
	local drawn = draw(original_win, buf, 0, 2)
	local replacements = conceals(drawn)
	eq({ "α", "β", "γ", "δ" },
		{ replacements["\\alpha"], replacements["\\beta"], replacements["\\gamma"], replacements["\\delta"] },
		"every formula is concealed")
	local active = vim.treesitter.highlighter.active[buf]
	active:prepare_highlight_states(0, 2)
	local expected = {}
	for index, state in ipairs(active._highlight_states) do
		if state.highlighter_query.lang == "latex" then
			for _, range in ipairs(state.tstree:included_ranges(false)) do
				expected[#expected + 1] = { index = index, unpack(range) }
			end
		end
	end
	for _, mark in ipairs(drawn) do
		local found
		for _, state in ipairs(expected) do
			local after_start = mark.row > state[1] or mark.row == state[1] and mark.column >= state[2]
			local end_row, end_col = mark.opts.end_row, mark.opts.end_col
			local before_end = end_row < state[3] or end_row == state[3] and end_col <= state[4]
			if after_start and before_end then
				found = state.index
			end
		end
		eq(found, mark.opts._subpriority, "a conceal uses the subpriority of its injected tree")
	end
end)

if #failures > 0 then
	error(table.concat(failures, "\n\n"), 0)
end
print(("Passed %d renderer tests (%d assertions; %d skipped)"):format(tests, assertions, skipped))
