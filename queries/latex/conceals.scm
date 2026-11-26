; extends

; Every pattern below is evaluated for each node it structurally matches, and
; each candidate match costs a Lua round trip. Compiling a pattern is costly
; too when a child must be found among arbitrary siblings.

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

(generic_command
  command: (command_name) @conceal
  (#set! latex.conceal-only)
  (#latex-symbol! @conceal))

((curly_group) @conceal @conceal.close
  (#latex-braces? @conceal)
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

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#set! latex.conceal-only)
  (#latex-argument! @conceal))

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

; The parser leaves `=`, `(` and `)` as anonymous tokens of the group.
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
  (#set! latex.conceal-only)
  (#set-pairs! @conceal conceal
    "." "" "\\{" "{" "\\}" "}" "\\|" "‖"
    "\\langle" "⟨" "\\rangle" "⟩" "\\lceil" "⌈" "\\rceil" "⌉"
    "\\lfloor" "⌊" "\\rfloor" "⌋" "\\backslash" "∖"
    "\\uparrow" "↑" "\\downarrow" "↓" "\\updownarrow" "↕"
    "\\Uparrow" "⇑" "\\Downarrow" "⇓" "\\Updownarrow" "⇕")
  (#latex-conceal! @conceal "math"))

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
