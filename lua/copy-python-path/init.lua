--- TODO: Add docs here

local rooter_utils = require("copy-python-path.utils.rooter")
local symbol_utils = require("copy-python-path.utils.symbol")

local M = {}

--- Supported Python path formats.
---@alias Format
---| '"dotted"' # Dotted path (e.g. `user.models.User`)
---| '"import"' # Import statement (e.g. `from user.models import User`)

--- Gets the Python path of the symbol underneath the cursor.
---@param format Format The Python path format.
---@return string
function M.get_path(format)
    -- TODO: Early return if not `*.py` file

    local current_file_path = vim.fs.normalize(vim.fn.expand("%:p"))
    local root_dir_path = rooter_utils.find_root_dir_path(current_file_path)

    if not root_dir_path:match("/$") then
        root_dir_path = root_dir_path .. "/"
    end

    local relative_path = current_file_path:sub(#root_dir_path + 1)
    local current_file_dotted_path = relative_path:gsub("/", "."):gsub(".py$", "")

    -- TODO: Check if symbol at cursor is an import alias
    -- local symbol_at_cursor = vim.fn.expand("<cword>")

    local current_linenr = vim.api.nvim_win_get_cursor(0)[1]
    local code_till_current_line = vim.api.nvim_buf_get_lines(0, 0, current_linenr, false)
    local symbol_chain = symbol_utils.get_importable_symbol_chain(code_till_current_line)

    local final_path = current_file_dotted_path
    if #symbol_chain then
        final_path = final_path .. "." .. table.concat(symbol_chain, ".")
    end

    return final_path
end

return M
