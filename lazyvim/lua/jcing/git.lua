-- Shared git helpers for PR-scoped reviewing.
--
-- Both gitsigns and diffview default to comparing against the index or HEAD,
-- which only ever shows the current commit. These helpers resolve the branch's
-- PR base and the merge base with it, so either plugin can be pointed at the
-- branch root and show every change the PR introduces -- and in a stacked PR,
-- only the changes this branch adds on top of its parent.

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

---Run a command in the repo dir; return the trimmed first stdout line, or nil
---on failure. `vim.system` rather than `systemlist` because it takes a cwd,
---which `gh` needs -- it has no `-C` equivalent.
---@param cmd string[]
---@param timeout integer? milliseconds
---@return string?
local function run(cmd, timeout)
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = M.repo_dir(), text = true }):wait(timeout or 5000)
  end)
  if not ok or res.code ~= 0 or not res.stdout then
    return nil
  end
  local line = vim.trim(vim.split(res.stdout, "\n", { plain = true })[1] or "")
  return line ~= "" and line or nil
end

---@param args string[]
---@return string?
local function git(args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  return run(cmd)
end

---For git commands that succeed silently, where `git()` cannot tell an empty
---stdout from a failure.
---@param args string[]
---@return boolean
local function git_ok(args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = M.repo_dir(), text = true }):wait(5000)
  end)
  return ok and res.code == 0
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

---The upstream default branch, e.g. "origin/main". The last resort when the
---branch has no PR and no override.
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

---Turn a bare branch name into a ref that exists, preferring the remote copy.
---@param name string?
---@return string?
local function resolve_ref(name)
  if not name then
    return nil
  end
  for _, ref in ipairs({ "origin/" .. name, name }) do
    if git({ "rev-parse", "--verify", "--quiet", ref }) then
      return ref
    end
  end
  return nil
end

---@return string? branch nil when detached or outside a repo
local function current_branch()
  local branch = git({ "rev-parse", "--abbrev-ref", "HEAD" })
  return branch ~= "HEAD" and branch or nil
end

-- Keyed by "<repo toplevel>\0<branch>": a bare branch key would leak a base
-- across projects, since the same branch name lives in many repos.
local base_cache = {}

---@return string?
local function cache_key(branch)
  local root = git({ "rev-parse", "--show-toplevel" })
  return root and (root .. "\0" .. branch) or nil
end

---Forget resolved bases, so a newly opened PR or a changed base is picked up
---without restarting nvim.
function M.clear_base_cache()
  base_cache = {}
end

---The branch's configured PR base override, if any.
---@param branch string
---@return string?
local function override(branch)
  return git({ "config", "--get", ("branch.%s.prbase"):format(branch) })
end

---The base GitHub would diff this branch against. A non-zero exit here is the
---normal "no PR for this branch" case, not an error.
---@return string?
local function github_base()
  return run({ "gh", "pr", "view", "--json", "baseRefName", "--jq", ".baseRefName" }, 5000)
end

---The ref this branch's PR is based on: an explicit override, else the open
---PR's base branch, else the repo default branch. Cached per repo and branch,
---since the GitHub lookup costs a network round trip.
---@return string?
function M.base_ref()
  local branch = current_branch()
  if not branch then
    return M.default_branch()
  end

  local key = cache_key(branch)
  if key and base_cache[key] then
    return base_cache[key]
  end

  local base = resolve_ref(override(branch)) or resolve_ref(github_base()) or M.default_branch()
  if key and base then
    base_cache[key] = base
  end
  return base
end

---Merge base between HEAD and `base`, i.e. the commit the branch forked from.
---@param base string? defaults to the branch's PR base
---@return string? sha, string? base
function M.merge_base(base)
  base = base or M.base_ref()
  if not base then
    return nil, nil
  end
  return git({ "merge-base", base, "HEAD" }), base
end

---`:PrBase` prints the resolved base, `:PrBase <ref>` pins one for this branch,
---`:PrBase!` drops the pin. Both forms clear the cache so the next lookup is
---fresh.
vim.api.nvim_create_user_command("PrBase", function(opts)
  local branch = current_branch()
  if not branch then
    return M.warn("detached HEAD: no branch to configure a base for")
  end

  if opts.bang then
    git_ok({ "config", "--unset", ("branch.%s.prbase"):format(branch) })
    M.clear_base_cache()
    return M.info(("%s: base override removed"):format(branch))
  end

  if opts.args ~= "" then
    if not git_ok({ "config", ("branch.%s.prbase"):format(branch), opts.args }) then
      return M.warn("could not write the base override")
    end
    M.clear_base_cache()
  end

  local base = M.base_ref()
  if not base then
    return M.warn(("%s: could not resolve a base branch"):format(branch))
  end
  M.info(("%s: base %s%s"):format(branch, base, override(branch) and " (pinned)" or ""))
end, { nargs = "?", bang = true, complete = "customlist,v:lua.require'jcing.git'.complete_refs" })

---@param lead string
---@return string[]
function M.complete_refs(lead)
  local ok, res = pcall(function()
    local cmd = { "git", "for-each-ref", "--format=%(refname:short)", "refs/remotes", "refs/heads" }
    return vim.system(cmd, { cwd = M.repo_dir(), text = true }):wait(5000)
  end)
  if not ok or res.code ~= 0 then
    return {}
  end
  return vim.tbl_filter(function(ref)
    return ref ~= "" and ref:sub(1, #lead) == lead
  end, vim.split(res.stdout, "\n", { plain = true }))
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
