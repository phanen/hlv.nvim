Highlight visual when in cmdline. (Mainly to fix `vim._extui` regression)

```
nvim --clean --cmd 'se rtp^=. nu culopt=number' --cmd "lua require('vim._extui').enable{}" lua/hlv.lua
```

## TODO
* More address types
  * `:h :range`
  * `:h nvim_parse_cmd` (cannot parse address only currently)
* Builtin command preview?
  * `:h command-preview` (don't support builtin command)
  * workaround known issues https://github.com/neovim/neovim/issues/28510 (nvim-hlslens, blink.cmp)

## credit
* https://github.com/echasnovski/mini.nvim/blob/ac06b81bd331f9fee1fbe3d6e721c0ec7640fb01/lua/mini/cmdline.lua#L895
* https://github.com/nacro90/numb.nvim
* https://github.com/mcauley-penney/visual-whitespace.nvim
* similar plugins
  * https://github.com/0xAdk/full_visual_line.nvim
  * https://github.com/moyiz/command-and-cursor.nvim
