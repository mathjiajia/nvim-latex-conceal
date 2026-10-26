# nvim-latex-conceal

Tree-sitter conceals for LaTeX, including LaTeX injected into Markdown.

## Requirements

- Neovim 0.13 or later.
- A `latex` parser and highlighting queries, provided by
  [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).
- For Markdown, also install `markdown` and `markdown_inline`.
- Tree-sitter highlighting enabled for the buffer; the plugin keeps the native
  syntax highlighter for colors and styles.

## Installation

```lua
-- lazy.nvim
{
  "mathjiajia/nvim-latex-conceal",
  lazy = false,
  dependencies = {
    { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate" },
  },
}
```

Install the parsers with `:TSInstall latex markdown markdown_inline`.
Run `:TSUpdate` after updating nvim-treesitter to keep parsers and queries compatible.

If your configuration does not already enable Tree-sitter highlighting, add:

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("latex_conceal_highlighting", { clear = true }),
  pattern = { "tex", "plaintex", "markdown" },
  callback = function()
    vim.treesitter.start()
  end,
})
```

The plugin sets `conceallevel=2` for `tex` and `plaintex` windows.
For Markdown, set `vim.wo.conceallevel = 2` in your Markdown ftplugin or configuration.
The `concealcursor` option controls whether text is concealed on the cursor line.

There is no `setup()` call.
To show the source in the current window, use `:setlocal conceallevel=0`;
restore conceals with `:setlocal conceallevel=2`.

## Features

- Delimiters such as `\left`, math delimiters, and selected curly braces.
- Fonts such as `\mathbb{Z}` → `ℤ`, `\mathbf{A}` → `𝐀`, and `\mathtt{x}` → `𝚡`.
- Greek letters, upright variants, and Unicode mathematical alphabets.
- Mathematical symbols, arrows, relations, integrals, and named delimiters.
- Dashed-arrow aliases, geometric symbols, literal escaped characters, and `\qedhere`.
- Upright alphabets and the available double-struck italic letters, such as `\symbbit{d}` → `ⅆ`.
- Supported superscripts and subscripts.
- Braced accents such as `\'{e}` → `é`, `\vec{x}` → `x⃗`, and `\hat{\alpha}` → `α̂`.
- Single-symbol arrow accents such as `\overleftarrow{x}` → `x⃖` and `\overrightarrow{x}` → `x⃗`.
- Fractions using `\frac`, `\dfrac`, `\tfrac`, and `\cfrac`.
- Physics notation: `\bra{ψ}` → `⟨ψ|`, `\ket{ψ}` → `|ψ⟩`, `\abs{x}` → `|x|`, and `\norm{x}` → `‖x‖`.
- Text symbol commands such as `\textalpha` and `\textdegree`.

Conceals change only the display, never the buffer contents.
The plugin evaluates its separate `conceals` query for visible LaTeX, caches the
completed results per window, and replays them as conceal extmarks on unchanged
redraws. Edits invalidate those results so the next redraw uses the current
syntax tree; when the parser rebuilds an injected tree without an edit, only the
rows that tree covers are evaluated again. Parsed trees are indexed once per
parser version, and change history is bounded; windows with older cached results
rebuild when needed. While native parsing runs asynchronously, unchanged rows
keep their cached conceals; changed rows refresh when parsing completes.
Glyph appearance depends on your terminal and font.

The supplementary symbol table and font coverage were compared with
[math-conceal.nvim](https://github.com/pxwg/math-conceal.nvim).
Font and accent replacements apply to a single supported letter, digit, or
Greek command in braces.
Longer or unsupported arguments are not collapsed into a single character.
The command `\div` remains visible for principal-divisor notation such as `\div(f)`.
Operators such as `\exp`, `\Pr`, `\log`, and `\not`, controls such as `\quad`,
`\qquad`, and `\nolimits`, and standalone combining enclosures retain their
source. Unavailable Unicode styles are not replaced by a different alphabet.
Typst and graphical equation rendering are outside this plugin's scope.
See [third-party notices](THIRD_PARTY_LICENSES.md) for the symbol data attribution.

## Development

Conceal patterns live in `queries/latex/conceals.scm`. Custom patterns can extend
the `conceals` query independently of ordinary highlighting queries.
Exact font and accent mappings live in `lua/latex-conceal/exact.lua`, script
replacements in `lua/latex-conceal/scripts.lua`, and symbol commands in
`lua/latex-conceal/symbols.lua`.

Every candidate match of a pattern costs a round trip into Lua, so the shipped
patterns are shaped to reject nodes inside the C query cursor first: braced
words are matched through their enclosing `curly_group`, unbraced scripts
through the grammar's `letter` and `command_name` arguments, and one pattern
covers all whole-command replacements. The plugin registers these directives
and predicates for custom patterns:

- `(#latex-symbol! @capture)` replaces a symbol command in math or text context.
- `(#latex-argument! @capture)` replaces a whole command with a braced argument.
- `(#latex-script! @capture)` replaces a script node, or a single word, operator
  or token inside a braced script.
- `(#latex-script-supported? @capture)` filters script captures while preserving
  their existing highlight behavior, including letters without replacements.
- `(#latex-script-marker? @script)` checks whether a braced script value is a
  single supported character; `(#set! @marker conceal "")` then hides `_` or `^`.
- `(#latex-conceal! @capture kind)` looks up `math`, `text`, `font`, `exact`,
  `bar`, or `overline` replacements.
- `(#latex-delimiters! @command @close)` and `(#set-pairs! @capture key ...)`.
- `(#has-grandparent? @capture type ...)` and `(#latex-script? @capture kind)`.

With the parsers and queries on Neovim's runtime path, run:

```sh
nvim --headless -u NONE -i NONE -l tests/conceal.lua
nvim --headless -u NONE -i NONE -l tests/render.lua
```

To test a separate nvim-treesitter `main` checkout, set `NVIM_TREESITTER` to its path;
the tests use its `runtime/` directory.

### Benchmarks

Run the TeX editor benchmark with Python 3 on macOS or Linux:

```sh
python3 tests/benchmark.py
python3 tests/benchmark.py --baseline ../nvim-latex-conceal-before --output /tmp/latex-conceal-benchmark.json
```

The runner starts fresh Neovim processes in a 120×40 terminal and measures first
render, cached full redraw, cursor movement, one-line scrolling, distant jumps,
text edits, and formula edits. Each operation includes native Tree-sitter parsing
and highlighting through the completed redraw. These are editor timings, not
isolated plugin callback costs.

Defaults are 10,000 TeX lines, four runs, and 40 samples per operation after ten
warmups. Results are the median of the run medians, in milliseconds. Use `--lines`,
`--runs`, `--steps`, and `--warmup` to change those settings, or `--nvim` to select
the Neovim executable. `NVIM_TREESITTER` also applies to the benchmark.

`--baseline` compares another plugin checkout using the same fixture and runtime,
alternating which version runs first. `--output` saves the measurements and
runtime details as JSON; temporary logs and intermediate results are cleaned up.
Run comparisons while other workloads are idle. Timings are reported without
fixed pass/fail thresholds because they depend on the machine and runtime.

## Acknowledgement

[latex.nvim](https://github.com/robbielyman/latex.nvim)

[math-conceal.nvim](https://github.com/pxwg/math-conceal.nvim)
