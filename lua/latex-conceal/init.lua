local symbols = require("latex-conceal.symbols")

local M = {}

---@param text string
---@param kind "math" | "text" | "font"
---@return string?
function M.lookup(text, kind)
	if kind == "font" then
		return require("latex-conceal.fonts").lookup(text)
	end
	return symbols[kind][text]
end

return M
