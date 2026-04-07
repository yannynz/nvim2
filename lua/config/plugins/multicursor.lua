return {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
        local mc = require("multicursor-nvim")

        mc.setup()

        vim.keymap.set({ "n", "x" }, "<C-A-j>", function()
            mc.lineAddCursor(1)
        end, { desc = "Multicursor: add cursor below" })

        vim.keymap.set({ "n", "x" }, "<C-A-k>", function()
            mc.lineAddCursor(-1)
        end, { desc = "Multicursor: add cursor above" })

        vim.keymap.set({ "n", "x" }, "<C-A-l>", function()
            mc.matchAddCursor(1)
        end, { desc = "Multicursor: add next match cursor" })

        vim.keymap.set({ "n", "x" }, "<C-A-h>", function()
            mc.matchAddCursor(-1)
        end, { desc = "Multicursor: add previous match cursor" })

        vim.keymap.set("x", "I", mc.insertVisual, { desc = "Multicursor: insert on selected lines" })
        vim.keymap.set("x", "A", mc.appendVisual, { desc = "Multicursor: append on selected lines" })

        mc.addKeymapLayer(function(layerSet)
            layerSet("n", "<Esc>", function()
                if not mc.cursorsEnabled() then
                    mc.enableCursors()
                else
                    mc.clearCursors()
                end
            end)
        end)
    end,
}
