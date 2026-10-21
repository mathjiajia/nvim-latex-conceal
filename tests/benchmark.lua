-- TUI worker for tests/benchmark.py; each invocation measures one fresh process.
local api, ts, uv = vim.api, vim.treesitter, vim.uv
local root = vim.env.CONCEAL_BENCH_ROOT
	or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local destination = assert(vim.env.CONCEAL_BENCH_OUTPUT, "CONCEAL_BENCH_OUTPUT is required")
local result = { root = root, neovim = vim.version(), samples = {}, validation = {} }
local parser

local function save()
	local file = assert(io.open(destination, "w"))
	file:write(vim.json.encode(result))
	file:close()
end

local function schedule(fn)
	vim.schedule(function ()
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then
			result.error = tostring(err)
			local saved, save_error = pcall(save)
			if not saved then
				api.nvim_err_writeln(tostring(save_error))
			end
			vim.cmd("cquit 1")
		end
	end)
end

local function integer(name, default, minimum)
	local raw = vim.env[name]
	local value = raw == nil and default or tonumber(raw)
	assert(value and value == math.floor(value) and value >= minimum,
		name .. " must be an integer >= " .. minimum)
	return value
end

local function draw(force)
	if force then
		api.nvim__redraw({ win = 0, valid = false, flush = true })
	else
		api.nvim__redraw({ flush = true })
	end
end

-- Time the complete redraw cycle, including native parsing/highlighting and
-- the callbacks/redraws it schedules, rather than just our provider callback.
local function settle(done, started)
	started = started or uv.hrtime()
	schedule(function ()
		draw(false)
		schedule(function ()
			draw(false)
			assert(uv.hrtime() - started < 30e9, "timed out waiting for the visible parser region")
			if parser:is_valid(false, { vim.fn.line("w0") - 1, vim.fn.line("w$") }) then
				done()
			else
				settle(done, started)
			end
		end)
	end)
end

