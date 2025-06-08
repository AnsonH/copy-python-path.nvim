local log = require("copy-python-path.util.log")

local CopyPythonPath = {}

--- CopyPythonPath configuration with its default values.
---
---@type table
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
CopyPythonPath.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
}

---@private
local defaults = vim.deepcopy(CopyPythonPath.options)

--- Defaults CopyPythonPath options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |CopyPythonPath.options|.
---
---@private
function CopyPythonPath.defaults(options)
    CopyPythonPath.options =
        vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

    -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
    assert(
        type(CopyPythonPath.options.debug) == "boolean",
        "`debug` must be a boolean (`true` or `false`)."
    )

    return CopyPythonPath.options
end

--- Define your copy-python-path setup.
---
---@param options table Module config table. See |CopyPythonPath.options|.
---
---@usage `require("copy-python-path").setup()` (add `{}` with your |CopyPythonPath.options| table)
function CopyPythonPath.setup(options)
    CopyPythonPath.options = CopyPythonPath.defaults(options or {})

    log.warn_deprecation(CopyPythonPath.options)

    return CopyPythonPath.options
end

return CopyPythonPath
