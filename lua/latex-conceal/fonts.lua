-- Single-symbol additions to the mappings in exact.lua.
-- A conceal can contain one base character and combining marks, not a word.
local M = {}

local function alphabet(upper, lower, digits, exceptions)
	local result = exceptions or {}
	for i = 0, 25 do
		local capital, small = string.char(65 + i), string.char(97 + i)
		result[capital] = result[capital] or vim.fn.nr2char(upper + i)
		result[small] = result[small] or vim.fn.nr2char(lower + i)
	end
	if digits then
		for i = 0, 9 do
			result[tostring(i)] = vim.fn.nr2char(digits + i)
		end
	end
	return result
end

local styles = {
	bold = alphabet(0x1D400, 0x1D41A, 0x1D7CE),
	italic = alphabet(0x1D434, 0x1D44E, nil, { h = "ℎ" }),
	bolditalic = alphabet(0x1D468, 0x1D482),
	script = alphabet(0x1D49C, 0x1D4B6, nil, {
		B = "ℬ", E = "ℰ", F = "ℱ", H = "ℋ", I = "ℐ", L = "ℒ", M = "ℳ", R = "ℛ",
		e = "ℯ", g = "ℊ", o = "ℴ",
	}),
	boldscript = alphabet(0x1D4D0, 0x1D4EA),
	fraktur = alphabet(0x1D504, 0x1D51E, nil, { C = "ℭ", H = "ℌ", I = "ℑ", R = "ℜ", Z = "ℨ" }),
	double = alphabet(0x1D538, 0x1D552, 0x1D7D8, { C = "ℂ", H = "ℍ", N = "ℕ", P = "ℙ", Q = "ℚ", R = "ℝ", Z = "ℤ" }),
	boldfraktur = alphabet(0x1D56C, 0x1D586),
	sans = alphabet(0x1D5A0, 0x1D5BA, 0x1D7E2),
	boldsans = alphabet(0x1D5D4, 0x1D5EE, 0x1D7EC),
	italicsans = alphabet(0x1D608, 0x1D622),
	bolditalicsans = alphabet(0x1D63C, 0x1D656),
	mono = alphabet(0x1D670, 0x1D68A, 0x1D7F6),
}

-- These names specify Unicode alphabets; unavailable styles (e.g. italic
-- digits or double-struck Greek) deliberately have no substitute.
local font_styles = {
	mathbf = "bold", mathbfup = "bold", symbf = "bold", symbfup = "bold",
	mathit = "italic", symit = "italic",
	mathbfit = "bolditalic", symbfit = "bolditalic", bm = "bolditalic", boldsymbol = "bolditalic",
	mathtt = "mono", symtt = "mono",
	mathbb = "double", symbb = "double",
	mathfrak = "fraktur", symfrak = "fraktur",
	mathbffrak = "boldfraktur", symbffrak = "boldfraktur",
	mathsf = "sans", mathsfup = "sans", symsf = "sans", symsfup = "sans",
	mathsfit = "italicsans", symsfit = "italicsans",
	mathbfsf = "boldsans", mathbfsfup = "boldsans", symbfsf = "boldsans", symbfsfup = "boldsans",
	mathbfsfit = "bolditalicsans", symbfsfit = "bolditalicsans",
	-- Keep the existing bold-script appearance of mathcal and mathscr.
	mathcal = "boldscript", mathscr = "boldscript",
	mathbfcal = "boldscript", mathbfscr = "boldscript", symbfcal = "boldscript", symbfscr = "boldscript",
	symcal = "script", symscr = "script",
}

local greek = {
	Alpha = "Α", Beta = "Β", Gamma = "Γ", Delta = "Δ", Epsilon = "Ε", Zeta = "Ζ",
	Eta = "Η", Theta = "Θ", Iota = "Ι", Kappa = "Κ", Lambda = "Λ", Mu = "Μ",
	Nu = "Ν", Xi = "Ξ", Omicron = "Ο", Pi = "Π", Rho = "Ρ", Sigma = "Σ",
	Tau = "Τ", Upsilon = "Υ", Phi = "Φ", Chi = "Χ", Psi = "Ψ", Omega = "Ω",
	alpha = "α", beta = "β", gamma = "γ", delta = "δ", epsilon = "ϵ", zeta = "ζ",
	eta = "η", theta = "θ", iota = "ι", kappa = "κ", lambda = "λ", mu = "μ",
	nu = "ν", xi = "ξ", omicron = "ο", pi = "π", rho = "ρ", sigma = "σ",
	tau = "τ", upsilon = "υ", phi = "ϕ", chi = "χ", psi = "ψ", omega = "ω",
	varepsilon = "ε", vartheta = "ϑ", varkappa = "ϰ", varpi = "ϖ", varrho = "ϱ",
	varsigma = "ς", varphi = "φ", partial = "∂", nabla = "∇", digamma = "ϝ", Digamma = "Ϝ",
}

