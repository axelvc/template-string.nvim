# Template String Converter

This plugin is inspired by the VS Code plugin: [Template String Converted](https://marketplace.visualstudio.com/items?itemName=meganrogge.template-string-converter)

## Explanation

As soon as this plugin detects you're trying to use template strings (adding ${}) the quotes will be changed to backticks

### Examples

```
Before           Input            After
----------------------------------------
'foo ${|'          }          `foo ${}|`

'bar $|}'          {          `bar ${|}`

'idk |{}'          $          `idk $|{}`
----------------------------------------
```

![Demo video](https://gist.githubusercontent.com/axelvc/b34d7fd659e573d0622f25d32ac3388a/raw/2b76682d7af471359325677fbebb6fd1b72558d3/demo.gif)

### Remove template string

Opposite function, remove backticks when there are no template strings

![Remove template string demo](https://gist.githubusercontent.com/axelvc/b34d7fd659e573d0622f25d32ac3388a/raw/4761aab9cd46c8d8112e9aaf5900a139d46e7241/demo_2.gif)

## Requirements

- Neovim 0.7.0 or later
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) plugin

## Supported languages

- Javascript / Typescript
- JSX
- Vue
- Python

## Configuration

Example with the default config. If you prefer, you could call the setup function with partial or no config, and the default will be taken

```lua
require('template-string').setup({
  filetypes = { 'html', 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue', 'python' }, -- filetypes where the plugin is active
  jsx_brackets = true, -- must add brackets to JSX attributes
  remove_template_string = false, -- remove backticks when there are no template strings
  restore_quotes = {
    -- quotes used when "remove_template_string" option is enabled
    normal = [[']],
    jsx = [["]],
  },
})
```

## License

Licensed under the [MIT](./LICENSE) license.
