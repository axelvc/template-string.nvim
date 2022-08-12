# Template String Converter

This plugin is inspired in [Template String Converted vscode plugin](https://marketplace.visualstudio.com/items?itemName=meganrogge.template-string-converter)

I think it's a small feature but useful if you write js/ts code

## Explication

As soon as this plugin detects you're trying to use template (adding ${}) the quotes will be changed to backticks

### Examples

```
Before           Input            After
----------------------------------------
'foo ${|'          }          `foo ${}|`

'bar $|}'          {          `bar ${|}`

'idk |{}'          $          `idk $|{}`
----------------------------------------
```

### Video example

![Sample video](https://gist.githubusercontent.com/axelvc/b34d7fd659e573d0622f25d32ac3388a/raw/2b76682d7af471359325677fbebb6fd1b72558d3/demo.gif)

## Requirements

- Neovim 0.7.0 or later
- [nvim-treesitter plugin](https://github.com/nvim-treesitter/nvim-treesitter)

## Configuration

Example with default config, if you preffer you can just call setup function with partial or no config and the default will be taken

```lua
require('template-string').setup({
  filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }, -- filetypes where the plugin is active
  jsx_brackets = true, -- should add brackets to jsx attributes
})
```

## License

Licensed under the [MIT](./LICENSE) license.
