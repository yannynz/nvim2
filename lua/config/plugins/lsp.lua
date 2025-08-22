return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            "saghen/blink.cmp",
            {
                "folke/lazydev.nvim",
                opts = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    },
                },
            },
            "mfussenegger/nvim-jdtls", -- Java via ftplugin
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            local lsp          = require("lspconfig")
            local util         = require("lspconfig.util")

            require("mason").setup()

            -- LSPs que queremos manter instalados
            local ensure = {
                "csharp_ls", -- ou "omnisharp"
                "vtsls", "angularls", "volar", "html", "cssls", "emmet_language_server",
                "eslint", "jsonls", "tailwindcss",
                "basedpyright", -- ou "pyright"
                "lua_ls", "bashls",
                "dockerls", "docker_compose_language_service", "yamlls", "helm_ls",
                "nginx_language_server",
                "gopls", "clangd", "dartls",
                -- "jdtls" -> instalado pelo Mason, iniciado via ftplugin/java.lua
            }

            require("mason-lspconfig").setup({
                ensure_installed = ensure,
                automatic_installation = true,
            })

            -- keymaps comuns
            local function on_attach(_, bufnr)
                local map = function(m, lhs, rhs, d)
                    vim.keymap.set(m, lhs, rhs, { buffer = bufnr, desc = d })
                end
                map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
                map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
                map("n", "gi", vim.lsp.buf.implementation, "LSP: Go to Implementation")
                map("n", "gr", vim.lsp.buf.references, "LSP: References")
                map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
                map("n", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature")
                map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
                map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
                map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "LSP: Format")
            end

            -- setups específicos
            local special = {}

            special.vtsls = function()
                lsp.vtsls.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = util.root_pattern("tsconfig.json", "package.json", ".git"),
                    settings = {
                        typescript = { preferences = { includeInlayParameterNameHints = "all" } },
                        javascript = { preferences = { includeInlayParameterNameHints = "all" } },
                    },
                })
            end

            special.angularls = function()
                lsp.angularls.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = util.root_pattern("angular.json", "project.json", "nx.json", ".git"),
                })
            end

            special.volar = function()
                lsp.volar.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    filetypes = { "vue" },
                    root_dir = util.root_pattern("pnpm-workspace.yaml", "yarn.lock", "package-lock.json", "package.json",
                        ".git"),
                })
            end

            special.yamlls = function()
                lsp.yamlls.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = {
                        redhat = { telemetry = { enabled = false } },
                        yaml = {
                            schemaStore = { enable = true, url = "" },
                            schemas = { kubernetes = { "*.k8s.yaml", "k8s/*.yaml", "*/kubernetes/*.yaml" } },
                        },
                    },
                })
            end

            special.lua_ls = function()
                lsp.lua_ls.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                        },
                    },
                })
            end

            special.csharp_ls = function()
                lsp.csharp_ls.setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = util.root_pattern("*.sln", "*.csproj", ".git"),
                })
            end

            -- setup padrão
            local function default_setup(name)
                if special[name] then return special[name]() end
                if lsp[name] then
                    lsp[name].setup({ capabilities = capabilities, on_attach = on_attach })
                else
                    vim.notify("lspconfig: servidor não conhecido: " .. name, vim.log.levels.WARN)
                end
            end

            -- aplica setup para todos da lista
            for _, name in ipairs(ensure) do
                default_setup(name)
            end

            -- DAPs e ferramentas extras
            require("mason-nvim-dap").setup({
                ensure_installed = { "js", "codelldb", "python", "delve", "netcoredbg" },
                automatic_installation = true,
            })

            require("mason-tool-installer").setup({
                ensure_installed = {
                    "prettierd", "eslint_d", "biome",
                    "black", "ruff", "debugpy",
                    "stylua",
                    "hadolint", "nginx-config-formatter",
                    "gofumpt", "goimports", "gci", "golines", "staticcheck",
                    "shellcheck", "shfmt",
                },
                auto_update = false,
                run_on_start = true,
            })
        end,
    },

    -- DAP base
    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<F5>",      function() require("dap").continue() end,          desc = "DAP Continue" },
            { "<F10>",     function() require("dap").step_over() end,         desc = "DAP Step Over" },
            { "<F11>",     function() require("dap").step_into() end,         desc = "DAP Step Into" },
            { "<F12>",     function() require("dap").step_out() end,          desc = "DAP Step Out" },
            { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "DAP Breakpoint" },
        },
    },

    -- Bridge do Mason para DAPs
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            -- instale os adapters que você usa
            ensure_installed = { "python", "delve", "codelldb", "netcoredbg", "js" },
            -- IMPORTANTe: manter handlers={}, isso aplica os defaults de config.
            handlers = {},
            automatic_installation = true,
        },
        config = function(_, opts)
            require("mason").setup()              -- mason primeiro
            require("mason-nvim-dap").setup(opts) -- depois mason-nvim-dap
        end,
    }
}
