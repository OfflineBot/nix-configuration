return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'catppuccin/nvim' },
    config = function()
        require('lualine').setup({
            options = {
                theme = 'catppuccin-mocha'
            },
            sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'filename'},
                lualine_x = {'encoding', 'fileformat', 'filetype'},
                lualine_y = {'progress'},
                lualine_z = {'location', {
                    function()
                        return os.date("%H:%M")  -- 24-hour format
                    end,
                    icon = '󰥔'  -- Optional clock icon
                }}
            },
        })
    end
}
