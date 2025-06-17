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
    },
}
