; math conceals
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal "\\\\" "\\{" "\\}" "\\|" "\\langle" "\\rangle" "\\varnothing"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\\\" "⏎" "\\{" "{" "\\}" "}" "\\|" "‖" "\\langle" "⟨" "\\rangle" "⟩"
    "\\varnothing" "∅"))
