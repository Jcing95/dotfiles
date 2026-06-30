return {
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    opts = {
      default_mappings = true, -- co/ct/cb/c0 + ]x/[x (see below)
      disable_diagnostics = true, -- don't spam LSP errors on conflict markers
    },
    keys = {
      -- Find every file with an unresolved conflict marker in the workspace
      {
        "<leader>gx",
        function()
          Snacks.picker.grep({ search = "^<<<<<<< ", regex = true, live = false })
        end,
        desc = "Conflicting files",
      },
    },
  },
}
