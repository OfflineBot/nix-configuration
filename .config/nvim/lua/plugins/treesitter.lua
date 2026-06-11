return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        config = function()
            -- main-branch API: install parsers, then enable highlight/indent
            -- per-buffer via a FileType autocmd (no more configs.setup()).
            require("nvim-treesitter").install({ "rust", "lua" })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "rust", "lua" },
                callback = function()
                    vim.treesitter.start()
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    }
}
