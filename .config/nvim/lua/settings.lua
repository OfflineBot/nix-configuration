
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--vim.api.nvim_create_autocmd("FileType", {
--  pattern = "markdown",
--  callback = function()
--    vim.opt_local.conceallevel = 2
--  end,
--})

vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set expandtab")
vim.cmd("set smarttab")
vim.cmd("set autoindent")

vim.cmd("set incsearch")
vim.cmd("set ignorecase")
vim.cmd("set smartcase")
vim.cmd("set hlsearch")

vim.cmd("set wildmode=longest")
vim.cmd("set list")
vim.cmd("set showcmd")
vim.cmd("set showmode")

vim.cmd("set clipboard=unnamedplus")

vim.cmd([[autocmd FileType * set formatoptions-=ro]])

vim.opt.swapfile = false


vim.filetype.add({
  extension = {
    ejs = "html",
  },
})

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')

vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
vim.wo.number = true
vim.wo.relativenumber = true

-- Make terminal mode functional
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true })


--vim.g.loaded_matchparen = 1



vim.api.nvim_create_autocmd("FileType", {
  pattern = {"tex", "julia"},
  callback = function()
    vim.bo.indentexpr = ""
  end,
})


-- =================== KeyStrokes ======================


local counter_file = vim.fn.stdpath("data") .. "/keystroke_count"

-- Load existing count or initialize it
local count = 0
local f = io.open(counter_file, "r")
if f then
  local saved = f:read("*n")
  if saved then count = saved end
  f:close()
end

-- Save function
local function save_count()
  local wf = io.open(counter_file, "w")
  if wf then
    wf:write(tostring(count))
    wf:close()
  end
end

-- Increment on every key
vim.on_key(function()
  count = count + 1
  save_count()
end)

-- Command to print total
vim.api.nvim_create_user_command("KeyCount", function()
  print("Total keystrokes: " .. count)
end, {})
