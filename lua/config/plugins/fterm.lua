return {
    'numToStr/FTerm.nvim',
    config = function()
        local term_cmd

        if vim.fn.has('win32') == 1 then
            if vim.fn.executable('pwsh') == 1 then
                term_cmd = { 'pwsh', '-NoLogo' }
            elseif vim.fn.executable('powershell.exe') == 1 then
                term_cmd = { 'powershell.exe', '-NoLogo' }
            else
                term_cmd = { 'cmd.exe' }
            end
        else
            term_cmd = { vim.o.shell ~= '' and vim.o.shell or 'sh' }
        end

        require('FTerm').setup({
            border = 'double',
            dimensions = {
                height = 0.9,
                width = 0.9,
            },
            cmd = term_cmd,
        })

        -- Keymaps
        vim.keymap.set('n', '<leader><C-i>', '<CMD>lua require("FTerm").toggle()<CR>')
        vim.keymap.set('t', '<leader><C-i>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>')
        -- Tab dentro do terminal
        vim.api.nvim_set_keymap('t', '<Tab>', '<Tab>', { noremap = true, silent = true })
    end
}
