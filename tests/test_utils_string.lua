local new_set = MiniTest.new_set
local expect = MiniTest.expect

local M = require("copy-python-path.utils.string")

local T = new_set()

T["split_string"] = new_set({
    parametrize = {
        { "foo.bar.baz", ".", { "foo", "bar", "baz" } },
        { "foo", ".", { "foo" } },
        { "", ".", { "" } },
    },
})

T["split_string"]["works"] = function(input, separator, expected)
    local output = M.split_string(input, separator)
    expect.equality(output, expected)
end

T["trim_string"] = new_set({
    parametrize = {
        { "   hello  ", "hello" },
        { "   hello world  ", "hello world" },
        { "hello_world", "hello_world" },
        { "", "" },
    },
})

T["trim_string"]["works"] = function(input, expected)
    local output = M.trim_string(input)
    expect.equality(output, expected)
end

return T
