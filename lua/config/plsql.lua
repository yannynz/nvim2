local M = {}

local keyword_docs = {
    ["begin"] = "Abre um bloco executavel PL/SQL.",
    ["bulk collect"] = "Carrega varias linhas em colecoes em uma unica operacao.",
    ["case"] = "Estrutura condicional por expressoes ou predicados.",
    ["cursor"] = "Cursor explicito para percorrer resultados de consulta.",
    ["declare"] = "Abre a secao de declaracao de um bloco anonimo.",
    ["elsif"] = "Ramo condicional intermediario dentro de IF.",
    ["exception"] = "Secao de tratamento de erros do bloco.",
    ["execute immediate"] = "Executa SQL ou PL/SQL dinamico.",
    ["forall"] = "Executa DML em lote sobre colecoes.",
    ["function"] = "Subprograma que retorna valor.",
    ["loop"] = "Estrutura de repeticao.",
    ["package"] = "Agrupa especificacao e implementacao de objetos PL/SQL.",
    ["pragma"] = "Diretiva para o compilador PL/SQL.",
    ["procedure"] = "Subprograma sem retorno direto.",
    ["raise"] = "Dispara uma excecao.",
    ["record"] = "Tipo composto com campos nomeados.",
    ["rowtype"] = "Tipo baseado na estrutura de uma linha de tabela ou cursor.",
    ["trigger"] = "Rotina executada por evento de banco.",
}

local definition_patterns = {
    "create%s+or%s+replace%s+package%s+body%s+([%w_$#]+)",
    "create%s+or%s+replace%s+package%s+([%w_$#]+)",
    "create%s+or%s+replace%s+procedure%s+([%w_$#]+)",
    "create%s+or%s+replace%s+function%s+([%w_$#]+)",
    "create%s+or%s+replace%s+trigger%s+([%w_$#]+)",
    "create%s+or%s+replace%s+type%s+body%s+([%w_$#]+)",
    "create%s+or%s+replace%s+type%s+([%w_$#]+)",
    "^%s*procedure%s+([%w_$#]+)",
    "^%s*function%s+([%w_$#]+)",
}

local function trim_right(line)
    return (line:gsub("%s+$", ""))
end

local function is_blank(line)
    return line:match("^%s*$") ~= nil
end

local function first_word(text)
    return text:match("^%s*([%a_]+)")
end

local function oracle_client()
    for _, candidate in ipairs({ "sql", "sqlcl", "sqlplus" }) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    return nil
end

