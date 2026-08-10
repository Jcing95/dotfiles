local gitutil = require("jcing.git")

-- Toggle the gitsigns diff base between the index (default -- shows only what
-- you changed since the last commit) and the merge base with the upstream
-- default branch (shows every line the PR touches).
--
-- Deliberately a toggle rather than a permanent `base` setting: while a
-- non-index base is active, hunks are relative to the branch root, so gitsigns'
-- staging actions (<leader>ghs / ghr and friends) no longer line up with the
-- index and should not be used. Toggle back before staging.
local pr_base = nil

local function toggle_pr_base()
  local gs = require("gitsigns")

  if pr_base then
    gs.change_base(nil, true)
    pr_base = nil
    return gitutil.info("gitsigns base: index")
  end

  local sha, base = gitutil.merge_base()
  if not sha then
    return gitutil.warn("could not resolve a merge base to diff against")
  end

  pr_base = sha
  gs.change_base(sha, true)
  gitutil.info(("gitsigns base: %s @ %s"):format(base, sha:sub(1, 7)))
end

return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
    },
    keys = {
      { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle inline blame" },
      -- Shares the <leader>gv "pr review" group with diffview; <leader>gp/gP are
      -- snacks' GitHub PR pickers.
      { "<leader>gvb", toggle_pr_base, desc = "Toggle PR-wide diff base" },
      { "<leader>gvl", "<cmd>Gitsigns setqflist all<cr>", desc = "Changed hunks to quickfix" },
    },
  },
}
