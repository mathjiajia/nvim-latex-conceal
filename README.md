# nvim-latex-conceal

Tree-sitter conceals for LaTeX, including LaTeX injected into Markdown.

## Requirements

- Neovim 0.12 or later.
- A `latex` parser and highlighting queries, provided by
  [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).
- For Markdown, also install `markdown` and `markdown_inline`.
- Tree-sitter highlighting enabled for the buffer.

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
- Supported superscripts and subscripts.
- Braced accents such as `\'{e}` → `é`, `\vec{x}` → `x⃗`, and `\hat{\alpha}` → `α̂`.
- Fractions using `\frac`, `\dfrac`, `\tfrac`, and `\cfrac`.
- Physics notation: `\bra{ψ}` → `⟨ψ|`, `\ket{ψ}` → `|ψ⟩`, `\abs{x}` → `|x|`, and `\norm{x}` → `‖x‖`.
- Text symbol commands such as `\textalpha` and `\textdegree`.

Conceals change only the display, never the buffer contents.
Glyph appearance depends on your terminal and font.

The supplementary symbol table and font coverage were compared with
[math-conceal.nvim](https://github.com/pxwg/math-conceal.nvim).
This plugin uses native Tree-sitter conceal: font and accent replacements apply
to a single supported letter, digit, or Greek command in braces.
Longer or unsupported arguments are not collapsed into a single character.
Typst and graphical equation rendering are outside this plugin's scope.
See [third-party notices](THIRD_PARTY_LICENSES.md) for the symbol data attribution.

## Development

With the parsers and queries on Neovim's runtime path, run:

```sh
nvim --headless -u NONE -i NONE -l tests/conceal.lua
```

To test a separate nvim-treesitter `main` checkout, set `NVIM_TREESITTER` to its path;
the tests use its `runtime/` directory.

## Acknowledgement

[latex.nvim](https://github.com/robbielyman/latex.nvim)

[math-conceal.nvim](https://github.com/pxwg/math-conceal.nvim)
