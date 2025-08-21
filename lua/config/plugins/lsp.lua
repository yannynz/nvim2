return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- use os pacotes “mason-org/…”, os antigos redirecionam mas é bom atualizar
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "saghen/blink.cmp",
            {
                "folke/lazydev.nvim",
                opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
            },
            "mfussenegger/nvim-jdtls",
        },
        config = function()
            -- 0) capabilities via blink.cmp
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            local util = require("lspconfig.util")

            -- 1) mason + mason-lspconfig (v2)
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    -- C#
                    "csharp_ls",
                    -- Web / JS / TS / Frameworks
                    "vtsls", "angularls", "vue_ls", "html", "cssls", "emmet_language_server",
                    "eslint", "jsonls", "tailwindcss",
                    -- Python / Lua / Bash
                    "basedpyright", "lua_ls", "bashls",
                    -- Infra
                    "dockerls", "docker_compose_language_service", "yamlls", "helm_ls",
                    "nginx_language_server",
                    -- Go / C++
                    "gopls", "clangd",
                    -- NÃO colocar dartls aqui (ver nota abaixo)
                },
                -- v2 liga sozinho os servidores instalados; pode desligar com automatic_enable=false
                automatic_enable = true,
            })

            -- 2) Defaults p/ TODOS os LSPs
            vim.lsp.config("*", {
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
            -- 3) Ajustes por servidor
            vim.lsp.config("vtsls", {
                settings = {
                    typescript = { preferences = { includeInlayParameterNameHints = "all" } },
                    javascript = { preferences = { includeInlayParameterNameHints = "all" } },
                },
                root_dir = util.root_pattern("tsconfig.json", "package.json", ".git"),
            })

            vim.lsp.config("angularls", {
                root_dir = util.root_pattern("angular.json", "project.json", "nx.json", ".git"),
            })

            -- ATENÇÃO: agora é vue_ls (não “volar”)
            vim.lsp.config("vue_ls", {
                filetypes = { "vue" },
                root_dir = util.root_pattern(
                    "pnpm-workspace.yaml", "yarn.lock", "package-lock.json", "package.json", ".git"
                ),
            })

            vim.lsp.config("yamlls", {
                settings = {
                    redhat = { telemetry = { enabled = false } },
                    yaml = {
                        schemaStore = { enable = true, url = "" },
                        schemas = { kubernetes = { "*.k8s.yaml", "k8s/*.yaml", "*/kubernetes/*.yaml" } },
                    },
                },
            })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            })

            vim.lsp.config("csharp_ls", {
                root_dir = util.root_pattern("*.sln", "*.csproj", ".git"),
            })

            -- 4) DAPs e ferramentas
            require("mason-nvim-dap").setup({
                ensure_installed = { "js", "codelldb", "python", "delve", "netcoredbg" },
                automatic_installation = true,
            })

            require("mason-tool-installer").setup({
                ensure_installed = {
                    "prettierd", "eslint_d", "biome",
                    "black", "ruff", "debugpy",
                    "stylua",
                    "hadolint", "nginx-language-server", "nginx-config-formatter",
                    "gofumpt", "goimports", "gci", "golines", "staticcheck",
                    "shellcheck", "shfmt",
                },
                auto_update = false,
                run_on_start = true,
            })

            -- 5) Dart: configure “por fora” do Mason
            -- Requer Dart/Flutter no PATH; não coloque em ensure_installed
            vim.lsp.config("dartls", {}) -- use os defaults do lspconfig
            vim.lsp.enable({ "dartls" }) -- habilite explicitamente (Mason não habilita)
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
            require("mason").setup()      -- mason primeiro
            require("mason-nvim-dap").setup(opts) -- depois mason-nvim-dap
        end,
    }

}
