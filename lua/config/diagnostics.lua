-- lua/config/diagnostics.lua
local function apply_global()
  vim.diagnostic.config({
    virtual_lines = true,   -- mensagens entre as linhas
    virtual_text  = false,  -- não mostrar no fim da linha (evita duplicar)
    signs = true,
    underline = true,
    severity_sort = true,
    update_in_insert = false,
  })
end

apply_global()

-- Reaplica por buffer quando um LSP anexar (caso algo tenha mudado)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("YNZ_Diagnostics", { clear = true }),
  callback = function(args)
    vim.diagnostic.config({
      virtual_lines = true,
      virtual_text  = false,
    }, args.buf)
  end,
})

