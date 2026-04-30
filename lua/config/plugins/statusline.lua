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

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.o.laststatus = 3

        vim.o.winbar = ""

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
