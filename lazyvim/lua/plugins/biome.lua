-- Biome LSP, for repos that ship a biome.json.
--
-- Why this exists: LazyVim's default <leader>co (servers["*"]) fires
-- `source.organizeImports`, which only vtsls answers -- imports get TypeScript's
-- flat alphabetical sort, ignoring biome's `assist.actions.source.
-- organizeImports.options.groups`.
--
-- The keymap is declared under `servers.biome`, which LazyVim binds with a
-- `{ name = "biome" }` client filter (lazyvim/plugins/lsp/keymaps.lua). It is
-- therefore only active in buffers where the biome client attached, and the
-- biome client only attaches when a biome.json/biome.jsonc is found upward from
-- the file (`workspace_required = true` in nvim-lspconfig/lsp/biome.lua).
-- Everywhere else -- other languages, TS repos without biome -- LazyVim's
-- default <leader>co is untouched.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {
          -- Use the repo-local binary (nvim-lspconfig's `cmd` prefers
          -- node_modules/.bin/biome) so the version matches the project.
          mason = false,
          keys = {
            {
              "<leader>co",
              function()
                vim.lsp.buf.code_action({
                  apply = true,
                  -- Biome scopes assist actions to the requested range, and the
                  -- organize-imports action only spans the import block, so the
                  -- default cursor range misses it from anywhere below.
                  range = { start = { 1, 0 }, ["end"] = { vim.api.nvim_buf_line_count(0), 0 } },
                  -- Biome answers under either the legacy kind or a
                  -- `source.biome.*` one; `filter` narrows the wider request back
                  -- down to organize-imports.
                  context = {
                    only = { "source.organizeImports.biome", "source.biome" },
                    diagnostics = {},
                  },
                  filter = function(action)
                    return (action.kind or ""):find("organizeImports", 1, true) ~= nil
                  end,
                })
              end,
              desc = "Organize Imports (biome)",
              has = "codeAction",
            },
          },
        },
      },
    },
  },
}
