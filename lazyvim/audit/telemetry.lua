-- Which keymaps do I actually press? Dumping tells you what exists; this tells
-- you what you use, which is the input to every KEEP/DROP decision.
--
-- Enabled only under NVIM_AUDIT=1. Delete this file and the require in
-- lua/config/keymaps.lua once the inventory is decided.
--
-- Caveat: vim.on_key sees *typed* keys only. Anything triggered by an autocmd,
-- or by a <Cmd> remap from inside another mapping, is invisible here. Treat the
-- counts as a signal, not a proof.

local path = vim.fn.expand("~/dotfiles/lazyvim/audit/keys.tsv")
local f = io.open(path, "a")
if not f then
  return
end

local buf = {}
local timer = assert((vim.uv or vim.loop).new_timer())

-- Group keystrokes into runs: a mapping like <leader>gvb arrives as three
-- separate on_key calls, and only the whole run can be matched against an lhs.
local function flush()
  if #buf == 0 then
    return
  end
  f:write(table.concat({ os.date("%F %T"), vim.bo.filetype, table.concat(buf) }, "\t") .. "\n")
  f:flush()
  buf = {}
end

vim.on_key(function(_, typed)
  if typed == nil or typed == "" then
    return
  end
  buf[#buf + 1] = vim.fn.keytrans(typed)
  timer:stop()
  timer:start(1200, 0, vim.schedule_wrap(flush))
end)

vim.api.nvim_create_autocmd("VimLeavePre", { callback = flush })
