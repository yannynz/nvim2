-- ~/.config/nvim/lua/plugins/lsp.lua  (ou onde você guarda os specs)
return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            -- (opcional mas recomendado p/ DAPs e ferramentas)
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
            -- Java
            "mfussenegger/nvim-jdtls",
        },
        config = function()
            -- 0) capabilities via blink.cmp (corrigido)
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- 1) mason (bins) + mason-lspconfig (LSPs)
            require("mason").setup()

            require("mason-lspconfig").setup({
                ensure_installed = {
                    -- C#
                    "csharp_ls", -- (ou "omnisharp")
                    -- Web / JS / TS / Frameworks
                    "vtsls", "angularls", "volar", "html", "cssls", "emmet_language_server",
                    "eslint", "jsonls", "tailwindcss",
                    -- Python / Lua / Bash
                    "basedpyright", -- (ou "pyright")
                    "lua_ls", "bashls",
                    -- Infra
                    "dockerls", "docker_compose_language_service", "yamlls", "helm_ls",
                    "nginx_language_server",
                    -- Go / C++ / Dart
                    "gopls", "clangd", "dartls",
                    -- Java via jdtls é especial (carrega no ftplugin)
                    -- "jdtls"  -- deixe instalado pelo :Mason, mas não configure aqui
                },
                automatic_installation = true,
            })

            -- 2) handlers genéricos (um setup padrão para todos os LSPs acima)
            local lsp = require("lspconfig")
            local util = require("lspconfig.util")

            require("mason-lspconfig").setup_handlers({
                function(server)
                    lsp[server].setup({
                        capabilities = capabilities,
                        on_attach = function(_, bufnr)
                            local map = function(m, lhs, rhs, d) vim.keymap.set(m, lhs, rhs, { buffer = bufnr, desc = d }) end
                            map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
                            map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
                            map("n", "gi", vim.lsp.buf.implementation, "LSP: Go to Implementation")
                            map("n", "gr", vim.lsp.buf.references, "LSP: References")
                            map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
                            map("n", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature")
                            map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
                            map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
                            map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "LSP: Format")
                        end,
                    })
                end,

                -- Ajustes finos por servidor (opcionais)
                ["vtsls"] = function()
                    lsp.vtsls.setup({
                        capabilities = capabilities,
                        root_dir = util.root_pattern("tsconfig.json", "package.json", ".git"),
                        settings = {
                            typescript = { preferences = { includeInlayParameterNameHints = "all" } },
                            javascript = { preferences = { includeInlayParameterNameHints = "all" } },
                        },
                    })
                end,

                ["angularls"] = function()
                    lsp.angularls.setup({
                        capabilities = capabilities,
                        root_dir = util.root_pattern("angular.json", "project.json", "nx.json", ".git"),
                    })
                end,

                ["volar"] = function()
                    lsp.volar.setup({
                        capabilities = capabilities,
                        filetypes = { "vue" },
                        root_dir = util.root_pattern("pnpm-workspace.yaml", "yarn.lock", "package-lock.json",
                            "package.json", ".git"),
                    })
                end,

                ["yamlls"] = function()
                    lsp.yamlls.setup({
                        capabilities = capabilities,
                        settings = {
                            redhat = { telemetry = { enabled = false } },
                            yaml = {
                                schemaStore = { enable = true, url = "" },
                                schemas = { kubernetes = { "*.k8s.yaml", "k8s/*.yaml", "*/kubernetes/*.yaml" } },
                            },
                        },
                    })
                end,

                ["lua_ls"] = function()
                    lsp.lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                diagnostics = { globals = { "vim" } },
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                            },
                        },
                    })
                end,

                ["csharp_ls"] = function()
                    lsp.csharp_ls.setup({
                        capabilities = capabilities,
                        root_dir = util.root_pattern("*.sln", "*.csproj", ".git"),
                    })
                end,
            })

            -- 3) (opcional) DAPs e ferramentas extras via Mason
            require("mason-nvim-dap").setup({
                ensure_installed = { "js", "codelldb", "python", "delve", "netcoredbg" },
                automatic_installation = true,
            })

            require("mason-tool-installer").setup({
                ensure_installed = {
                    -- formatters/linters/CLIs (NÃO são LSPs)
                    "prettierd", "eslint_d", "biome",
                    "black", "ruff", "debugpy",
                    "stylua",
                    "hadolint", "nginx-language-server", "nginx-config-formatter",
                    "gofumpt", "goimports", "gci", "golines", "staticcheck",
                    "shellcheck", "shfmt",
                    -- você pode adicionar mais aqui (p.ex. markdownlint etc.)
                },
                auto_update = false,
                run_on_start = true,
            })
        end,
    },
}
