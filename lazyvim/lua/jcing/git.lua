-- Shared git helpers for PR-scoped reviewing.
--
-- Both gitsigns and diffview default to comparing against the index or HEAD,
-- which only ever shows the current commit. These helpers resolve the upstream
-- default branch and the merge base with it, so either plugin can be pointed at
-- the branch root and show every change the PR introduces.

local uv = vim.uv or vim.loop

local M = {}

---Directory to run git in: the current file's own directory when it exists on
---disk, otherwise cwd. Keeps things correct when editing a file outside cwd.
---@return string
function M.repo_dir()
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" and uv.fs_stat(file) then
    return vim.fs.dirname(file)
  end
  return uv.cwd()
end

---Run git synchronously; return the trimmed first stdout line, or nil on failure.
---@param args string[]
---@return string?
local function git(args)
  local cmd = { "git", "-C", M.repo_dir() }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 or not out[1] then
    return nil
  end
  local line = vim.trim(out[1])
  return line ~= "" and line or nil
end

-- Tried in order when origin/HEAD is unset, which happens with plain clones of
-- bare mirrors and some CI checkouts.
local FALLBACKS = {
  "origin/main",
  "origin/master",
  "upstream/main",
  "upstream/master",
  "main",
  "master",
}

---The upstream default branch, e.g. "origin/main".
---@return string?
function M.default_branch()
  local head = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
  if head then
    return head
  end
  for _, ref in ipairs(FALLBACKS) do
    if git({ "rev-parse", "--verify", "--quiet", ref }) then
      return ref
    end
  end
  return nil
end

---Merge base between HEAD and `base`, i.e. the commit the branch forked from.
---@param base string? defaults to the upstream default branch
---@return string? sha, string? base
function M.merge_base(base)
  base = base or M.default_branch()
  if not base then
    return nil, nil
  end
  return git({ "merge-base", base, "HEAD" }), base
end

---@param msg string
function M.info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "git" })
end

---@param msg string
function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "git" })
end

return M
