return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        lazy = false,
        config = function()
            local ok, configs = pcall(require, "nvim-treesitter.configs")
            if not ok then
                vim.schedule(function()
                    vim.notify(
                        "nvim-treesitter nao foi carregado. Rode :Lazy sync e reabra o Neovim.",
                        vim.log.levels.WARN
                    )
                end)
                return
            end

            configs.setup({
                ensure_installed = {
                    "bash",
                    "c", "c_sharp", "cpp",
                    "css",
                    "dockerfile",
                    "go",
                    "html",
                    "java",
                    "javascript", "typescript", "tsx",
                    "json",
                    "lua",
                    "markdown", "markdown_inline",
                    "python",
                    "query",
                    "sql",
                    "toml",
                    "vim", "vimdoc",
                    "yaml",
                },
                auto_install = false,
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    additional_vim_regex_highlighting = false,
                },
            })
        end,
    }
}
