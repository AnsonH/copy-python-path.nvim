local new_set = MiniTest.new_set
local expect = MiniTest.expect

local utils = require("copy-python-path.utils")

local T = new_set()

T["find_importable_symbol"] = new_set({
    parametrize = {
        -- module-level variables
        { "foo = 10",                "foo",     "" },
        { "_FOO    =    (",          "_FOO",    "" },
        { "foo=10",                  "foo",     "" },
        -- class definition
        { "class Foo:",              "Foo",     "" },
        { "class    Foo :",          "Foo",     "" },
        { "    class _Bar123(Baz):", "_Bar123", "    " },
        -- function definition
        { "def foo():",              "foo",     "" },
        { "def foo(bar):",           "foo",     "" },
        { "def   foo  ( bar ):",     "foo",     "" },
        { "    def _v123():",        "_v123",   "    " },
        -- non-matches
        { "",                        nil,       nil },
        { "    foo = 10",            nil,       nil },
        { "if foo == 10:",           nil,       nil },
        { "for foo in foos:",        nil,       nil },
        { "_def()",                  nil,       nil },
    },
})

T["find_importable_symbol"]["works"] = function(code, expected_symbol, expected_indent)
    local symbol, indent = utils.find_importable_symbol(code)
    expect.equality(symbol, expected_symbol)
    expect.equality(indent, expected_indent)
end

return T
