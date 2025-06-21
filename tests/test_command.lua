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

local EDIT_ROOT_FILE_COMMAND = "edit tests/fixtures/root.py"
local EDIT_NESTED_FILE_COMMAND = "edit tests/fixtures/layer_one/layer_two/services.py"

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
        -- Importable symbols
        { { 5, 5 },   "root.func" },
        { { 9, 16 },  "root.async_func" },
        { { 13, 7 },  "root.OuterClass" },
        { { 18, 13 }, "root.OuterClass.InnerClass.inner_class_method" },
        { { 22, 10 }, "root.MODULE_LEVEL_CONSTANT" },
        { { 15, 16 }, "numpy" },
        { { 6, 5 },   "layer_one.layer_two.services.some_service" },
        -- Non-importable symbol
        { { 15, 26 }, "root" },
    }
    run_test_cases("CopyPythonPath dotted a", "a", test_cases)
end

T[":CopyPythonPath"]["dotted"]["nested Python file"] = function()
    child.api.nvim_command(EDIT_NESTED_FILE_COMMAND)
    local test_cases = {
        -- Importable symbols
        { { 4, 5 },  "layer_one.layer_two.services.some_service" },
        { { 5, 12 }, "numpy" },
        -- Non-importable symbol
        { { 5, 21 }, "layer_one.layer_two.services" },
    }
    run_test_cases("CopyPythonPath dotted a", "a", test_cases)
end

T[":CopyPythonPath"]["import"] = MiniTest.new_set()

T[":CopyPythonPath"]["import"]["root level Python file"] = function()
    child.api.nvim_command(EDIT_ROOT_FILE_COMMAND)
    local test_cases = {
        -- Importable symbols
        { { 5, 5 },   "from root import func" },
        { { 9, 16 },  "from root import async_func" },
        { { 13, 7 },  "from root import OuterClass" },
        { { 18, 13 }, "from root import OuterClass" },
        { { 22, 10 }, "from root import MODULE_LEVEL_CONSTANT" },
        { { 15, 16 }, "import numpy" },
        { { 6, 5 },   "from layer_one.layer_two.services import some_service" },
        -- Non-importable symbol
        { { 15, 26 }, "from root import " },
    }
    run_test_cases("CopyPythonPath import a", "a", test_cases)
end

T[":CopyPythonPath"]["import"]["nested Python file"] = function()
    child.api.nvim_command(EDIT_NESTED_FILE_COMMAND)
    local test_cases = {
        -- Importable symbols
        { { 4, 5 },  "from layer_one.layer_two.services import some_service" },
        { { 5, 12 }, "import numpy" },
        -- Non-importable symbol
        { { 5, 21 }, "from layer_one.layer_two.services import " },
    }
    run_test_cases("CopyPythonPath import a", "a", test_cases)
end

T[":CopyPythonPath"]["copies to clipboard if no register is provided"] = function()
    child.api.nvim_command(EDIT_ROOT_FILE_COMMAND)

    child.api.nvim_win_set_cursor(0, { 5, 5 })
    child.api.nvim_command("CopyPythonPath dotted")

    local dotted_path = child.fn.getreg("+")
    expect.equality(dotted_path, "root.func")
end

return T
