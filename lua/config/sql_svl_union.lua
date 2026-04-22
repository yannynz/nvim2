local M = {}
local svl_order = { "SVL502", "SVL503", "SVL505", "SVL509" }
local svl_tables = {
    SVL502 = "tron2000.a2109435_vcr",
    SVL503 = "tron2000.a2109393_vcr",
    SVL505 = "tron2000.a2109457_vcr",
    SVL509 = "tron2000.a2109406_vcr",
}

local function normalize_clause(poliza, spto)
    return string.format("( a.num_poliza = '%s' AND A.NUM_SPTO = %s )", poliza, spto)
end

local function add_clause(svl_map, seen, svl_name, poliza, spto)
    if not svl_name or not poliza or not spto then
        return
    end

    local clause = normalize_clause(poliza, spto)
    if not seen[svl_name][clause] then
        seen[svl_name][clause] = true
        table.insert(svl_map[svl_name], clause)
    end
end

local function process_block(block_lines, svl_map, seen)
    local text = table.concat(block_lines, "\n")
    local lower_text = text:lower()
    local targets = {}

    for svl_name, table_name in pairs(svl_tables) do
        if lower_text:find(table_name, 1, true) then
            targets[#targets + 1] = svl_name
        end
    end

    if #targets == 0 then
        return
    end

    for _, line in ipairs(block_lines) do
        local lower_line = line:lower()
        local poliza, spto = lower_line:match("num_poliza%s*=%s*'([^']+)'%s*and%s*[%a_][%w_]*%.?num_spto%s*=%s*([0-9]+)")

        if not poliza or not spto then
            poliza, spto = lower_line:match("num_poliza%s*=%s*'([^']+)'%s*and%s*num_spto%s*=%s*([0-9]+)")
        end

        if poliza and spto then
            for _, target in ipairs(targets) do
                add_clause(svl_map, seen, target, poliza, spto)
            end
        end
    end
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
    local svl_map = {}
    local seen = {}

    for _, svl_name in ipairs(svl_order) do
        svl_map[svl_name] = {}
        seen[svl_name] = {}
    end

    local block_lines = {}
    local block_depth = 0

    for _, line in ipairs(lines) do
        local lower_line = line:lower()
        local begin_count = 0
        local end_count = 0

        for _ in lower_line:gmatch("%f[%a]begin%f[%A]") do
            begin_count = begin_count + 1
        end
        for _ in lower_line:gmatch("%f[%a]end%f[%A]%s*;") do
            end_count = end_count + 1
        end

        if begin_count > 0 and block_depth == 0 then
            block_lines = {}
        end

        if block_depth > 0 or begin_count > 0 then
            block_lines[#block_lines + 1] = line
        end

        block_depth = block_depth + begin_count - end_count

        if block_depth == 0 and #block_lines > 0 then
            process_block(block_lines, svl_map, seen)
            block_lines = {}
        end
    end

    return svl_map
end

function M.render_lines(svl_map)
    local lines = {}

    for index, svl_name in ipairs(svl_order) do
        vim.list_extend(lines, render_section(svl_name, svl_map[svl_name] or {}))
        if index < #svl_order then
            lines[#lines + 1] = ""
        end
    end

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
    desc = "Consolida filtros de SVL502, SVL503, SVL505 e SVL509 do buffer atual",
})

return M
