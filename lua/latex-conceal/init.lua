local symbols = require("latex-conceal.symbols")
local lookup_font

local M = {}

---@param text string
---@param kind "math" | "text" | "font"
---@return string?
function M.lookup(text, kind)
	if kind == "font" then
		lookup_font = lookup_font or require("latex-conceal.fonts").lookup
		return lookup_font(text)
	end
	return symbols[kind][text]
end

return M
