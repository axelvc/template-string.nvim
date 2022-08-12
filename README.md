# Template String Converter

This plugins is inspired in [Template String Converted vscode plugin](https://marketplace.visualstudio.com/items?itemName=meganrogge.template-string-converter)

I think it's a small feature but useful if you write js/ts code

## Requirements

- Neovim 0.7.0 or later
- [nvim-treesitter plugin](https://github.com/nvim-treesitter/nvim-treesitter)

## Configuration

Example with default config, if you want you can just call setup function with partial or no config and the default will be taken

```lua
require('template-string').setup({
  filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }, -- filetypes where the plugin is active
  jsx_brackets = true, -- should add brackets to jsx attributes
})
```
