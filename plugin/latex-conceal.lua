if vim.g.loaded_latex_conceal then
	return
end
vim.g.loaded_latex_conceal = true

local ts = vim.treesitter
local get_node_text = ts.get_node_text

for _, filetype in ipairs({ "tex", "plaintex" }) do
	if ts.language.get_lang(filetype) == filetype then
		ts.language.register("latex", filetype)
	end
end

-- Query arguments are immutable, so tables derived from them are cached by
-- argument list. Weak keys release the caches when queries are reloaded.
local pred_cache = setmetatable({}, { __mode = "k" })

---@param pred  any[]
---@param first integer index of the first type name in `pred`
---@return table<string, true>
local function type_set(pred, first)
	local set = pred_cache[pred]
	if not set then
		set = {}
		for i = first, #pred do
			set[pred[i]] = true
		end
		pred_cache[pred] = set
	end
	return set
end

---@param metadata table
---@param id       integer
---@return table
local function capture_metadata(metadata, id)
	local entry = metadata[id]
	if not entry then
		entry = {}
		metadata[id] = entry
	end
	return entry
end

---@param match table<integer, TSNode[]>
---@param pred  any[]
local function has_grandparent(match, _, _, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end
	local types = type_set(pred, 3)
	for _, node in ipairs(nodes) do
		local parent = node:parent()
		local grandparent = parent and parent:parent()
		if grandparent and types[grandparent:type()] then
			return true
		end
	end
	return false
end

-- Grouping braces preserve a script's context; commands and nested scripts own theirs.
-- Returns the type of the nearest ancestor that is not a group, and its depth.
---@param node TSNode
---@return string? kind
---@return integer depth
local function enclosing(node)
	local depth = 0
	local parent = node:parent()
	while parent do
		depth = depth + 1
		local kind = parent:type()
		if kind ~= "text" and kind ~= "curly_group" then
			return kind, depth
		end
		parent = parent:parent()
	end
	return nil, depth
end

---@param match table<integer, TSNode[]>
---@param pred  any[]
local function in_script(match, _, _, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end
	for _, node in ipairs(nodes) do
		if enclosing(node) == pred[3] then
			return true
		end
	end
	return false
end

---@param match    table<integer, TSNode[]>
---@param source   integer | string
---@param pred     any[]
---@param metadata table
local function set_pairs(match, _, source, pred, metadata)
	local id, key = pred[2], pred[3]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end

	local replacements = pred_cache[pred]
	if not replacements then
		replacements = {}
		for i = 4, #pred, 2 do
			-- Preserve the first entry if a query contains duplicate keys.
			if replacements[pred[i]] == nil then
				replacements[pred[i]] = pred[i + 1]
			end
		end
		pred_cache[pred] = replacements
	end

	for _, node in ipairs(nodes) do
		local replacement = replacements[get_node_text(node, source)]
		if replacement ~= nil then
			capture_metadata(metadata, id)[key] = replacement
		end
	end
end

ts.query.add_predicate("has-grandparent?", has_grandparent, { force = true })
ts.query.add_predicate("latex-script?", in_script, { force = true })
ts.query.add_directive("set-pairs!", set_pairs, { force = true })

local math_nodes = { math_environment = true, inline_formula = true, displayed_equation = true }

-- Replacement tables load on first use, when a query needs them.
local symbols, math_symbols, exact, fonts, scripts
local function load_symbols()
	symbols = require("latex-conceal.symbols")
	-- Common math symbols take precedence over the supplementary table.
	math_symbols = {}
	for command, replacement in pairs(symbols.math) do
		math_symbols[command] = replacement
	end
	for command, replacement in pairs(symbols.math_common) do
		math_symbols[command] = replacement
	end
end

-- Emphasis wrappers are hidden in every context, like the braces they own.
local hidden_commands = { ["\\emph"] = "", ["\\mathit"] = "", ["\\textit"] = "", ["\\mathbf"] = "", ["\\textbf"] = "" }

-- The query excludes labels; enclosing text takes precedence over math.
ts.query.add_directive("latex-symbol!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end
	if not symbols then
		load_symbols()
	end
	for _, node in ipairs(nodes) do
		local text = get_node_text(node, source)
		local replacement = hidden_commands[text]
		if replacement == nil then
			local math_symbol, text_symbol = math_symbols[text], symbols.text[text]
			if math_symbol ~= nil or text_symbol ~= nil then
				local in_math, in_text, labelled = false, false, false
				local parent = node:parent()
				while parent do
					local kind = parent:type()
					if kind == "label_definition" then
						labelled = true
						break
					elseif kind == "text_mode" then
						in_text = true
					elseif math_nodes[kind] then
						in_math = true
					end
					parent = parent:parent()
				end
				if not labelled then
					if in_math and not in_text then
						replacement = math_symbol
					else
						replacement = text_symbol
					end
				end
			end
		end
		if replacement ~= nil then
			capture_metadata(metadata, id).conceal = replacement
		end
	end
end, { force = true }
)

local lookup
ts.query.add_directive("latex-conceal!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end

	lookup = lookup or require("latex-conceal").lookup
	for _, node in ipairs(nodes) do
		local replacement = lookup(get_node_text(node, source), pred[3])
		if replacement ~= nil then
			capture_metadata(metadata, id).conceal = replacement
		end
	end
end, { force = true }
)

-- Math context for font alphabets: inside math and outside labels and text.
---@param node TSNode
---@return boolean
local function in_math(node)
	local found = false
	local parent = node:parent()
	while parent do
		local kind = parent:type()
		if kind == "label_definition" or kind == "text_mode" then
			return false
		end
		found = found or math_nodes[kind] == true
		parent = parent:parent()
	end
	return found
end

-- Every supported whole-command replacement is short; longer arguments such
-- as \text{...} skip text extraction entirely.
local argument_limit
local function load_arguments()
	exact = require("latex-conceal.exact")
	fonts = require("latex-conceal.fonts")
	argument_limit = fonts.max_length
	for _, map in pairs(exact) do
		for command in pairs(map) do
			if #command > argument_limit then
				argument_limit = #command
			end
		end
	end
end

ts.query.add_directive("latex-argument!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end
	if not exact then
		load_arguments()
	end
	for _, node in ipairs(nodes) do
		if node:byte_length() <= argument_limit then
			local text = get_node_text(node, source)
			local replacement = exact.exact[text]
			if replacement ~= nil then
				capture_metadata(metadata, id).conceal = replacement
			else
				replacement = exact.bar[text] or exact.overline[text]
				if replacement == nil and in_math(node) then
					replacement = fonts.lookup(text)
				end
				if replacement ~= nil then
					local entry = capture_metadata(metadata, id)
					entry.conceal = replacement
					entry.priority = vim.hl.priorities.treesitter + 1
				end
			end
		end
	end
end, { force = true }
)

-- Preserve the script captures that can also carry a custom @conceal color.
-- In particular, some unsupported braced superscript letters were highlighted
-- without a replacement, while unbraced scripts and subscript words were not.
local function script_capture(node, source)
	local kind = node:type()
	if kind == "subscript" or kind == "superscript" then
		if node:byte_length() <= 3 then
			local replacement = scripts.inline[get_node_text(node, source)]
			return replacement, replacement ~= nil
		end
	elseif node:byte_length() == 1 then
		local text = get_node_text(node, source)
		local script, depth = enclosing(node)
		local replacements = script and scripts.braced[script]
		if replacements then
			if kind == "word" then
				local pattern = script == "subscript" and "^[0-9aeh-pr-vxA-Z]$" or "^[0-9a-zA-W]$"
				if text:match(pattern) or script == "superscript" and text == "." and depth == 3 then
					return replacements[text], true
				end
			else
				local replacement = replacements[text]
				return replacement, replacement ~= nil
			end
		end
	end
	return nil, false
end

ts.query.add_predicate("latex-script-supported?", function (match, _, source, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return false
	end
	scripts = scripts or require("latex-conceal.scripts")
	for _, node in ipairs(nodes) do
		local _, accepted = script_capture(node, source)
		if accepted then
			return true
		end
	end
	return false
end, { force = true }
)

-- A predicate rejects unsupported captures; this directive assigns replacements.
ts.query.add_directive("latex-script!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end
	scripts = scripts or require("latex-conceal.scripts")
	for _, node in ipairs(nodes) do
		local replacement = script_capture(node, source)
		if replacement ~= nil then
			capture_metadata(metadata, id).conceal = replacement
		end
	end
end, { force = true }
)

-- Hide `_` or `^` only when the entire braced value has a replacement.
ts.query.add_predicate("latex-script-marker?", function (match, _, source, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return false
	end
	scripts = scripts or require("latex-conceal.scripts")
	for _, node in ipairs(nodes) do
		-- `_{x}` is exactly four bytes.
		if node:byte_length() == 4 then
			local text = get_node_text(node, source)
			local sigil, value = text:match("^([_^]){(.)}$")
			if sigil and scripts.braced[sigil == "_" and "subscript" or "superscript"][value] ~= nil then
				return true
			end
		end
	end
	return false
end, { force = true }
)

local delimiters = {
	["\\bra"] = { "⟨", "|" },
	["\\ket"] = { "|", "⟩" },
	["\\abs"] = { "|", "|" },
	["\\norm"] = { "‖", "‖" }
}
ts.query.add_directive("latex-delimiters!", function (match, _, source, pred, metadata)
	local command, close = pred[2], pred[3]
	local nodes = match[command]
	if not nodes or #nodes == 0 then
		return
	end
	for _, node in ipairs(nodes) do
		local pair = delimiters[get_node_text(node, source)]
		if pair then
			capture_metadata(metadata, command).conceal = pair[1]
			capture_metadata(metadata, close).conceal = pair[2]
		end
	end
end, { force = true }
)

require("latex-conceal.render").setup()
