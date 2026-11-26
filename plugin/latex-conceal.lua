if vim.g.loaded_latex_conceal then
	return
end
vim.g.loaded_latex_conceal = true

local ts = vim.treesitter
local get_text = vim.api.nvim_buf_get_text
local context = require("latex-conceal.context")

-- The common single-line buffer case does not need the general helper's
-- metadata and byte-range tables.
local function get_node_text(node, source)
	if type(source) == "number" then
		local sr, sc, er, ec = node:range()
		if sr == er then
			local line = source == context.buf and context.lines[sr]
			if line then
				return line:sub(sc + 1, ec)
			end
			return get_text(source, sr, sc, er, ec, {})[1]
		end
	end
	return ts.get_node_text(node, source)
end

-- Neovim passes a pattern's predicates and directives the same argument list
-- on every match.
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

---@param node TSNode
---@return string? kind
---@return integer depth
local function ancestor_outside_groups(node)
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
		if ancestor_outside_groups(node) == pred[3] then
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

-- #any-of?: the built-in predicate copies every node's byte range to extract
-- its text.
---@param match  table<integer, TSNode[]>
---@param source integer | string
---@param pred   any[]
local function is_command(match, _, source, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end
	local names = type_set(pred, 3)
	for _, node in ipairs(nodes) do
		if names[get_node_text(node, source)] then
			return true
		end
	end
	return false
end

ts.query.add_predicate("has-grandparent?", has_grandparent, { force = true })
ts.query.add_predicate("latex-command?", is_command, { force = true })
ts.query.add_predicate("latex-script?", in_script, { force = true })
ts.query.add_directive("set-pairs!", set_pairs, { force = true })

-- The native ancestor matcher uses the same arguments as #has-ancestor?.
local math_ancestors = { "has-ancestor?", 0, "math_environment", "inline_formula", "displayed_equation" }
local non_math_ancestors = { "has-ancestor?", 0, "text_mode", "label_definition" }
local label_ancestors = { "has-ancestor?", 0, "label_definition" }
local script_ancestors = { "has-ancestor?", 0, "subscript", "superscript" }
local MATH, LABEL = context.math, context.label

---@param node TSNode
---@return boolean
local function in_math(node)
	local row, _, start, _, _, finish = node:range(true)
	if row >= context.first and row < context.last and finish > start then
		local math = false
		local starts, finishes, kinds = context.start, context.finish, context.kind
		for i = context.depth, 1, -1 do
			local stop = finishes[i]
			if stop > start and (stop ~= finish or starts[i] ~= start) then
				if kinds[i] ~= MATH then
					return false
				end
				math = true
			end
		end
		return math
	end
	return node:__has_ancestor(math_ancestors) and not node:__has_ancestor(non_math_ancestors)
end

---@param node TSNode
---@return boolean
local function in_label(node)
	local row, _, start, _, _, finish = node:range(true)
	if row >= context.first and row < context.last and finish > start then
		local starts, finishes, kinds = context.start, context.finish, context.kind
		for i = context.depth, 1, -1 do
			local stop = finishes[i]
			if kinds[i] == LABEL and stop > start and (stop ~= finish or starts[i] ~= start) then
				return true
			end
		end
		return false
	end
	return node:__has_ancestor(label_ancestors)
end

local symbols, exact, fonts, scripts

local function math_symbol(text)
	symbols = symbols or require("latex-conceal.symbols")
	return symbols.words.math[text] or symbols.math_common[text] or symbols.math[text]
end

---@param node  TSNode
---@param after boolean?
---@return TSNode?
local function sibling(node, after)
	repeat
		if after then
			node = node:next_sibling()
		else
			node = node:prev_sibling()
		end
	until not node or not node:extra()
	return node
end

local formatting = { ["\\emph"] = true, ["\\mathit"] = true, ["\\textit"] = true, ["\\mathbf"] = true, ["\\textbf"] = true }

ts.query.add_directive("latex-symbol!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end
	for _, node in ipairs(nodes) do
		local text = get_node_text(node, source)
		local replacement
		if formatting[text] then
			local after = sibling(node, true)
			if after and after:type() == "curly_group" then
				replacement = ""
			end
		else
			local math_value = math_symbol(text)
			local text_value = symbols.words.text[text] or symbols.text[text]
			if math_value ~= nil or text_value ~= nil then
				if in_math(node) then
					replacement = math_value
				elseif text_value ~= nil and not in_label(node) then
					replacement = text_value
				end
			end
			if replacement and text == "\\sqrt" then
				local _, _, row, col = node:range()
				local after = node:tree():root():descendant_for_range(row, col, row, col + 1)
				if after and after:type() == "[" then
					replacement = nil
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

ts.query.add_predicate("latex-math?", function (match, _, _, pred)
	local nodes = match[pred[2]]
	if nodes then
		for _, node in ipairs(nodes) do
			if in_math(node) then
				return true
			end
		end
	end
	return false
end, { force = true }
)

local argument_limit
local function load_arguments()
	exact = require("latex-conceal.exact")
	fonts = require("latex-conceal.fonts")
	argument_limit = fonts.max_argument_bytes
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
				if replacement == nil then
					local font = fonts.lookup(text)
					if font and in_math(node) then
						replacement = font
					end
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

-- A match's predicate and directive receive the same node.
local checked = setmetatable({}, { __mode = "v" })
local checked_replacement, checked_accepted
-- The operator tokens the parser leaves anonymous.
local operator_tokens = { ["="] = true, ["("] = true, [")"] = true }

local function script_capture(node, source)
	if rawequal(checked[1], node) then
		return checked_replacement, checked_accepted
	end
	local replacement, accepted = nil, false
	local kind = node:type()
	if kind == "subscript" or kind == "superscript" then
		if node:byte_length() <= 3 then
			replacement = scripts.unbraced[get_node_text(node, source)]
			accepted = replacement ~= nil
		end
	elseif node:byte_length() == 1 and node:__has_ancestor(script_ancestors) then
		local script, depth = ancestor_outside_groups(node)
		local replacements = script and scripts.braced[script]
		if replacements then
			local text = get_node_text(node, source)
			if kind == "word" then
				local pattern = script == "subscript" and "^[0-9aeh-pr-vxA-Z]$" or "^[0-9a-zA-W]$"
				if text:match(pattern) or script == "superscript" and text == "." and depth == 3 then
					replacement, accepted = replacements[text], true
				end
			elseif depth == 2 or not operator_tokens[kind] then
				replacement = replacements[text]
				accepted = replacement ~= nil
			end
		end
	end
	checked[1], checked_replacement, checked_accepted = node, replacement, accepted
	return replacement, accepted
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

ts.query.add_predicate("latex-script-marker?", function (match, _, source, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return false
	end
	scripts = scripts or require("latex-conceal.scripts")
	for _, node in ipairs(nodes) do
		if node:byte_length() == #"_{x}" then
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

local opening = { ["{"] = true, ["$"] = true, ["$$"] = true, ["\\("] = true, ["\\["] = true }
local closing = { ["}"] = true, ["$"] = true, ["$$"] = true, ["\\)"] = true, ["\\]"] = true }
ts.query.add_directive("latex-ends!", function (match, _, _, pred, metadata)
	local open, close = pred[2], pred[3]
	local nodes = match[open]
	local node = nodes and nodes[1]
	if not node then
		return
	end
	local sr, sc, sb, er, ec, eb = node:range(true)
	local first, last
	if node:type() == "curly_group" and not node:has_error() then
		-- An intact group begins and ends with a one-byte brace.
		first, last = { sr, sc, sb, sr, sc + 1, sb + 1 }, { er, ec - 1, eb - 1, er, ec, eb }
	else
		local count = node:child_count()
		local token = count > 0 and node:child(0)
		if token and opening[token:type()] then
			first = { token:range(true) }
		end
		token = count > 1 and node:child(count - 1)
		if token and closing[token:type()] then
			last = { token:range(true) }
		end
	end
	capture_metadata(metadata, open).range = first or { sr, sc, sb, sr, sc, sb }
	capture_metadata(metadata, close).range = last or { sr, sc, sb, sr, sc, sb }
end, { force = true }
)

local function simple_radicand(group, source)
	if group:has_error() or group:child_count() ~= 3 then
		return false
	end
	local atom = group:child(1)
	if atom:type() == "text" and atom:child_count() == 1 then
		atom = atom:child(0)
	end
	local value
	if atom:type() == "word" and atom:byte_length() <= 4 then
		value = get_node_text(atom, source)
	elseif atom:type() == "generic_command" and atom:child_count() == 1 then
		value = math_symbol(get_node_text(atom, source))
	end
	return value ~= nil and value:find("%S") ~= nil and vim.fn.strchars(value, 1) == 1
end

ts.query.add_predicate("latex-braces?", function (match, _, source, pred)
	local nodes = match[pred[2]]
	local group = nodes and nodes[1]
	if not group then
		return false
	end
	local parent = group:parent()
	local kind = parent and parent:type()
	if kind == "text_mode" then
		return true
	elseif kind == "generic_command" then
		local command = parent:child(0)
		local name = get_node_text(command, source)
		if name == "\\sqrt" then
			return sibling(group) == command and in_math(group) and simple_radicand(group, source)
		end
		return formatting[name] == true and sibling(group) == command
	elseif not in_math(group) then
		return false
	end
	local previous = sibling(group)
	return not previous or previous:type() ~= "]"
end, { force = true }
)

local delimiters = {
	["\\bra"] = { command = "⟨", close = "|" },
	["\\ket"] = { command = "|", close = "⟩" },
	["\\abs"] = { command = "|", close = "|" },
	["\\norm"] = { command = "‖", close = "‖" },
	["\\pmod"] = { command = "(mod", close = ")", open = " " },
	["\\pod"] = { command = "(", close = ")" },
	["\\mod"] = { command = "mod", close = "", open = " " },
	["\\operatorname"] = { command = "", close = "" },
	["\\operatorname*"] = { command = "", close = "" }
}
ts.query.add_directive("latex-delimiters!", function (match, _, source, pred, metadata)
	local command, close, open = pred[2], pred[3], pred[4]
	local nodes = match[command]
	if not nodes or #nodes == 0 then
		return
	end
	for _, node in ipairs(nodes) do
		local replacements = delimiters[get_node_text(node, source)]
		if replacements then
			capture_metadata(metadata, command).conceal = replacements.command
			capture_metadata(metadata, close).conceal = replacements.close
			if open then
				capture_metadata(metadata, open).conceal = replacements.open or ""
			end
		end
	end
end, { force = true }
)

require("latex-conceal.render").setup()
