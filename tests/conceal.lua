-- Run: nvim --headless -u NONE -i NONE -l tests/conceal.lua
-- Requires an installed latex parser. Set NVIM_TREESITTER to test another checkout.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(root .. "/after")
if vim.env.NVIM_TREESITTER then
	local runtime = vim.env.NVIM_TREESITTER
	if vim.fn.isdirectory(runtime .. "/runtime") == 1 then
		runtime = runtime .. "/runtime"
	end
	vim.opt.runtimepath:prepend(runtime)
end
vim.cmd.runtime("plugin/latex-conceal.lua")

local query = assert(vim.treesitter.query.get("latex", "highlights"))
local tests, assertions, failures = 0, 0, {}

local function eq(expected, actual, message)
	assertions = assertions + 1
	assert(
		vim.deep_equal(expected, actual),
		(message or "unexpected result") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
	)
end

local function test(name, fn)
	tests = tests + 1
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		failures[#failures + 1] = name .. ": " .. err
	end
end

local function parse(source)
	return vim.treesitter.get_string_parser(source, "latex"):parse()[1]:root()
end

local function captures(source, node)
	local result = {}
	for id, captured, metadata in query:iter_captures(node or parse(source), source, 0, -1) do
		local capture_metadata = metadata[id] or {}
		local value = capture_metadata.conceal
		if value == nil then
			value = metadata.conceal
		end
		if value ~= nil then
			result[#result + 1] = {
				text = vim.treesitter.get_node_text(captured, source),
				name = query.captures[id],
				value = value,
				local_value = capture_metadata.conceal,
				shared_value = metadata.conceal
			}
		end
	end
	return result
end

local function values(source, text)
	local result = {}
	for _, capture in ipairs(captures(source)) do
		if capture.text == text then
			result[#result + 1] = capture.value
		end
	end
	return result
end

local function replacement(source, text, value)
	eq({ value }, values(source, text), source .. ": " .. text)
end

local function matches(source, pattern)
	local parsed = vim.treesitter.query.parse("latex", pattern)
	local result = {}
	for _, match, metadata in parsed:iter_matches(parse(source), source, 0, -1) do
		result[#result + 1] = { match = match, metadata = metadata }
	end
	return result, parsed
end

test("symbol and font mappings", function ()
	for _, pair in ipairs({
		{ [[\alpha]], "α" },
		{ [[\varepsilon]], "ε" },
		{ [[\Omega]], "Ω" },
		{ [[\infty]], "∞" },
		{ [[\coloneqq]], "≔" },
		{ [[\nexists]], "∄" },
		{ [[\gg]], "≫" },
		{ [[\simeq]], "≃" },
		{ [[\emptyset]], "∅" },
		{ [[\imath]], "ı" },
		{ [[\longleftarrow]], "⟵" },
		{ [[\Longrightarrow]], "⟹" },
		{ [[\longleftrightarrow]], "⟷" },
		{ [[\impliedby]], "⟸" },
		{ [[\oiint]], "∯" },
		{ [[\iiiint]], "⨌" },
		{ [[\coloneq]], "≔" },
		{ [[\biguplus]], "⨄" },
		{ [[\mho]], "℧" },
		{ [[\Cap]], "⋒" },
		{ [[\Cup]], "⋓" },
		{ [[\mapsfrom]], "↤" },
		{ [[\nsubset]], "⊄" },
		{ [[\lll]], "⋘" },
		{ [[\ggg]], "⋙" },
		{ [[\upalpha]], "α" },
		{ [[\mupalpha]], "α" },
		{ [[\lfloor]], "⌊" },
		{ [[\lBrack]], "⟦" },
		{ [[\mathbb{R}]], "ℝ" },
		{ [[\mathcal{A}]], "𝓐" },
		{ [[\mathfrak{H}]], "ℌ" },
		{ [[\mathscr{L}]], "𝓛" },
		{ [[\mathsf{x}]], "𝗑" }
	}) do
		replacement("$" .. pair[1] .. "$", pair[1], pair[2])
	end
	for _, source in ipairs({ [=[\[\alpha\]]=], [[\begin{equation}\alpha\end{equation}]] }) do
		replacement(source, [[\alpha]], "α")
	end
end)

test("additional mathematical alphabets", function ()
	for _, pair in ipairs({
		{ [[\mathbf{A}]], "𝐀" },
		{ [[\mathit{h}]], "ℎ" },
		{ [[\mathtt{x}]], "𝚡" },
		{ [[\mathbb{a}]], "𝕒" },
		{ [[\mathbb{0}]], "𝟘" },
		{ [[\mathsf{5}]], "𝟧" },
		{ [[\mathcal{a}]], "𝓪" },
		{ [[\mathscr{a}]], "𝓪" },
		{ [[\boldsymbol{\alpha}]], "𝜶" },
		{ [[\bm{\Gamma}]], "𝚪" }
	}) do
		replacement("$" .. pair[1] .. "$", pair[1], pair[2])
	end
	for _, command in ipairs({
		[[\mathit{1}]],
		[[\mathbf{AB}]],
		[[\mathbf{}]],
		[[\mathbf{A}{B}]],
		[[\mathbf{\unknown}]]
	}) do
		eq({}, values("$" .. command .. "$", command), "unsupported font arguments stay visible: " .. command)
	end
end)

test("operator words and unsupported spacing commands stay visible", function ()
	for _, command in ipairs({ [[\exp]], [[\Pr]], [[\not]], [[\quad]], [[\qquad]] }) do
		eq({}, values("$" .. command .. " x$", command), command)
	end
end)

test("text symbols respect text and label contexts", function ()
	for _, pair in ipairs({ { [[\textdegree]], "°" }, { [[\textalpha]], "α" } }) do
		local command = pair[1]
		replacement(command, command, pair[2])
		replacement("$\\text{" .. command .. "}$", command, pair[2])
		eq({}, values("$" .. command .. "$", command), "text commands outside text mode stay visible")
		eq({}, values("\\label{" .. command .. "}", command), "labels stay visible")
	end
end)

test("sized mathematical delimiters receive the same symbols", function ()
	for _, pair in ipairs({
		{ [[$\left\lfloor x\right\rfloor$]], [[\lfloor]], "⌊" },
		{ [[$\left\lfloor x\right\rfloor$]], [[\rfloor]], "⌋" },
		{ [[$\bigl\lVert x\bigr\rVert$]], [[\lVert]], "‖" },
		{ [[$\bigl\lVert x\bigr\rVert$]], [[\rVert]], "‖" },
		{ [[$\left\langle x\right\rangle$]], [[\langle]], "⟨" },
		{ [[$\left\langle x\right\rangle$]], [[\rangle]], "⟩" }
	}) do
		replacement(pair[1], pair[2], pair[3])
	end
	for _, source in ipairs({
		[[\left\lfloor x\right\rfloor]],
		[[$\text{\left\lfloor x\right\rfloor}$]]
	}) do
		eq({}, values(source, [[\lfloor]]), source)
		eq({}, values(source, [[\rfloor]]), source)
	end
end)

test("accent mappings", function ()
	for _, pair in ipairs({
		{ [[\'{e}]], "é" },
		{ [[\`{a}]], "à" },
		{ [[\~{a}]], "ã" },
		{ [[\^{l}]], "l̂" },
		{ [[\^{n}]], "n̂" },
		{ [[\^{L}]], "L̂" },
		{ [[\c{e}]], "ȩ" },
		{ [[\c{E}]], "Ȩ" },
		{ [[\c{g}]], "ģ" },
		{ [[\c{G}]], "Ģ" },
		{ [[\u{g}]], "ğ" },
		{ [[\u{G}]], "Ğ" },
		{ [[\k{s}]], "s̨" },
		{ [[\v{J}]], "J̌" },
		{ [[\.{i}]], "i̇" },
		{ [[\hat{x}]], "x̂" },
		{ [[\hat{\alpha}]], "α̂" },
		{ [[\vec{x}]], "x⃗" },
		{ [[\ddot{x}]], "ẍ" },
		{ [[\bar{\alpha}]], "α̅" },
		{ [[\overline{\epsilon}]], "ϵ̅" },
		{ [[\bar{\varepsilon}]], "ε̅" }
	}) do
		replacement("$" .. pair[1] .. "$", pair[1], pair[2])
	end
	eq({}, values([[$\mathbb{RR}$]], [[\mathbb{RR}]]), "unmapped arguments remain visible")
	for _, command in ipairs({ [[\vec{xy}]], [[\vec{}]], [[\vec{x}{y}]], [[\hat{\unknown}]] }) do
		eq({}, values("$" .. command .. "$", command), "unsupported accent arguments stay visible: " .. command)
	end
end)

test("math context and text exclusions", function ()
	for _, source in ipairs({
		[[\alpha x_1]],
		[[$\text{\alpha x_1}$]],
		[[$\label{alpha_1}$]]
	}) do
		eq({}, values(source, [[\alpha]]), source)
		eq({}, values(source, "_1"), source)
	end
	for _, command in ipairs({ [[\frac]], [[\dfrac]], [[\tfrac]], [[\cfrac]] }) do
		for _, source in ipairs({ command .. "{1}{2}", "$\\text{" .. command .. "{1}{2}}$" }) do
			eq({}, values(source, command), source)
		end
	end
	for _, command in ipairs({ [[\Longrightarrow]], [[\mathbf{A}]], [[\vec{x}]], [[\upalpha]] }) do
		for _, source in ipairs({ command, "$\\text{" .. command .. "}$" }) do
			eq({}, values(source, command), source)
		end
	end
end)

test("fractions use independent capture metadata", function ()
	for _, command in ipairs({ [[\frac]], [[\dfrac]], [[\tfrac]], [[\cfrac]] }) do
		local found = {}
		for _, capture in ipairs(captures("$" .. command .. "{1}{2}$")) do
			if capture.text ~= "$" then
				found[#found + 1] = { capture.text, capture.value }
				eq(capture.value, capture.local_value, "fraction value is capture-local")
				eq(nil, capture.shared_value, "fraction value must not leak to other captures")
			end
		end
		eq({ { command, "(" }, { "{", "" }, { "}", "⧸" }, { "{", " " }, { "}", ")" } }, found)
		eq({}, values("$" .. command .. "{1}$", command), "incomplete fractions stay visible")
		eq({}, values("$" .. command .. "{1}{2}{3}$", command), "unsupported extra fraction arguments stay visible")
	end
	eq({}, values([[$\cfrac[l]{1}{2}$]], [[\cfrac]]), "unsupported fraction options stay visible")
end)

test("paired mathematical delimiters preserve their contents", function ()
	for _, pair in ipairs({
		{ [[\bra]], "⟨", "|" },
		{ [[\ket]], "|", "⟩" },
		{ [[\abs]], "|", "|" },
		{ [[\norm]], "‖", "‖" }
	}) do
		local command = pair[1]
		local found = {}
		for _, capture in ipairs(captures("$" .. command .. "{x+y}$")) do
			if capture.text ~= "$" then
				found[#found + 1] = { capture.text, capture.value }
				eq(capture.value, capture.local_value, "delimiter value is capture-local")
				eq(nil, capture.shared_value, "delimiter metadata must not leak")
			end
		end
		eq({ { command, pair[2] }, { "{", "" }, { "}", pair[3] } }, found)
		for _, source in ipairs({
			command .. "{x}",
			"$\\text{" .. command .. "{x}}$",
			"$\\label{" .. command .. "{x}}$",
			"$" .. command .. "{x$",
			"$" .. command .. "{x}{y}$",
			"$" .. command .. "[x]{y}$"
		}) do
			eq({}, values(source, command), "unsupported delimiter usage stays visible: " .. source)
		end
	end
end)

test("braced and unbraced scripts", function ()
	for _, pair in ipairs({
		{ "_1", "₁" },
		{ "_i", "ᵢ" },
		{ "_=", "₌" },
		{ "_(", "₍" },
		{ "_)", "₎" },
		{ "^2", "²" },
		{ "^n", "ⁿ" },
		{ "^+", "⁺" },
		{ "^.", "˙" }
	}) do
		replacement("$x" .. pair[1] .. "$", pair[1], pair[2])
		local sigil, argument = pair[1]:sub(1, 1), pair[1]:sub(2)
		replacement("$x" .. sigil .. "{" .. argument .. "}$", argument, pair[2])
		replacement("$x" .. sigil .. "{" .. argument .. "}$", sigil, "")
	end
	eq({}, values("$x^{12}$", "^"), "unsupported groups retain the script marker")
end)

test("incomplete input and ancestor-free nodes are safe", function ()
	for _, source in ipairs({ "{a}", "{}", "{", "}", "$x_{", [[\frac{1}]], [[\section{Title}]] }) do
		captures(source)
	end
	eq(0, #matches("a", "((source_file) @root (#has-grandparent? @root source_file))"))
	eq(1, #matches("a", "((source_file) @root (#not-has-grandparent? @root source_file))"))
	eq({}, values([[\section{Title}]], "{"), "section braces stay visible")
end)

test("grandparent predicate handles multiple and absent captures", function ()
	local pattern = [[
		(source_file
		  (inline_formula (text (word) @candidate))
		  (text (word) @candidate)
		  (#has-grandparent? @candidate inline_formula))
	]]
	eq(1, #matches("$a$ b", pattern), "one matching node is sufficient")
	eq(0, #matches("$a$ b", pattern:gsub("#has%-grandparent%?", "#not-has-grandparent?")))
	eq(
		1, #matches("a", [[
		(source_file (generic_command)? @candidate (#has-grandparent? @candidate inline_formula))
	]]), "absent optional captures follow built-in ancestor semantics"
	)
end)

test("pair directive preserves unrelated metadata and ignores missing keys", function ()
	local result, parsed = matches(
		"a b",
		[[
		(text (word) @target (word) @other
		  (#set! priority 101)
		  (#set! @target note "preserved")
		  (#set-pairs! @target conceal "a" "α" "a" "wrong"))
	]]
	)
	eq(1, #result)
	local id
	for capture_id, name in ipairs(parsed.captures) do
		if name == "target" then
			id = capture_id
		end
	end
	assert(id)
	eq({ priority = "101", [id] = { note = "preserved", conceal = "α" } }, result[1].metadata)
	local unmapped = matches("z", [[((word) @target (#set-pairs! @target conceal "a" "α"))]])
	eq({}, unmapped[1].metadata, "unmapped text adds no metadata")
	local absent = matches("z", [[
		(source_file (generic_command)? @target (#set-pairs! @target conceal "a" "α"))
	]])
	eq({}, absent[1].metadata, "absent captures add no metadata")
	local repeated = matches("a z a", [[((word) @target (#set-pairs! @target conceal "a" "α"))]])
	eq(3, #repeated)
	eq(repeated[1].metadata, repeated[3].metadata, "cached lookups remain stable across matches")
	eq({}, repeated[2].metadata, "cached lookups do not leak previous matches")
end)

test("Markdown injected LaTeX", function ()
	for _, language in ipairs({ "markdown", "markdown_inline" }) do
		if not pcall(vim.treesitter.language.add, language) then
			print("SKIP Markdown injection: missing " .. language .. " parser")
			return
		end
	end
	local source = "Inline $\\alpha + x_1$.\n\n$$\\beta$$"
	local parser = vim.treesitter.get_string_parser(source, "markdown")
	parser:parse(true)
	local found = {}
	parser:for_each_tree(function (tree, language_tree)
		if language_tree:lang() == "latex" then
			for _, capture in ipairs(captures(source, tree:root())) do
				if capture.value ~= "" then
					found[capture.text] = capture.value
				end
			end
		end
	end)
	eq({ ["\\alpha"] = "α", ["_1"] = "₁", ["\\beta"] = "β" }, found)
end)

test("reloading the plugin preserves its loaded state and query behavior", function ()
	eq(true, vim.g.loaded_latex_conceal)
	vim.cmd.runtime("plugin/latex-conceal.lua")
	vim.cmd.runtime("plugin/latex-conceal.lua")
	eq(true, vim.g.loaded_latex_conceal)
	replacement([[$\alpha$]], [[\alpha]], "α")
end)

test("TeX filetypes receive a parser mapping without replacing user mappings", function ()
	local language = vim.treesitter.language
	for _, filetype in ipairs({ "tex", "plaintex" }) do
		eq("latex", language.get_lang(filetype), filetype .. " uses the LaTeX parser")
		language.register(filetype, filetype)
	end
	vim.g.loaded_latex_conceal = nil
	vim.cmd.runtime("plugin/latex-conceal.lua")
	for _, filetype in ipairs({ "tex", "plaintex" }) do
		eq("latex", language.get_lang(filetype), "unmapped filetypes receive the default")
		language.register("custom_" .. filetype, filetype)
	end
	vim.g.loaded_latex_conceal = nil
	vim.cmd.runtime("plugin/latex-conceal.lua")
	for _, filetype in ipairs({ "tex", "plaintex" }) do
		eq("custom_" .. filetype, language.get_lang(filetype), "explicit user mappings survive")
		language.register("latex", filetype)
	end
end)

test("ftplugins affect only the current window and preserve undo commands", function ()
	local current = vim.api.nvim_get_current_win()
	local original_buffer = vim.api.nvim_get_current_buf()
	local global = vim.go.conceallevel
	vim.go.conceallevel = 1
	vim.cmd.vsplit()
	local other = vim.api.nvim_get_current_win()
	vim.wo[other][0].conceallevel = 3
	vim.api.nvim_set_current_win(current)
	for _, filetype in ipairs({ "tex", "plaintex" }) do
		local buffer = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(current, buffer)
		vim.wo[current][0].conceallevel = 0
		vim.b.undo_ftplugin = "let b:conceal_test_undone = 1"
		dofile(root .. "/after/ftplugin/" .. filetype .. ".lua")
		eq(2, vim.wo[current][0].conceallevel, filetype .. " enables conceal")
		eq(3, vim.wo[other][0].conceallevel, "other windows retain their setting")
		eq(1, vim.go.conceallevel, "the global default is unchanged")
		vim.cmd(vim.b.undo_ftplugin)
		eq(1, vim.b.conceal_test_undone, "existing undo commands still run")
		eq(1, vim.wo[current][0].conceallevel, "undo restores the global default")
		eq(3, vim.wo[other][0].conceallevel, "undo affects only the current window")
		vim.api.nvim_win_set_buf(current, original_buffer)
		vim.api.nvim_buf_delete(buffer, { force = true })
	end
	vim.api.nvim_win_close(other, true)
	vim.go.conceallevel = global
end)

if #failures > 0 then
	error(table.concat(failures, "\n\n"), 0)
end
print(("Passed %d tests (%d assertions)"):format(tests, assertions))
