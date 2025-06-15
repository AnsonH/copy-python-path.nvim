local M = {}

--- Checks if an input string is a valid Python identifier.
---@param input string
function M.is_valid_symbol_name(input)
    return input:match("^[a-zA-Z_][a-zA-Z0-9_]*$") ~= nil
end

--- Splits a string by separator
---@param input string
---@param separator string
---@return string[]
function M.split_string(input, separator)
    local t = {}
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end
    if #t == 0 then
        table.insert(t, "")
    end
    return t
end

--- Removes whitespace from both ends of the string.
---@param input string
---@return string
function M.trim_string(input)
    return input:match("^%s*(.-)%s*$")
end

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

--- Parses a segment of a Python import statement to get the original name of the imported symbol
--- and its alias name (if any).
---@param import_str string Import string segment (e.g. `numpy`, `numpy as np`, `some.path`, `*`)
---@return string|nil original_symbol, string|nil alias_symbol
function M.parse_import_symbol(import_str)
    local original_symbol, alias_symbol = import_str:match("^([%w_%.]+)%s+as%s+([%w_]+)$")
    if original_symbol and alias_symbol then
        return original_symbol, alias_symbol
    end

    original_symbol = import_str:match("^([%w_%.]+)$")
    return original_symbol, nil
end

--- Creates a map of imported symbols to their full dotted paths.
---
--- Types of supported import symbols:
--- 1. From-imports without alias: `from X import Y, Z`
--- 2. From-imports with alias: `from X import Y as YAlias`
--- 3. Import without alias: `import numpy, pandas`
--- 4. Import with alias: `import numpy as np, user.constants as user_constants`
---
--- NOTE: For (3), we ignore the path if it contains dot(s) (e.g. `import user.services`).
--- This is because it won't create a new symbol where the name equals the word behind the last dot.
--- For example, we still need to reference symbols via `user.services.xxx`, not `services`.
---
---@param lines string[] Lines of source code. Searching happens from last line
---@return table<string, string> symbols_map A map of the symbol name to its dotted path
function M.get_imported_symbols_map(lines)
    ---@type table<string, string>
    local symbols_map = {}

    --- For `from A import B, ...`
    local from_import_pattern = "^%s*from%s+([%w%._]+)%s+import%s+(.+)%s*$"

    --- For `import A, B, ...`
    local import_pattern = "^%s*import%s+(.+)%s*$"

    for _, line in ipairs(lines) do
        local from_import_module, from_import_symbols_str = line:match(from_import_pattern)
        if from_import_module and from_import_symbols_str then
            local import_symbol_strings =
                vim.tbl_map(M.trim_string, M.split_string(from_import_symbols_str, ","))

            for _, symbol_str in ipairs(import_symbol_strings) do
                local original_symbol, alias_symbol = M.parse_import_symbol(symbol_str)
                local name = alias_symbol or original_symbol -- Use the original name if no alias
                if name then
                    local path = from_import_module .. "." .. original_symbol
                    symbols_map[name] = path
                end
            end
        end

        local import_symbols_str = line:match(import_pattern)
        if import_symbols_str then
            local import_symbol_strings =
                vim.tbl_map(M.trim_string, M.split_string(import_symbols_str, ","))

            for _, symbol_str in ipairs(import_symbol_strings) do
                local path, alias_symbol = M.parse_import_symbol(symbol_str)

                if alias_symbol then
                    symbols_map[alias_symbol] = path
                elseif path and path:find("%.") == nil then
                    symbols_map[path] = path
                end
            end
        end
    end

    return symbols_map
end

--- Generates an import statement from a symbol's dotted path. Examples:
--- - `"numpy"` -> `"import numpy"`
--- - `"some.module.foo"` -> `"from some.module import foo"`
---@param dotted_path string Dotted path of a symbol (e.g. `some.module.Symbol`)
---@return string
function M.make_import_statement(dotted_path)
    local last_dot_index = dotted_path:find("%.[^%.]*$")

    if last_dot_index then
        local module_path = dotted_path:sub(1, last_dot_index - 1)
        local symbol_name = dotted_path:sub(last_dot_index + 1)
        return "from " .. module_path .. " import " .. symbol_name
    end

    return "import " .. dotted_path
end

return M
