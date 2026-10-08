local biome_fts = {
  "typescript",
  "typescriptreact",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "css",
}

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      local util = require("conform.util")

      opts.formatters = opts.formatters or {}
      -- conform's `biome` formats only, and its `biome-check` also applies lint
      -- fixes; this is the middle ground, format plus assist (import sorting).
      opts.formatters["biome-format-assist"] = {
        command = util.from_node_modules("biome"),
        stdin = true,
        args = {
          "check",
          "--write",
          "--linter-enabled=false",
          "--stdin-file-path",
          "$FILENAME",
        },
        cwd = util.root_file({ "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }),
        -- No biome.json means no biome, so fall through to prettier.
        require_cwd = true,
      }

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(biome_fts) do
        opts.formatters_by_ft[ft] = { "biome-format-assist", "prettier", stop_after_first = true }
      end
    end,
  },
}
