vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('nvim-tree').setup({
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')
    api.config.mappings.default_on_attach(bufnr)

    local opts = {buffer = bufnr, noremap=true, silent=true}
    vim.keymap.set('n', '<Tab>', '<C-w>w', opts)
  end,
})

vim.keymap.set('n', '<c-n>', ':NvimTreeFindFileToggle<CR>')
vim.keymap.set('n', '<Tab>', '<C-w>w', {noremap = true, silent = true})
