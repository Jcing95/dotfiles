-- Migration audit: dump every observable behaviour of the running config.
--
-- Run interactively, from inside a real repo with real files open:
--     :luafile audit/dump.lua
-- Headless misses a lot: VeryLazy fires via vim.schedule after VimEnter, and
-- LSP clients / buffer-local maps only exist once real files are loaded.
--
-- vim.g.audit_prefix is set to "clean-" by baseline.lua so the pristine-Neovim
-- run lands in separate files to diff against.

local PREFIX = vim.g.audit_prefix or ""
local OUT = vim.fn.expand("~/dotfiles/lazyvim/audit/raw")
vim.fn.mkdir(OUT, "p")

local LAZY = vim.fn.expand("~/.local/share/nvim/lazy") .. "/"
local USER = vim.fn.expand("~/dotfiles/lazyvim") .. "/"
local RT = (vim.env.VIMRUNTIME or "") .. "/"

local function W(name, lines)
  vim.fn.writefile(lines, OUT .. "/" .. PREFIX .. name)
  print(("  %-28s %d lines"):format(PREFIX .. name, #lines))
end

local function clean(s)
  return (tostring(s == nil and "" or s):gsub("[\t\r\n]", " "))
end

local function oneline(v)
  return (vim.inspect(v):gsub("%s+", " "))
end

-- Exact definition site of any lua function. Beats `:verbose map`, which reports
-- lazy.nvim's handler file rather than the spec that declared the mapping.
local function src(fn)
  if type(fn) ~= "function" then
    return ""
  end
  local ok, i = pcall(debug.getinfo, fn, "S")
  if not ok or not i or not i.source then
    return "?"
  end
  -- info.source, not short_src: short_src truncates long paths with "..."
  local s = i.source:gsub("^@", "")
  s = s:gsub("^" .. vim.pesc(LAZY), ""):gsub("^" .. vim.pesc(USER), "USER/"):gsub("^" .. vim.pesc(RT), "RUNTIME/")
  return s .. ":" .. (i.linedefined or 0)
end

-- Read a module-local upvalue out of a closure. The only way to reach snacks'
-- by_ft / by_lsp registries, which have no public listing API.
local function upval(fn, name)
  if type(fn) ~= "function" then
    return nil
  end
  for i = 1, 200 do
    local n, v = debug.getupvalue(fn, i)
    if not n then
      return nil
    end
    if n == name then
      return v
    end
  end
end

local function sorted_body(header, body)
  table.sort(body)
  table.insert(body, 1, header)
  return body
end

print("audit: writing to " .. OUT)

---------------------------------------------------------------------------
-- 0. Force every lazy-loaded plugin to materialise its keymaps
---------------------------------------------------------------------------
if not vim.g.audit_clean then
  local ok = pcall(vim.cmd, "Lazy! load all")
  if not ok then
    pcall(function()
      local cfg = require("lazy.core.config")
      require("lazy.core.loader").load(vim.tbl_keys(cfg.plugins), { cmd = "audit" }, { force = true })
    end)
  end
  vim.wait(3000)
  print("  did_very_lazy = " .. tostring(vim.g.did_very_lazy))
end

---------------------------------------------------------------------------
-- 1. Keymaps: global + buffer-local
---------------------------------------------------------------------------
local MODES = { "n", "i", "v", "x", "s", "o", "t", "c" }
do
  local body = {}
  local function emit(scope, mode, k)
    body[#body + 1] = table.concat({
      scope,
      mode,
      clean(k.lhs),
      clean(k.desc),
      clean(k.rhs),
      src(k.callback),
      tostring(k.expr == 1),
      tostring(k.nowait == 1),
    }, "\t")
  end

  for _, m in ipairs(MODES) do
    for _, k in ipairs(vim.api.nvim_get_keymap(m)) do
      emit("global", m, k)
    end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      for _, m in ipairs(MODES) do
        for _, k in ipairs(vim.api.nvim_buf_get_keymap(buf, m)) do
          emit("buf:" .. (ft ~= "" and ft or "?"), m, k)
        end
      end
    end
  end
  W("keymaps.tsv", sorted_body("scope\tmode\tlhs\tdesc\trhs\tsource\texpr\tnowait", body))
end

---------------------------------------------------------------------------
-- 2. The hidden layer: snacks' ft= / lsp= registries
--
-- LazyVim 16 routes keymaps through Snacks.keymap.set. Maps declared with
-- `ft =` or `lsp =` are parked in module-local tables and only become real
-- buffer-local maps once a matching filetype or client appears -- so they are
-- invisible to nvim_get_keymap until then.
---------------------------------------------------------------------------
if not vim.g.audit_clean then
  local body = {}
  local ok, SK = pcall(require, "snacks.keymap")
  if ok then
    local by_ft = upval(SK.set, "by_ft")
    local by_lsp = upval(SK.set, "by_lsp")
    if not by_ft and not by_lsp then
      body[#body + 1] = "ERROR\tupvalue extraction failed -- snacks renamed by_ft/by_lsp; fall back to lsp-keys.tsv + the per-ft probe\t\t\t\t"
    end
    for ft, maps in pairs(by_ft or {}) do
      for _, km in pairs(maps) do
        body[#body + 1] = table.concat({
          "ft",
          clean(ft),
          clean(km.mode),
          clean(km.lhs),
          clean((km.opts or {}).desc),
          src(type(km.rhs) == "function" and km.rhs or nil),
        }, "\t")
      end
    end
    for _, km in pairs(by_lsp or {}) do
      body[#body + 1] = table.concat({
        "lsp",
        oneline(km.lsp),
        clean(km.mode),
        clean(km.lhs),
        clean((km.opts or {}).desc),
        src(type(km.rhs) == "function" and km.rhs or nil),
      }, "\t")
    end
  else
    body[#body + 1] = "ERROR\tsnacks.keymap not loadable\t\t\t\t"
  end
  W("keymaps-scoped.tsv", sorted_body("kind\tfilter\tmode\tlhs\tdesc\tsource", body))
end

---------------------------------------------------------------------------
-- 3. Lazy spec keymaps -- the authoritative lhs -> plugin attribution.
--    debug.getinfo cannot attribute string-rhs maps like "<cmd>ToggleTerm<cr>".
---------------------------------------------------------------------------
if not vim.g.audit_clean then
  local body = {}
  local ok = pcall(function()
    local cfg = require("lazy.core.config")
    local plugin = require("lazy.core.plugin")
    for name, p in pairs(cfg.plugins) do
      local keys = plugin.values(p, "keys", true) or {}
      for _, k in pairs(keys) do
        if type(k) == "table" then
          body[#body + 1] = table.concat({
            clean(k[1]),
            clean(type(k.mode) == "table" and table.concat(k.mode, ",") or (k.mode or "n")),
            clean(k.desc),
            name,
            type(k[2]) == "function" and src(k[2]) or clean(k[2]),
          }, "\t")
        elseif type(k) == "string" then
          body[#body + 1] = table.concat({ clean(k), "n", "", name, "" }, "\t")
        end
      end
    end
  end)
  if not ok then
    body[#body + 1] = "ERROR\t\t\tlazy.core.plugin.values failed\t"
  end
  W("keymaps-lazyspec.tsv", sorted_body("lhs\tmode\tdesc\tplugin\trhs", body))
end

---------------------------------------------------------------------------
-- 4. Options -- current value against nvim's own compiled-in default
---------------------------------------------------------------------------
do
  local body = {}
  local info = vim.api.nvim_get_all_options_info()
  local names = vim.tbl_keys(info)
  table.sort(names)
  for _, n in ipairs(names) do
    local ok, v = pcall(vim.api.nvim_get_option_value, n, {})
    if ok then
      local cur, def = oneline(v), oneline(info[n].default)
      body[#body + 1] = table.concat({ n, info[n].scope, cur, def, tostring(cur ~= def) }, "\t")
    end
  end
  W("options.tsv", sorted_body("option\tscope\tcurrent\tnvim_default\tdiffers", body))
end

---------------------------------------------------------------------------
-- 5. Globals -- small, but these are the feature flags (root_spec, autoformat, ...)
---------------------------------------------------------------------------
do
  local body = {}
  -- vim.g is a metatable proxy: pairs()/tbl_keys() see nothing. Completion is
  -- the only way to enumerate it.
  for _, name in ipairs(vim.fn.getcompletion("g:", "var")) do
    local n = name:gsub("^g:", "")
    local ok, v = pcall(function()
      return vim.g[n]
    end)
    body[#body + 1] = n .. "\t" .. (ok and oneline(v):sub(1, 500) or "<error>")
  end
  W("globals.tsv", sorted_body("name\tvalue", body))
end

---------------------------------------------------------------------------
-- 6. Autocmds
---------------------------------------------------------------------------
do
  local body = {}
  local ok, aus = pcall(vim.api.nvim_get_autocmds, {})
  if not ok then
    aus = {}
    for _, ev in ipairs(vim.fn.getcompletion("", "event")) do
      local ok2, r = pcall(vim.api.nvim_get_autocmds, { event = ev })
      if ok2 then
        vim.list_extend(aus, r)
      end
    end
  end
  for _, a in ipairs(aus) do
    body[#body + 1] = table.concat({
      a.group_name or "-",
      a.event,
      clean(a.pattern),
      tostring(a.once),
      tostring(a.buflocal),
      src(a.callback),
      clean(a.command),
    }, "\t")
  end
  W("autocmds.tsv", sorted_body("group\tevent\tpattern\tonce\tbuflocal\tsource\tcommand", body))
end

---------------------------------------------------------------------------
-- 7. User commands. No callback field exists, so there is no debug.getinfo
--    attribution here -- cross-reference verbose-command.txt (see build.sh).
---------------------------------------------------------------------------
do
  local body = {}
  local function emit(scope, n, c)
    body[#body + 1] = table.concat({
      scope,
      n,
      tostring(c.nargs),
      tostring(c.bang),
      tostring(c.range),
      clean(c.complete),
      clean(c.definition):sub(1, 300),
    }, "\t")
  end
  for n, c in pairs(vim.api.nvim_get_commands({})) do
    emit("global", n, c)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      for n, c in pairs(vim.api.nvim_buf_get_commands(buf, {})) do
        emit("buf:" .. vim.bo[buf].filetype, n, c)
      end
    end
  end
  W("commands.tsv", sorted_body("scope\tname\tnargs\tbang\trange\tcomplete\tdefinition", body))
end

---------------------------------------------------------------------------
-- 8. LSP / format / lint -- all statically recoverable from merged opts
---------------------------------------------------------------------------
if not vim.g.audit_clean then
  local function dump_opts(plugin, file)
    local ok, o = pcall(function()
      return LazyVim.opts(plugin)
    end)
    W(file, vim.split(ok and vim.inspect(o) or ("could not resolve opts for " .. plugin), "\n"))
    return ok and o or nil
  end

  local lsp = dump_opts("nvim-lspconfig", "lspconfig-opts.lua")
  dump_opts("conform.nvim", "conform-opts.lua")
  dump_opts("nvim-lint", "lint-opts.lua")

  -- servers[*].keys, merged via opts_extend = { "servers.*.keys" }
  local body = {}
  for server, cfg in pairs((lsp or {}).servers or {}) do
    if type(cfg) == "table" then
      for _, k in ipairs(cfg.keys or {}) do
        body[#body + 1] = table.concat({
          server,
          clean(type(k.mode) == "table" and table.concat(k.mode, ",") or (k.mode or "n")),
          clean(k[1]),
          clean(k.desc),
          type(k.has) == "table" and table.concat(k.has, "+") or clean(k.has),
          tostring(k.enabled ~= nil),
          type(k[2]) == "function" and src(k[2]) or clean(k[2]),
        }, "\t")
      end
    end
  end
  W("lsp-keys.tsv", sorted_body("server\tmode\tlhs\tdesc\thas\thas_enabled_fn\trhs", body))

  -- Live clients, so the enabled set can be checked against the declared one
  local cl = {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    cl[#cl + 1] = table.concat({
      c.name,
      clean(c.root_dir),
      table.concat((c.config or {}).filetypes or {}, ","),
      tostring(vim.tbl_count(c.attached_buffers or {})),
    }, "\t")
  end
  W("lsp-clients.tsv", sorted_body("client\troot\tfiletypes\tattached_bufs", cl))
end

---------------------------------------------------------------------------
-- 9. Plugins. lazy.nvim does not record which spec file asked for a plugin
--    (_.module is not a field), so frag_kinds is the honest substitute: how
--    many layers touched this plugin, and what each one set.
---------------------------------------------------------------------------
if not vim.g.audit_clean then
  local body = {}
  local ok = pcall(function()
    local cfg = require("lazy.core.config")
    local frags = cfg.spec.fragments
    for name, p in pairs(cfg.plugins) do
      local kinds = {}
      for _, fid in ipairs(p._.frags or {}) do
        local f = frags.fragments[fid]
        local ks = {}
        for k in pairs((f or {}).spec or {}) do
          if k ~= 1 then
            ks[#ks + 1] = tostring(k)
          end
        end
        table.sort(ks)
        kinds[#kinds + 1] = "{" .. table.concat(ks, ",") .. "}"
      end
      body[#body + 1] = table.concat({
        name,
        clean(p.url),
        tostring(p.lazy),
        tostring(p._.loaded ~= nil),
        oneline(p.event),
        oneline(p.cmd),
        oneline(p.ft),
        tostring(#(p.keys or {})),
        table.concat(p.dependencies or {}, ","),
        tostring(#(p._.frags or {})),
        table.concat(kinds, " "),
      }, "\t")
    end
    W("spec-modules.txt", cfg.spec.modules or {})
  end)
  if not ok then
    body[#body + 1] = "ERROR: lazy.core.config walk failed"
  end
  W("plugins.tsv", sorted_body(
    "plugin\turl\tlazy\tloaded\tevent\tcmd\tft\tkeys#\tdeps\tn_frags\tfrag_kinds",
    body
  ))

  pcall(function()
    W("extras.txt", LazyVim.config.json.data.extras or {})
  end)
end

---------------------------------------------------------------------------
-- 10. :verbose capture. The only attribution available for user commands
--     (nvim_get_commands exposes no callback) and for string-rhs keymaps.
---------------------------------------------------------------------------
do
  local function redir(cmds, file)
    local path = OUT .. "/" .. PREFIX .. file
    vim.cmd("redir! > " .. vim.fn.fnameescape(path))
    for _, c in ipairs(cmds) do
      pcall(vim.cmd, "silent " .. c)
    end
    vim.cmd("redir END")
    print(("  %-28s (redir)"):format(PREFIX .. file))
  end
  redir({ "verbose command" }, "verbose-command.txt")
  redir({ "verbose map", "verbose map!" }, "verbose-map.txt")
end

print("audit: done")
