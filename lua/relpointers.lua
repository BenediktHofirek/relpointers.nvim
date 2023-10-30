local M = {}

local config = {
    amount = 20,
    distance = 4,

    hl_properties = { underline = true },

    pointer_style = "virtual",

    enable_autocmd = true,
    autocmd_pattern = "*",

    white_space_rendering = "\t\t\t\t\t",
}

M.setup = function(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    if (config.enable_autocmd) then
        -- autogroup
        local group = vim.api.nvim_create_augroup("Relative", { clear = true })
        -- autocmd
        autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = group,
            pattern = config.autocmd_pattern,
            callback = M.start,
        })
    end
end

local function render_pointers_match(buf_nr, namespace, line_nr)
    vim.fn.matchaddpos("RelPointersHl", { line_nr })

    local line_content = vim.api.nvim_buf_get_lines(buf_nr, line_nr - 1, line_nr, false)
    local pointer_text = line_content[1]

    if (pointer_text == "") then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0,
            {
                virt_text_pos = "overlay",
                virt_text = { { config.white_space_rendering, "RelPointersHL" } },
                virt_text_win_col = 0
            })
    end
end

local function render_pointers_virt(buf_nr, namespace, line_nr)
    local virtual_text = { { line_nr, "RelPointersHL", } }

    if (line_nr <= vim.fn.line("$")) then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, -1,
            { virt_text_pos = "overlay", virt_text = virtual_text })
    end
end

local function render_pointers_column(buf_nr, namespace, line_nr)
    local virtual_text = { { " ", "RelPointersHL", } }
    local line_content = vim.fn.getline(line_nr)
    local cursor_position = vim.fn.getcurpos()[3]

    if (line_content ~= "") then
        vim.fn.matchaddpos("RelPointersHL", { { line_nr, cursor_position, 1 } })
        if (#line_content < cursor_position) then
            vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0,
                { virt_text_pos = "overlay", virt_text = virtual_text, virt_text_win_col = cursor_position - 1 })
        end
    elseif (line_nr <= vim.fn.line("$")) then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0,
            { virt_text_pos = "overlay", virt_text = virtual_text, virt_text_win_col = cursor_position - 1 })
    end
end

local function define_positions(line_nr, buf_nr, namespace, direction)
    local amount = config.amount
    local distance = config.distance

    local offset = line_nr + (direction * (amount * distance))

    for i = line_nr + (direction * distance), offset, (direction * distance) do
        if (i > 0) then
            if (config.pointer_style == "line region") then
                render_pointers_match(buf_nr, namespace, i)
            elseif (config.pointer_style == "virtual") then
                render_pointers_virt(buf_nr, namespace, i)
            elseif (config.pointer_style == "column") then
                render_pointers_column(buf_nr, namespace, i)
            end
        end
    end
end

M.start = function()
    -- highlight group
    vim.api.nvim_set_hl(0, "RelPointersHl", config.hl_properties)

    local buf_nr = vim.api.nvim_get_current_buf()
    local line_nr = vim.fn.line(".")
    local namespace = vim.api.nvim_create_namespace("relpointers")

    -- clearing
    vim.fn.clearmatches()
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

    -- below cursor
    define_positions(line_nr, buf_nr, namespace, 1)
    -- above cursor
    define_positions(line_nr, buf_nr, namespace, -1)
end

-- disable plugin
M.disable = function()
    vim.api.nvim_del_autocmd(autocmd_id)
    local namespaces = vim.api.nvim_get_namespaces()
    local namespace = namespaces["relpointers"]
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    vim.fn.clearmatches()
end

return M
