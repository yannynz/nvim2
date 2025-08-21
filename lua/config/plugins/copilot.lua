return {
  -- Copilot oficial
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "BufWinEnter",
    init = function()
      -- evita que o plugin crie mapeamentos próprios (Tab, etc.)
      vim.g.copilot_no_maps = true
    end,
    config = function()
      -- bloqueia o ghost text/painel padrão (vamos usar só o blink)
      vim.api.nvim_create_augroup("github_copilot", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
        group = "github_copilot",
        callback = function(args)
          vim.fn["copilot#On" .. args.event]()
        end,
      })
      vim.fn["copilot#OnFileType"]()
    end,
  },

  -- Fonte do Copilot pro blink
  {
    "saghen/blink.cmp",
    dependencies = { "fang2hou/blink-copilot" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      local def = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      table.insert(def, 1, "copilot")
      opts.sources.default = def
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        copilot = { name = "copilot", module = "blink-copilot", async = true, score_offset = 100 },
      })
    end,
  },
}

