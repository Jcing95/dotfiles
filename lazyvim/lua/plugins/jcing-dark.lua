return {
  "jcing95/jcing-dark.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("jcing-dark").setup({})
    vim.cmd.colorscheme("jcing-dark")
  end,
}
