-- lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
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
