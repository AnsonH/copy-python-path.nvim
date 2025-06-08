local M = {}

--- Finds a symbol name that can be imported from another module from a single line of code.
---@param code string a single line of Python source code
---@return string|nil symbol the symbol name, or nil if no match
---@return string|nil indent the indentation of the statement, or nil if no match
function M.find_importable_symbol(code)
    -- module-level variables (which has zero indentation)
    module_level_var_pattern = "^([a-zA-Z_][a-zA-Z0-9_]*)%s*="
    local symbol = code:match(module_level_var_pattern)
    if symbol then
        return symbol, ""
    end

    -- TODO: Support `async def` definitions
    local patterns_with_indent = {
        "^(%s*)class%s+([a-zA-Z_][a-zA-Z0-9_]*)", -- class definition
        "^(%s*)def%s+([a-zA-Z_][a-zA-Z0-9_]*)",   -- function definition
    }

    for _, pattern in ipairs(patterns_with_indent) do
        local indent, symbol = code:match(pattern)
        if indent and symbol then
            return symbol, indent
        end
    end

    return nil, nil
end

return M
