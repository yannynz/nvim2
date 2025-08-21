require("config.lazy")

--opts
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.o.termguicolors = true
vim.opt.scrolloff = 12
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 100

--remaps
---- Leader
vim.g.mapleader = " "

--Go directory
vim.keymap.set("n", "<leader><leader>", '<cmd>Oil<CR>')

-- Move selected line / block of text in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Don't move cursor when Joining lines
vim.keymap.set("n", "J", "mzJ`z")

-- Don't move cursor when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Don't move cursor when searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste without losing register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Save quicker
vim.keymap.set("n", "<leader>k", '<cmd>wa<CR>')

-- Yanking to clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Search word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- LSP format
--vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
---- Lsp go references
--vim.api.nvim_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
---- Lsp go to implementation
--vim.api.nvim_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true })
---- Lsp code action
--vim.api.nvim_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
---- Lsp rename
--vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })
---- Lsp see error
--vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float(0, {scope="line"})<CR>',
--    { noremap = true, silent = true })
--
---- Open terminal
--vim.api.nvim_set_keymap('n', '<leader>t', '<cmd>edit term://pwsh<CR>', { noremap = true, silent = true })

-- Exite terminal mode
vim.api.nvim_set_keymap('t', '<leader>q', '<C-\\><C-n>', { noremap = true })

-- Identing better
vim.api.nvim_set_keymap('x', '<', '<gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '>', '>gv', { noremap = true, silent = false })

-- Faster autocomplete
vim.api.nvim_command('set complete-=i')
vim.api.nvim_command('set complete-=t')

-- Resize windows
vim.api.nvim_set_keymap('n', '<Up>', ':resize -2<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Down>', ':resize +2<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Left>', ':vertical res -2<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Right>', ':vertical res +2<CR>', { noremap = true, silent = true })

-- Copy name of the currente file to clipboard
vim.api.nvim_set_keymap('n', '<leader>cn', ':let @+ = expand("%:t")<CR>', { noremap = true, silent = true })

-- Move in quickfix list
vim.api.nvim_set_keymap('n', '<C-f>', ':cnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-b>', ':cprev<CR>', { noremap = true, silent = true })

-- Better moving between windows
vim.api.nvim_set_keymap('n', '<leader>w', '<C-w>', { noremap = true, silent = true })

-- Horizontal scrolling
vim.api.nvim_set_keymap('n', '<leader><C-L>', '20zl', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader><C-H>', '20zh', { noremap = true, silent = true })

-- Git Lens
--vim.api.nvim_set_keymap('n', '<leader>gl', ':Gitsigns toggle_current_line_blame<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', '<leader>gld', ':Gitsigns toggle_word_diff<CR> :Gitsigns toggle_deleted<CR>:Gitsigns toggle_linehl<CR>', { noremap = true, silent = true })
--vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)

-- Save all buffers with alt-S
vim.keymap.set("n", "<M-s>", "<cmd>wa<CR>", { noremap = true, silent = true })

-- Quit Neovim with Ctrl-Q
vim.keymap.set("n", "<M-q>", "<cmd>qa<CR>", { noremap = true, silent = true })

-- Open Mason with Alt-m 
vim.keymap.set('n', '<M-m>', "<cmd>Mason<CR>", { noremap = true, silent = true })

-- Abre o prompt do : com Alt-t
vim.keymap.set('n', '<M-t>', ':', { noremap = true, silent = false })

