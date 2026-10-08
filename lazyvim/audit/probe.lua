-- Per-filetype behaviour matrix: what actually happens when I open this file.
--
-- Run twice, both times with :luafile audit/probe.lua
--   pass 1: anywhere. Scratch buffers give the cheap columns.
--   pass 2: vim.g.audit_probe_real = true, from inside a real repo with real
--           files of each type open. Scratch buffers never attach LSP, and this
--           pass is also what materialises the lsp=-scoped snacks maps as real
--           buffer-local maps -- a cross-check on the by_lsp upvalue extraction.

local OUT = vim.fn.expand("~/dotfiles/lazyvim/audit/raw")
local REAL = vim.g.audit_probe_real
local FTS = {
  "lua",
  "typescript",
  "typescriptreact",
  "javascript",
  "json",
  "jsonc",
  "markdown",
  "nix",
  "sh",
  "yaml",
  "gitcommit",
}

local function clean(s)
  return (tostring(s == nil and "" or s):gsub("[\t\r\n]", " "))
end

local function row(ft, buf)
  local clients = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    clients[#clients + 1] = c.name
  end

  local byft, to_run = {}, {}
  pcall(function()
    byft = LazyVim.opts("conform.nvim").formatters_by_ft[ft] or {}
  end)
  pcall(function()
    for _, f in ipairs(require("conform").list_formatters_to_run(buf)) do
      to_run[#to_run + 1] = f.name .. (f.available and "" or "(unavailable)")
    end
  end)

  local linters = {}
  pcall(function()
    -- _resolve_linter_by_ft, not linters_by_ft[ft]: it splits dotted filetypes,
    -- and it is what LazyVim itself calls.
    linters = require("lint")._resolve_linter_by_ft(ft)
  end)

  local nmaps = 0
  for _, m in ipairs({ "n", "i", "v", "x" }) do
    nmaps = nmaps + #vim.api.nvim_buf_get_keymap(buf, m)
  end

  return table.concat({
    ft,
    table.concat(clients, ","),
    clean(vim.inspect(byft):gsub("%s+", " ")),
    table.concat(to_run, ","),
    table.concat(linters or {}, ","),
    tostring(vim.treesitter.language.get_lang(ft) or "-"),
    ("wrap=%s spell=%s cl=%s sw=%d et=%s"):format(
      vim.wo.wrap,
      vim.wo.spell,
      vim.wo.conceallevel,
      vim.bo[buf].shiftwidth,
      vim.bo[buf].expandtab
    ),
    tostring(nmaps),
  }, "\t")
end

local body = {}
if REAL then
  -- Walk the buffers already open, so root detection and workspace_required
  -- resolution (biome) behave as they do in real use.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
      local ft = vim.bo[buf].filetype
      if ft ~= "" then
        vim.api.nvim_set_current_buf(buf)
        body[#body + 1] = row(ft, buf)
      end
    end
  end
else
  for _, ft in ipairs(FTS) do
    vim.cmd("enew")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].filetype = ft
    vim.wait(400)
    body[#body + 1] = row(ft, buf)
    vim.cmd("bd!")
  end
end

table.sort(body)
table.insert(body, 1, "ft\tlsp_clients\tconform_by_ft\tconform_to_run\tlint\tts_parser\tlocal_opts\tbuf_maps")
local file = REAL and "filetypes-real.tsv" or "filetypes.tsv"
vim.fn.writefile(body, OUT .. "/" .. file)
print(("probe: wrote %s (%d rows)"):format(file, #body - 1))
