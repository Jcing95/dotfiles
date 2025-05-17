require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'ayu',
    },
    sections = {
        lualine_a = {
            {
                'filename',
                path = 1,
            }
        }
    }
}
