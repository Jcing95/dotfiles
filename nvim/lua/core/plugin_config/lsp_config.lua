require('mason').setup()
print('running')
require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
--    'gdtoolkit',
  }
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

