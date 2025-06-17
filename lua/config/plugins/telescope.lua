return {
    'nvim-telescope/telescope.nvim',
    config = function()
        local builtin = require('telescope.builtin')

        vim.keymap.set("n", "<space>pf", require('telescope.builtin').find_files)
        vim.keymap.set("n", "<space>ps", builtin.live_grep, { desc = "Search String (Live Grep)" })
    end,
}
