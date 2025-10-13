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
            local has_go = vim.fn.executable("go") == 1
            local mason_lsp_servers = {
                -- Java / Spring
                "jdtls",
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
                -- C/C++
                "clangd",
                -- NÃO colocar dartls aqui (ver nota abaixo)
            }
            if has_go then
                table.insert(mason_lsp_servers, "gopls")
            else
                vim.notify("Go (binário 'go') não encontrado no PATH; pulando instalação de gopls e ferramentas Go.", vim.log.levels.WARN)
            end
            require("mason-lspconfig").setup({
                ensure_installed = mason_lsp_servers,
                -- v2 liga sozinho os servidores instalados; pode desligar com automatic_enable=false
                automatic_enable = true,
            })

            local function on_attach(_, bufnr)
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
            end

            -- 2) Defaults p/ TODOS os LSPs
            vim.lsp.config("*", {
                capabilities = capabilities,
                on_attach = on_attach,
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

            -- 4) Java (JDTLS + Lombok)
            local function setup_java()
                local ok, jdtls = pcall(require, "jdtls")
                if not ok then
                    return
                end

                local registry_ok, registry = pcall(require, "mason-registry")
                if not registry_ok then
                    vim.notify("mason-registry indisponível para configurar o JDTLS", vim.log.levels.WARN)
                    return
                end

                if not registry.is_installed("jdtls") then
                    vim.notify("Instale o jdtls via Mason para habilitar Java", vim.log.levels.WARN)
                    return
                end

                if vim.fn.executable("java") ~= 1 then
                    vim.notify("Java (binário java) não encontrado no PATH", vim.log.levels.ERROR)
                    return
                end

                local jdtls_pkg = registry.get_package("jdtls")
                local jdtls_path = jdtls_pkg:get_install_path()
                local lombok_path = jdtls_path .. "/lombok.jar"
                local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
                if launcher == "" then
                    vim.notify("Launcher do JDTLS não encontrado", vim.log.levels.ERROR)
                    return
                end

                local sysname = vim.loop.os_uname().sysname
                local os_config = "linux"
                if sysname == "Darwin" then
                    os_config = "mac"
                elseif sysname == "Windows_NT" then
                    os_config = "win"
                end

                local root_dir = require("jdtls.setup").find_root({ "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
                if not root_dir then
                    return
                end

                local workspace_dir = vim.fn.stdpath("data") .. "/java-workspace/" .. vim.fs.basename(root_dir)
                vim.fn.mkdir(workspace_dir, "p")

                local bundles = {}
                if registry.is_installed("java-debug-adapter") then
                    local java_debug_pkg = registry.get_package("java-debug-adapter")
                    local java_debug_path = java_debug_pkg:get_install_path()
                    local debug_bundle = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
                    if debug_bundle ~= "" then
                        table.insert(bundles, debug_bundle)
                    end
                end
                if registry.is_installed("java-test") then
                    local java_test_pkg = registry.get_package("java-test")
                    local java_test_path = java_test_pkg:get_install_path()
                    local test_bundles = vim.fn.glob(java_test_path .. "/extension/server/*.jar", false, true)
                    if test_bundles then
                        vim.list_extend(bundles, test_bundles)
                    end
                end

                local jdtls_dap = nil
                local jdtls_dap_ok, dap_mod = pcall(require, "jdtls.dap")
                if jdtls_dap_ok then
                    jdtls_dap = dap_mod
                end

                jdtls.start_or_attach({
                    cmd = {
                        "java",
                        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                        "-Dosgi.bundles.defaultStartLevel=4",
                        "-Declipse.product=org.eclipse.jdt.ls.core.product",
                        "-Dlog.protocol=true",
                        "-Dlog.level=ALL",
                        "-javaagent:" .. lombok_path,
                        "-Xms1g",
                        "--add-modules=ALL-SYSTEM",
                        "--add-opens", "java.base/java.util=ALL-UNNAMED",
                        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
                        "-jar", launcher,
                        "-configuration", jdtls_path .. "/config_" .. os_config,
                        "-data", workspace_dir,
                    },
                    root_dir = root_dir,
                    init_options = { bundles = bundles },
                    settings = {
                        java = {
                            configuration = { updateBuildConfiguration = "automatic" },
                        },
                    },
                    capabilities = capabilities,
                    on_attach = function(client, bufnr)
                        on_attach(client, bufnr)
                        require("jdtls.setup").add_commands()
                        if jdtls_dap then
                            jdtls_dap.setup_dap_main_class_configs()
                        end
                    end,
                })
            end

            local java_group = vim.api.nvim_create_augroup("UserJdtls", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                group = java_group,
                callback = setup_java,
            })

            -- 5) DAPs e ferramentas
            local mason_tools = {
                "prettierd", "eslint_d", "biome",
                "black", "ruff", "google-java-format",
                "csharpier",
                "stylua",
                "hadolint", "nginx-language-server", "nginx-config-formatter",
                "shellcheck", "shfmt",
            }
            if has_go then
                vim.list_extend(mason_tools, { "gofumpt", "goimports", "gci", "golines", "staticcheck" })
            end
            require("mason-tool-installer").setup({
                ensure_installed = mason_tools,
                auto_update = false,
                run_on_start = true,
            })

            -- 6) Dart: configure “por fora” do Mason
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
        opts = function()
            local dap_adapters = { "python", "java", "codelldb", "netcoredbg", "js" }
            if vim.fn.executable("go") == 1 then
                table.insert(dap_adapters, "delve")
            end
            return {
                -- instale os adapters que você usa
                ensure_installed = dap_adapters,
                -- IMPORTANTe: manter handlers={}, isso aplica os defaults de config.
                handlers = {},
                automatic_installation = true,
            }
        end,
        config = function(_, opts)
            require("mason").setup()      -- mason primeiro
            require("mason-nvim-dap").setup(opts) -- depois mason-nvim-dap
        end,
    }

}
