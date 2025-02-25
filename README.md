# nvim-latex-conceal

(very) minimal, opinionated neovim filetype plugin for (La)TeX and Markdown, written in Lua.
There is no reason to prefer this plugin to [VimTeX](https://github.com/lervag/vimtex).

## Installation

```lua
-- lazy.nvim
{
    "mathjiajia/nvim-latex-conceal",
    init = function()
        vim.g.latex_conf = {
            enabled = {
                "amssymb",
                "core",
                "delim",
                "font",
                "greek",
                "math",
                -- "mleftright",
                "script",
            },
            add = {},
        }
    end
}
```

## Requirements

To use this plugin,
you must have treesitter parsers for the relevant filetype installed.
For example, `latex` for `.tex` files
and `markdown` and `markdown_inline` for `.md` files.

## Configuration

To use `nvim-latex-conceal` you need modify the global variable

```lua
vim.g.latex_conf
```

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

You can add your own concealed commands to the `conceals.add` table in the following format

```lua
add = {
	["colon"] = ":",
}
```

The key should be the command name with the leading backslash stripped,
and the value should be the single-character conceal to replace that command with.
The `add` table is for concealing `generic_command` elements.
Unlike most other conceals, these are _not_ sensitive to the presence or absence of math mode.

## Non-features

- compilation, forward/backward search, completion, linting—use [texlab](https://github.com/latex-lsp/texlab)
- highlighting—use treesitter

# Acknowledgement

[latex.nvim](https://github.com/robbielyman/latex.nvim)