local greek_offsets = {
	Alpha = 0, Beta = 1, Gamma = 2, Delta = 3, Epsilon = 4, Zeta = 5,
	Eta = 6, Theta = 7, Iota = 8, Kappa = 9, Lambda = 10, Mu = 11,
	Nu = 12, Xi = 13, Omicron = 14, Pi = 15, Rho = 16, Sigma = 18,
	Tau = 19, Upsilon = 20, Phi = 21, Chi = 22, Psi = 23, Omega = 24, nabla = 25,
	alpha = 26, beta = 27, gamma = 28, delta = 29, varepsilon = 30, zeta = 31,
	eta = 32, theta = 33, iota = 34, kappa = 35, lambda = 36, mu = 37,
	nu = 38, xi = 39, omicron = 40, pi = 41, rho = 42, varsigma = 43, sigma = 44,
	tau = 45, upsilon = 46, varphi = 47, chi = 48, psi = 49, omega = 50,
	partial = 51, epsilon = 52, vartheta = 53, varkappa = 54, phi = 55, varrho = 56, varpi = 57,
}

local greek_styles = {
	bold = 0x1D6A8, italic = 0x1D6E2, bolditalic = 0x1D71C,
	boldsans = 0x1D756, bolditalicsans = 0x1D790,
}

-- Legacy math alphabet commands do not change Greek commands. The Unicode
-- math styles and bm/boldsymbol do; bm preserves upright capitals/nabla.
local greek_fonts = {
	symit = "italic", symbfup = "bold", symbfit = "bolditalic",
	symbfsfup = "boldsans", symbfsfit = "bolditalicsans",
	symbf = "mixed", symbfsf = "boldsans", bm = "mixed", boldsymbol = "mixed",
}

for style, base in pairs(greek_styles) do
	local alphabet_map = styles[style]
	for name, offset in pairs(greek_offsets) do
		alphabet_map["\\" .. name] = vim.fn.nr2char(base + offset)
	end
end
styles.bold["\\Digamma"], styles.bold["\\digamma"] = "𝟊", "𝟋"

local greek_letters, mixed_greek = {}, {}
for name, letter in pairs(greek) do
	local command = "\\" .. name
	greek_letters[command] = letter
	local upright = name:match("^%u") or name == "nabla" or name == "digamma"
	mixed_greek[command] = (upright and styles.bold or styles.bolditalic)[command]
end

for command, style in pairs(font_styles) do
	font_styles[command] = styles[style]
end
for command, style in pairs(greek_fonts) do
	greek_fonts[command] = style == "mixed" and mixed_greek or styles[style]
end

local accents = {
	acute = "́", grave = "̀", breve = "̆", check = "̌", ddot = "̈",
	dddot = "⃛", ddddot = "⃜", vec = "⃗", dot = "̇",
	bar = "̅", overline = "̅", hat = "̂", widehat = "̂", tilde = "̃", widetilde = "̃",
}

local existing_letters = {
	mathbb = "^[A-Z]$", mathcal = "^[A-Z]$", mathscr = "^[A-Z]$",
	mathfrak = "^[A-Za-z]$", mathsf = "^[A-Za-z]$",
	bar = "^[A-Za-z]$", overline = "^[A-Za-z]$",
	hat = "^[A-Za-z]$", widehat = "^[A-Za-z]$", tilde = "^[A-Za-z]$", widetilde = "^[A-Za-z]$",
	dot = "^[AaBbCcDdEeFfGgHhIMmNnOoPpRrSsTtWwXxYyZz]$",
}

local additional_bars = {
	["\\varkappa"] = true, ["\\partial"] = true, ["\\nabla"] = true,
	["\\digamma"] = true, ["\\Digamma"] = true,
}

---@param full_command string
---@return string?
function M.lookup(full_command)
	local command, body = full_command:match("^\\(%a+){([^{}]+)}$")
	if not command then
		return
	end
	local existing = existing_letters[command]
	if existing and body:match(existing) then
		return
	end
	local greek_letter = greek_letters[body]
	if greek_letter then
		local accent = accents[command]
		if accent then
			if (command == "bar" or command == "overline") and not additional_bars[body] then
				return
			end
			return greek_letter .. accent
		end
		local alphabet_map = greek_fonts[command]
		return alphabet_map and alphabet_map[body]
	end
	local alphabet_map = font_styles[command]
	if alphabet_map then
		return alphabet_map[body]
	end
	local accent = accents[command]
	if accent and body:match("^[A-Za-z0-9]$") then
		return body .. accent
	end
end

return M
