return {
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })
            local builtin = require("telescope.builtin")

            local function find_files_reveal()
                local actions = require("telescope.actions")
                builtin.find_files({
                    attach_mappings = function(_, _)
                        actions.select_default:enhance({
                            post = function()
                                vim.schedule(function()
                                    local file_win = vim.api.nvim_get_current_win()
                                    pcall(vim.cmd, "Neotree reveal")
                                    if vim.api.nvim_win_is_valid(file_win) then
                                        vim.api.nvim_set_current_win(file_win)
                                    end
                                end)
                            end,
                        })
                        return true
                    end,
                })
            end

            vim.keymap.set("n", "<C-p>", find_files_reveal, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader><leader>", find_files_reveal, {})



            vim.keymap.set('n', '<leader>gd', function()
                require('telescope.builtin').lsp_definitions()
            end, { desc = "Go to definition (show all overloads)" })

            vim.keymap.set('n', '<leader>gr', function()
                require('telescope.builtin').lsp_references()
            end, { desc = "List references (and overloads)" })


            require("telescope").load_extension("ui-select")
        end,
    },
}
