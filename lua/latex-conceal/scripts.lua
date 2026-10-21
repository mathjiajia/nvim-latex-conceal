-- Subscript and superscript replacements.
--
-- `braced` maps a single word, operator or token inside a braced script to
-- its replacement, keyed by the kind of script that encloses it. `inline`
-- maps the text of an unbraced script node such as `_1` or `^n`.
local subscript = {
	["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃", ["4"] = "₄",
	["5"] = "₅", ["6"] = "₆", ["7"] = "₇", ["8"] = "₈", ["9"] = "₉",
	a = "ₐ", e = "ₑ", h = "ₕ", i = "ᵢ", j = "ⱼ", k = "ₖ", l = "ₗ", m = "ₘ", n = "ₙ",
	o = "ₒ", p = "ₚ", r = "ᵣ", s = "ₛ", t = "ₜ", u = "ᵤ", v = "ᵥ", x = "ₓ",
	A = "ᴀ", B = "ʙ", C = "ᴄ", D = "ᴅ", E = "ᴇ", F = "ғ", G = "ɢ", H = "ʜ", I = "ɪ",
	J = "ᴊ", K = "ᴋ", L = "ʟ", M = "ᴍ", N = "ɴ", O = "ᴏ", P = "ᴘ", Q = "ǫ", R = "ʀ",
	S = "s", T = "ᴛ", U = "ᴜ", V = "ᴠ", W = "ᴡ", X = "x", Y = "ʏ", Z = "ᴢ",
	["+"] = "₊", ["-"] = "₋", ["/"] = "ˏ", ["="] = "₌", ["("] = "₍", [")"] = "₎",
}

local superscript = {
	["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴",
	["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹",
	a = "ᵃ", b = "ᵇ", c = "ᶜ", d = "ᵈ", e = "ᵉ", f = "ᶠ", g = "ᵍ", h = "ʰ", i = "ⁱ",
	j = "ʲ", k = "ᵏ", l = "ˡ", m = "ᵐ", n = "ⁿ", o = "ᵒ", p = "ᵖ", r = "ʳ", s = "ˢ",
	t = "ᵗ", u = "ᵘ", v = "ᵛ", w = "ʷ", x = "ˣ", y = "ʸ", z = "ᶻ",
	A = "ᴬ", B = "ᴮ", D = "ᴰ", E = "ᴱ", G = "ᴳ", H = "ᴴ", I = "ᴵ", J = "ᴶ", K = "ᴷ",
	L = "ᴸ", M = "ᴹ", N = "ᴺ", O = "ᴼ", P = "ᴾ", R = "ᴿ", T = "ᵀ", U = "ᵁ", V = "ⱽ", W = "ᵂ",
	["+"] = "⁺", ["-"] = "⁻", ["<"] = "˂", [">"] = "˃", ["/"] = "ˊ", ["="] = "˭", ["."] = "˙",
}

local inline = { ["_\\."] = "‸" }
for text, replacement in pairs(subscript) do
	inline["_" .. text] = replacement
end
for text, replacement in pairs(superscript) do
	inline["^" .. text] = replacement
end

return {
	braced = { subscript = subscript, superscript = superscript },
	inline = inline,
}
