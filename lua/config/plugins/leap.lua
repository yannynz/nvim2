return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        name = "leap.nvim",
        config = function()
            local leap = require('leap')

            vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward)')
            vim.keymap.set({ 'n', 'x', 'o' }, 'S', '<Plug>(leap-backward)')
            vim.keymap.set({ 'x', 'o' }, 'x', '<Plug>(leap-forward-till)')
            vim.keymap.set({ 'x', 'o' }, 'X', '<Plug>(leap-backward-till)')
            vim.keymap.set({ 'n', 'x', 'o' }, 'gs', '<Plug>(leap-from-window)')

            require('leap').opts.highlight_unlabeled_phase_one_targets = true
        end,
    },
}
