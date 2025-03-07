local defaults = {
	enabled = {
		"amssymb",
		"core",
		"delim",
		"font",
		"greek",
		"math",
		-- "mleftright",
		"script",
	},
	add = {},
}

local conf = vim.g.latex_conf or {}
conf = vim.tbl_deep_extend("force", defaults, conf)
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.md", "*.markdown", "*.tex" },
	group = vim.api.nvim_create_augroup("latex-conceal", {}),
	callback = function()
		---@param match TSMatch
		---@param pred string[]
		---@return boolean
		local function hasgrandparent(match, _, _, pred)
			local nodes = match[pred[2]]
			if not nodes or #nodes == 0 then
				return true
			end

			local types = { unpack(pred, 3) }
			for _, node in ipairs(nodes) do
				if vim.list_contains(types, node:parent():parent():type()) then
					return true
				end
			end
			return false
		end

		---@param match TSMatch
		---@param pred string[]
		local function setpairs(match, _, source, pred, metadata)
			-- (#set-pairs! @aa key list)
			local id = pred[2]
			local key = pred[3]
			local nodes = match[id]
			if not nodes or #nodes == 0 then
				return
			end

			for _, node in ipairs(nodes) do
				local node_text = vim.treesitter.get_node_text(node, source)
				-- if metadata[capture_id] and metadata[capture_id].range then
				-- 	local sr, sc, er, ec = unpack(metadata[capture_id].range)
				-- 	node_text = vim.api.nvim_buf_get_text(source, sr, sc, er, ec, {})[1]
				-- end
				for i = 4, #pred, 2 do
					if node_text == pred[i] then
						metadata[key] = pred[i + 1]
						break
					end
				end
			end
		end

		vim.treesitter.query.add_predicate("has-grandparent?", hasgrandparent, { force = true })
		vim.treesitter.query.add_directive("set-pairs!", setpairs, { force = true, all = true })
	end,
})
