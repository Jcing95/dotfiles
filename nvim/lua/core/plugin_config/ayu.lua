vim.o.termguicolors = true

local ayu = require('ayu')
local colors = require('ayu.colors')
colors.generate()

ayu.setup({
    mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
    terminal = true, -- Set to `false` to let terminal manage its own colors.
    overrides = {
      Normal = {
        bg = "None",
             },
      NormalFloat = { bg = "none" },
      ColorColumn = { bg = "None" },
      SignColumn = { bg = "None" },
      Folded = { bg = "None" },
      FoldColumn = { bg = "None" },
      CursorLine = { bg = "None" },
      CursorColumn = { bg = "None" },
      VertSplit = { bg = "None" },
      visual = {
        bg = colors.selection_bg,
      }
   }, 
})

ayu.colorscheme()
