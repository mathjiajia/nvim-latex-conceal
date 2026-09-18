if vim.g.loaded_latex_conceal then
	return
end
vim.g.loaded_latex_conceal = true

for _, filetype in ipairs({ "tex", "plaintex" }) do
	if vim.treesitter.language.get_lang(filetype) == filetype then
		vim.treesitter.language.register("latex", filetype)
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
		local replacement = replacements[vim.treesitter.get_node_text(node, source)]
		if replacement ~= nil then
			metadata[id] = metadata[id] or {}
			metadata[id][key] = replacement
		end
	end
end

vim.treesitter.query.add_predicate("has-grandparent?", has_grandparent, { force = true })
vim.treesitter.query.add_directive("set-pairs!", set_pairs, { force = true })

-- Load the supplementary symbol tables only when a query needs them.
vim.treesitter.query.add_directive("latex-conceal!", function (match, _, source, pred, metadata)
	local id = pred[2]
	local nodes = match[id]
	if not nodes then
		return
	end

	local lookup = require("latex-conceal").lookup
	for _, node in ipairs(nodes) do
		local replacement = lookup(vim.treesitter.get_node_text(node, source), pred[3])
		if replacement ~= nil then
			metadata[id] = metadata[id] or {}
			metadata[id].conceal = replacement
		end
	end
end, { force = true })
