; extends

; Symbol commands share one lookup; the directive selects math or text context.
(generic_command
  command: (command_name) @conceal
  (#not-has-ancestor? @conceal label_definition)
  (#latex-symbol! @conceal))

(curly_group
  [
    "{"
    "}"
  ] @conceal
  (#not-has-grandparent? @conceal
    title_declaration author_declaration chapter part section subsection subsubsection paragraph
    subparagraph generic_command)
  (#set! conceal ""))

(math_delimiter
  [
    left_command: _ @conceal
    right_command: _ @conceal
  ]
  (#set! conceal ""))

([
  (inline_formula
    [
      "$"
      "\\("
      "\\)"
    ] @conceal)
  (displayed_equation
    [
      "$$"
      "\\["
      "\\]"
    ] @conceal)
]
  (#set! conceal ""))

(text_mode
  command: _ @conceal
  (#set! conceal ""))

("\\item" @punctuation.special
  (#set! conceal "○"))

(generic_command
  command: (command_name) @conceal
  (#any-of? @conceal "\\emph" "\\mathit" "\\textit" "\\mathbf" "\\textbf")
  (#set! conceal ""))

; Exact replacements retain separate priorities and context from supplementary fonts.
((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#latex-conceal! @conceal "exact"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "^\\bar{\\[%a]+}$")
  (#set! priority 101)
  (#latex-conceal! @conceal "bar"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "^\\overline{\\[%a]+}$")
  (#set! priority 101)
  (#latex-conceal! @conceal "overline"))

; superscripts and subscripts conceals
(text
  word: (subscript) @conceal
  (#any-of? @conceal
    "_0" "_1" "_2" "_3" "_4" "_5" "_6" "_7" "_8" "_9" "_a" "_e" "_h" "_i" "_j" "_k" "_l" "_m" "_n"
    "_o" "_p" "_r" "_s" "_t" "_u" "_v" "_x" "_A" "_B" "_C" "_D" "_E" "_F" "_G" "_H" "_I" "_J" "_K"
    "_L" "_M" "_N" "_O" "_P" "_Q" "_R" "_S" "_T" "_U" "_V" "_W" "_X" "_Y" "_Z" "_\\.")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
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
  (#lua-match? @conceal "^[0-9aeh-pr-vxA-Z]$")
  (#latex-script? @conceal subscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#set-pairs! @conceal
    conceal "0" "₀" "1" "₁" "2" "₂" "3" "₃" "4" "₄" "5" "₅" "6" "₆" "7" "₇" "8"
    "₈" "9" "₉" "a" "ₐ" "e" "ₑ" "h" "ₕ" "i" "ᵢ" "j" "ⱼ" "k" "ₖ" "l" "ₗ" "m" "ₘ"
    "n" "ₙ" "o" "ₒ" "p" "ₚ" "r" "ᵣ" "s" "ₛ" "t" "ₜ" "u" "ᵤ" "v" "ᵥ" "x" "ₓ" "A"
    "ᴀ" "B" "ʙ" "C" "ᴄ" "D" "ᴅ" "E" "ᴇ" "F" "ғ" "G" "ɢ" "H" "ʜ" "I" "ɪ" "J" "ᴊ" "K"
    "ᴋ" "L" "ʟ" "M" "ᴍ" "N" "ɴ" "O" "ᴏ" "P" "ᴘ" "Q" "ǫ" "R" "ʀ" "S" "s" "T" "ᴛ" "U"
    "ᴜ" "V" "ᴠ" "W" "ᴡ" "X" "x" "Y" "ʏ" "Z" "ᴢ"))

(text
  word: (subscript) @conceal
  (#any-of? @conceal "_+" "_-" "_/" "_=" "_(" "_)")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal conceal "_+" "₊" "_-" "₋" "_/" "ˏ" "_=" "₌" "_(" "₍" "_)" "₎"))

(text
  word: (operator) @conceal
  (#any-of? @conceal "+" "-" "/" "=" "(" ")")
  (#latex-script? @conceal subscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal conceal "+" "₊" "-" "₋" "/" "ˏ" "=" "₌" "(" "₍" ")" "₎"))

(text
  word: (superscript) @conceal
  (#any-of? @conceal
    "^0" "^1" "^2" "^3" "^4" "^5" "^6" "^7" "^8" "^9" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i"
    "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^r" "^s" "^t" "^u" "^v" "^w" "^x" "^y" "^z" "^A" "^B" "^D"
    "^E" "^G" "^H" "^I" "^J" "^K" "^L" "^M" "^N" "^O" "^P" "^R" "^T" "^U" "^V" "^W")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
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
  (#lua-match? @conceal "^[0-9a-zA-W]$")
  (#latex-script? @conceal superscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "0" "⁰" "1" "¹" "2" "²" "3" "³" "4" "⁴" "5" "⁵" "6" "⁶" "7" "⁷" "8" "⁸"
    "9" "⁹" "a" "ᵃ" "b" "ᵇ" "c" "ᶜ" "d" "ᵈ" "e" "ᵉ" "f" "ᶠ" "g" "ᵍ" "h" "ʰ" "i"
    "ⁱ" "j" "ʲ" "k" "ᵏ" "l" "ˡ" "m" "ᵐ" "n" "ⁿ" "o" "ᵒ" "p" "ᵖ" "r" "ʳ" "s" "ˢ" "t"
    "ᵗ" "u" "ᵘ" "v" "ᵛ" "w" "ʷ" "x" "ˣ" "y" "ʸ" "z" "ᶻ" "A" "ᴬ" "B" "ᴮ" "D" "ᴰ" "E"
    "ᴱ" "G" "ᴳ" "H" "ᴴ" "I" "ᴵ" "J" "ᴶ" "K" "ᴷ" "L" "ᴸ" "M" "ᴹ" "N" "ᴺ" "O" "ᴼ"
    "P" "ᴾ" "R" "ᴿ" "T" "ᵀ" "U" "ᵁ" "V" "ⱽ" "W" "ᵂ"))

(text
  word: (superscript) @conceal
  (#any-of? @conceal "^+" "^-" "^<" "^>" "^/" "^=" "^.")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#set-pairs! @conceal
    conceal "^+" "⁺" "^-" "⁻" "^<" "˂" "^>" "˃" "^/" "ˊ" "^=" "˭" "^." "˙"))

(text
  word: (operator) @conceal
  (#any-of? @conceal "+" "-" "<" ">" "/" "=" ".")
  (#latex-script? @conceal superscript)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal conceal "+" "⁺" "-" "⁻" "<" "˂" ">" "˃" "/" "ˊ" "=" "˭" "." "˙"))

; The parser represents these grouped operators as anonymous tokens.
(subscript
  subscript: (curly_group
    ["=" "(" ")"] @conceal)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal conceal "=" "₌" "(" "₍" ")" "₎"))

(superscript
  superscript: (curly_group
    "=" @conceal)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set! conceal "˭"))

(superscript
  superscript: (curly_group
    (text word: (word) @conceal))
  (#eq? @conceal ".")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set! conceal "˙"))

; Hide the script marker only when the whole braced value is supported.
((subscript
  "_" @conceal
  subscript: (curly_group)) @_script
  (#lua-match? @_script "^_{[0-9aeh-pr-vxA-Z+%-/=()]}$")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set! @conceal conceal ""))

((superscript
  "^" @conceal
  superscript: (curly_group)) @_script
  (#lua-match? @_script "^%^{[0-9a-pr-zABDEG-PRT-W+%-<>/=%.]}$")
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set! @conceal conceal ""))

; Fractions display as (numerator⧸ denominator).
((generic_command
  .
  command: (command_name) @conceal.command
  .
  arg: (curly_group
    "{" @conceal.open1
    "}" @conceal.close1)
  .
  arg: (curly_group
    "{" @conceal.open2
    "}" @conceal.close2)
  .)
  (#any-of? @conceal.command "\\frac" "\\dfrac" "\\tfrac" "\\cfrac")
  (#has-ancestor? @conceal.command math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal.command label_definition text_mode)
  (#set! priority 101)
  (#set! @conceal.command conceal "(")
  (#set! @conceal.open1 conceal "")
  (#set! @conceal.close1 conceal "⧸")
  (#set! @conceal.open2 conceal " ")
  (#set! @conceal.close2 conceal ")"))

; Sized delimiters use different parser fields from ordinary symbol commands.
(math_delimiter
  [
    left_delimiter: _ @conceal
    right_delimiter: _ @conceal
  ]
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal conceal
    "." "" "\\{" "{" "\\}" "}" "\\|" "‖"
    "\\langle" "⟨" "\\rangle" "⟩" "\\lceil" "⌈" "\\rceil" "⌉"
    "\\lfloor" "⌊" "\\rfloor" "⌋" "\\backslash" "∖"
    "\\uparrow" "↑" "\\downarrow" "↓" "\\updownarrow" "↕"
    "\\Uparrow" "⇑" "\\Downarrow" "⇓" "\\Updownarrow" "⇕")
  (#latex-conceal! @conceal "math"))

; A whole command becomes one grapheme only when its full argument is supported.
((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#latex-conceal! @conceal "font")
  (#set! priority 101))

; Physics wrappers share the same structure, context, and priority.
((generic_command
  .
  command: (command_name) @conceal.command
  .
  arg: (curly_group
    "{" @conceal.open
    "}" @conceal.close)
  .)
  (#any-of? @conceal.command "\\bra" "\\ket" "\\abs" "\\norm")
  (#has-ancestor? @conceal.command math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal.command label_definition text_mode)
  (#set! priority 101)
  (#latex-delimiters! @conceal.command @conceal.close)
  (#set! @conceal.open conceal ""))
