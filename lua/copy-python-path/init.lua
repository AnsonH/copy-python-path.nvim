local rooter_utils = require("copy-python-path.utils.rooter")
local python_utils = require("copy-python-path.utils.python")

local CopyPythonPath = {}

--- Gets the Python path of the symbol underneath the cursor.
---@param format string The Python path format. Accepted values are:
---  - `"dotted"`: Dotted path (e.g. `user.models.User`)
---  - `"import"`: Import statement (e.g. `from user.models import User`)
---@return string path
CopyPythonPath.get_path_under_cursor = function(format)
    local current_file_path = vim.fs.normalize(vim.fn.expand("%:p"))
    local root_dir_path = rooter_utils.find_root_dir_path(current_file_path)

    if not root_dir_path:match("/$") then
        root_dir_path = root_dir_path .. "/"
    end

    local relative_path = current_file_path:sub(#root_dir_path + 1)
    local current_file_dotted_path = relative_path:gsub("/", "."):gsub(".py$", "")

    local current_linenr = vim.api.nvim_win_get_cursor(0)[1]
    local code_till_current_line = vim.api.nvim_buf_get_lines(0, 0, current_linenr, false)

    -- Check if symbol at cursor is an import alias
    local symbol_at_cursor = vim.fn.expand("<cword>")
    if python_utils.is_valid_symbol_name(symbol_at_cursor) then
        local imported_symbols_map = python_utils.get_imported_symbols_map(code_till_current_line)
        local imported_symbol_path = imported_symbols_map[symbol_at_cursor]

        if imported_symbol_path then
            if format == "dotted" then
                return imported_symbol_path
            elseif format == "import" then
                return python_utils.make_import_statement(imported_symbol_path)
            end
        end
    end

    local symbol_chain = python_utils.get_importable_symbol_chain(code_till_current_line)

    local final_path = ""
    if format == "dotted" then
        final_path = current_file_dotted_path
        if #symbol_chain > 0 then
            final_path = final_path .. "." .. table.concat(symbol_chain, ".")
        end
    elseif format == "import" then
        final_path = "from " .. current_file_dotted_path .. " import "
        if #symbol_chain > 0 then
            final_path = final_path .. symbol_chain[1]
        end
    end

    return final_path
end

return CopyPythonPath
