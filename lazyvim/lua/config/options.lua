-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Over SSH there's no local clipboard tool (xclip/pbcopy) reachable, so yanks
-- never reach the local system clipboard. Route *copies* through OSC 52: nvim
-- hands yanked text to the terminal, which writes it to the *local* clipboard.
-- Travels through SSH (and tmux, if `set-clipboard on`) as plain terminal bytes.
--
-- Paste cannot use OSC 52. WezTerm ignores clipboard *queries* by design
-- ("Requests to query the clipboard are ignored" -- wezterm escape-sequences
-- docs), and most terminals do the same, since answering one lets any remote
-- process read your clipboard. `vim.ui.clipboard.osc52.paste` has no way to know
-- that: it blocks 1s, nags "Waiting for OSC 52 response from the terminal...",
-- blocks 9s more, then gives up empty -- on every single `p`.
--
-- So reads are served from a cache file on this host that the copy handler
-- writes alongside the OSC 52 sequence. Pasting is instant, and every nvim
-- running here shares one clipboard, so yank in one window / paste in another
-- works. Text copied on the *local* machine still arrives via the terminal's
-- own paste (Cmd/Ctrl+V), which never touched this path anyway.
--
-- LazyVim deliberately sets `clipboard = ""` over SSH (see its options.lua), so
-- re-enable `unnamedplus` here to keep yank/paste routed through `+` seamlessly.
if vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")

  local cache_dir = vim.fn.stdpath("cache")
  local cache = {
    ["+"] = cache_dir .. "/ssh-clipboard-plus",
    ["*"] = cache_dir .. "/ssh-clipboard-star",
  }

  -- Line 1 holds the register type, the rest is the payload. Binary mode round
  -- trips exactly: no trailing newline is added on write or implied on read.
  local function store(reg, lines, regtype)
    -- stdpath("cache") is not guaranteed to exist yet; without this the write
    -- below fails and the pcall swallows it, leaving yanks silently unshared.
    vim.fn.mkdir(cache_dir, "p")

    local path = cache[reg]
    local tmp = path .. "." .. vim.uv.os_getpid()
    local payload = { regtype or "v" }
    vim.list_extend(payload, lines)

    local ok = pcall(vim.fn.writefile, payload, tmp, "b")
    if not ok then
      return
    end
    -- Yanks routinely carry secrets; keep them off other accounts on the box.
    vim.uv.fs_chmod(tmp, tonumber("600", 8))
    if not vim.uv.fs_rename(tmp, path) then
      vim.uv.fs_unlink(tmp)
    end
  end

  local function load(reg)
    local path = cache[reg]
    if vim.fn.filereadable(path) == 0 then
      return { { "" }, "v" }
    end

    local ok, lines = pcall(vim.fn.readfile, path, "b")
    if not ok or #lines == 0 then
      return { { "" }, "v" }
    end

    local regtype = table.remove(lines, 1)
    if #lines == 0 then
      lines = { "" }
    end
    return { lines, regtype }
  end

  local function copier(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      store(reg, lines, regtype)
      send(lines)
    end
  end

  vim.g.clipboard = {
    name = "OSC 52 (write) + host cache (read)",
    copy = {
      ["+"] = copier("+"),
      ["*"] = copier("*"),
    },
    paste = {
      ["+"] = function()
        return load("+")
      end,
      ["*"] = function()
        return load("*")
      end,
    },
  }
  vim.opt.clipboard = "unnamedplus"
end
