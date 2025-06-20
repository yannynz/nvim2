return {
    {
        "scottmckendry/cyberdream.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("cyberdream").setup({
                transparent = true, -- Enable transparency
                italic_comments = true,
                hide_fillchars = true,
            })
            vim.cmd("colorscheme cyberdream")
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
        },
        config = function()
            -- ...
        end,
    },
    { "nvim-tree/nvim-web-devicons", lazy = true },
    { "stevearc/dressing.nvim",      event = "VeryLazy" },

    -- {
    --     "rebelot/kanagawa.nvim",
    --     lazy = false,
    --     priority = 1000,
    --     config = function()
    --         vim.cmd([[colorscheme kanagawa]])
    --     end,
    -- },
}
