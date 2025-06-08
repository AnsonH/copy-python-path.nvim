-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.CopyPythonPathLoaded then
    return
end

_G.CopyPythonPathLoaded = true

-- Useful if you want your plugin to be compatible with older (<0.7) neovim versions
if vim.fn.has("nvim-0.7") == 0 then
    vim.cmd("command! CopyPythonPath lua require('copy-python-path').toggle()")
else
    vim.api.nvim_create_user_command("CopyPythonPath", function()
        require("copy-python-path").toggle()
    end, {})
end
