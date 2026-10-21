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

---@param match table<integer, TSNode[]>
---@param pred  any[]
local function has_grandparent(match, _, _, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end

	for _, node in ipairs(nodes) do
		local parent = node:parent()
		local grandparent = parent and parent:parent()
		if grandparent then
			local node_type = grandparent:type()
			for i = 3, #pred do
				if node_type == pred[i] then
					return true
				end
			end
		end
	end
	return false
end

-- Query arguments are immutable. Weak keys release maps when queries are reloaded.
local pair_maps = setmetatable({}, { __mode = "k" })

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

	local replacements = pair_maps[pred]
	if not replacements then
		replacements = {}
		for i = 4, #pred, 2 do
			-- Preserve the first entry if a query contains duplicate keys.
			if replacements[pred[i]] == nil then
				replacements[pred[i]] = pred[i + 1]
			end
		end
		pair_maps[pred] = replacements
	end

	for _, node in ipairs(nodes) do
		local replacement = replacements[get_node_text(node, source)]
		if replacement ~= nil then
			metadata[id] = metadata[id] or {}
			metadata[id][key] = replacement
		end
	end
end

ts.query.add_predicate("has-grandparent?", has_grandparent, { force = true })
ts.query.add_directive("set-pairs!", set_pairs, { force = true })

local math_nodes = { math_environment = true, inline_formula = true, displayed_equation = true }
local symbols
ts.query.add_directive("latex-symbol!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end

	symbols = symbols or require("latex-conceal.symbols")
	for _, node in ipairs(nodes) do
		local text = get_node_text(node, source)
		local math_symbol = symbols.math_common[text] or symbols.math[text]
		local text_symbol = symbols.text[text]
		if math_symbol ~= nil or text_symbol ~= nil then
			-- The query excludes labels; enclosing text takes precedence over math.
			local in_math = false
			local parent = node:parent()
			while parent do
				local node_type = parent:type()
				if node_type == "text_mode" then
					in_math = false
					break
				end
				in_math = in_math or math_nodes[node_type] == true
				parent = parent:parent()
			end
			local replacement = text_symbol
			if in_math then
				replacement = math_symbol
			end
			if replacement ~= nil then
				metadata[id] = metadata[id] or {}
				metadata[id].conceal = replacement
			end
		end
	end
end, { force = true })

-- Load the supplementary symbol tables only when a query needs them.
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
			metadata[id] = metadata[id] or {}
			metadata[id].conceal = replacement
		end
	end
end, { force = true })

require("latex-conceal.render").setup()
