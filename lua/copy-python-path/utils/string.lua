local M = {}

--- Splits a string by separator
---@param input string
---@param separator string
---@return string[]
M.split_string = function(input, separator)
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
M.trim_string = function(input)
    return input:match("^%s*(.-)%s*$")
end

return M
