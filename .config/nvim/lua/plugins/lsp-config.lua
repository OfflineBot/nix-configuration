return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            auto_install = true,
        },
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()

            vim.diagnostic.config({
                virtual_text = true,
                signs = true,
                underline = true,
                severity_sort = true,
                update_in_insert = false,
            })

            vim.keymap.set("n", "K", function()
                vim.diagnostic.open_float(nil, { focusable = false })
            end)

            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            local lspconfig = require("lspconfig")
            --lspconfig.gopls.setup({
            --  capabilities = capabilities
            --})
            lspconfig.ts_ls.setup({
                flags = {
                    debounce_text_changes = 500,
                },
                capabilities = capabilities
            })
            lspconfig.solargraph.setup({
                capabilities = capabilities
            })
            lspconfig.html.setup({
                capabilities = capabilities
            })
            lspconfig.lua_ls.setup({
                capabilities = capabilities
            })
            lspconfig.clangd.setup {
              cmd = { "clangd", "--completion-style=detailed" }
            }

            lspconfig.julials.setup{
                on_new_config = function(new_config, _)
                    local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
                    if require'lspconfig'.util.path.is_file(julia) then
                        new_config.cmd[1] = julia
                    end
                end
            }

            vim.keymap.set("n", "m", function()
              vim.lsp.buf.hover({border="rounded"})
            end, {})
            --vim.keymap.set("n", "m", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
            vim.keymap.set("n", "<leader>gD", vim.lsp.buf.declaration, {})
            vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
        end,
    },
}
