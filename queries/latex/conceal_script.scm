; superscripts and subscripts conceals
(text
  word: (subscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#any-of? @conceal
    "_0" "_1" "_2" "_3" "_4" "_5" "_6" "_7" "_8" "_9" "_a" "_e" "_h" "_i" "_j" "_k" "_l" "_m" "_n"
    "_o" "_p" "_r" "_s" "_t" "_u" "_v" "_x" "_A" "_B" "_C" "_D" "_E" "_F" "_G" "_H" "_I" "_J" "_K"
    "_L" "_M" "_N" "_O" "_P" "_Q" "_R" "_S" "_T" "_U" "_V" "_W" "_X" "_Y" "_Z" "_\\.")
  (#set-pairs! @conceal
    conceal "_0" "₀" "_1" "₁" "_2" "₂" "_3" "₃" "_4" "₄" "_5" "₅" "_6" "₆" "_7" "₇"
    "_8" "₈" "_9" "₉" "_a" "ₐ" "_e" "ₑ" "_h" "ₕ" "_i" "ᵢ" "_j" "ⱼ" "_k" "ₖ" "_l"
    "ₗ" "_m" "ₘ" "_n" "ₙ" "_o" "ₒ" "_p" "ₚ" "_r" "ᵣ" "_s" "ₛ" "_t" "ₜ" "_u" "ᵤ"
    "_v" "ᵥ" "_x" "ₓ" "_A" "ᴀ" "_B" "ʙ" "_C" "ᴄ" "_D" "ᴅ" "_E" "ᴇ" "_F" "ғ" "_G" "ɢ"
    "_H" "ʜ" "_I" "ɪ" "_J" "ᴊ" "_K" "ᴋ" "_L" "ʟ" "_M" "ᴍ" "_N" "ɴ" "_O" "ᴏ" "_P" "ᴘ"
    "_Q" "ǫ" "_R" "ʀ" "_S" "s" "_T" "ᴛ" "_U" "ᴜ" "_V" "ᴠ" "_W" "ᴡ" "_X" "x" "_Y" "ʏ" "_Z"
    "ᴢ" "_\\." "‸"))

(text
  word: (word) @conceal
  (#has-ancestor? @conceal subscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#any-of? @conceal
    "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "e" "h" "i" "j" "k" "l" "m" "n" "o" "p" "r" "s" "t"
    "u" "v" "x" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U"
    "V" "W" "X" "Y" "Z" "\\.")
  (#set-pairs! @conceal
    conceal "0" "₀" "1" "₁" "2" "₂" "3" "₃" "4" "₄" "5" "₅" "6" "₆" "7" "₇" "8"
    "₈" "9" "₉" "a" "ₐ" "e" "ₑ" "h" "ₕ" "i" "ᵢ" "j" "ⱼ" "k" "ₖ" "l" "ₗ" "m" "ₘ"
    "n" "ₙ" "o" "ₒ" "p" "ₚ" "r" "ᵣ" "s" "ₛ" "t" "ₜ" "u" "ᵤ" "v" "ᵥ" "x" "ₓ" "A"
    "ᴀ" "B" "ʙ" "C" "ᴄ" "D" "ᴅ" "E" "ᴇ" "F" "ғ" "G" "ɢ" "H" "ʜ" "I" "ɪ" "J" "ᴊ" "K"
    "ᴋ" "L" "ʟ" "M" "ᴍ" "N" "ɴ" "O" "ᴏ" "P" "ᴘ" "Q" "ǫ" "R" "ʀ" "S" "s" "T" "ᴛ" "U"
    "ᴜ" "V" "ᴠ" "W" "ᴡ" "X" "x" "Y" "ʏ" "Z" "ᴢ" "_\\." "‸"))

