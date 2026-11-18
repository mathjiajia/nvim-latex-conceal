; extends

; Every pattern below is evaluated for each node it structurally matches, and
; each candidate match costs a Lua round trip, so the patterns are shaped to
; reject nodes in the C query cursor before any predicate or directive runs.
; Compiling a pattern is costly too when a child must be found among arbitrary
; siblings, so braces and delimiters are not matched as children: their node is
; captured twice and #latex-ends! narrows the captures to its two end tokens.

; Mathematics, text commands and labels. The renderer records these regions as
; the query yields them, in document order, which lets #latex-math? and the
; symbol directives place a node without walking its ancestors. A formula's
; delimiters are hidden by the same match.
([
  (inline_formula)
  (displayed_equation)
] @_math @conceal @conceal.close
  (#latex-ends! @conceal @conceal.close)
  (#set! @conceal conceal "")
  (#set! @conceal.close conceal ""))

(math_environment) @_math

(text_mode) @_text

(label_definition) @_label

; Symbol commands share one lookup; the directive selects math or text context,
; excludes labels, and hides emphasis wrappers such as \emph and \textbf.
(generic_command
  command: (command_name) @conceal
  (#latex-symbol! @conceal))

; One match per group checks the group's parent once for both braces. The
; captures are narrowed to the braces, so the group itself stays visible.
((curly_group) @conceal @conceal.close
  (#not-latex-parent? @conceal
    title_declaration author_declaration chapter part section subsection subsubsection paragraph
    subparagraph generic_command)
  (#latex-ends! @conceal @conceal.close)
  (#set! @conceal conceal "")
  (#set! @conceal.close conceal ""))

(math_delimiter
  [
    left_command: _ @conceal
    right_command: _ @conceal
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
; one above the Tree-sitter default so they win over conceals of their contents.
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
  (#latex-math? @conceal)
  (#latex-script! @conceal))

; Braced scripts: a single word or operator inside a group follows the nearest
; enclosing script through grouping braces. The parser leaves `=`, `(` and `)`
; as anonymous tokens of the group, which count directly inside a script only.
(curly_group
  [
    (text
      word: [
        (word)
        (operator)
      ] @conceal)
    "=" @conceal
    "(" @conceal
    ")" @conceal
  ]
  (#latex-script-supported? @conceal)
  (#latex-math? @conceal)
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
  (#latex-math? @conceal)
  (#set! @conceal conceal ""))

; Fractions display as (numerator⧸ denominator). Each argument is captured
; twice and narrowed to its opening and closing brace.
((generic_command
  .
  command: (command_name) @conceal.command
  .
  arg: (curly_group) @conceal.open1 @conceal.close1
  .
  arg: (curly_group) @conceal.open2 @conceal.close2
  .)
  (#latex-command? @conceal.command "\\frac" "\\dfrac" "\\tfrac" "\\cfrac")
  (#latex-math? @conceal.command)
  (#set! priority 101)
  (#latex-ends! @conceal.open1 @conceal.close1)
  (#latex-ends! @conceal.open2 @conceal.close2)
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
  (#latex-math? @conceal)
  (#set-pairs! @conceal conceal
    "." "" "\\{" "{" "\\}" "}" "\\|" "‖"
    "\\langle" "⟨" "\\rangle" "⟩" "\\lceil" "⌈" "\\rceil" "⌉"
    "\\lfloor" "⌊" "\\rfloor" "⌋" "\\backslash" "∖"
    "\\uparrow" "↑" "\\downarrow" "↓" "\\updownarrow" "↕"
    "\\Uparrow" "⇑" "\\Downarrow" "⇓" "\\Updownarrow" "⇕")
  (#latex-conceal! @conceal "math"))

; Physics wrappers, modular arithmetic such as \pmod{n} → (mod n), and
; \operatorname share the same structure, context, and priority.
((generic_command
  .
  command: (command_name) @conceal.command
  .
  arg: (curly_group) @conceal.open @conceal.close
  .)
  (#latex-command? @conceal.command
    "\\bra" "\\ket" "\\abs" "\\norm" "\\pmod" "\\pod" "\\mod" "\\operatorname" "\\operatorname*")
  (#latex-math? @conceal.command)
  (#set! priority 101)
  (#latex-ends! @conceal.open @conceal.close)
  (#latex-delimiters! @conceal.command @conceal.close @conceal.open))
