local function current_filename()
    local name = vim.fn.expand("%:t")
    if name == "" then
        return "[No Name]"
    end
    return name
end

local function current_directory()
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
        return ""
    end

    local home = vim.fn.expand("~")
    if home ~= "" and dir:sub(1, #home) == home then
        dir = "~" .. dir:sub(#home + 1)
    end

    return dir
end

local function query_lote_date()
    local day, month, year = current_filename():match("^query(%d%d)(%d%d)(%d%d)%.sql$")
    if not day then
        return ""
    end

    return "LOTE " .. day .. "/" .. month .. "/20" .. year
end

local function file_badges()
    local badges = {}

    if vim.bo.modified then
        table.insert(badges, "MODIFICADO")
    end
    if vim.bo.readonly then
        table.insert(badges, "SOMENTE LEITURA")
    end

    return table.concat(badges, " | ")
end

local function winbar_title()
    local parts = { "ARQUIVO: " .. current_filename() }
    local lote = query_lote_date()
    local badges = file_badges()

    if lote ~= "" then
        table.insert(parts, lote)
    end
    if badges ~= "" then
        table.insert(parts, badges)
    end

    return table.concat(parts, " | ")
end

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.o.laststatus = 3

        local function set_highlights()
            vim.api.nvim_set_hl(0, "UserCurrentFileBanner", {
                bg = "#f5c542",
                fg = "#11131a",
                bold = true,
            })
            vim.api.nvim_set_hl(0, "UserCurrentFilePath", {
                bg = "#23252e",
                fg = "#d7dae0",
            })
        end

        set_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = set_highlights,
        })

        _G.NvimCurrentFileWinbar = winbar_title
        _G.NvimCurrentFilePath = current_directory

        vim.o.winbar = "%#UserCurrentFileBanner# %{%v:lua.NvimCurrentFileWinbar()%} %#UserCurrentFilePath# %{%v:lua.NvimCurrentFilePath()%} %*"

        require("lualine").setup({
            options = {
                theme = "auto",
                globalstatus = true,
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff" },
                lualine_c = {
                    {
                        current_filename,
                        color = { bg = "#f5c542", fg = "#11131a", gui = "bold" },
                        padding = { left = 1, right = 1 },
                    },
                    {
                        query_lote_date,
                        color = { fg = "#f5c542", gui = "bold" },
                    },
                    {
                        current_directory,
                        color = { fg = "#8bd5ff" },
                    },
                },
                lualine_x = { "diagnostics", "encoding", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { current_filename },
                lualine_x = { current_directory },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