(text
  word: (subscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal "_+" "_-" "_/")
  (#set-pairs! @conceal conceal "_+" "₊" "_-" "₋" "_/" "ˏ"))

(text
  word: (operator) @conceal
  (#has-ancestor? @conceal subscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal "+" "-" "/" "(" ")")
  (#set-pairs! @conceal conceal "+" "₊" "-" "₋" "/" "ˏ" "(" "₍" ")" "₎"))

(text
  word: (superscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal
    "^0" "^1" "^2" "^3" "^4" "^5" "^6" "^7" "^8" "^9" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i"
    "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^r" "^s" "^t" "^u" "^v" "^w" "^x" "^y" "^z" "^A" "^B" "^D"
    "^E" "^G" "^H" "^I" "^J" "^K" "^L" "^M" "^N" "^O" "^P" "^R" "^T" "^U" "^V" "^W")
  (#set-pairs! @conceal
    conceal "^0" "⁰" "^1" "¹" "^2" "²" "^3" "³" "^4" "⁴" "^5" "⁵" "^6" "⁶" "^7" "⁷"
    "^8" "⁸" "^9" "⁹" "^a" "ᵃ" "^b" "ᵇ" "^c" "ᶜ" "^d" "ᵈ" "^e" "ᵉ" "^f" "ᶠ" "^g"
    "ᵍ" "^h" "ʰ" "^i" "ⁱ" "^j" "ʲ" "^k" "ᵏ" "^l" "ˡ" "^m" "ᵐ" "^n" "ⁿ" "^o" "ᵒ" "^p"
    "ᵖ" "^r" "ʳ" "^s" "ˢ" "^t" "ᵗ" "^u" "ᵘ" "^v" "ᵛ" "^w" "ʷ" "^x" "ˣ" "^y" "ʸ" "^z"
    "ᶻ" "^A" "ᴬ" "^B" "ᴮ" "^D" "ᴰ" "^E" "ᴱ" "^G" "ᴳ" "^H" "ᴴ" "^I" "ᴵ" "^J" "ᴶ"
    "^K" "ᴷ" "^L" "ᴸ" "^M" "ᴹ" "^N" "ᴺ" "^O" "ᴼ" "^P" "ᴾ" "^R" "ᴿ" "^T" "ᵀ" "^U"
    "ᵁ" "^V" "ⱽ" "^W" "ᵂ"))

(text
  word: (word) @conceal
  (#has-ancestor? @conceal superscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal
    "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n"
    "o" "p" "r" "s" "t" "u" "v" "w" "x" "y" "z" "A" "B" "D" "E" "G" "H" "I" "J" "K" "L" "M" "N" "O"
    "P" "R" "T" "U" "V" "W")
  (#set-pairs! @conceal
    conceal "0" "⁰" "1" "¹" "2" "²" "3" "³" "4" "⁴" "5" "⁵" "6" "⁶" "7" "⁷" "8" "⁸"
    "9" "⁹" "a" "ᵃ" "b" "ᵇ" "c" "ᶜ" "d" "ᵈ" "e" "ᵉ" "f" "ᶠ" "g" "ᵍ" "h" "ʰ" "i"
    "ⁱ" "j" "ʲ" "k" "ᵏ" "l" "ˡ" "m" "ᵐ" "n" "ⁿ" "o" "ᵒ" "p" "ᵖ" "r" "ʳ" "s" "ˢ" "t"
    "ᵗ" "u" "ᵘ" "v" "ᵛ" "w" "ʷ" "x" "ˣ" "y" "ʸ" "z" "ᶻ" "A" "ᴬ" "B" "ᴮ" "D" "ᴰ" "E"
    "ᴱ" "G" "ᴳ" "H" "ᴴ" "I" "ᴵ" "J" "ᴶ" "K" "ᴷ" "L" "ᴸ" "M" "ᴹ" "N" "ᴺ" "O" "ᴼ"
    "P" "ᴾ" "R" "ᴿ" "T" "ᵀ" "U" "ᵁ" "V" "ⱽ" "W" "ᵂ"))

(text
  word: (superscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#any-of? @conceal "^+" "^-" "^<" "^>" "^/" "^=" "^\.")
  (#set-pairs! @conceal
    conceal "^+" "⁺" "^-" "⁻" "^<" "˂" "^>" "˃" "^/" "ˊ" "^=" "˭" "^\." "˙"))

(text
  word: (operator) @conceal
  (#has-ancestor? @conceal superscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal "+" "-" "<" ">" "/" "=" "\.")
  (#set-pairs! @conceal conceal "+" "⁺" "-" "⁻" "<" "˂" ">" "˃" "/" "ˊ" "=" "˭" "\." "˙"))
