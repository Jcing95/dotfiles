-- Biome LSP, for repos that ship a biome.json.
--
-- Why this exists: LazyVim's default <leader>co fires the LSP code action
-- `source.organizeImports`, which only vtsls answers -- so imports get
-- TypeScript's flat alphabetical sort, ignoring biome's `assist.actions.
-- source.organizeImports.options.groups` entirely. Biome's action is named
-- `source.organizeImports.biome`, so it never matched.
--
-- The keymap is declared under `servers.biome`, which LazyVim binds with a
-- `{ name = "biome" }` client filter (lazyvim/plugins/lsp/init.lua:175). It is
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
          -- stylua: ignore
          keys = {
            {
              "<leader>co",
              function() LazyVim.lsp.action["source.organizeImports.biome"]() end,
              desc = "Organize Imports (biome)",
              has = "codeAction",
            },
          },
        },
      },
    },
  },
}
