vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.backspace = '2'
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

vim.wo.relativenumber = true

vim.keymap.set('n', '<space><CR>', ':nohlsearch<CR>')
vim.keymap.set('i', 'jk', '<Esc>', { noremap = false })
vim.keymap.set('v', 'jk', '<Esc>', { noremap = false })

