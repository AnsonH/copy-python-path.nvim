vim.api.nvim_create_user_command("CopyPythonPath", function(opts)
    local copy_python_path = require("copy-python-path")
    local fargs = opts.fargs

    if vim.fn.expand("%"):match(".py$") == nil then
        vim.notify("CopyPythonPath: Current file is not a Python file.", vim.log.levels.ERROR)
        return
    end

    ---@type Format
    local format = fargs[1]
    if not format or (format ~= "dotted" and format ~= "import") then
        vim.notify("CopyPythonPath: Unknown command '" .. format .. "'.", vim.log.levels.ERROR)
        return
    end

    --- Register to copy to. Defaults to system clipboard.
    ---@type string
    local register = fargs[2] or "+"

    local python_path = copy_python_path.get_path_under_cursor(format)
    vim.fn.setreg(register, python_path)

    local register_name = register == "+" and "clipboard" or ("register '" .. register .. "'")
    local notify_msg = "CopyPythonPath: Copied to " .. register_name .. ": " .. python_path
    vim.notify(notify_msg)
end, {
    nargs = "+",
    desc = "Copy Python path of the symbol under the cursor",
    complete = function(arg_lead, cmdline, _)
        -- Provide completion for first argument
        if cmdline:match("^CopyPythonPath%s+%w*$") then
            return vim.tbl_filter(function(val)
                return val:match("^" .. arg_lead)
            end, { "dotted", "import" })
        end
        return {}
    end,
})
