if vim.g.loaded_latex_conceal then
	return
end
vim.g.loaded_latex_conceal = true

local ts = vim.treesitter
local get_text = vim.api.nvim_buf_get_text
local context = require("latex-conceal.context")

-- Directives read raw node text. The common single-line buffer case does not
-- need the general helper's metadata and byte-range tables, and the renderer
-- has already read the lines it is collecting.
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

-- #has-parent? and #any-of? with their arguments cached as a set: the built-in
-- predicates copy their argument list or the node's byte ranges on every call.
---@param match table<integer, TSNode[]>
---@param pred  any[]
local function has_parent(match, _, _, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end
	local types = type_set(pred, 3)
	for _, node in ipairs(nodes) do
		local parent = node:parent()
		if parent and types[parent:type()] then
			return true
		end
	end
	return false
end

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
ts.query.add_predicate("latex-parent?", has_parent, { force = true })
ts.query.add_predicate("latex-command?", is_command, { force = true })
ts.query.add_predicate("latex-script?", in_script, { force = true })
ts.query.add_directive("set-pairs!", set_pairs, { force = true })

-- Nightly's native ancestor matcher uses the same arguments as #has-ancestor?.
local math_ancestors = { "has-ancestor?", 0, "math_environment", "inline_formula", "displayed_equation" }
local text_ancestors = { "has-ancestor?", 0, "text_mode", "label_definition" }
local label_ancestors = { "has-ancestor?", 0, "label_definition" }
local script_ancestors = { "has-ancestor?", 0, "subscript", "superscript" }
local MATH, LABEL = context.math, context.label

-- Whether the node lies in mathematics outside text commands and labels.
-- While the renderer collects a tree, the recorded regions that reach past the
-- node's start are its math, text and label ancestors, so they answer without
-- walking the tree. A region is not its own ancestor, and an empty node at a
-- region's edge could lie on either side of it.
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
	return node:__has_ancestor(math_ancestors) and not node:__has_ancestor(text_ancestors)
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

-- Replacement tables load on first use, when a query needs them.
local symbols, exact, fonts, scripts

-- Emphasis wrappers are hidden in every context, like the braces they own.
local hidden_commands = { ["\\emph"] = "", ["\\mathit"] = "", ["\\textit"] = "", ["\\mathbf"] = "", ["\\textbf"] = "" }

-- The query excludes labels; enclosing text takes precedence over math.
ts.query.add_directive("latex-symbol!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end
	symbols = symbols or require("latex-conceal.symbols")
	for _, node in ipairs(nodes) do
		local text = get_node_text(node, source)
		local replacement = hidden_commands[text]
		if replacement == nil then
			local math_symbol = symbols.words.math[text] or symbols.math_common[text] or symbols.math[text]
			local text_symbol = symbols.words.text[text] or symbols.text[text]
			if math_symbol ~= nil or text_symbol ~= nil then
				-- Text ancestors include labels, so only a text replacement needs the label check.
				if in_math(node) then
					replacement = math_symbol
				elseif text_symbol ~= nil and not in_label(node) then
					replacement = text_symbol
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

-- Share one predicate dispatch for math context and its text/label exclusions.
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

-- Preserve the script captures that can also carry a custom @conceal color.
-- In particular, some unsupported braced superscript letters were highlighted
-- without a replacement, while unbraced scripts and subscript words were not.
--
-- A match's predicate and directive receive the same node, so the directive
-- reuses the predicate's answer; the weak reference does not keep a tree alive.
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
			replacement = scripts.inline[get_node_text(node, source)]
			accepted = replacement ~= nil
		end
	elseif node:byte_length() == 1 and node:__has_ancestor(script_ancestors) then
		-- Most braced words lie outside every script, and one native walk has
		-- rejected them before the nearest ancestor is found step by step.
		local script, depth = enclosing(node)
		local replacements = script and scripts.braced[script]
		if replacements then
			local text = get_node_text(node, source)
			if kind == "word" then
				local pattern = script == "subscript" and "^[0-9aeh-pr-vxA-Z]$" or "^[0-9a-zA-W]$"
				if text:match(pattern) or script == "superscript" and text == "." and depth == 3 then
					replacement, accepted = replacements[text], true
				end
			elseif depth == 2 or not operator_tokens[kind] then
				-- An operator token counts directly inside the script's braces only.
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

-- Narrow two captures of one node to its first and last token: the braces of a
-- group or the delimiters of a formula. Matching those tokens as children
-- instead makes Tree-sitter analyse every way the node's contents can parse,
-- which dominated the time to compile the query.
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
	-- Without its token a capture covers nothing, never the whole node.
	capture_metadata(metadata, open).range = first or { sr, sc, sb, sr, sc, sb }
	capture_metadata(metadata, close).range = last or { sr, sc, sb, sr, sc, sb }
end, { force = true }
)

-- The command, closing brace and optional opening brace replacements.
local delimiters = {
	["\\bra"] = { "⟨", "|" },
	["\\ket"] = { "|", "⟩" },
	["\\abs"] = { "|", "|" },
	["\\norm"] = { "‖", "‖" },
	["\\pmod"] = { "(mod", ")", " " },
	["\\pod"] = { "(", ")" },
	["\\mod"] = { "mod", "", " " },
	["\\operatorname"] = { "", "" },
	["\\operatorname*"] = { "", "" }
}
ts.query.add_directive("latex-delimiters!", function (match, _, source, pred, metadata)
	local command, close, open = pred[2], pred[3], pred[4]
	local nodes = match[command]
	if not nodes or #nodes == 0 then
		return
	end
	for _, node in ipairs(nodes) do
		local pair = delimiters[get_node_text(node, source)]
		if pair then
			capture_metadata(metadata, command).conceal = pair[1]
			capture_metadata(metadata, close).conceal = pair[2]
			if open then
				capture_metadata(metadata, open).conceal = pair[3] or ""
			end
		end
	end
end, { force = true }
)

require("latex-conceal.render").setup()
