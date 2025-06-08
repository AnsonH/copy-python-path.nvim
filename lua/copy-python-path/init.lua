local utils = require("copy-python-path.utils")

local M = {}

function M.copy_dotted_path()
    -- TODO: Early return if not `*.py` file

    local current_file_path = vim.fs.normalize(vim.fn.expand("%:p"))

    -- TODO: Use a more robust method to get root path
    local root_path = vim.fs.root(current_file_path, ".git")

    if root_path == nil then
        -- TODO: Obtain root path in another method
        return
    end

    if not root_path:match("/$") then
        root_path = root_path .. "/"
    end

    local relative_path = current_file_path:sub(#root_path + 1)
    local current_file_dotted_path = relative_path:gsub("/", "."):gsub(".py$", "")

    -- TODO: Check if symbol at cursor is an import alias
    -- local symbol_at_cursor = vim.fn.expand("<cword>")

    local current_linenr = vim.api.nvim_win_get_cursor(0)[1]
    local code_till_current_line = vim.api.nvim_buf_get_lines(0, 0, current_linenr, false)
    local symbol_chain = utils.get_importable_symbol_chain(code_till_current_line)

    local final_path = current_file_dotted_path
    if #symbol_chain then
        final_path = final_path .. "." .. table.concat(symbol_chain, ".")
    end

    vim.print(final_path)
end

return M
