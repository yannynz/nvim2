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

            local function fallback_root(bufnr)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                if fname ~= "" then
                    local git = vim.fs.root(fname, ".git")
                    if git then
                        return git
                    end
                    return vim.fs.dirname(fname)
                end
                local cwd = (vim.uv or vim.loop).cwd()
                local git = vim.fs.root(cwd, ".git")
                return git or cwd
            end

            local function make_root_dir(...)
                local resolver = util.root_pattern(...)
                return function(bufnr, on_dir)
                    local fname = vim.api.nvim_buf_get_name(bufnr)
                    local root
                    if fname ~= "" then
                        root = resolver(fname)
                    end
                    on_dir(root or fallback_root(bufnr))
                end
            end

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
                -- Rust (Adicionado para garantir suporte)
                "rust_analyzer",
            }
            if has_go then
                table.insert(mason_lsp_servers, "gopls")
            else
                vim.notify("Go (binário 'go') não encontrado no PATH; pulando instalação de gopls e ferramentas Go.", vim.log.levels.WARN)
            end

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

            -- Definição dos handlers para o Mason-LSPConfig
            require("mason-lspconfig").setup({
                ensure_installed = mason_lsp_servers,
                handlers = {
                    -- Handler Padrão (Fallback)
                    function(server_name)
                        require("lspconfig")[server_name].setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                        })
                    end,

                    -- Ignorar JDTLS aqui (configurado manualmente abaixo com nvim-jdtls)
                    ["jdtls"] = function() end,

                    -- Configurações Específicas
                    ["vtsls"] = function()
                        require("lspconfig").vtsls.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            settings = {
                                typescript = { preferences = { includeInlayParameterNameHints = "none" } },
                                javascript = { preferences = { includeInlayParameterNameHints = "none" } },
                            },
                            root_dir = make_root_dir("tsconfig.json", "package.json", ".git"),
                        })
                    end,

                    ["angularls"] = function()
                        require("lspconfig").angularls.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            root_dir = make_root_dir("angular.json", "project.json", "nx.json", ".git"),
                        })
                    end,

                    ["html"] = function()
                        local filetypes = { "html", "angular.html", "htmlangular" }
                        -- Tenta carregar defaults do lspconfig se existirem
                        local ok, html_defaults = pcall(require, "lspconfig.server_configurations.html")
                        if ok then
                            local default_fts = vim.deepcopy(html_defaults.default_config.filetypes or {})
                            vim.list_extend(filetypes, default_fts)
                        end
                        -- Remover duplicatas
                        local seen = {}
                        local unique_fts = {}
                        for _, ft in ipairs(filetypes) do
                            if not seen[ft] then table.insert(unique_fts, ft); seen[ft] = true end
                        end
                        require("lspconfig").html.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            filetypes = unique_fts,
                        })
                    end,

                    ["vue_ls"] = function()
                        require("lspconfig").vue_ls.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            filetypes = { "vue" },
                            root_dir = make_root_dir(
                                "pnpm-workspace.yaml", "yarn.lock", "package-lock.json", "package.json", ".git"
                            ),
                        })
                    end,

                    ["yamlls"] = function()
                        require("lspconfig").yamlls.setup({
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
                    end,

                    ["lua_ls"] = function()
                        require("lspconfig").lua_ls.setup({
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
                    end,

                    ["csharp_ls"] = function()
                        require("lspconfig").csharp_ls.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            root_dir = make_root_dir("*.sln", "*.slnx", "*.csproj", ".git"),
                        })
                    end,

                    ["rust_analyzer"] = function()
                        require("lspconfig").rust_analyzer.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            -- root_dir padrão do lspconfig já funciona bem para rust (Cargo.toml)
                        })
                    end,
                },
            })

            -- 4) Java (JDTLS + Lombok) - Manual Setup
            local function setup_java()
                local ok, jdtls = pcall(require, "jdtls")
                if not ok then
                    return
                end

                if vim.fn.executable("java") ~= 1 then
                    vim.notify("Java (binário java) não encontrado no PATH", vim.log.levels.ERROR)
                    return
                end

                -- Caminhos Hardcoded do Mason (Mais seguro que usar registry na inicialização)
                local mason_path = vim.fn.stdpath("data") .. "/mason"
                local jdtls_path = mason_path .. "/packages/jdtls"
                local lombok_path = jdtls_path .. "/lombok.jar"
                local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

                if vim.fn.empty(launcher) == 1 then
                    -- Tenta fallback se o Mason instalou em outro lugar ou estrutura mudou
                    -- Mas geralmente packages/jdtls é o padrão
                    vim.notify("Launcher do JDTLS não encontrado em: " .. jdtls_path, vim.log.levels.WARN)
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
                -- Java Debug Adapter
                local java_debug_path = mason_path .. "/packages/java-debug-adapter"
                local debug_bundle = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
                if debug_bundle ~= "" then
                    table.insert(bundles, debug_bundle)
                end
                
                -- Java Test
                local java_test_path = mason_path .. "/packages/java-test"
                local test_bundles = vim.fn.glob(java_test_path .. "/extension/server/*.jar", false, true)
                if not vim.tbl_isempty(test_bundles) then
                    vim.list_extend(bundles, test_bundles)
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
            -- Uso de vim.lsp.config (Nativo Nvim 0.11) para evitar warnings de deprecation
            local dart_opts = {
                capabilities = capabilities,
                on_attach = on_attach,
            }
            
            -- Tenta carregar defaults do nvim-lspconfig se disponível
            local ok_configs, configs = pcall(require, "lspconfig.configs")
            if ok_configs and configs["dartls"] then
                local defaults = configs["dartls"].default_config or {}
                dart_opts = vim.tbl_deep_extend("force", defaults, dart_opts)
            end

            -- Registra e habilita o servidor
            if vim.lsp.config then
                vim.lsp.config("dartls", dart_opts)
                vim.lsp.enable("dartls")
            else
                -- Fallback para versões antigas (se necessário, mas você está na 0.11)
                require("lspconfig").dartls.setup(dart_opts)
            end
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