local new_set = MiniTest.new_set
local expect = MiniTest.expect

local utils = require("copy-python-path.utils.symbol")

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

T["get_importable_symbol_chain"] = new_set({
    parametrize = {
        -- Module-level variable
        {
            { "GLOBAL_VAR = 10" },
            { "GLOBAL_VAR" },
        },
        -- Function
        {
            { "def foo_bar(baz):" },
            { "foo_bar" },
        },
        -- Class
        {
            { "class Foo:" },
            { "Foo" },
        },
        -- Class method
        {
            {
                "class Foo:",
                "    def bar():",
            },
            { "Foo", "bar" },
        },
        -- Nested class's method
        {
            {
                "class LevelOne:",
                "    class LevelTwo:",
                "",
                "        level_two_attr = 'whatever'",
                "        class LevelThree:",
                "            def level_three(foo, bar):",
            },
            { "LevelOne", "LevelTwo", "LevelThree", "level_three" },
        },
        -- Ignores unrelated code
        {
            {
                "IRRELEVANT_VAR = 10",
                "GLOBAL_VAR = 10",
            },
            { "GLOBAL_VAR" },
        },
        {
            {
                "def irrelevant()",
                "def foo():",
            },
            { "foo" },
        },
        {
            {
                "class Irrelevant:",
                "    def irrelevant():",
                "        pass",
                "class Foo:",
                "    def bar():",
            },
            { "Foo", "bar" },
        },
        -- Empty lines
        { {},                {} },
        { { "" },            {} },
        { { "", "" },        {} },
        -- Non-importable
        { { "if x == 10:" }, {} },
        {
            {
                "while i > 10:",
                "    GLOBAL_VAR = i",
            },
            {},
        },
        {
            { "    GLOBAL_VAR = 10" }, -- since it's indented it's not module-level
            {},
        },
        {
            {
                "class Foo:",
                "    def bar():",
                "        pass", -- last line is not on `def bar()`, so no results
            },
            {},
        },
    },
})

T["get_importable_symbol_chain"]["works"] = function(lines, expected_symbols)
    local symbols = utils.get_importable_symbol_chain(lines)
    expect.equality(symbols, expected_symbols)
end

return T
