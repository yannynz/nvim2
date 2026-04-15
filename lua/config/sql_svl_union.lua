local M = {}

local function normalize_clause(poliza, spto)
    return string.format("( a.num_poliza = '%s' AND A.NUM_SPTO = %s )", poliza, spto)
end

local function render_section(name, items)
    local lines = { name }

    if #items == 0 then
        lines[#lines + 1] = "-- nenhum registro encontrado"
        return lines
    end

    for index, item in ipairs(items) do
        local suffix = index < #items and " OR" or ""
        lines[#lines + 1] = item .. suffix
    end

    return lines
end

function M.collect_from_lines(lines)
    local svl_map = {
        SVL509 = {},
        SVL502 = {},
    }
    local seen = {
        SVL509 = {},
        SVL502 = {},
    }

    local current_svl = nil
    local inside_target_select = false

    for _, line in ipairs(lines) do
        if line:match("^%s*%-%-%s*SCRIPT%s+509") then
            current_svl = "SVL509"
            inside_target_select = false
        elseif line:match("^%s*%-%-%s*SCRIPT%s+502") then
            current_svl = "SVL502"
            inside_target_select = false
        elseif line:match("FOR%s+REG%s+IN%s*%(%s*SELECT%s+%*%s+FROM%s+TRON2000%.A2109406_VCR%s+A") then
            current_svl = "SVL509"
            inside_target_select = true
        elseif line:match("FOR%s+REG%s+IN%s*%(%s*SELECT%s+%*%s+FROM%s+TRON2000%.A2109435_VCR%s+A") then
            current_svl = "SVL502"
            inside_target_select = true
        elseif inside_target_select and line:match("%)%s*LOOP") then
            inside_target_select = false
        end

        if current_svl and inside_target_select then
            local poliza, spto = line:match("a%.num_poliza%s*=%s*'([^']+)'%s+and%s+a%.num_spto%s*=%s*([0-9]+)")
            if poliza and spto then
                local clause = normalize_clause(poliza, spto)
                if not seen[current_svl][clause] then
                    seen[current_svl][clause] = true
                    table.insert(svl_map[current_svl], clause)
                end
            end
        end
    end

    return svl_map
end

function M.render_lines(svl_map)
    local lines = {}

    vim.list_extend(lines, render_section("SVL509", svl_map.SVL509 or {}))
    lines[#lines + 1] = ""
    vim.list_extend(lines, render_section("SVL502", svl_map.SVL502 or {}))

    return lines
end

function M.collect_current_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return M.collect_from_lines(lines)
end

function M.open_result_buffer()
    local rendered = M.render_lines(M.collect_current_buffer())

    vim.cmd("new")

    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "sql"
    vim.api.nvim_buf_set_name(buf, "sql-svl-union")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered)
end

vim.api.nvim_create_user_command("SqlSvlUnion", function()
    M.open_result_buffer()
end, {
    desc = "Consolida filtros de SVL502 e SVL509 do buffer atual",
})

return M
