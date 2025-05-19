require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
--    'gdtoolkit',
  },
  automatic_enable = true,
})
--[[
local on_attach = function(_, _)
  vim.keymap.set('n', '<F2>', ,, {})
  vim.keymap.set('n', '', ,, {})
  vim.keymap.set('n', '', ,, {})
  vim.keymap.set('n', '', ,, {})
  vim.keymap.set('n', '', ,, {})
end
]]
require('lspconfig').lua_ls.setup {}

