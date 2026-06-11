
-- return {
--     "ellisonleao/gruvbox.nvim", priority = 1000 , config = true, opts = ...
-- }

-- return {
--     "neanias/everforest-nvim",
--     version = false,
--     lazy = false,
--     priority = 1000,
--     config = function()
--         require("everforest").setup({
--             background = "hard",
--             transparent_background_level = 1
--         })
--         vim.cmd([[colorscheme everforest]])
--     end,
-- }

-- return {
--     "catppuccin/nvim",
--     name = "catppuccin",
--     priority = 1000,
--     config = function()
--         require("catppuccin").setup({
--             flavour = "mocha",
--             transparent_background = true,
--             compile = {
--                 enabled = false,  -- DISABLE COMPILATION
--             },
--             integrations = {
--                 treesitter = true,
--                 neotree = true,
--                 -- Add any other integrations you use
--             },
--         })
--
--         vim.cmd.colorscheme "catppuccin-mocha"
--
--         vim.api.nvim_create_autocmd("FileType", {
--             pattern = "*",
--             callback = function()
--                 vim.schedule(function()
--                     vim.cmd.colorscheme "catppuccin-mocha"
--                 end)
--             end,
--         })
--     end
-- }

-- Active: serenity (colors/serenity.lua) — uses the terminal background.
-- Catppuccin is kept installed (lazy) so `:colorscheme catppuccin-mocha`
-- still works on demand.
return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        priority = 1000,
        opts = {
            flavour = "mocha",
            transparent_background = true,
            compile = { enabled = false },
            integrations = {
                treesitter = true,
                neotree = true,
            },
        },
    },
    {
        "serenity",
        name = "serenity",
        dir = vim.fn.stdpath("config"),
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("serenity")
        end,
    },
}
