return {
    'numToStr/FTerm.nvim',
    config = function()
        require('FTerm').setup({
            border = 'double',
            dimensions = {
                height = 0.9,
                width = 0.9,
            },
            cmd = { 'powershell.exe', '-NoLogo' },
        })

        -- Keymaps
        vim.keymap.set('n', '<leader><C-i>', '<CMD>lua require("FTerm").toggle()<CR>')
        vim.keymap.set('t', '<leader><C-i>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>')
        -- Tab dentro do terminal
        vim.api.nvim_set_keymap('t', '<Tab>', '<Tab>', { noremap = true, silent = true })
    end
}
