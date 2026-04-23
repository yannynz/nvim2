local M = {}

local analyst_aliases = {
    EMPURRADOR = "EMPURRADOR",
    YANN = "Yann",
    NATTACHA = "NATTACHA",
    OPERACOESPEND = "OPERACOES-PEND",
    JOCELIOPEND = "JocelioPend",
}

local function default_project_root()
    local env_root = vim.env.FERRAMENTAS_SQL_ROOT
    if env_root and env_root ~= "" then
        return env_root
    end

    local home = vim.uv.os_homedir()
    return home .. "/Documents/ferramentasSql"
end

local function normalize_space(value)
    local normalized = (value or ""):gsub("\194\160", " "):gsub("&nbsp;", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return normalized
end

local function normalize_analyst_name(value)
    local cleaned = normalize_space(value):gsub("_", "-")
    if cleaned == "" then
        return "SEM_ANALISTA"
    end

    local alias_key = cleaned:upper():gsub("[^A-Z0-9]+", "")
    return analyst_aliases[alias_key] or cleaned
end

local function extract_cells(row_html)
    local cells = {}
    for cell in row_html:gmatch("<T[DdHh][^>]*>(.-)</T[DdHh]>") do
        local plain_cell = cell:gsub("<[^>]+>", "")
        table.insert(cells, normalize_space(plain_cell))
    end
    return cells
end

local function parse_html_text(text)
    local rows_by_analyst = {}
    local current_policies = {}

    for row_html in text:gmatch("<[Tt][Rr][^>]*>(.-)</[Tt][Rr]>") do
        local cells = extract_cells(row_html)
        if #cells >= 16 and cells[1] ~= "TIPO_SVL" then
            local analyst = normalize_analyst_name(cells[16])
            rows_by_analyst[analyst] = rows_by_analyst[analyst] or {}
            rows_by_analyst[analyst][cells[5]] = true
            current_policies[cells[5]] = true
        end
    end

    return rows_by_analyst, current_policies
end

local function sorted_keys(map)
    local keys = {}
    for key in pairs(map) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function find_latest_html(errors_dir)
    local html_paths = vim.fn.glob(errors_dir .. "/erros*.html", false, true)
    table.sort(html_paths)
    return html_paths[#html_paths]
end

local function today_token()
    return os.date("%d%m%y")
end

local function token_from_path(path)
    return path:match("(%d%d%d%d%d%d)%.html$")
end

local function normalize_date_token(raw)
    if not raw or raw == "" then
        return today_token()
    end

    local digits = raw:gsub("%D", "")
    if #digits == 8 then
        return digits:sub(1, 2) .. digits:sub(3, 4) .. digits:sub(7, 8)
    end
    if #digits == 6 then
        return digits
    end
    return nil
end

local function resolve_html_path(project_root, requested_token)
    local errors_dir = project_root .. "/dados/errosDiariosHtml"
    local token = normalize_date_token(requested_token)
    if not token then
        return nil, "data invalida; use DDMMYY ou DD/MM/YYYY"
    end

    local exact_path = errors_dir .. "/erros" .. token .. ".html"
    if vim.uv.fs_stat(exact_path) then
        return exact_path, nil
    end

    return nil, "HTML de erros nao encontrado para a data " .. token
end

local function collect_sql_paths(project_root, html_path)
    local query_paths = vim.fn.glob(project_root .. "/consultas/lotesDiarios/query*.sql", false, true)
    local extra_sql_paths = vim.fn.glob(project_root .. "/dados/errosDiariosHtml/inserts*.sql", false, true)
    local seen = {}
    local all_paths = {}

    local function append_unique(paths)
        for _, path in ipairs(paths) do
            if not seen[path] then
                seen[path] = true
                table.insert(all_paths, path)
            end
        end
    end

    append_unique(query_paths)
    append_unique(extra_sql_paths)

    local token = token_from_path(html_path)
    if token then
        append_unique(vim.fn.glob(project_root .. "/dados/errosDiariosHtml/*" .. token .. "*.sql", false, true))
    end

    table.sort(all_paths)
    return all_paths
end

local function file_contains_sql_analyst(text)
    local analysts = {}
    if text:find("NSSOLIVE", 1, true) then
        analysts["Yann"] = true
    end
    if text:find("YSANTANA", 1, true) then
        analysts["NATTACHA"] = true
    end
    return analysts
end

local function policies_present_in_sql(sql_paths, current_policies)
    local in_sql = {}

    for _, path in ipairs(sql_paths) do
        local ok, lines = pcall(vim.fn.readfile, path)
        if ok then
            local text = table.concat(lines, "\n")
            local _sql_analysts = file_contains_sql_analyst(text)
            for policy in text:gmatch("'(%d%d%d%d%d%d%d%d%d%d%d%d%d?)'") do
                if current_policies[policy] then
                    in_sql[policy] = true
                end
            end
        end
    end

    return in_sql
end

local function render_lines(html_path, rows_by_analyst, policies_in_sql)
    local lines = {
        "BASE_HTML: " .. vim.fn.fnamemodify(html_path, ":t"),
        "",
    }

    for _, analyst in ipairs(sorted_keys(rows_by_analyst)) do
        table.insert(lines, "ANALISTA: " .. analyst)

        local policy_keys = sorted_keys(rows_by_analyst[analyst])
        for _, policy in ipairs(policy_keys) do
            if policies_in_sql[policy] then
                table.insert(lines, string.format("'%s',", policy))
            else
                table.insert(lines, string.format("'%s', -- OBS: marcada no HTML, mas nao encontrada em nenhum .sql", policy))
            end
        end

        table.insert(lines, "")
    end

    return lines
end

function M.build_report()
    return M.build_report_for_date(nil)
end

function M.build_report_for_date(requested_token)
    local project_root = default_project_root()
    local html_path, err = resolve_html_path(project_root, requested_token)
    if not html_path or html_path == "" then
        return { "-- " .. (err or "nenhum HTML de erros encontrado") }
    end

    local html_lines = vim.fn.readfile(html_path)
    local rows_by_analyst, current_policies = parse_html_text(table.concat(html_lines, "\n"))
    local sql_paths = collect_sql_paths(project_root, html_path)
    local policies_in_sql = policies_present_in_sql(sql_paths, current_policies)

    return render_lines(html_path, rows_by_analyst, policies_in_sql)
end

function M.open_result_buffer(requested_token)
    local rendered = M.build_report_for_date(requested_token)

    vim.cmd("new")

    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "text"
    vim.api.nvim_buf_set_name(buf, "sql-apolices-analista")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered)
end

vim.api.nvim_create_user_command("SqlApolicesAnalista", function(opts)
    local requested_token = opts.args ~= "" and opts.args or nil
    M.open_result_buffer(requested_token)
end, {
    nargs = "?",
    desc = "Lista apolices por analista por data (padrao: hoje, formato DDMMYY ou DD/MM/YYYY)",
})

return M
