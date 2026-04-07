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
      -- usa <Tab> para aceitar apenas quando existir sugestão do Copilot
      vim.keymap.set("i", "<Tab>", function()
        local ok, cmp = pcall(require, "blink.cmp")
        if ok and cmp.snippet_active({ direction = 1 }) then
          cmp.snippet_forward()
          return ""
        end

        local has_suggestion = false
        local ok_suggestion, suggestion = pcall(vim.fn["copilot#GetDisplayedSuggestion"])
        if ok_suggestion and suggestion and type(suggestion) == "table" then
          has_suggestion = suggestion.text and suggestion.text ~= ""
        end

        if has_suggestion then
          return vim.fn["copilot#Accept"]("")
        end

        return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
      end, { expr = true, silent = true, replace_keycodes = false, desc = "Copilot: aceitar sugestão" })

      -- garante que o Copilot esteja ativo quando entrar em um buffer
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("github_copilot_activate", { clear = true }),
        callback = function()
          vim.cmd("silent! Copilot enable")
        end,
      })
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
