; extends

; amssymb conceals
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal
      "\\Bbbk" "\\Bumpeq" "\\Finv" "\\Game" "\\Lleftarrow" "\\Rrightarrow" "\\Subset" "\\Supset"
      "\\Vdash" "\\Vvdash" "\\approxeq" "\\backepsilon" "\\backprime" "\\backsim" "\\backsimeq"
      "\\barwedge" "\\because" "\\beth" "\\between" "\\bigstar" "\\blacklozenge" "\\blacksquare"
      "\\blacktriangle" "\\blacktriangledown" "\\blacktriangleleft" "\\blacktriangleright"
      "\\boxdot" "\\boxminus" "\\boxplus" "\\boxtimes" "\\bumpeq" "\\centerdot" "\\checkmark"
      "\\circeq" "\\circlearrowleft" "\\circlearrowright" "\\circledS" "\\circledast"
      "\\circledcirc" "\\circleddash" "\\complement" "\\curlyeqprec" "\\curlyeqsucc" "\\curlyvee"
      "\\curlywedge" "\\curvearrowleft" "\\curvearrowright" "\\daleth" "\\diagdown" "\\diagup"
      "\\digamma" "\\divideontimes" "\\doteqdot" "\\dotplus" "\\doublebarwedge" "\\downdownarrows"
      "\\downharpoonleft" "\\downharpoonright" "\\eqcirc" "\\eqsim" "\\eqslantgtr" "\\eqslantless"
      "\\fallingdotseq" "\\geqq" "\\geqslant" "\\gimel" "\\gnapprox" "\\gneq" "\\gneqq" "\\gnsim"
      "\\gtrapprox" "\\gtrdot" "\\gtreqless" "\\gtreqqless" "\\gtrless" "\\gtrsim" "\\gvertneqq"
      "\\hslash" "\\intercal" "\\leftarrowtail" "\\leftleftarrows" "\\leftrightarrows"
      "\\leftrightharpoons" "\\leftrightsquigarrow" "\\leftthreetimes" "\\leqq" "\\leqslant"
      "\\lessapprox" "\\lessdot" "\\lesseqgtr" "\\lesseqqgtr" "\\lessgtr" "\\lesssim" "\\lnapprox"
      "\\lneq" "\\lneqq" "\\lnsim" "\\looparrowleft" "\\looparrowright" "\\lozenge" "\\ltimes"
      "\\lvertneqq" "\\maltese" "\\measuredangle" "\\multimap" "\\nLeftarrow" "\\nLeftrightarrow"
      "\\nRightarrow" "\\nVDash" "\\nVdash" "\\ncong" "\\nexists" "\\ngeq" "\\ngeqq" "\\ngeqslant"
      "\\ngtr" "\\nleftarrow" "\\nleftrightarrow" "\\nleq" "\\nleqq" "\\nleqslant" "\\nless"
      "\\nmid" "\\nparallel" "\\nprec" "\\npreceq" "\\nrightarrow" "\\nshortmid" "\\nshortparallel"
      "\\nsim" "\\nsubseteq" "\\nsubseteqq" "\\nsucc" "\\nsucceq" "\\nsupseteq" "\\nsupseteqq"
      "\\ntriangleleft" "\\ntrianglelefteq" "\\ntriangleright" "\\ntrianglerighteq" "\\nvDash"
      "\\nvdash" "\\pitchfork" "\\precapprox" "\\preccurlyeq" "\\precnapprox" "\\precneqq"
      "\\precnsim" "\\precsim" "\\rightarrowtail" "\\rightleftarrows" "\\rightrightarrows"
      "\\rightsquigarrow" "\\rightthreetimes" "\\risingdotseq" "\\rtimes" "\\shortmid"
      "\\shortparallel" "\\smallfrown" "\\smallsetminus" "\\smallsmile" "\\sphericalangle"
      "\\square" "\\subseteqq" "\\subsetneq" "\\subsetneqq" "\\succapprox" "\\succcurlyeq"
      "\\succnapprox" "\\succneqq" "\\succnsim" "\\succsim" "\\supseteqq" "\\supsetneq"
      "\\supsetneqq" "\\therefore" "\\thickapprox" "\\thicksim" "\\triangledown" "\\trianglelefteq"
      "\\triangleq" "\\trianglerighteq" "\\twoheadleftarrow" "\\twoheadrightarrow" "\\upharpoonleft"
      "\\upharpoonright" "\\upuparrows" "\\vDash" "\\varkappa" "\\varnothing" "\\varpropto"
      "\\varsubsetneq" "\\varsubsetneqq" "\\varsupsetneq" "\\varsupsetneqq" "\\vartriangle"
      "\\vartriangleleft" "\\vartriangleright" "\\veebar"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\Bbbk" "𝕜" "\\Bumpeq" "≎" "\\Finv" "Ⅎ" "\\Game" "⅁" "\\Lleftarrow" "⇚"
    "\\Rrightarrow" "⇛" "\\Subset" "⋐" "\\Supset" "⋑" "\\Vdash" "⊩" "\\Vvdash" "⊪"
    "\\approxeq" "≊" "\\backepsilon" "∍" "\\backprime" "‵" "\\backsim" "∽" "\\backsimeq"
    "⋍" "\\barwedge" "⊼" "\\because" "∵" "\\beth" "ℶ" "\\between" "≬" "\\bigstar" "★"
    "\\blacklozenge" "◆" "\\blacksquare" "■" "\\blacktriangle" "▲" "\\blacktriangledown" "▼"
    "\\blacktriangleleft" "◀" "\\blacktriangleright" "▶" "\\boxdot" "⊡" "\\boxminus" "⊟"
    "\\boxplus" "⊞" "\\boxtimes" "⊠" "\\bumpeq" "≏" "\\centerdot" "⋅" "\\checkmark" "✓"
    "\\circeq" "≗" "\\circlearrowleft" "↺" "\\circlearrowright" "↻" "\\circledS" "Ⓢ"
    "\\circledast" "⊛" "\\circledcirc" "⊚" "\\circleddash" "⊝" "\\complement" "∁"
    "\\curlyeqprec" "⋞" "\\curlyeqsucc" "⋟" "\\curlyvee" "⋎" "\\curlywedge" "⋏"
    "\\curvearrowleft" "↶" "\\curvearrowright" "↷" "\\daleth" "ℸ" "\\diagdown" "╲"
    "\\diagup" "╱" "\\digamma" "ϝ" "\\divideontimes" "⋇" "\\doteqdot" "≑" "\\dotplus" "∔"
    "\\doublebarwedge" "⩞" "\\downdownarrows" "⇊" "\\downharpoonleft" "⇃" "\\downharpoonright"
    "⇂" "\\eqcirc" "≖" "\\eqsim" "≂" "\\eqslantgtr" "⪖" "\\eqslantless" "⪕"
    "\\fallingdotseq" "≒" "\\geqq" "≧" "\\geqslant" "⩾" "\\gimel" "ℷ" "\\gnapprox" "⪊"
    "\\gneq" "⪈" "\\gneqq" "≩" "\\gnsim" "⋧" "\\gtrapprox" "⪆" "\\gtrdot" "⋗"
    "\\gtreqless" "⋛" "\\gtreqqless" "⪌" "\\gtrless" "≷" "\\gtrsim" "≳" "\\gvertneqq" ""
    "\\hslash" "ℏ" "\\intercal" "⊺" "\\leftarrowtail" "↢" "\\leftleftarrows" "⇇"
    "\\leftrightarrows" "⇆" "\\leftrightharpoons" "⇋" "\\leftrightsquigarrow" "↭"
    "\\leftthreetimes" "⋋" "\\leqq" "≦" "\\leqslant" "⩽" "\\lessapprox" "⪅" "\\lessdot"
    "⋖" "\\lesseqgtr" "⋚" "\\lesseqqgtr" "⪋" "\\lessgtr" "≶" "\\lesssim" "≲" "\\lnapprox"
    "⪉" "\\lneq" "⪇" "\\lneqq" "≨" "\\lnsim" "⋦" "\\looparrowleft" "↫" "\\looparrowright"
    "↬" "\\lozenge" "◊" "\\ltimes" "⋉" "\\lvertneqq" "" "\\maltese" "✠" "\\measuredangle"
    "∡" "\\multimap" "⊸" "\\nLeftarrow" "⇍" "\\nLeftrightarrow" "⇎" "\\nRightarrow" "⇏"
    "\\nVDash" "⊯" "\\nVdash" "⊮" "\\ncong" "≆" "\\nexists" "∄" "\\ngeq" "≱" "\\ngeqq"
    "" "\\ngeqslant" "" "\\ngtr" "≯" "\\nleftarrow" "↚" "\\nleftrightarrow" "↮" "\\nleq"
    "≰" "\\nleqq" "" "\\nleqslant" "" "\\nless" "≮" "\\nmid" "∤" "\\nparallel" "∦"
    "\\nprec" "⊀" "\\npreceq" "⋠" "\\nrightarrow" "↛" "\\nshortmid" "" "\\nshortparallel"
    "" "\\nsim" "≁" "\\nsubseteq" "⊈" "\\nsubseteqq" "" "\\nsucc" "⊁" "\\nsucceq" "⋡"
    "\\nsupseteq" "⊉" "\\nsupseteqq" "" "\\ntriangleleft" "⋪" "\\ntrianglelefteq" "⋬"
    "\\ntriangleright" "⋫" "\\ntrianglerighteq" "⋭" "\\nvDash" "⊭" "\\nvdash" "⊬"
    "\\pitchfork" "⋔" "\\precapprox" "⪷" "\\preccurlyeq" "≼" "\\precnapprox" "⪹"
    "\\precneqq" "⪵" "\\precnsim" "⋨" "\\precsim" "≾" "\\rightarrowtail" "↣"
    "\\rightleftarrows" "⇄" "\\rightrightarrows" "⇉" "\\rightsquigarrow" "⇝"
    "\\rightthreetimes" "⋌" "\\risingdotseq" "≓" "\\rtimes" "⋊" "\\shortmid" "∣"
    "\\shortparallel" "∥" "\\smallfrown" "⌢" "\\smallsetminus" "∖" "\\smallsmile" "⌣"
    "\\sphericalangle" "∢" "\\square" "□" "\\subseteqq" "⫅" "\\subsetneq" "⊊" "\\subsetneqq"
    "⫋" "\\succapprox" "⪸" "\\succcurlyeq" "≽" "\\succnapprox" "⪺" "\\succneqq" "⪶"
    "\\succnsim" "⋩" "\\succsim" "≿" "\\supseteqq" "⫆" "\\supsetneq" "⊋" "\\supsetneqq"
    "⫌" "\\therefore" "∴" "\\thickapprox" "≈" "\\thicksim" "∼" "\\triangledown" "▽"
    "\\trianglelefteq" "⊴" "\\triangleq" "≜" "\\trianglerighteq" "⊵" "\\twoheadleftarrow"
    "↞" "\\twoheadrightarrow" "↠" "\\upharpoonleft" "↿" "\\upharpoonright" "↾"
    "\\upuparrows" "⇈" "\\vDash" "⊨" "\\varkappa" "ϰ" "\\varnothing" "∅" "\\varpropto" "∝"
    "\\varsubsetneq" "" "\\varsubsetneqq" "" "\\varsupsetneq" "" "\\varsupsetneqq" ""
    "\\vartriangle" "△" "\\vartriangleleft" "⊲" "\\vartriangleright" "⊳" "\\veebar" "⊻")
  )

