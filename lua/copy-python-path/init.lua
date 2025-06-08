local main = require("copy-python-path.main")
local config = require("copy-python-path.config")

local CopyPythonPath = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function CopyPythonPath.toggle()
    if _G.CopyPythonPath.config == nil then
        _G.CopyPythonPath.config = config.options
    end

    main.toggle("public_api_toggle")
end

--- Initializes the plugin, sets event listeners and internal state.
function CopyPythonPath.enable(scope)
    if _G.CopyPythonPath.config == nil then
        _G.CopyPythonPath.config = config.options
    end

    main.toggle(scope or "public_api_enable")
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function CopyPythonPath.disable()
    main.toggle("public_api_disable")
end

-- setup CopyPythonPath options and merge them with user provided ones.
function CopyPythonPath.setup(opts)
    _G.CopyPythonPath.config = config.setup(opts)
end

_G.CopyPythonPath = CopyPythonPath

return _G.CopyPythonPath
