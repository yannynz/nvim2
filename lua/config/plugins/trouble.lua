return {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
        {
            "<leader>pe",
            function()
                require('telescope.builtin').diagnostics()
            end,
            desc = "Diagnostics (Telescope)"
        },
        {
            "<leader>e",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
        },
    },
}
