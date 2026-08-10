local gitutil = require("jcing.git")

---Diff the whole branch against where it forked from the default branch.
---`A...HEAD` is git's symmetric-difference syntax, which diffview resolves to
---the merge base -- so commits landed on main after branching stay out of view.
---`--imply-local` puts the real working tree on the right instead of a
---read-only blob, so files stay editable inside the diff.
local function open_pr()
  local base = gitutil.default_branch()
  if not base then
    return gitutil.warn("could not resolve an upstream default branch")
  end
  vim.cmd(("DiffviewOpen %s...HEAD --imply-local"):format(base))
end

---Every commit the branch adds, as a browsable log with per-commit diffs.
---`--right-only` drops commits that are only on the base side.
local function pr_commits()
  local base = gitutil.default_branch()
  if not base then
    return gitutil.warn("could not resolve an upstream default branch")
  end
  vim.cmd(("DiffviewFileHistory --range=%s...HEAD --right-only --no-merges"):format(base))
end

return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal", winbar_info = true },
        file_history = { layout = "diff2_horizontal", winbar_info = true },
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 36 },
      },
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle file panel" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
      },
    },
    -- Under <leader>gv: <leader>gd/gp/gP are already taken by snacks' git-diff
    -- and GitHub PR pickers, and adding subkeys there would shadow them.
    keys = {
      { "<leader>gvv", open_pr, desc = "Diff whole PR (vs merge base)" },
      { "<leader>gvc", pr_commits, desc = "PR commits (file history)" },
      { "<leader>gvw", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree (uncommitted)" },
      { "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>gvt", "<cmd>DiffviewToggleFiles<cr>", desc = "Toggle file panel" },
      { "<leader>gvx", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
  },

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>gv", group = "pr review" })
    end,
  },
}
