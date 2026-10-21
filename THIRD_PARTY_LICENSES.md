# Third-party notices

## math-conceal.nvim

Supplementary LaTeX symbol data in `lua/latex-conceal/symbols.lua` is adapted
from [pxwg/math-conceal.nvim](https://github.com/pxwg/math-conceal.nvim),
revision `0c8dc9a63fe8f786333402e12c0b4ed3ae2ae5e1`.
Additional symbol, font, and accent coverage was checked against revision
`c456e87c608fa019f8a6e58c35e88161f450ba85`.
The adapted tables omit existing replacements and unsuitable mappings, and add
selected aliases. Unsupported Unicode styles and substitutions that change
operator meaning are omitted. Text double brackets use the LaTeX kernel's
Unicode characters U+27E6 and U+27E7.

```text
MIT License

Copyright (c) 2025 Xinyu Xiang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## unicode-math

The LaTeX math symbol conceal table includes entries derived from or checked
against the `unicode-math` symbol data, including `unicode-math-table.tex` and
`unimath-symbols.pdf`.

- Source: [unicode-math](https://github.com/latex3/unicode-math)
- License: LaTeX Project Public License, version 1.3c or later
  (LPPL-1.3c-or-later)
- Upstream copyright notices:
  - Copyright 2006-2019 Will Robertson, LPPL “maintainer”
  - Copyright 2010-2017 Philipp Stephani
  - Copyright 2011-2017 Joseph Wright
  - Copyright 2012-2015 Khaled Hosny

The upstream package states:

```text
This package is free software and may be redistributed and/or modified under
the conditions of the LaTeX Project Public License, version 1.3c or higher
(your choice): <http://www.latex-project.org/lppl/>.
```
