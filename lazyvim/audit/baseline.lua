-- Pristine-Neovim baseline, to diff the live dump against.
--
--     cd /tmp && nvim --clean --headless \
--       -c 'luafile ~/dotfiles/lazyvim/audit/baseline.lua' -c 'qa!'
--
-- `--clean` rather than `-u NONE`: it still loads $VIMRUNTIME/plugin/*, which is
-- the same ground LazyVim sits on. Without this diff you will "discover" gcc,
-- grn, gO, ]q and gx and credit them to LazyVim -- they are 0.12 defaults.
vim.g.audit_clean = true
vim.g.audit_prefix = "clean-"
dofile(vim.fn.expand("~/dotfiles/lazyvim/audit/dump.lua"))
