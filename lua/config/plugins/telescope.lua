return {
    'nvim-telescope/telescope.nvim',
    config = function()
        local telescope = require('telescope')
        local builtin = require('telescope.builtin')

        local function first_executable(candidates)
            for _, candidate in ipairs(candidates) do
                local expanded = vim.fn.expand(candidate)
                if vim.fn.executable(expanded) == 1 then
                    return expanded
                end
            end
        end

        local rg = "rg"
        if vim.fn.executable(rg) ~= 1 then
            if vim.fn.has("win32") == 1 then
                rg = first_executable({
                    "~/bin/rg.exe",
                    "$LOCALAPPDATA/bin/rg.exe",
                    "$LOCALAPPDATA/rg/rg.exe",
                    "$LOCALAPPDATA/ripgrep/rg.exe",
                })
            else
                rg = first_executable({
                    "~/bin/rg",
                    "~/.local/bin/rg",
                })
            end
        end

        telescope.setup({
            defaults = rg and {
                vimgrep_arguments = {
                    rg,
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                },
            } or {},
        })

        vim.keymap.set("n", "<space>pf", require('telescope.builtin').find_files)
        vim.keymap.set("n", "<space>ps", function()
            if not rg then
                vim.notify(
                    "ripgrep nao encontrado. Coloque rg.exe em ~/bin ou em %LOCALAPPDATA%/bin.",
                    vim.log.levels.WARN
                )
                return
            end

            builtin.live_grep()
        end, { desc = "Search String (Live Grep)" })
    end,
}
