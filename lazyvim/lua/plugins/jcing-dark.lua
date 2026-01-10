return {
  "jcing-dark.nvim",
  dev = true,
  lazy = false,
  config = function()
    require("jcing-dark").setup()
    vim.cmd.colorscheme("jcing-dark")
  end,
}
