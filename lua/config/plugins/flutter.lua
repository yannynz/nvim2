return {
    {
        "akinsho/flutter-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "stevearc/dressing.nvim" },
        ft = { "dart" },
        config = function()
            require("flutter-tools").setup({
                widget_guides = {
                    enabled = true,
                },
                lsp = {
                    color = {
                        enabled = true,
                        background = true,
                        background_color = nil,
                        foreground = false,
                        virtual_text = true,
                        virtual_text_str = "■",
                    },
                },
            })
        end,
    },
}