; math conceals
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal
      "\\aleph" "\\amalg" "\\angle" "\\approx" "\\ast" "\\asymp" "\\backslash" "\\bigcap"
      "\\bigcirc" "\\bigcup" "\\bigodot" "\\bigoplus" "\\bigotimes" "\\bigsqcup" "\\bigtriangledown"
      "\\bigtriangleup" "\\bigvee" "\\bigwedge" "\\bot" "\\bowtie" "\\bullet" "\\cap" "\\cdot"
      "\\cdots" "\\circ" "\\clubsuit" "\\cong" "\\coprod" "\\copyright" "\\cup" "\\dagger" "\\dashv"
      "\\ddagger" "\\ddots" "\\diamond" "\\diamondsuit" ; "\\div"
       "\\doteq" "\\dots" "\\downarrow" "\\Downarrow" "\\ell" "\\emptyset" "\\equiv" "\\exists"
      "\\flat" "\\forall" "\\frown" "\\ge" "\\geq" "\\gets" "\\gg" "\\hbar" "\\heartsuit"
      "\\hookleftarrow" "\\hookrightarrow" "\\iff" "\\Im" "\\imath" "\\in" "\\infty" "\\int"
      "\\iint" "\\iiint" "\\jmath" "\\land" "\\lnot" "\\lceil" "\\ldots" "\\le" "\\leftarrow"
      "\\Leftarrow" "\\leftharpoondown" "\\leftharpoonup" "\\leftrightarrow" "\\Leftrightarrow"
      "\\lhd" "\\rhd" "\\leq" "\\ll" "\\lmoustache" "\\lor" "\\mapsto" "\\mid" "\\models" "\\mp"
      "\\nabla" "\\natural" "\\ne" "\\nearrow" "\\neg" "\\neq" "\\ni" "\\notin" "\\nwarrow" "\\odot"
      "\\oint" "\\ominus" "\\oplus" "\\oslash" "\\otimes" "\\owns" "\\P" "\\parallel" "\\partial"
      "\\perp" "\\pm" "\\prec" "\\preceq" "\\prime" "\\prod" "\\propto" "\\rceil" "\\Re"
      "\\rightarrow" "\\Rightarrow" "\\leftarrow" "\\Leftarrow" "\\rightleftharpoons" "\\rmoustache"
      "\\S" "\\searrow" "\\setminus" "\\sharp" "\\sim" "\\simeq" "\\smile" "\\spadesuit" "\\sqcap"
      "\\sqcup" "\\sqsubset" "\\sqsubseteq" "\\sqsupset" "\\sqsupseteq" "\\star" "\\subset"
      "\\subseteq" "\\succ" "\\succeq" "\\sum" "\\supset" "\\supseteq" "\\surd" "\\swarrow"
      "\\times" "\\to" "\\top" "\\triangle" "\\triangleleft" "\\triangleright" "\\uparrow"
      "\\Uparrow" "\\updownarrow" "\\Updownarrow" "\\vdash" "\\vdots" "\\vee" "\\wedge" "\\wp"
      "\\wr" "\\implies" "\\choose" "\\sqrt" "\\colon" "\\coloneqq" "\\eqqcolon"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\aleph" "ℵ" "\\amalg" "∐" "\\angle" "∠" "\\approx" "≈" "\\ast" "∗" "\\asymp"
    "≍" "\\backslash" "∖" "\\bigcap" "∩" "\\bigcirc" "○" "\\bigcup" "∪" "\\bigodot" "⊙"
    "\\bigoplus" "⊕" "\\bigotimes" "⊗" "\\bigsqcup" "⊔" "\\bigtriangledown" "∇"
    "\\bigtriangleup" "∆" "\\bigvee" "⋁" "\\bigwedge" "⋀" "\\bot" "⊥" "\\bowtie" "⋈"
    "\\bullet" "•" "\\cap" "∩" "\\cdot" "·" "\\cdots" "⋯" "\\circ" "∘" "\\clubsuit" "♣"
    "\\cong" "≅" "\\coprod" "∐" "\\copyright" "©" "\\cup" "∪" "\\dagger" "†" "\\dashv"
    "⊣" "\\ddagger" "‡" "\\ddots" "⋱" "\\diamond" "⋄" "\\diamondsuit" "♢" ; 
     "\\div" "÷" "\\doteq" "≐" "\\dots" "…" "\\downarrow" "↓" "\\Downarrow" "⇓" "\\ell"
    "ℓ" "\\emptyset" "Ø" "\\equiv" "≡" "\\exists" "∃" "\\flat" "♭" "\\forall" "∀"
    "\\frown" "⁔" "\\ge" "≥" "\\geq" "≥" "\\gets" "←" "\\gg" "⟫" "\\hbar" "ℏ"
    "\\heartsuit" "♡" "\\hookleftarrow" "↩" "\\hookrightarrow" "↪" "\\iff" "⇔" "\\Im" "ℑ"
    "\\imath" "ɩ" "\\in" "∈" "\\infty" "∞" "\\int" "∫" "\\iint" "∬" "\\iiint" "∭"
    "\\jmath" "𝚥" "\\land" "∧" "\\lnot" "¬" "\\lceil" "⌈" "\\ldots" "…" "\\le" "≤"
    "\\leftarrow" "←" "\\Leftarrow" "⇐" "\\leftharpoondown" "↽" "\\leftharpoonup" "↼"
    "\\leftrightarrow" "↔" "\\Leftrightarrow" "⇔" "\\lhd" "◁" "\\rhd" "▷" "\\leq" "≤"
    "\\ll" "≪" "\\lmoustache" "╭" "\\lor" "∨" "\\mapsto" "↦" "\\mid" "∣" "\\models" "⊨"
    "\\mp" "∓" "\\nabla" "∇" "\\natural" "♮" "\\ne" "≠" "\\nearrow" "↗" "\\neg" "¬"
    "\\neq" "≠" "\\ni" "∋" "\\notin" "∉" "\\nwarrow" "↖" "\\odot" "⊙" "\\oint" "∮"
    "\\ominus" "⊖" "\\oplus" "⊕" "\\oslash" "⊘" "\\otimes" "⊗" "\\owns" "∋" "\\P" "¶"
    "\\parallel" "║" "\\partial" "∂" "\\perp" "⊥" "\\pm" "±" "\\prec" "≺" "\\preceq" "⪯"
    "\\prime" "′" "\\prod" "∏" "\\propto" "∝" "\\rceil" "⌉" "\\Re" "ℜ" "\\rightarrow"
    "→" "\\Rightarrow" "⇒" "\\leftarrow" "←" "\\Leftarrow" "⇐" "\\rightleftharpoons" "⇌"
    "\\rmoustache" "╮" "\\S" "§" "\\searrow" "↘" "\\setminus" "⧵" "\\sharp" "♯" "\\sim"
    "∼" "\\simeq" "⋍" "\\smile" "‿" "\\spadesuit" "♠" "\\sqcap" "⊓" "\\sqcup" "⊔"
    "\\sqsubset" "⊏" "\\sqsubseteq" "⊑" "\\sqsupset" "⊐" "\\sqsupseteq" "⊒" "\\star" "✫"
    "\\subset" "⊂" "\\subseteq" "⊆" "\\succ" "≻" "\\succeq" "⪰" "\\sum" "∑" "\\supset"
    "⊃" "\\supseteq" "⊇" "\\surd" "√" "\\swarrow" "↙" "\\times" "×" "\\to" "→" "\\top"
    "⊤" "\\triangle" "∆" "\\triangleleft" "⊲" "\\triangleright" "⊳" "\\uparrow" "↑"
    "\\Uparrow" "⇑" "\\updownarrow" "↕" "\\Updownarrow" "⇕" "\\vdash" "⊢" "\\vdots" "⋮"
    "\\vee" "∨" "\\wedge" "∧" "\\wp" "℘" "\\wr" "≀" "\\implies" "⇒" "\\choose" "C"
    "\\sqrt" "√" "\\colon" ":" "\\coloneqq" "≔" "\\eqqcolon" "≕")
  )

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

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\`{[aeiouyAEIOUY]}")
  (#set-pairs! @conceal
    conceal "\\`{a}" "à" "\\`{e}" "è" "\\`{i}" "ì" "\\`{o}" "ò" "\\`{u}" "ù" "\\`{y}" "ỳ"
    "\\`{A}" "À" "\\`{E}" "È" "\\`{I}" "Ì" "\\`{O}" "Ò" "\\`{U}" "Ù" "\\`{Y}" "Ỳ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\'{[acegilnorsuyzACEGILNORSUYZ]}")
  (#set-pairs! @conceal
    conceal "\\'{a}" "á" "\\'{c}" "ć" "\\'{e}" "é" "\\'{g}" "ǵ" "\\'{i}" "í" "\\'{l}" "ĺ"
    "\\'{n}" "ń" "\\'{o}" "ó" "\\'{r}" "ŕ" "\\'{s}" "ś" "\\'{u}" "ú" "\\'{y}" "ý" "\\'{z}"
    "ź" "\\'{A}" "Á" "\\'{C}" "Ć" "\\'{E}" "É" "\\'{G}" "Ǵ" "\\'{I}" "Í" "\\'{L}" "Ĺ"
    "\\'{N}" "Ń" "\\'{O}" "Ó" "\\'{R}" "Ŕ" "\\'{S}" "Ś" "\\'{U}" "Ú" "\\'{Y}" "Ý" "\\'{Z}"
    "Ź"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\^{[aceghijlosuwACEGILOSUW]}")
  (#set-pairs! @conceal
    conceal "\\^{a}" "â" "\\^{c}" "ĉ" "\\^{e}" "ê" "\\^{g}" "ĝ" "\\^{h}" "ĥ" "\\^{i}" "î"
    "\\^{j}" "ĵ" "\\^{l}" "ľ" "\\^{n}" "ň" "\\^{o}" "ô" "\\^{s}" "ŝ" "\\^{u}" "û" "\\^{w}"
    "ŵ" "\\^{A}" "Â" "\\^{C}" "Ĉ" "\\^{E}" "Ê" "\\^{G}" "Ĝ" "\\^{I}" "Î" "\\^{L}" "Ľ"
    "\\^{O}" "Ô" "\\^{S}" "Ŝ" "\\^{U}" "Û" "\\^{W}" "Ŵ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\\"{[aeiouyAEIOUY]}")
  (#set-pairs! @conceal
    conceal "\\\"{a}" "ä" "\\\"{e}" "ë" "\\\"{i}" "ï" "\\\"{o}" "ö" "\\\"{u}" "ü" "\\\"{y}"
    "ÿ" "\\\"{A}" "Ä" "\\\"{E}" "Ë" "\\\"{I}" "Ï" "\\\"{O}" "Ö" "\\\"{U}" "Ü" "\\\"{Y}" "Ÿ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\%{[aeinouyAEINOUY]}")
  (#set-pairs! @conceal
    conceal "\\%{a}" "ã" "\\%{e}" "ẽ" "\\%{i}" "ĩ" "\\%{n}" "ñ" "\\%{o}" "õ" "\\%{u}" "ũ"
    "\\%{y}" "ỹ" "\\%{A}" "Ã" "\\%{E}" "Ẽ" "\\%{I}" "Ĩ" "\\%{N}" "Ñ" "\\%{O}" "Õ" "\\%{U}"
    "Ũ" "\\%{Y}" "Ỹ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\\.{[acegimoryACEGIMORY]}")
  (#set-pairs! @conceal
    conceal "\\\.{a}" "ȧ" "\\\.{c}" "ċ" "\\\.{e}" "ė" "\\\.{g}" "ġ" "\\\.{i}" "İ" "\\\.{m}"
    "ṁ" "\\\.{o}" "ȯ" "\\\.{r}" "ṙ" "\\\.{y}" "ẏ" "\\\.{A}" "Ȧ" "\\\.{C}" "Ċ" "\\\.{E}"
    "Ė" "\\\.{G}" "Ġ" "\\\.{I}" "İ" "\\\.{M}" "Ṁ" "\\\.{O}" "Ȯ" "\\\.{R}" "Ṙ" "\\\.{Y}"
    "Ẏ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\={[aeiouAEIOU]}")
  (#set-pairs! @conceal
    conceal "\\={a}" "ā" "\\={e}" "ē" "\\={i}" "ī" "\\={o}" "ō" "\\={u}" "ū" "\\={A}" "Ā"
    "\\={E}" "Ē" "\\={I}" "Ī" "\\={O}" "Ō" "\\={U}" "Ū"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\c{[cegklnrstCEGKLNRST]}")
  (#set-pairs! @conceal
    conceal "\\c{c}" "ç" "\\c{e}" "ę" "\\c{g}" "ğ" "\\c{k}" "ķ" "\\c{l}" "ļ" "\\c{n}" "ņ"
    "\\c{r}" "ŗ" "\\c{s}" "ş" "\\c{t}" "ţ" "\\c{C}" "Ç" "\\c{E}" "Ę" "\\c{G}" "Ğ" "\\c{K}"
    "Ķ" "\\c{L}" "Ļ" "\\c{N}" "Ņ" "\\c{R}" "Ŗ" "\\c{S}" "Ş" "\\c{T}" "Ţ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\H{[ouOU]}")
  (#set-pairs! @conceal conceal "\\H{o}" "ő" "\\H{u}" "ű" "\\H{O}" "Ő" "\\H{U}" "Ű"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\k{[aeiosuAEIOU]}")
  (#set-pairs! @conceal
    conceal "\\k{a}" "ą" "\\k{e}" "ę" "\\k{i}" "į" "\\k{o}" "ǫ" "\\k{s}" "ȿ" "\\k{u}" "ų"
    "\\k{A}" "Ą" "\\k{E}" "Ę" "\\k{I}" "Į" "\\k{O}" "Ǫ" "\\k{U}" "Ų"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\r{[auAU]}")
  (#set-pairs! @conceal conceal "\\r{a}" "å" "\\r{u}" "ů" "\\r{A}" "Å" "\\r{U}" "Ů"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\u{[aegiouAEGIOU]}")
  (#set-pairs! @conceal
    conceal "\\u{a}" "ă" "\\u{e}" "ĕ" "\\u{g}" "ģ" "\\u{i}" "ĭ" "\\u{o}" "ŏ" "\\u{u}" "ŭ"
    "\\u{A}" "Ă" "\\u{E}" "Ĕ" "\\u{G}" "Ģ" "\\u{I}" "Ĭ" "\\u{O}" "Ŏ" "\\u{U}" "Ŭ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\v{[acdeghijklnorstuzACDEGHIJKLNORSTUZ]}")
  (#set-pairs! @conceal
    conceal "\\v{a}" "ǎ" "\\v{c}" "č" "\\v{d}" "ď" "\\v{e}" "ě" "\\v{g}" "ǧ" "\\v{h}" "ȟ"
    "\\v{i}" "ǐ" "\\v{j}" "ǰ" "\\v{k}" "ǩ" "\\v{l}" "ľ" "\\v{n}" "ň" "\\v{o}" "ǒ" "\\v{r}"
    "ř" "\\v{s}" "š" "\\v{t}" "ť" "\\v{u}" "ǔ" "\\v{z}" "ž" "\\v{A}" "Ǎ" "\\v{C}" "Č"
    "\\v{D}" "Ď" "\\v{E}" "Ě" "\\v{G}" "Ǧ" "\\v{H}" "Ȟ" "\\v{I}" "Ǐ" "\\v{J}" "ǰ" "\\v{K}"
    "Ǩ" "\\v{L}" "Ľ" "\\v{N}" "Ň" "\\v{O}" "Ǒ" "\\v{R}" "Ř" "\\v{S}" "Š" "\\v{T}" "Ť"
    "\\v{U}" "Ǔ" "\\v{Z}" "Ž"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\bar{[%a]}")
  (#set-pairs! @conceal
    conceal "\\bar{a}" "a̅" "\\bar{b}" "b̅" "\\bar{c}" "c̅" "\\bar{d}" "d̅" "\\bar{e}" "e̅"
    "\\bar{f}" "f̅" "\\bar{g}" "g̅" "\\bar{h}" "h̅" "\\bar{i}" "i̅" "\\bar{j}" "j̅" "\\bar{k}"
    "k̅" "\\bar{l}" "l̅" "\\bar{m}" "m̅" "\\bar{n}" "n̅" "\\bar{o}" "o̅" "\\bar{p}" "p̅"
    "\\bar{q}" "q̅" "\\bar{r}" "r̅" "\\bar{s}" "s̅" "\\bar{t}" "t̅" "\\bar{u}" "u̅" "\\bar{v}"
    "v̅" "\\bar{w}" "w̅" "\\bar{x}" "x̅" "\\bar{y}" "y̅" "\\bar{z}" "z̅" "\\bar{A}" "A̅"
    "\\bar{B}" "B̅" "\\bar{C}" "C̅" "\\bar{D}" "D̅" "\\bar{E}" "E̅" "\\bar{F}" "F̅" "\\bar{G}"
    "G̅" "\\bar{H}" "H̅" "\\bar{I}" "I̅" "\\bar{J}" "J̅" "\\bar{K}" "K̅" "\\bar{L}" "L̅"
    "\\bar{M}" "M̅" "\\bar{N}" "N̅" "\\bar{O}" "O̅" "\\bar{P}" "P̅" "\\bar{Q}" "Q̅" "\\bar{R}"
    "R̅" "\\bar{S}" "S̅" "\\bar{T}" "T̅" "\\bar{U}" "U̅" "\\bar{V}" "V̅" "\\bar{W}" "W̅"
    "\\bar{X}" "X̅" "\\bar{Y}" "Y̅" "\\bar{Z}" "Z̅"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\bar{\\\\[%a]+}")
  (#set! priority 101)
  (#set-pairs! @conceal
    conceal
    ; Lowercase Greek letters (using combining macron U+0304)
    "\\bar{\\alpha}" "α̅" "\\bar{\\beta}" "β̅" "\\bar{\\gamma}" "γ̅" "\\bar{\\delta}" "δ̅"
    "\\bar{\\epsilon}" "ε̅" "\\bar{\\zeta}" "ζ̅" "\\bar{\\eta}" "η̅" "\\bar{\\theta}" "θ̅"
    "\\bar{\\iota}" "ι̅" "\\bar{\\kappa}" "κ̅" "\\bar{\\lambda}" "λ̅" "\\bar{\\mu}" "μ̅"
    "\\bar{\\nu}" "ν̅" "\\bar{\\xi}" "ξ̅" "\\bar{\\omicron}" "ο̅" "\\bar{\\pi}" "π̅"
    "\\bar{\\rho}" "ρ̅" "\\bar{\\sigma}" "σ̅" "\\bar{\\tau}" "τ̅" "\\bar{\\upsilon}" "υ̅"
    "\\bar{\\phi}" "ϕ̅" "\\bar{\\chi}" "χ̅" "\\bar{\\psi}" "ψ̅" "\\bar{\\omega}" "ω̅"
    ; Uppercase Greek letters
    "\\bar{\\Alpha}" "Α̅" "\\bar{\\Beta}" "Β̅" "\\bar{\\Gamma}" "Γ̅" "\\bar{\\Delta}" "Δ̅"
    "\\bar{\\Epsilon}" "Ε̅" "\\bar{\\Zeta}" "Ζ̅" "\\bar{\\Eta}" "Η̅" "\\bar{\\Theta}" "Θ̅"
    "\\bar{\\Iota}" "Ι̅" "\\bar{\\Kappa}" "Κ̅" "\\bar{\\Lambda}" "Λ̅" "\\bar{\\Mu}" "Μ̅"
    "\\bar{\\Nu}" "Ν̅" "\\bar{\\Xi}" "Ξ̅" "\\bar{\\Omicron}" "Ο̅" "\\bar{\\Pi}" "Π̅"
    "\\bar{\\Rho}" "Ρ̅" "\\bar{\\Sigma}" "Σ̅" "\\bar{\\Tau}" "Τ̅" "\\bar{\\Upsilon}" "Υ̅"
    "\\bar{\\Phi}" "Φ̅" "\\bar{\\Chi}" "Χ̅" "\\bar{\\Psi}" "Ψ̅" "\\bar{\\Omega}" "Ω̅"
    ; Variants and alternate forms
    "\\bar{\\varepsilon}" "ϵ̅" "\\bar{\\vartheta}" "ϑ̅" "\\bar{\\varpi}" "ϖ̅"
    "\\bar{\\varrho}" "ϱ̅" "\\bar{\\varsigma}" "ς̅" "\\bar{\\varphi}" "φ̅"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\overline{[%a]}")
  (#set-pairs! @conceal
    conceal "\\overline{a}" "a̅" "\\overline{b}" "b̅" "\\overline{c}" "c̅" "\\overline{d}" "d̅"
    "\\overline{e}" "e̅" "\\overline{f}" "f̅" "\\overline{g}" "g̅" "\\overline{h}" "h̅"
    "\\overline{i}" "i̅" "\\overline{j}" "j̅" "\\overline{k}" "k̅" "\\overline{l}" "l̅"
    "\\overline{m}" "m̅" "\\overline{n}" "n̅" "\\overline{o}" "o̅" "\\overline{p}" "p̅"
    "\\overline{q}" "q̅" "\\overline{r}" "r̅" "\\overline{s}" "s̅" "\\overline{t}" "t̅"
    "\\overline{u}" "u̅" "\\overline{v}" "v̅" "\\overline{w}" "w̅" "\\overline{x}" "x̅"
    "\\overline{y}" "y̅" "\\overline{z}" "z̅" "\\overline{A}" "A̅" "\\overline{B}" "B̅"
    "\\overline{C}" "C̅" "\\overline{D}" "D̅" "\\overline{E}" "E̅" "\\overline{F}" "F̅"
    "\\overline{G}" "G̅" "\\overline{H}" "H̅" "\\overline{I}" "I̅" "\\overline{J}" "J̅"
    "\\overline{K}" "K̅" "\\overline{L}" "L̅" "\\overline{M}" "M̅" "\\overline{N}" "N̅"
    "\\overline{O}" "O̅" "\\overline{P}" "P̅" "\\overline{Q}" "Q̅" "\\overline{R}" "R̅"
    "\\overline{S}" "S̅" "\\overline{T}" "T̅" "\\overline{U}" "U̅" "\\overline{V}" "V̅"
    "\\overline{W}" "W̅" "\\overline{X}" "X̅" "\\overline{Y}" "Y̅" "\\overline{Z}" "Z̅"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\overline{\\\\[%a]+}")
  (#set! priority 101)
  (#set-pairs! @conceal
    conceal
    ; Lowercase Greek letters (using combining macron U+0304)
    "\\overline{\\alpha}" "α̅" "\\overline{\\beta}" "β̅" "\\overline{\\gamma}" "γ̅"
    "\\overline{\\delta}" "δ̅" "\\overline{\\epsilon}" "ε̅" "\\overline{\\zeta}" "ζ̅"
    "\\overline{\\eta}" "η̅" "\\overline{\\theta}" "θ̅" "\\overline{\\iota}" "ι̅"
    "\\overline{\\kappa}" "κ̅" "\\overline{\\lambda}" "λ̅" "\\overline{\\mu}" "μ̅"
    "\\overline{\\nu}" "ν̅" "\\overline{\\xi}" "ξ̅" "\\overline{\\omicron}" "ο̅"
    "\\overline{\\pi}" "π̅" "\\overline{\\rho}" "ρ̅" "\\overline{\\sigma}" "σ̅"
    "\\overline{\\tau}" "τ̅" "\\overline{\\upsilon}" "υ̅" "\\overline{\\phi}" "ϕ̅"
    "\\overline{\\chi}" "χ̅" "\\overline{\\psi}" "ψ̅" "\\overline{\\omega}" "ω̅"
    ; Uppercase Greek letters
    "\\overline{\\Alpha}" "Α̅" "\\overline{\\Beta}" "Β̅" "\\overline{\\Gamma}" "Γ̅"
    "\\overline{\\Delta}" "Δ̅" "\\overline{\\Epsilon}" "Ε̅" "\\overline{\\Zeta}" "Ζ̅"
    "\\overline{\\Eta}" "Η̅" "\\overline{\\Theta}" "Θ̅" "\\overline{\\Iota}" "Ι̅"
    "\\overline{\\Kappa}" "Κ̅" "\\overline{\\Lambda}" "Λ̅" "\\overline{\\Mu}" "Μ̅"
    "\\overline{\\Nu}" "Ν̅" "\\overline{\\Xi}" "Ξ̅" "\\overline{\\Omicron}" "Ο̅"
    "\\overline{\\Pi}" "Π̅" "\\overline{\\Rho}" "Ρ̅" "\\overline{\\Sigma}" "Σ̅"
    "\\overline{\\Tau}" "Τ̅" "\\overline{\\Upsilon}" "Υ̅" "\\overline{\\Phi}" "Φ̅"
    "\\overline{\\Chi}" "Χ̅" "\\overline{\\Psi}" "Ψ̅" "\\overline{\\Omega}" "Ω̅"
    ; Variants and alternate forms
    "\\overline{\\varepsilon}" "ϵ̅" "\\overline{\\vartheta}" "ϑ̅" "\\overline{\\varpi}" "ϖ̅"
    "\\overline{\\varrho}" "ϱ̅" "\\overline{\\varsigma}" "ς̅" "\\overline{\\varphi}" "φ̅"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\dot{[%a]}")
  (#set-pairs! @conceal
    conceal "\\dot{A}" "Ȧ" "\\dot{a}" "ȧ" "\\dot{B}" "Ḃ" "\\dot{b}" "ḃ" "\\dot{C}" "Ċ"
    "\\dot{c}" "ċ" "\\dot{D}" "Ḋ" "\\dot{d}" "ḋ" "\\dot{E}" "Ė" "\\dot{e}" "ė" "\\dot{F}"
    "Ḟ" "\\dot{f}" "ḟ" "\\dot{G}" "Ġ" "\\dot{g}" "ġ" "\\dot{H}" "Ḣ" "\\dot{h}" "ḣ"
    "\\dot{I}" "İ" "\\dot{M}" "Ṁ" "\\dot{m}" "ṁ" "\\dot{N}" "Ṅ" "\\dot{n}" "ṅ" "\\dot{O}"
    "Ȯ" "\\dot{o}" "ȯ" "\\dot{P}" "Ṗ" "\\dot{p}" "ṗ" "\\dot{R}" "Ṙ" "\\dot{r}" "ṙ"
    "\\dot{S}" "Ṡ" "\\dot{s}" "ṡ" "\\dot{T}" "Ṫ" "\\dot{t}" "ṫ" "\\dot{W}" "Ẇ" "\\dot{w}"
    "ẇ" "\\dot{X}" "Ẋ" "\\dot{x}" "ẋ" "\\dot{Y}" "Ẏ" "\\dot{y}" "ẏ" "\\dot{Z}" "Ż"
    "\\dot{z}" "ż"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\hat{[%a]}")
  (#set-pairs! @conceal
    conceal "\\hat{a}" "â" "\\hat{b}" "b̂" "\\hat{c}" "ĉ" "\\hat{d}" "d̂" "\\hat{e}" "ê"
    "\\hat{f}" "f̂" "\\hat{g}" "ĝ" "\\hat{h}" "ĥ" "\\hat{i}" "î" "\\hat{j}" "ĵ" "\\hat{k}"
    "k̂" "\\hat{l}" "l̂" "\\hat{m}" "m̂" "\\hat{n}" "n̂" "\\hat{o}" "ô" "\\hat{p}" "p̂"
    "\\hat{q}" "q̂" "\\hat{r}" "r̂" "\\hat{s}" "ŝ" "\\hat{t}" "t̂" "\\hat{u}" "û" "\\hat{v}"
    "v̂" "\\hat{w}" "ŵ" "\\hat{x}" "x̂" "\\hat{y}" "ŷ" "\\hat{z}" "ẑ" "\\hat{A}" "Â"
    "\\hat{B}" "B̂" "\\hat{C}" "Ĉ" "\\hat{D}" "D̂" "\\hat{E}" "Ê" "\\hat{F}" "F̂" "\\hat{G}"
    "Ĝ" "\\hat{H}" "Ĥ" "\\hat{I}" "Î" "\\hat{J}" "Ĵ" "\\hat{K}" "K̂" "\\hat{L}" "L̂"
    "\\hat{M}" "M̂" "\\hat{N}" "N̂" "\\hat{O}" "Ô" "\\hat{P}" "P̂" "\\hat{Q}" "Q̂" "\\hat{R}"
    "R̂" "\\hat{S}" "Ŝ" "\\hat{T}" "T̂" "\\hat{U}" "Û" "\\hat{V}" "V̂" "\\hat{W}" "Ŵ"
    "\\hat{X}" "X̂" "\\hat{Y}" "Ŷ" "\\hat{Z}" "Ẑ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\widehat{[%a]}")
  (#set-pairs! @conceal
    conceal "\\widehat{a}" "â" "\\widehat{b}" "b̂" "\\widehat{c}" "ĉ" "\\widehat{d}" "d̂"
    "\\widehat{e}" "ê" "\\widehat{f}" "f̂" "\\widehat{g}" "ĝ" "\\widehat{h}" "ĥ"
    "\\widehat{i}" "î" "\\widehat{j}" "ĵ" "\\widehat{k}" "k̂" "\\widehat{l}" "l̂"
    "\\widehat{m}" "m̂" "\\widehat{n}" "n̂" "\\widehat{o}" "ô" "\\widehat{p}" "p̂"
    "\\widehat{q}" "q̂" "\\widehat{r}" "r̂" "\\widehat{s}" "ŝ" "\\widehat{t}" "t̂"
    "\\widehat{u}" "û" "\\widehat{v}" "v̂" "\\widehat{w}" "ŵ" "\\widehat{x}" "x̂"
    "\\widehat{y}" "ŷ" "\\widehat{z}" "ẑ" "\\widehat{A}" "Â" "\\widehat{B}" "B̂"
    "\\widehat{C}" "Ĉ" "\\widehat{D}" "D̂" "\\widehat{E}" "Ê" "\\widehat{F}" "F̂"
    "\\widehat{G}" "Ĝ" "\\widehat{H}" "Ĥ" "\\widehat{I}" "Î" "\\widehat{J}" "Ĵ"
    "\\widehat{K}" "K̂" "\\widehat{L}" "L̂" "\\widehat{M}" "M̂" "\\widehat{N}" "N̂"
    "\\widehat{O}" "Ô" "\\widehat{P}" "P̂" "\\widehat{Q}" "Q̂" "\\widehat{R}" "R̂"
    "\\widehat{S}" "Ŝ" "\\widehat{T}" "T̂" "\\widehat{U}" "Û" "\\widehat{V}" "V̂"
    "\\widehat{W}" "Ŵ" "\\widehat{X}" "X̂" "\\widehat{Y}" "Ŷ" "\\widehat{Z}" "Ẑ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\tilde{[aeinouyAEINOUY]}")
  (#set-pairs! @conceal
    conceal "\\tilde{a}" "ã" "\\tilde{e}" "ẽ" "\\tilde{i}" "ĩ" "\\tilde{n}" "ñ" "\\tilde{o}"
    "õ" "\\tilde{u}" "ũ" "\\tilde{y}" "ỹ" "\\tilde{A}" "Ã" "\\tilde{E}" "Ẽ" "\\tilde{I}" "Ĩ"
    "\\tilde{N}" "Ñ" "\\tilde{O}" "Õ" "\\tilde{U}" "Ũ" "\\tilde{Y}" "Ỹ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\widetilde{[%a]}")
  (#set-pairs! @conceal
    conceal "\\widetilde{a}" "ã" "\\widetilde{b}" "b̃" "\\widetilde{c}" "c̃" "\\widetilde{d}"
    "d̃" "\\widetilde{e}" "ẽ" "\\widetilde{f}" "f̃" "\\widetilde{g}" "g̃" "\\widetilde{h}"
    "h̃" "\\widetilde{i}" "ĩ" "\\widetilde{j}" "j̃" "\\widetilde{k}" "k̃" "\\widetilde{l}"
    "l̃" "\\widetilde{m}" "m̃" "\\widetilde{n}" "ñ" "\\widetilde{o}" "õ" "\\widetilde{p}"
    "p̃" "\\widetilde{q}" "q̃" "\\widetilde{r}" "r̃" "\\widetilde{s}" "s̃" "\\widetilde{t}"
    "t̃" "\\widetilde{u}" "ũ" "\\widetilde{v}" "ṽ" "\\widetilde{w}" "w̃" "\\widetilde{x}"
    "x̃" "\\widetilde{y}" "ỹ" "\\widetilde{z}" "z̃" "\\widetilde{A}" "Ã" "\\widetilde{B}"
    "B̃" "\\widetilde{C}" "C̃" "\\widetilde{D}" "D̃" "\\widetilde{E}" "Ẽ" "\\widetilde{F}"
    "F̃" "\\widetilde{G}" "G̃" "\\widetilde{H}" "H̃" "\\widetilde{I}" "Ĩ" "\\widetilde{J}"
    "J̃" "\\widetilde{K}" "K̃" "\\widetilde{L}" "L̃" "\\widetilde{M}" "M̃" "\\widetilde{N}"
    "Ñ" "\\widetilde{O}" "Õ" "\\widetilde{P}" "P̃" "\\widetilde{Q}" "Q̃" "\\widetilde{R}"
    "R̃" "\\widetilde{S}" "S̃" "\\widetilde{T}" "T̃" "\\widetilde{U}" "Ũ" "\\widetilde{V}"
    "Ṽ" "\\widetilde{W}" "W̃" "\\widetilde{X}" "X̃" "\\widetilde{Y}" "Ỹ" "\\widetilde{Z}"
    "Z̃"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\mathbb{%u}")
  (#set-pairs! @conceal
    conceal "\\mathbb{A}" "𝔸" "\\mathbb{B}" "𝔹" "\\mathbb{C}" "ℂ" "\\mathbb{D}" "𝔻"
    "\\mathbb{E}" "𝔼" "\\mathbb{F}" "𝔽" "\\mathbb{G}" "𝔾" "\\mathbb{H}" "ℍ" "\\mathbb{I}"
    "𝕀" "\\mathbb{J}" "𝕁" "\\mathbb{K}" "𝕂" "\\mathbb{L}" "𝕃" "\\mathbb{M}" "𝕄"
    "\\mathbb{N}" "ℕ" "\\mathbb{O}" "𝕆" "\\mathbb{P}" "ℙ" "\\mathbb{Q}" "ℚ" "\\mathbb{R}"
    "ℝ" "\\mathbb{S}" "𝕊" "\\mathbb{T}" "𝕋" "\\mathbb{U}" "𝕌" "\\mathbb{V}" "𝕍"
    "\\mathbb{W}" "𝕎" "\\mathbb{X}" "𝕏" "\\mathbb{Y}" "𝕐" "\\mathbb{Z}" "ℤ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\mathcal{%u}")
  (#set-pairs! @conceal
    conceal "\\mathcal{A}" "𝓐" "\\mathcal{B}" "𝓑" "\\mathcal{C}" "𝓒" "\\mathcal{D}" "𝓓"
    "\\mathcal{E}" "𝓔" "\\mathcal{F}" "𝓕" "\\mathcal{G}" "𝓖" "\\mathcal{H}" "𝓗"
    "\\mathcal{I}" "𝓘" "\\mathcal{J}" "𝓙" "\\mathcal{K}" "𝓚" "\\mathcal{L}" "𝓛"
    "\\mathcal{M}" "𝓜" "\\mathcal{N}" "𝓝" "\\mathcal{O}" "𝓞" "\\mathcal{P}" "𝓟"
    "\\mathcal{Q}" "𝓠" "\\mathcal{R}" "𝓡" "\\mathcal{S}" "𝓢" "\\mathcal{T}" "𝓣"
    "\\mathcal{U}" "𝓤" "\\mathcal{V}" "𝓥" "\\mathcal{W}" "𝓦" "\\mathcal{X}" "𝓧"
    "\\mathcal{Y}" "𝓨" "\\mathcal{Z}" "𝓩"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\mathfrak{[%a]}")
  (#set-pairs! @conceal
    conceal "\\mathfrak{a}" "𝔞" "\\mathfrak{b}" "𝔟" "\\mathfrak{c}" "𝔠" "\\mathfrak{d}"
    "𝔡" "\\mathfrak{e}" "𝔢" "\\mathfrak{f}" "𝔣" "\\mathfrak{g}" "𝔤" "\\mathfrak{h}"
    "𝔥" "\\mathfrak{i}" "𝔦" "\\mathfrak{j}" "𝔧" "\\mathfrak{k}" "𝔨" "\\mathfrak{l}"
    "𝔩" "\\mathfrak{m}" "𝔪" "\\mathfrak{n}" "𝔫" "\\mathfrak{o}" "𝔬" "\\mathfrak{p}"
    "𝔭" "\\mathfrak{q}" "𝔮" "\\mathfrak{r}" "𝔯" "\\mathfrak{s}" "𝔰" "\\mathfrak{t}"
    "𝔱" "\\mathfrak{u}" "𝔲" "\\mathfrak{v}" "𝔳" "\\mathfrak{w}" "𝔴" "\\mathfrak{x}"
    "𝔵" "\\mathfrak{y}" "𝔶" "\\mathfrak{z}" "𝔷" "\\mathfrak{A}" "𝔄" "\\mathfrak{B}"
    "𝔅" "\\mathfrak{C}" "ℭ" "\\mathfrak{D}" "𝔇" "\\mathfrak{E}" "𝔈" "\\mathfrak{F}"
    "𝔉" "\\mathfrak{G}" "𝔊" "\\mathfrak{H}" "ℌ" "\\mathfrak{I}" "ℑ" "\\mathfrak{J}" "𝔍"
    "\\mathfrak{K}" "𝔎" "\\mathfrak{L}" "𝔏" "\\mathfrak{M}" "𝔐" "\\mathfrak{N}" "𝔑"
    "\\mathfrak{O}" "𝔒" "\\mathfrak{P}" "𝔓" "\\mathfrak{Q}" "𝔔" "\\mathfrak{R}" "ℜ"
    "\\mathfrak{S}" "𝔖" "\\mathfrak{T}" "𝔗" "\\mathfrak{U}" "𝔘" "\\mathfrak{V}" "𝔙"
    "\\mathfrak{W}" "𝔚" "\\mathfrak{X}" "𝔛" "\\mathfrak{Y}" "𝔜" "\\mathfrak{Z}" "ℨ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\mathscr{[%a]}")
  (#set-pairs! @conceal
    conceal "\\mathscr{A}" "𝓐" "\\mathscr{B}" "𝓑" "\\mathscr{C}" "𝓒" "\\mathscr{D}" "𝓓"
    "\\mathscr{E}" "𝓔" "\\mathscr{F}" "𝓕" "\\mathscr{G}" "𝓖" "\\mathscr{H}" "𝓗"
    "\\mathscr{I}" "𝓘" "\\mathscr{J}" "𝓙" "\\mathscr{K}" "𝓚" "\\mathscr{L}" "𝓛"
    "\\mathscr{M}" "𝓜" "\\mathscr{N}" "𝓝" "\\mathscr{O}" "𝓞" "\\mathscr{P}" "𝓟"
    "\\mathscr{Q}" "𝓠" "\\mathscr{R}" "𝓡" "\\mathscr{S}" "𝓢" "\\mathscr{T}" "𝓣"
    "\\mathscr{U}" "𝓤" "\\mathscr{V}" "𝓥" "\\mathscr{W}" "𝓦" "\\mathscr{X}" "𝓧"
    "\\mathscr{Y}" "𝓨" "\\mathscr{Z}" "𝓩"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\mathsf{[%a]}")
  (#set-pairs! @conceal
    conceal "\\mathsf{a}" "𝖺" "\\mathsf{b}" "𝖻" "\\mathsf{c}" "𝖼" "\\mathsf{d}" "𝖽"
    "\\mathsf{e}" "𝖾" "\\mathsf{f}" "𝖿" "\\mathsf{g}" "𝗀" "\\mathsf{h}" "𝗁"
    "\\mathsf{i}" "𝗂" "\\mathsf{j}" "𝗃" "\\mathsf{k}" "𝗄" "\\mathsf{l}" "𝗅"
    "\\mathsf{m}" "𝗆" "\\mathsf{n}" "𝗇" "\\mathsf{o}" "𝗈" "\\mathsf{p}" "𝗉"
    "\\mathsf{q}" "𝗊" "\\mathsf{r}" "𝗋" "\\mathsf{s}" "𝗌" "\\mathsf{t}" "𝗍"
    "\\mathsf{u}" "𝗎" "\\mathsf{v}" "𝗏" "\\mathsf{w}" "𝗐" "\\mathsf{x}" "𝗑"
    "\\mathsf{y}" "𝗒" "\\mathsf{z}" "𝗓" "\\mathsf{A}" "𝖠" "\\mathsf{B}" "𝖡"
    "\\mathsf{C}" "𝖢" "\\mathsf{D}" "𝖣" "\\mathsf{E}" "𝖤" "\\mathsf{F}" "𝖥"
    "\\mathsf{G}" "𝖦" "\\mathsf{H}" "𝖧" "\\mathsf{I}" "𝖨" "\\mathsf{J}" "𝖩"
    "\\mathsf{K}" "𝖪" "\\mathsf{L}" "𝖫" "\\mathsf{M}" "𝖬" "\\mathsf{N}" "𝖭"
    "\\mathsf{O}" "𝖮" "\\mathsf{P}" "𝖯" "\\mathsf{Q}" "𝖰" "\\mathsf{R}" "𝖱"
    "\\mathsf{S}" "𝖲" "\\mathsf{T}" "𝖳" "\\mathsf{U}" "𝖴" "\\mathsf{V}" "𝖵"
    "\\mathsf{W}" "𝖶" "\\mathsf{X}" "𝖷" "\\mathsf{Y}" "𝖸" "\\mathsf{Z}" "𝖹"))

; greek conceal
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal
      "\\alpha" "\\beta" "\\gamma" "\\delta" "\\epsilon" "\\varepsilon" "\\zeta" "\\eta" "\\theta"
      "\\vartheta" "\\iota" "\\kappa" "\\lambda" "\\mu" "\\nu" "\\xi" "\\pi" "\\varpi" "\\rho"
      "\\varrho" "\\sigma" "\\varsigma" "\\tau" "\\upsilon" "\\phi" "\\varphi" "\\chi" "\\psi"
      "\\omega" "\\Gamma" "\\Delta" "\\Theta" "\\Lambda" "\\Xi" "\\Pi" "\\Sigma" "\\Upsilon" "\\Phi"
      "\\Chi" "\\Psi" "\\Omega"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\alpha" "α" "\\beta" "β" "\\gamma" "γ" "\\delta" "δ" "\\epsilon" "ϵ"
    "\\varepsilon" "ε" "\\zeta" "ζ" "\\eta" "η" "\\theta" "θ" "\\vartheta" "ϑ" "\\iota" "ι"
    "\\kappa" "κ" "\\lambda" "λ" "\\mu" "μ" "\\nu" "ν" "\\xi" "ξ" "\\pi" "π" "\\varpi" "ϖ"
    "\\rho" "ρ" "\\varrho" "ϱ" "\\sigma" "σ" "\\varsigma" "ς" "\\tau" "τ" "\\upsilon" "υ"
    "\\phi" "ϕ" "\\varphi" "φ" "\\chi" "χ" "\\psi" "ψ" "\\omega" "ω" "\\Gamma" "Γ" "\\Delta"
    "Δ" "\\Theta" "Θ" "\\Lambda" "Λ" "\\Xi" "Ξ" "\\Pi" "Π" "\\Sigma" "Σ" "\\Upsilon" "Υ"
    "\\Phi" "Φ" "\\Chi" "Χ" "\\Psi" "Ψ" "\\Omega" "Ω"))

; math conceals
(generic_command
  command: ((command_name) @conceal
    (#any-of? @conceal "\\\\" "\\{" "\\}" "\\|" "\\langle" "\\rangle" "\\varnothing"))
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#set-pairs! @conceal
    conceal "\\\\" "⏎" "\\{" "{" "\\}" "}" "\\|" "‖" "\\langle" "⟨" "\\rangle" "⟩"
    "\\varnothing" "∅"))

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
  (#lua-match? @conceal "[0-9aeh-pr-vxA-Z]")
  (#set-pairs! @conceal
    conceal "0" "₀" "1" "₁" "2" "₂" "3" "₃" "4" "₄" "5" "₅" "6" "₆" "7" "₇" "8"
    "₈" "9" "₉" "a" "ₐ" "e" "ₑ" "h" "ₕ" "i" "ᵢ" "j" "ⱼ" "k" "ₖ" "l" "ₗ" "m" "ₘ"
    "n" "ₙ" "o" "ₒ" "p" "ₚ" "r" "ᵣ" "s" "ₛ" "t" "ₜ" "u" "ᵤ" "v" "ᵥ" "x" "ₓ" "A"
    "ᴀ" "B" "ʙ" "C" "ᴄ" "D" "ᴅ" "E" "ᴇ" "F" "ғ" "G" "ɢ" "H" "ʜ" "I" "ɪ" "J" "ᴊ" "K"
    "ᴋ" "L" "ʟ" "M" "ᴍ" "N" "ɴ" "O" "ᴏ" "P" "ᴘ" "Q" "ǫ" "R" "ʀ" "S" "s" "T" "ᴛ" "U"
    "ᴜ" "V" "ᴠ" "W" "ᴡ" "X" "x" "Y" "ʏ" "Z" "ᴢ"))

(text
  word: (subscript) @conceal
  (#has-ancestor? @conceal math_environment inline_formula displayed_equation)
  (#not-has-ancestor? @conceal label_definition text_mode)
  (#any-of? @conceal "_+" "_-" "_/" "_=" "_(" "_)")
  (#set-pairs! @conceal conceal "_+" "₊" "_-" "₋" "_/" "ˏ" "=" "₌" "(" "₍" ")" "₎"))

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
  (#lua-match? @conceal "[0-9a-zA-W]")
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

(generic_command
  command: ((command_name) @cmd
    (#eq? @cmd "\\frac"))
  (#has-ancestor? @cmd math_environment inline_formula displayed_equation)
  (#set! priority 101)
  (#set! conceal "("))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\frac")
  arg: (curly_group
    "{" @open1)
  (#has-ancestor? @open1 math_environment inline_formula displayed_equation)
  (#set! conceal ""))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\frac")
  arg: (curly_group
    "}" @close1)
  arg: (curly_group)
  (#has-ancestor? @close1 math_environment inline_formula displayed_equation)
  (#set! conceal "⧸"))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\frac")
  arg: (curly_group)
  arg: (curly_group
    "{" @open2)
  (#has-ancestor? @open2 math_environment inline_formula displayed_equation)
  (#set! conceal " "))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\frac")
  arg: (curly_group)
  arg: (curly_group
    "}" @close2)
  (#has-ancestor? @close2 math_environment inline_formula displayed_equation)
  (#set! conceal ")"))

; Conceal \dfrac command and brackets to show as numerator/denominator
(generic_command
  command: ((command_name) @cmd
    (#eq? @cmd "\\dfrac"))
  (#has-ancestor? @cmd math_environment inline_formula displayed_equation)
  (#set! priority 101)
  (#set! conceal "("))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\dfrac")
  arg: (curly_group
    "{" @open1)
  (#has-ancestor? @open1 math_environment inline_formula displayed_equation)
  (#set! conceal ""))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\dfrac")
  arg: (curly_group
    "}" @close1)
  arg: (curly_group)
  (#has-ancestor? @close1 math_environment inline_formula displayed_equation)
  (#set! conceal "⧸"))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\dfrac")
  arg: (curly_group)
  arg: (curly_group
    "{" @open2)
  (#has-ancestor? @open2 math_environment inline_formula displayed_equation)
  (#set! conceal " "))

(generic_command
  command: (command_name) @_cmd
  (#eq? @_cmd "\\dfrac")
  arg: (curly_group)
  arg: (curly_group
    "}" @close2)
  (#has-ancestor? @close2 math_environment inline_formula displayed_equation)
  (#set! conceal ")"))
