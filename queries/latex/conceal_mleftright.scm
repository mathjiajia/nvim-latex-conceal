; math conceals
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal
      "\\mleft\\lvert" "\\mright\\rvert" "\\mleft\\lVert" "\\mright\\rVert" "\\mleft|" "\\mright|"
      "\\mleft\\|" "\\mright\\|" "\\mleft(" "\\mright)" "\\mleft\[" "\\mright]" "\\mleft\\{"
      "\\mright\\}" "\\mleft<" "\\mright>" "\\mleft(" "\\mright)" "\\mleft\[" "\\mright]"
      "\\mleft\\{" "\\mright\\}" "\\mleft\\lbrace" "\\mleft\\lceil" "\\mleft\\lfloor"
      "\\mleft\\lgroup" "\\mleft\\lmoustache" "\\mright\\rbrace" "\\mright\\rceil"
      "\\mright\\rfloor" "\\mright\\rgroup" "\\mright\\rmoustache" "\\m\(left\|right\)|"
      "\\m\(left\|right\)\\|" "\\m\(left\|right\)\\downarrow" "\\m\(left\|right\)\\Downarrow"
      "\\m\(left\|right\)\\uparrow" "\\m\(left\|right\)\\Uparrow" "\\m\(left\|right\)\\updownarrow"
      "\\m\(left\|right\)\\Updownarrow"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\mleft\\lvert" "|" "\\mright\\rvert" "|" "\\mleft\\lVert" "‖" "\\mright\\rVert"
    "‖" "\\mleft|" "|" "\\mright|" "|" "\\mleft\\|" "‖" "\\mright\\|" "‖" "\\mleft(" "("
    "\\mright)" ")" "\\mleft\[" "[" "\\mright]" "]" "\\mleft\\{" "{" "\\mright\\}" "}" "\\mleft<"
    "<" "\\mright>" ">" "\\mleft(" "(" "\\mright)" ")" "\\mleft\[" "[" "\\mright]" "]" "\\mleft\\{"
    "{" "\\mright\\}" "}" "\\mleft\\lbrace" "[" "\\mleft\\lceil" "⌈" "\\mleft\\lfloor" "⌊"
    "\\mleft\\lgroup" "⌊" "\\mleft\\lmoustache" "⎛" "\\mright\\rbrace" "]" "\\mright\\rceil"
    "⌉" "\\mright\\rfloor" "⌋" "\\mright\\rgroup" "⌋" "\\mright\\rmoustache" "⎞"
    "\\m\(left\|right\)|" "|" "\\m\(left\|right\)\\|" "‖" "\\m\(left\|right\)\\downarrow" "↓"
    "\\m\(left\|right\)\\Downarrow" "⇓" "\\m\(left\|right\)\\uparrow" "↑"
    "\\m\(left\|right\)\\Uparrow" "↑" "\\m\(left\|right\)\\updownarrow" "↕"
    "\\m\(left\|right\)\\Updownarrow" "⇕"))
