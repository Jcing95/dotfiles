require('mason').setup()
require('mason-lspconfig').setup({
  automatic_enable = true,
})

local on_attach = function(_, _)
  vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, {})
  vim.keymap.set('n', '<C>.', vim.lsp.buf.code_action, {})
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, {})
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
end

