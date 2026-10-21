; extends

; Every pattern below is evaluated for each node it structurally matches, and
; each candidate match costs a Lua round trip, so the patterns are shaped to
; reject nodes in the C query cursor before any predicate or directive runs.

; Symbol commands share one lookup; the directive selects math or text context,
; excludes labels, and hides emphasis wrappers such as \emph and \textbf.
(generic_command
  command: (command_name) @conceal
  (#latex-symbol! @conceal))

; One match per group checks the grandparent once for both braces.
(curly_group
  "{" @conceal
  "}" @conceal
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

; A command with a braced argument becomes one grapheme when the whole text is
; supported: exact accents and legacy fonts keep the default priority, while
; bars, overlines and Unicode font alphabets (math context only) take priority
; 101 so they win over conceals of their contents.
((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#latex-argument! @conceal))

; Unbraced scripts: the node text such as `_1` or `^n` selects the replacement.
; The grammar's script argument is a curly_group, a letter, or a command_name.
(text
  word: [
    (subscript
      subscript: [
        (letter)
        (command_name)
      ])
    (superscript
      superscript: [
        (letter)
        (command_name)
      ])
  ] @conceal
  (#latex-script-supported? @conceal)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal text_mode label_definition)
  (#latex-script! @conceal))

; Braced scripts: a single word or operator inside a group follows the nearest
; enclosing script through grouping braces. Only braced words are candidates.
(curly_group
  (text
    word: [
      (word)
      (operator)
    ] @conceal)
  (#latex-script-supported? @conceal)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#latex-script! @conceal))

; The parser represents these grouped operators as anonymous tokens.
([
  (subscript
    subscript: (curly_group
      [
        "="
        "("
        ")"
      ] @conceal))
  (superscript
    superscript: (curly_group
      [
        "="
        "("
        ")"
      ] @conceal))
]
  (#latex-script-supported? @conceal)
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#latex-script! @conceal))

; Hide the script marker only when the whole braced value is supported.
([
  (subscript
    "_" @conceal
    subscript: (curly_group))
  (superscript
    "^" @conceal
    superscript: (curly_group))
] @_script
  (#latex-script-marker? @_script)
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
