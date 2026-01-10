return {
  -- Disable LazyVim's snacks terminal
  {
    "folke/snacks.nvim",
    keys = {
      { "<C-/>", false },
      { "<C-_>", false },
      { "<C-t>", false },
    },
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 20,
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      dir = "git_dir",
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    },
    keys = {
      { "<C-t>", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal 1" },
      { "<C-t>", "<cmd>ToggleTerm<cr>", mode = "t", desc = "Hide Terminal" },

      -- Numbered terminals
      { "<leader>t1", "<cmd>1ToggleTerm<cr>", desc = "Terminal 1" },
      { "<leader>t2", "<cmd>2ToggleTerm<cr>", desc = "Terminal 2" },
      { "<leader>t3", "<cmd>3ToggleTerm<cr>", desc = "Terminal 3" },

      -- Terminal for logs (horizontal at bottom)
      { "<leader>tl", "<cmd>4ToggleTerm direction=horizontal size=15<cr>", desc = "Log Terminal (bottom)" },

      -- Select terminal
      { "<leader>ts", "<cmd>TermSelect<cr>", desc = "Select Terminal" },

      -- Directions
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Float Terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Horizontal Terminal" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Vertical Terminal" },

      -- EXIT terminal mode (keep terminal open, move focus to code)
      { "<Esc>", [[<C-\><C-n>]], mode = "t", desc = "Exit Terminal Mode" },
    },
  },
}