local function project_root(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return (vim.uv or vim.loop).cwd()
    end

    local root = vim.fs.root(name, { ".git" })
    return root or vim.fs.dirname(name)
end

local function decrease_before(line)
    local upper = line:upper()

    if upper:match("^%s*END[%s;]") then
        return true
    end
    if upper:match("^%s*EXCEPTION%s*$") then
        return true
    end
    if upper:match("^%s*ELSE%s*$") then
        return true
    end
    if upper:match("^%s*ELSIF%s+") then
        return true
    end
    if upper:match("^%s*WHEN%s+.-%s+THEN%s*$") then
        return true
    end

    return false
end

local function increase_after(line)
    local upper = line:upper()

    if upper:match("^%s*DECLARE%s*$") then
        return true
    end
    if upper:match("^%s*BEGIN%s*$") then
        return true
    end
    if upper:match("^%s*EXCEPTION%s*$") then
        return true
    end
    if upper:match("^%s*ELSE%s*$") then
        return true
    end
    if upper:match("^%s*ELSIF%s+.-%s+THEN%s*$") then
        return true
    end
    if upper:match("^%s*WHEN%s+.-%s+THEN%s*$") then
        return true
    end
    if upper:match("%f[%a]LOOP%f[%A]%s*$") then
        return true
    end
    if upper:match("%f[%a]THEN%f[%A]%s*$") then
        return true
    end
    if upper:match("^%s*CASE%s+") or upper:match("^%s*CASE%s*$") then
        return not upper:match("%f[%a]END%f[%A]")
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+PACKAGE%s+BODY%s+[%w_$#]+%s+AS%s*$") then
        return true
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+PACKAGE%s+[%w_$#]+%s+AS%s*$") then
        return true
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+FUNCTION%s+[%w_$#]+") and upper:match("%s+IS%s*$") then
        return true
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+FUNCTION%s+[%w_$#]+") and upper:match("%s+AS%s*$") then
        return true
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+PROCEDURE%s+[%w_$#]+") and upper:match("%s+IS%s*$") then
        return true
    end
    if upper:match("^%s*CREATE%s+OR%s+REPLACE%s+PROCEDURE%s+[%w_$#]+") and upper:match("%s+AS%s*$") then
        return true
    end

    return false
end

local function reindent(lines, shiftwidth)
    local formatted = {}
    local indent = 0

    for _, original in ipairs(lines) do
        local line = trim_right(original)

        if is_blank(line) then
            table.insert(formatted, "")
        else
            local current = indent
            if decrease_before(line) then
                current = math.max(indent - 1, 0)
            end

            table.insert(formatted, string.rep(" ", current * shiftwidth) .. vim.trim(line))

            indent = current
            if increase_after(line) then
                indent = indent + 1
            end
        end
    end

    return formatted
end

local function gather_buffer_symbols(bufnr)
    local symbols = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for row, line in ipairs(lines) do
        local lower = line:lower()
        for _, pattern in ipairs(definition_patterns) do
            local name = lower:match(pattern)
            if name then
                table.insert(symbols, {
                    name = name,
                    bufnr = bufnr,
                    lnum = row,
                    text = line,
                })
            end
        end
    end

    return symbols
end

local function find_local_definition(bufnr, target)
    for _, item in ipairs(gather_buffer_symbols(bufnr)) do
        if item.name == target then
            return item
        end
    end
    return nil
end

local function fill_quickfix(items, title)
    vim.fn.setqflist({}, " ", {
        title = title,
        items = items,
    })
    vim.cmd("copen")
end

function M.format_current_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    if ft ~= "plsql" and ft ~= "sql" then
        vim.cmd("normal! gg=G")
        return
    end

    local view = vim.fn.winsaveview()
    local shiftwidth = vim.bo[bufnr].shiftwidth > 0 and vim.bo[bufnr].shiftwidth or vim.o.shiftwidth
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local formatted = reindent(lines, shiftwidth)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
    vim.fn.winrestview(view)
end

function M.show_hover()
    local cword = vim.fn.expand("<cword>")
    if cword == "" then
        return
    end

    local lower = cword:lower()
    local doc = keyword_docs[lower]

    if not doc then
        vim.notify("Sem documentacao local para '" .. cword .. "'.", vim.log.levels.INFO)
        return
    end

    vim.lsp.util.open_floating_preview({ cword:upper() .. " - " .. doc }, "markdown", {
        border = "rounded",
    })
end

function M.goto_definition()
    local bufnr = vim.api.nvim_get_current_buf()
    local target = vim.fn.expand("<cword>"):lower()
    if target == "" then
        return
    end

    local local_hit = find_local_definition(bufnr, target)
    if local_hit then
        vim.api.nvim_win_set_cursor(0, { local_hit.lnum, 0 })
        return
    end

    local root = project_root(bufnr)
    local globs = { "*.sql", "*.pls", "*.plb", "*.pks", "*.pkb", "*.prc", "*.fnc", "*.trg", "*.tps", "*.tpb" }
    local pattern = table.concat({
        [[\bcreate\s+or\s+replace\s+(package\s+body|package|procedure|function|trigger|type\s+body|type)\s+]],
        vim.fn.escape(target, [[\]]),
        [[\b|\b(procedure|function)\s+]],
        vim.fn.escape(target, [[\]]),
        [[\b]],
    })

    local cmd = { "rg", "-n", "-i", "-e", pattern }
    for _, glob in ipairs(globs) do
        table.insert(cmd, "-g")
        table.insert(cmd, glob)
    end
    table.insert(cmd, root)

    local result = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or #result == 0 then
        vim.notify("Definicao de '" .. target .. "' nao encontrada.", vim.log.levels.WARN)
        return
    end

    local items = {}
    for _, line in ipairs(result) do
        local path, lnum, text = line:match("^(.+):(%d+):(.*)$")
        if path and lnum and text then
            table.insert(items, {
                filename = path,
                lnum = tonumber(lnum),
                col = 1,
                text = text,
            })
        end
    end

    if #items == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(items[1].filename))
        vim.api.nvim_win_set_cursor(0, { items[1].lnum, 0 })
        return
    end

    fill_quickfix(items, "PL/SQL definitions: " .. target)
end

function M.check_current_buffer()
    local client = oracle_client()
    if not client then
        vim.notify("Nenhum cliente Oracle encontrado. Use sql, sqlcl ou sqlplus no PATH.", vim.log.levels.WARN)
        return
    end

    local conn = vim.env.PLSQL_CONNECT_STRING or vim.env.ORACLE_CONNECT_STRING
    if not conn or conn == "" then
        vim.notify(
            "Defina PLSQL_CONNECT_STRING ou ORACLE_CONNECT_STRING para validar via " .. client .. ".",
            vim.log.levels.WARN
        )
        return
    end

    local source = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local temp = vim.fn.tempname() .. ".sql"
    vim.fn.writefile(vim.split(source, "\n", { plain = true }), temp)

    local script = table.concat({
        "set echo off feedback off heading off pagesize 0 verify off serveroutput off",
        "whenever sqlerror continue",
        "@" .. temp,
        "show errors",
        "exit",
        "",
    }, "\n")

    local output = vim.fn.system({ client, "-s", conn }, script)
    vim.fn.delete(temp)

    local items = {}
    for _, line in ipairs(vim.split(output or "", "\n", { trimempty = true })) do
        local lnum, text = line:match("^LINE/COL%s+(%d+)/%d+%s+(.*)$")
        if lnum and text then
            table.insert(items, {
                bufnr = 0,
                lnum = tonumber(lnum),
                col = 1,
                text = text,
            })
        elseif line:match("ORA%-%d+") or line:match("PLS%-%d+") or line:match("SP2%-%d+") then
            table.insert(items, {
                bufnr = 0,
                lnum = 1,
                col = 1,
                text = line,
            })
        end
    end

    if #items == 0 then
        vim.notify("Nenhum erro retornado pelo " .. client .. ".", vim.log.levels.INFO)
        vim.fn.setqflist({})
        return
    end

    fill_quickfix(items, "PL/SQL check")
end

function M.setup_buffer(bufnr)
    vim.bo[bufnr].commentstring = "-- %s"
    vim.bo[bufnr].comments = ":--"
    vim.bo[bufnr].suffixesadd = ".sql,.pls,.plb,.pks,.pkb,.prc,.fnc,.trg,.tps,.tpb"
    vim.bo[bufnr].omnifunc = "syntaxcomplete#Complete"
    vim.bo[bufnr].iskeyword = vim.bo[bufnr].iskeyword .. ",#,$"

    local opts = { buffer = bufnr, silent = true, noremap = true }
    vim.keymap.set("n", "gd", M.goto_definition, opts)
    vim.keymap.set("n", "gH", M.show_hover, opts)
    vim.keymap.set("n", "<leader>f", M.format_current_buffer, opts)
    vim.keymap.set("n", "<leader>pc", M.check_current_buffer, vim.tbl_extend("force", opts, { desc = "PL/SQL Check" }))
end

function M.setup()
    vim.filetype.add({
        extension = {
            fnc = "plsql",
            pkb = "plsql",
            pks = "plsql",
            plb = "plsql",
            pls = "plsql",
            prc = "plsql",
            tpb = "plsql",
            tps = "plsql",
            trg = "plsql",
        },
    })

    local group = vim.api.nvim_create_augroup("UserPlsql", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = group,
        pattern = "*.sql",
        callback = function(args)
            local lines = vim.api.nvim_buf_get_lines(args.buf, 0, math.min(40, vim.api.nvim_buf_line_count(args.buf)), false)
            local sample = table.concat(lines, "\n"):lower()
            if sample:match("create%s+or%s+replace%s+package")
                or sample:match("create%s+or%s+replace%s+procedure")
                or sample:match("create%s+or%s+replace%s+function")
                or sample:match("create%s+or%s+replace%s+trigger")
                or sample:match("^%s*declare%s")
            then
                vim.bo[args.buf].filetype = "plsql"
            end
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "plsql", "sql" },
        callback = function(args)
            M.setup_buffer(args.buf)
        end,
    })

    vim.api.nvim_create_user_command("PlsqlFormat", function()
        M.format_current_buffer()
    end, { desc = "Formata o buffer PL/SQL atual" })

    vim.api.nvim_create_user_command("PlsqlCheck", function()
        M.check_current_buffer()
    end, { desc = "Valida o buffer atual via sql/sqlcl/sqlplus" })

    vim.api.nvim_create_user_command("PlsqlDefinition", function()
        M.goto_definition()
    end, { desc = "Procura a definicao do simbolo atual" })
end

M.setup()

return M
