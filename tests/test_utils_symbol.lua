local new_set = MiniTest.new_set
local expect = MiniTest.expect

local utils = require("copy-python-path.utils.symbol")

local T = new_set()

T["is_valid_symbol_name"] = new_set({
    parametrize = {
        { "_",       true },
        { "a",       true },
        { "foo",     true },
        { "BAR",     true },
        { "_Bar123", true },

        { "",        false },
        { "1",       false },
        { "+",       false },
        { "(foo)",   false },
    },
})

T["is_valid_symbol_name"]["works"] = function(input, expected_output)
    expect.equality(utils.is_valid_symbol_name(input), expected_output)
end

T["split_string"] = new_set({
    parametrize = {
        { "foo.bar.baz", ".", { "foo", "bar", "baz" } },
        { "foo",         ".", { "foo" } },
        { "",            ".", { "" } },
    },
})

T["split_string"]["works"] = function(input, separator, expected)
    local output = utils.split_string(input, separator)
    expect.equality(output, expected)
end

T["trim_string"] = new_set({
    parametrize = {
        { "   hello  ",       "hello" },
        { "   hello world  ", "hello world" },
        { "hello_world",      "hello_world" },
        { "",                 "" },
    },
})

T["trim_string"]["works"] = function(input, expected)
    local output = utils.trim_string(input)
    expect.equality(output, expected)
end

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

T["parse_import_symbol"] = new_set({
    parametrize = {
        { "numpy",                     { "numpy", nil } },
        { "numpy as np",               { "numpy", "np" } },
        { "foo_bar_Baz123",            { "foo_bar_Baz123", nil } },
        { "foo_bar_Baz123 as F00_Bar", { "foo_bar_Baz123", "F00_Bar" } },
        { "module.path",               { "module.path", nil } },
        { "module.path as path_alias", { "module.path", "path_alias" } },
    },
})

T["parse_import_symbol"]["works"] = function(import_str, expected_output)
    local original_symbol, alias_symbol = utils.parse_import_symbol(import_str)
    expect.equality(original_symbol, expected_output[1])
    expect.equality(alias_symbol, expected_output[2])
end

T["get_imported_symbols_map"] = new_set({
    parametrize = {
        -- From-import statements
        {
            {
                "from module.path import SymbolOne, SymbolTwo as symbol_2",
                "from another.module.path import    SYMBOL_THREE   , S4",
                "from numpy import *", -- Ignore import all
                "from .relative.path import Symbol5",
            },
            {
                ["SymbolOne"] = "module.path.SymbolOne",
                ["symbol_2"] = "module.path.SymbolTwo",
                ["SYMBOL_THREE"] = "another.module.path.SYMBOL_THREE",
                ["S4"] = "another.module.path.S4",
                ["Symbol5"] = ".relative.path.Symbol5",
            },
        },
        -- Import statements
        {
            {
                "import module.path.constants, another.module as alias",
                "import     numpy,     pandas    as pd",
                "import .services",
            },
            {
                ["constants"] = "module.path.constants",
                ["alias"] = "another.module",
                ["numpy"] = "numpy",
                ["pd"] = "pandas",
                ["services"] = ".services",
            },
        },
        -- Mixture of import styles
        {
            {
                "import numpy as np, pandas as pd",
                "from user.models import CustomerUser, USER_PERMISSIONS",
            },
            {
                ["np"] = "numpy",
                ["pd"] = "pandas",
                ["CustomerUser"] = "user.models.CustomerUser",
                ["USER_PERMISSIONS"] = "user.models.USER_PERMISSIONS",
            },
        },
        -- Import statement inside nested block (often a trick to avoid circular dependencies)
        {
            {
                "def get_customer():",
                "    from user.services import retrieve_customer",
                "    ",
                "    customer = retrieve_customer(first_name='Foo')",
            },
            {
                ["retrieve_customer"] = "user.services.retrieve_customer",
            },
        },
    },
})

T["get_imported_symbols_map"]["works"] = function(lines, expected_map)
    local symbols_map = utils.get_imported_symbols_map(lines)
    expect.equality(symbols_map, expected_map)
end

return T
