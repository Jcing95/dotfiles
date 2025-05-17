require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    'lua',
    'rust',
    'java',
    'typescript',
    'vim',
    'gdscript',
    'godot_resource',
    'gdshader',
  },

  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
  },
}
