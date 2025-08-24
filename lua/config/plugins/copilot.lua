return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },         -- sem painel
      suggestion = {
        enabled = true,                    -- <- liga o ghost text
        auto_trigger = true,               -- sugere automaticamente
        hide_during_completion = true,     -- some quando o menu do cmp abre
        keymap = {                         -- mapeamentos; use os que preferir
          accept = "<Tab>",                -- aceitar sugestão
          next = "<M-]>",                  -- próxima sugestão
          prev = "<M-[>",                  -- anterior
          dismiss = "<C-]>",               -- dispensar
        },
      },
      filetypes = { ["*"] = true },        -- habilita em todos os tipos de arquivo
    },
    config = function(_, opts)
      require("copilot").setup(opts)

      -- Opcional: esconder ghost text quando o menu do cmp abrir/fechar
      -- (trecho sugerido pelo README do copilot.lua)
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.event:on("menu_opened", function() vim.b.copilot_suggestion_hidden = true end)
        cmp.event:on("menu_closed", function() vim.b.copilot_suggestion_hidden = false end)
      end

      -- Atalho para ligar/desligar auto_trigger no buffer atual
      vim.keymap.set("n", "<leader>ca", function()
        require("copilot.suggestion").toggle_auto_trigger()
      end, { desc = "Copilot: toggle auto trigger" })
    end,
  },
}

