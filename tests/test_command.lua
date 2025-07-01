-- See https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/test.lua for more documentation
local Helpers = dofile("tests/helpers.lua")
local expect = Helpers.expect
local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

local EDIT_ROOT_FILE_COMMAND = "edit tests/fixtures/app.py"
local EDIT_NESTED_FILE_COMMAND = "edit tests/fixtures/user/models.py"

---@param command string Full command to execute
---@param register string Register to check
---@param test_cases table Each test case is `{ cursor_pos, expected_path }`
local function run_test_cases(command, register, test_cases)
    for _, test_case in ipairs(test_cases) do
        local cursor_pos, expected_path = test_case[1], test_case[2]

        child.api.nvim_win_set_cursor(0, cursor_pos)
        child.api.nvim_command(command)

        local dotted_path = child.fn.getreg(register)
        expect.equality(dotted_path, expected_path)
    end
end

T[":CopyPythonPath"] = MiniTest.new_set()

T[":CopyPythonPath"]["dotted"] = MiniTest.new_set()

T[":CopyPythonPath"]["dotted"]["root level Python file"] = function()
    child.api.nvim_command(EDIT_ROOT_FILE_COMMAND)
    local test_cases = {
        { { 5, 5 }, "app.func_1" },
        { { 9, 11 }, "app.func_2" },
        { { 13, 9 }, "app.MyClass" },
        { { 14, 11 }, "app.MyClass.Meta" },
        { { 17, 9 }, "app.MyClass.method_1" },
        { { 18, 9 }, "user.models.User" },
        { { 19, 16 }, "numpy" },
        { { 22, 1 }, "app.MODULE_VAR" },
        { { 6, 5 }, "app" }, -- non-importable symbol
    }
    run_test_cases("CopyPythonPath dotted a", "a", test_cases)
end

T[":CopyPythonPath"]["dotted"]["nested Python file"] = function()
    child.api.nvim_command(EDIT_NESTED_FILE_COMMAND)
    local test_cases = {
        -- Importable symbols
        { { 5, 7 }, "user.models.User" },
        { { 4, 4 }, "attrs.define" },
        -- Non-importable symbol
        { { 6, 9 }, "user.models" },
    }
    run_test_cases("CopyPythonPath dotted a", "a", test_cases)
end

T[":CopyPythonPath"]["import"] = MiniTest.new_set()

T[":CopyPythonPath"]["import"]["root level Python file"] = function()
    child.api.nvim_command(EDIT_ROOT_FILE_COMMAND)
    local test_cases = {
        { { 5, 5 }, "from app import func_1" },
        { { 9, 11 }, "from app import func_2" },
        { { 13, 9 }, "from app import MyClass" },
        { { 14, 11 }, "from app import MyClass" }, -- MyClass.Meta
        { { 17, 9 }, "from app import MyClass" }, -- MyClass.method_1
        { { 18, 9 }, "from user.models import User" },
        { { 19, 16 }, "import numpy" },
        { { 22, 1 }, "from app import MODULE_VAR" },
        { { 6, 5 }, "from app import " }, -- non-importable symbol
    }
    run_test_cases("CopyPythonPath import a", "a", test_cases)
end

T[":CopyPythonPath"]["import"]["nested Python file"] = function()
    child.api.nvim_command(EDIT_NESTED_FILE_COMMAND)
    local test_cases = {
        -- Importable symbols
        { { 5, 7 }, "from user.models import User" },
        { { 4, 4 }, "from attrs import define" },
        -- Non-importable symbol
        { { 6, 9 }, "from user.models import " },
    }
    run_test_cases("CopyPythonPath import a", "a", test_cases)
end

T[":CopyPythonPath"]["copies to clipboard if no register is provided"] = function()
    -- CI env may not have clipboard, so skipping it
    if child.fn.has("clipboard") == 0 then
        return
    end

    child.api.nvim_command(EDIT_ROOT_FILE_COMMAND)

    child.api.nvim_win_set_cursor(0, { 5, 5 })
    child.api.nvim_command("CopyPythonPath dotted")

    local dotted_path = child.fn.getreg("+")
    expect.equality(dotted_path, "app.func_1")
end

return T
