local biome_with_fallback = { "biome", "prettier", stop_after_first = true }

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        typescript = biome_with_fallback,
        typescriptreact = biome_with_fallback,
        javascript = biome_with_fallback,
        javascriptreact = biome_with_fallback,
        json = biome_with_fallback,
        jsonc = biome_with_fallback,
        css = biome_with_fallback,
      },
    },
  },
}
