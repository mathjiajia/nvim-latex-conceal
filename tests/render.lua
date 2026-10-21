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
local renderer = require("latex-conceal.render")
renderer.setup()
assert(provider and provider.on_win and provider.on_range, "renderer did not register its decoration provider")

local tests, assertions, failures = 0, 0, {}
local original_win = api.nvim_get_current_win()
local original_buf = api.nvim_get_current_buf()
local original_conceallevel = vim.wo[original_win][0].conceallevel
local buffers, windows = {}, {}

local function eq(expected, actual, message)
	assertions = assertions + 1
	assert(
		vim.deep_equal(expected, actual),
		(message or "unexpected result") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
	)
end

local function cleanup()
	vim.treesitter.query.set("latex", "conceals", nil)
	for _, win in ipairs(windows) do
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
	end
	api.nvim_set_current_win(original_win)
	api.nvim_win_set_buf(original_win, original_buf)
	vim.wo[original_win][0].conceallevel = original_conceallevel
	for _, buf in ipairs(buffers) do
		if api.nvim_buf_is_valid(buf) then
			api.nvim_buf_delete(buf, { force = true })
		end
	end
	buffers, windows, query_calls = {}, {}, {}
end

local function test(name, fn)
	tests = tests + 1
	local ok, err = xpcall(fn, debug.traceback)
	cleanup()
	if not ok then
		failures[#failures + 1] = name .. ": " .. err
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
			print("SKIP Markdown injection: missing " .. language .. " parser")
			return
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

if #failures > 0 then
	error(table.concat(failures, "\n\n"), 0)
end
print(("Passed %d renderer tests (%d assertions)"):format(tests, assertions))
