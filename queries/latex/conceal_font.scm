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
  (#lua-match? @conceal "\\bar{[aegiouAEGIOU]}")
  (#set-pairs! @conceal
    conceal "\\bar{a}" "ā" "\\bar{e}" "ē" "\\bar{g}" "ḡ" "\\bar{i}" "ī" "\\bar{o}" "ō"
    "\\bar{u}" "ū" "\\bar{A}" "Ā" "\\bar{E}" "Ē" "\\bar{G}" "Ḡ" "\\bar{I}" "Ī" "\\bar{O}" "Ō"
    "\\bar{U}" "Ū"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\overline{[aegiouAEGIOU]}")
  (#set-pairs! @conceal
    conceal "\\overline{a}" "ā" "\\overline{e}" "ē" "\\overline{g}" "ḡ" "\\overline{i}" "ī"
    "\\overline{o}" "ō" "\\overline{u}" "ū" "\\overline{A}" "Ā" "\\overline{E}" "Ē"
    "\\overline{G}" "Ḡ" "\\overline{I}" "Ī" "\\overline{O}" "Ō" "\\overline{U}" "Ū"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\dot{[a-zA-Z]}")
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
  (#lua-match? @conceal "\\hat{[acegiosuwyACEGIOSUWY]}")
  (#set-pairs! @conceal
    conceal "\\hat{a}" "â" "\\hat{A}" "Â" "\\hat{c}" "ĉ" "\\hat{C}" "Ĉ" "\\hat{e}" "ê"
    "\\hat{E}" "Ê" "\\hat{g}" "ĝ" "\\hat{G}" "Ĝ" "\\hat{i}" "î" "\\hat{I}" "Î" "\\hat{o}" "ô"
    "\\hat{O}" "Ô" "\\hat{s}" "ŝ" "\\hat{S}" "Ŝ" "\\hat{u}" "û" "\\hat{U}" "Û" "\\hat{w}" "ŵ"
    "\\hat{W}" "Ŵ" "\\hat{y}" "ŷ" "\\hat{Y}" "Ŷ"))

((generic_command
  command: (command_name)
  arg: (curly_group)) @conceal
  (#lua-match? @conceal "\\widehat{[acegiosuwyACEGIOSUWY]}")
  (#set-pairs! @conceal
    conceal "\\widehat{a}" "â" "\\widehat{A}" "Â" "\\widehat{c}" "ĉ" "\\widehat{C}" "Ĉ"
    "\\widehat{e}" "ê" "\\widehat{E}" "Ê" "\\widehat{g}" "ĝ" "\\widehat{G}" "Ĝ" "\\widehat{i}"
    "î" "\\widehat{I}" "Î" "\\widehat{o}" "ô" "\\widehat{O}" "Ô" "\\widehat{s}" "ŝ"
    "\\widehat{S}" "Ŝ" "\\widehat{u}" "û" "\\widehat{U}" "Û" "\\widehat{w}" "ŵ" "\\widehat{W}"
    "Ŵ" "\\widehat{y}" "ŷ" "\\widehat{Y}" "Ŷ"))

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
  (#lua-match? @conceal "\\widetilde{[aeinouyAEINOUY]}")
  (#set-pairs! @conceal
    conceal "\\widetilde{a}" "ã" "\\widetilde{e}" "ẽ" "\\widetilde{i}" "ĩ" "\\widetilde{n}" "ñ"
    "\\widetilde{o}" "õ" "\\widetilde{u}" "ũ" "\\widetilde{y}" "ỹ" "\\widetilde{A}" "Ã"
    "\\widetilde{E}" "Ẽ" "\\widetilde{I}" "Ĩ" "\\widetilde{N}" "Ñ" "\\widetilde{O}" "Õ"
    "\\widetilde{U}" "Ũ" "\\widetilde{Y}" "Ỹ"))

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
  (#lua-match? @conceal "\\mathfrak{[a-Z]}")
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
  (#lua-match? @conceal "\\mathscr{[a-Z]}")
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
  (#lua-match? @conceal "\\mathsf{[a-Z]}")
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
