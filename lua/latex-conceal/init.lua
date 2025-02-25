local L = {}

L.conceals = require("latex-conceal.conceals")

L.__index = L

L._defaults = {
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

function L.setup()
	local conf = vim.g.latex_conf or {}
	conf = vim.tbl_deep_extend("force", L._defaults, conf)
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.md", "*.tex" },
		callback = function()
			L.conceals.init(conf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
		pattern = { "*.md", "*.tex" },
		callback = L._deinit,
	})
end

function L._deinit() end

return L
