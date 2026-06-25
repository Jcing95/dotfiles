-- lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles in the file tree
          win = {
            list = {
              keys = {
                ["<c-t>"] = false, -- disable terminal mapping
              },
            },
          },
        },
      },
    },
  },
}
