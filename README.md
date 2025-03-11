# nvim-latex-conceal

## Installation

```lua
-- lazy.nvim
{ "mathjiajia/nvim-latex-conceal" }
```

## Requirements

To use this plugin,
you must have treesitter parsers for the relevant filetype installed.
For example, `latex` for `.tex` files
and `markdown` and `markdown_inline` for `.md` files.

## Features

### Conceals

Almost all of the low-hanging fruit is done as far as concealing;
hard things like using tree-sitter for `\'e` to `é` are not a priority.

You can disable conceals on a per-file basis by redefining `conceals.enabled` in the `setup` function.

Currently the conceals provided are:

- Delim: things like `\left` and many instances of curly braces.
- Font: things like `\mathbb{Z}` to `ℤ`
- Greek: things like `\sigma` to `σ`
- Math: things like `\amalg` to `⨿`
- Script: superscripts and subscripts

# Acknowledgement

[latex.nvim](https://github.com/robbielyman/latex.nvim)
