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

print("here")

local conf = vim.g.latex_conf or {}
conf = vim.tbl_deep_extend("force", defaults, conf)
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.md", "*.markdown", "*.tex" },
	group = vim.api.nvim_create_augroup("latex-conceal", {}),
	callback = function()
		require("latex-conceal.conceals").init(conf)
	end,
})
