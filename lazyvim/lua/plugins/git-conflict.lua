return {
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    opts = {
      default_mappings = true, -- co/ct/cb/c0 + ]x/[x (see below)
      -- The plugin's own implementation calls the pre-0.11 vim.diagnostic.disable/enable
      -- API, which errors on nvim 0.12. Handled below instead.
      disable_diagnostics = false,
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)

      -- Don't spam LSP errors on conflict markers
      local group = vim.api.nvim_create_augroup("GitConflictDiagnostics", { clear = true })
      for pattern, enabled in pairs({ GitConflictDetected = false, GitConflictResolved = true }) do
        vim.api.nvim_create_autocmd("User", {
          group = group,
          pattern = pattern,
          callback = function()
            vim.diagnostic.enable(enabled, { bufnr = vim.api.nvim_get_current_buf() })
          end,
        })
      end
    end,
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
