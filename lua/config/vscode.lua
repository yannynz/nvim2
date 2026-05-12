vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 100

local function vscode_command(command)
    return function()
        if vim.fn.exists("*VSCodeNotify") == 1 then
            vim.fn.VSCodeNotify(command)
        end
    end
end

local function duplicate_current_line(direction)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line = vim.api.nvim_get_current_line()
    local insert_at = direction > 0 and row or (row - 1)
    local new_row = direction > 0 and (row + 1) or row

    vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, { line })
    vim.api.nvim_win_set_cursor(0, { new_row, cursor[2] })
end

local function duplicate_visual_lines(direction)
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local insert_at = direction > 0 and end_line or (start_line - 1)
    local new_start = direction > 0 and (start_line + #lines) or start_line
    local new_end = new_start + #lines - 1

    vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, lines)
    vim.api.nvim_win_set_cursor(0, { new_start, 0 })
    vim.cmd("normal! V")
    if new_end > new_start then
        vim.cmd("normal! " .. (new_end - new_start) .. "j")
    end
end

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

vim.keymap.set("n", "<A-J>", function() duplicate_current_line(1) end, { silent = true })
vim.keymap.set("n", "<A-K>", function() duplicate_current_line(-1) end, { silent = true })
vim.keymap.set("n", "<A-H>", "<<", { silent = true })
vim.keymap.set("n", "<A-L>", ">>", { silent = true })
vim.keymap.set("x", "<A-J>", function() duplicate_visual_lines(1) end, { silent = true })
vim.keymap.set("x", "<A-K>", function() duplicate_visual_lines(-1) end, { silent = true })
vim.keymap.set("x", "<A-H>", "<gv", { silent = true })
vim.keymap.set("x", "<A-L>", ">gv", { silent = true })

vim.keymap.set("n", "H", "b", { silent = true })
vim.keymap.set("n", "L", "e", { silent = true })
vim.keymap.set("n", "K", "{", { silent = true })
vim.keymap.set("n", "J", "}", { silent = true })
vim.keymap.set("n", "<leader>j", "mzJ`z", { silent = true })

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("x", "<", "<gv", { silent = true })
vim.keymap.set("x", ">", ">gv", { silent = true })

vim.keymap.set("n", "<leader>k", vscode_command("workbench.action.files.saveAll"), { silent = true })
vim.keymap.set("n", "<M-s>", vscode_command("workbench.action.files.saveAll"), { silent = true })
vim.keymap.set("n", "<M-q>", vscode_command("workbench.action.closeActiveEditor"), { silent = true })
vim.keymap.set("n", "<leader><leader>", vscode_command("workbench.action.quickOpen"), { silent = true })
vim.keymap.set("n", "<leader>e", vscode_command("workbench.files.action.focusFilesExplorer"), { silent = true })
vim.keymap.set("n", "gd", vscode_command("editor.action.revealDefinition"), { silent = true })
vim.keymap.set("n", "gr", vscode_command("editor.action.goToReferences"), { silent = true })
vim.keymap.set("n", "gi", vscode_command("editor.action.goToImplementation"), { silent = true })
vim.keymap.set("n", "<leader>rn", vscode_command("editor.action.rename"), { silent = true })
vim.keymap.set("n", "<leader>ca", vscode_command("editor.action.quickFix"), { silent = true })
vim.keymap.set("n", "<leader>f", vscode_command("editor.action.formatDocument"), { silent = true })
