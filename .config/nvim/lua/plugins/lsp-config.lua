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

            -- Capabilities global für alle Server setzen.
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            --vim.lsp.config("gopls", {})

            vim.lsp.config("ts_ls", {
                flags = {
                    debounce_text_changes = 500,
                },
            })
            vim.lsp.config("solargraph", {})
            vim.lsp.config("html", {})
            vim.lsp.config("lua_ls", {})
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--completion-style=detailed" },
            })

            -- julia: lokales Julia aus der nvim-lspconfig-Umgebung bevorzugen.
            local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
            if vim.fn.filereadable(julia) == 1 then
                local julials_cmd = vim.lsp.config.julials and vim.lsp.config.julials.cmd
                if type(julials_cmd) == "table" then
                    julials_cmd = vim.deepcopy(julials_cmd)
                    julials_cmd[1] = julia
                    vim.lsp.config("julials", { cmd = julials_cmd })
                end
            end

            -- rust-analyzer via rustup (Mason-Binaries laufen auf NixOS nicht).
            -- Voraussetzung: `rustup component add rust-analyzer`
            vim.lsp.config("rust_analyzer", {
                cmd = { "rust-analyzer" },
            })

            vim.lsp.enable({
                "ts_ls",
                "solargraph",
                "html",
                "lua_ls",
                "clangd",
                "julials",
                "rust_analyzer",
            })

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
