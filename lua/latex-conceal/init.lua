local symbols = require("latex-conceal.symbols")
local lookup_font
local exact

local M = {}

---@param text string
---@param kind "math" | "text" | "font" | "exact" | "bar" | "overline"
---@return string?
function M.lookup(text, kind)
	if kind == "font" then
		lookup_font = lookup_font or require("latex-conceal.fonts").lookup
		return lookup_font(text)
	end
	if kind == "math" or kind == "text" then
		return symbols[kind][text]
	end
	exact = exact or require("latex-conceal.exact")
	return exact[kind][text]
end

return M
