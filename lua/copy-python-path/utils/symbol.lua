local M = {}

--- Finds a symbol name that can be imported from another module from a single line of code.
---@param code string a single line of Python source code
---@return string|nil symbol the symbol name, or nil if no match
---@return string|nil indent the indentation of the statement, or nil if no match
function M.find_importable_symbol(code)
    -- module-level variables (which shouldn't have indentation)
    local module_level_var_pattern = "^([a-zA-Z_][a-zA-Z0-9_]*)%s*="
    local module_level_var = code:match(module_level_var_pattern)
    if module_level_var then
        return module_level_var, ""
    end

    -- TODO: Support `async def` definitions
    local patterns_with_indent = {
        "^(%s*)class%s+([a-zA-Z_][a-zA-Z0-9_]*)", -- class definition
        "^(%s*)def%s+([a-zA-Z_][a-zA-Z0-9_]*)", -- function definition
    }

    for _, pattern in ipairs(patterns_with_indent) do
        local indent, symbol = code:match(pattern)
        if indent and symbol then
            return symbol, indent
        end
    end

    return nil, nil
end

--- If the last line of the input lines of code contains an importable symbol, gets the
--- path for locating that symbol.
---@param lines string[] Lines of source code. Searching happens from last line
---@return string[] symbols List of symbols in hierarchical order, or empty array if no match
function M.get_importable_symbol_chain(lines)
    if #lines == 0 then
        return {}
    end

    -- Start searching from last line
    local last_line = lines[#lines]
    local symbol, indent = M.find_importable_symbol(last_line)

    if not symbol or not indent then
        return {}
    end

    local symbols = { symbol }
    local current_indent_level = #indent

    -- Walk up the indentation to find parent symbols
    for i = #lines - 1, 1, -1 do
        symbol, indent = M.find_importable_symbol(lines[i])
        if symbol and indent and #indent < current_indent_level then
            table.insert(symbols, 1, symbol)
            current_indent_level = #indent

            -- if current line has no indentation, it's no longer nested so no need to
            -- continue searching upwards
            if #indent == 0 then
                break
            end
        end
    end

    return symbols
end

return M