local function screen()
	local rows = {}
	for row = 1, math.min(8, api.nvim_win_get_height(0)) do
		local columns = {}
		for column = 1, api.nvim_win_get_width(0) do
			columns[#columns + 1] = vim.fn.screenstring(row, column)
		end
		rows[#rows + 1] = table.concat(columns)
	end
	return rows
end

local function isolate_runtime()
	local treesitter = vim.env.NVIM_TREESITTER
	if treesitter then
		treesitter = vim.fn.fnamemodify(treesitter, ":p") .. "/runtime"
		assert(vim.fn.isdirectory(treesitter) == 1, "NVIM_TREESITTER must contain runtime/")
		vim.opt.runtimepath:prepend(treesitter)
	end
	local parser_file = assert(api.nvim_get_runtime_file("parser/latex.so", false)[1],
		"install the latex Tree-sitter parser before benchmarking")
	local highlights_file = assert(api.nvim_get_runtime_file("queries/latex/highlights.scm", false)[1],
		"install LaTeX highlighting queries before benchmarking")
	local runtimes, seen = {}, {}
	for _, path in ipairs({ treesitter or "", vim.fn.fnamemodify(parser_file, ":h:h"),
		vim.fn.fnamemodify(highlights_file, ":h:h:h"), vim.env.VIMRUNTIME }) do
		if path ~= "" and not seen[path] then
			seen[path] = true
			runtimes[#runtimes + 1] = path
		end
	end
	vim.opt.runtimepath = runtimes
	result.parser = uv.fs_realpath(parser_file) or parser_file
end

local function document(size)
	local lines = { "\\documentclass{article}", "\\begin{document}" }
	for i = 3, size - 1 do
		local kind = i % 10
		if kind == 0 then
			lines[i] = "\\section{Section " .. i .. "}"
		elseif kind == 1 then
			lines[i] = "Let $X$ be a smooth projective variety over $\\mathbb{C}$."
		elseif kind == 2 then
			lines[i] = "Consider $D = \\alpha H + \\beta E$, with $\\alpha \\geq 0$ and $\\beta \\in \\mathbb{R}$."
		elseif kind == 3 then
			lines[i] = "$f(x) = \\frac{x^2 + " .. (i % 17 + 1) .. "}{x_1} + \\sum_{i=1}^{n} a_i$"
		elseif kind == 4 then
			lines[i] = "The following argument applies to every divisor in this family, indexed by " .. i .. "."
		elseif kind == 5 then
			lines[i] = "$\\mathcal{L} \\otimes \\mathbf{A} \\longrightarrow \\mathfrak{g}, \\hat{\\alpha} + \\vec{x}$"
		elseif kind == 6 then
			lines[i] = "$\\left\\langle x,y\\right\\rangle = \\bra{\\psi} A \\ket{\\phi}, \\abs{x} \\leq \\norm{y}$"
		elseif kind == 7 then
			lines[i] = "We conclude that $H^1(X, \\mathcal{O}) = 0$, as claimed in the proposition."
		elseif kind == 8 then
			lines[i] = "$\\int_0^1 f(x) \\, dx = \\infty, \\Gamma \\subseteq \\Omega, \\mathbf{B} = \\symbf{\\alpha}$"
		else
			lines[i] = "\\label{eq:example-" .. i .. "}"
		end
	end
	lines[size] = "\\end{document}"
	return lines
end

local function run()
	vim.fn.writefile({ tostring(uv.os_getpid()) }, destination .. ".pid")
	local size = integer("CONCEAL_BENCH_LINES", 10000, 100)
	local steps = integer("CONCEAL_BENCH_STEPS", 40, 1)
	local warmup = integer("CONCEAL_BENCH_WARMUP", 10, 0)
	result.lines, result.steps, result.warmup = size, steps, warmup
	assert(root:sub(1, 1) == "/", "CONCEAL_BENCH_ROOT must be an absolute path")
	assert(vim.fn.isdirectory(root) == 1, "benchmark root does not exist: " .. root)
	assert(#api.nvim_list_uis() > 0, "benchmark requires a real TUI; use tests/benchmark.py")
	isolate_runtime()
	vim.o.termguicolors = true
	vim.o.laststatus = 0
	vim.o.showtabline = 0
	vim.o.showmode = false
	vim.o.ruler = false
	vim.o.showcmd = false
	vim.o.swapfile = false
	vim.o.undofile = false
	vim.o.lazyredraw = false
	vim.o.scrolloff = 0
	vim.wo.wrap = false
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
	vim.wo.foldenable = false
	vim.wo.conceallevel = 2
	vim.wo.concealcursor = "n"
	vim.bo.filetype = "tex"
	vim.bo.syntax = ""
	local lines = document(size)
	api.nvim_buf_set_lines(0, 0, -1, false, lines)
	api.nvim_win_set_cursor(0, { 1, 0 })
	ts.language.register("latex", "tex")
	draw(false)
	collectgarbage("collect")
	local started = uv.hrtime()
	vim.opt.runtimepath:prepend(root)
	vim.opt.runtimepath:append(root .. "/after")
	dofile(root .. "/plugin/latex-conceal.lua")
	dofile(root .. "/after/ftplugin/tex.lua")
	-- Shared parser runtimes can contain an installed copy of this plugin. Do
	-- not merge its conceals into the checkout being measured.
	local query = table.concat(vim.fn.readfile(root .. "/queries/latex/conceals.scm"), "\n")
	ts.query.set("latex", "conceals", (query:gsub("^; extends\n", "")))
	ts.start(0, "latex")
	parser = ts.get_parser(0, "latex")
	assert(ts.query.get("latex", "highlights"), "LaTeX highlighting queries are unavailable")
	draw(false)
	settle(function ()
		result.attach_first_paint_ms = (uv.hrtime() - started) / 1e6
		result.validation.screen = screen()
		result.validation.ui = api.nvim_list_uis()
		result.validation.viewport = { width = api.nvim_win_get_width(0), height = api.nvim_win_get_height(0) }
		result.validation.highlighter = ts.highlighter.active[api.nvim_get_current_buf()] ~= nil
		assert(result.validation.highlighter, "native Tree-sitter highlighting did not attach")
		assert(table.concat(result.validation.screen, "\n"):find("α", 1, true), "concealed alpha is not visible")
		collectgarbage("collect")
		local scroll_direction = 1
		local height = api.nvim_win_get_height(0)
		local last_top = size - height + 1
		local jump_width = math.max(1, math.floor((size - 2 * height - 40) / 4))
		local math_column = assert(lines[13]:find("x^", 1, true)) - 1
		local phases = {
			{ name = "cached_redraw", prepare = function () vim.cmd("normal! gg") end,
				action = function () draw(true) end },
			{ name = "cursor", prepare = function ()
				api.nvim_win_set_cursor(0, { 12, 0 })
				vim.cmd("normal! zt")
			end, action = function (i)
				api.nvim_win_set_cursor(0, { 12, i % 2 == 0 and 15 or 25 })
				api.nvim_exec_autocmds("CursorMoved", { buf = 0, modeline = false })
				draw(false)
			end },
			{ name = "scroll_line", prepare = function () vim.cmd("normal! gg") end,
				action = function ()
					local previous_top = vim.fn.line("w0")
					if vim.fn.line("w$") >= size then
						scroll_direction = -1
					elseif previous_top <= 1 then
						scroll_direction = 1
					end
					-- Bounce so small fixtures or long runs never time no-op scrolls.
					vim.cmd("normal! " .. string.char(scroll_direction == 1 and 5 or 25))
					assert(vim.fn.line("w0") ~= previous_top, "scroll sample did not move the viewport")
					api.nvim_exec_autocmds("CursorMoved", { buf = 0, modeline = false })
					draw(false)
				end },
			{ name = "jump", prepare = function () vim.cmd("normal! gg") end,
				action = function (i)
					-- Alternate opposite ends, visiting new positions in large files.
					-- Small fixtures still jump beyond the previous padded viewport.
					local offset = (math.floor((i - 1) / 2) * 137) % jump_width
					local target = i % 2 == 1 and last_top - offset or 1 + offset
					api.nvim_win_set_cursor(0, { target, 0 })
					vim.cmd("normal! zt")
					api.nvim_exec_autocmds("CursorMoved", { buf = 0, modeline = false })
					draw(false)
				end },
			{ name = "edit", prepare = function ()
				api.nvim_win_set_cursor(0, { 12, 0 })
				vim.cmd("normal! zt")
			end, action = function (i)
				api.nvim_buf_set_text(0, 11, 0, 11, 1, { i % 2 == 0 and "C" or "c" })
				api.nvim_exec_autocmds("TextChanged", { buf = 0, modeline = false })
				draw(false)
			end },
			{ name = "edit_math", prepare = function ()
				api.nvim_win_set_cursor(0, { 13, 0 })
				vim.cmd("normal! zt")
			end, action = function (i)
				api.nvim_buf_set_text(0, 12, math_column, 12, math_column + 1, { i % 2 == 0 and "x" or "y" })
				api.nvim_exec_autocmds("TextChanged", { buf = 0, modeline = false })
				draw(false)
			end },
		}
		local function phase(index)
			local current = phases[index]
			if not current then
				save()
				vim.cmd("qa!")
				return
			end
			current.prepare()
			draw(false)
			settle(function ()
				result.samples[current.name] = {}
				local function step(i)
					local begin = uv.hrtime()
					current.action(i)
					settle(function ()
						if i > warmup then
							local samples = result.samples[current.name]
							samples[#samples + 1] = (uv.hrtime() - begin) / 1e6
						end
						if i < steps + warmup then
							schedule(function () step(i + 1) end)
						else
							schedule(function () phase(index + 1) end)
						end
					end)
				end
				step(1)
			end)
		end
		phase(1)
	end)
end

schedule(run)
