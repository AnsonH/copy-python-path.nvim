# copy-python-path.nvim

Neovim plugin to copy the reference path of a Python symbol.

TODO(Anson): Add video

# Features

- Supports copying different path formats (see [examples](#path-format-examples)):
  - Dotted path (e.g. `some.module.func_1`)
  - Import path (e.g. `from some.module import func_1`)
- Supports various Python symbol definitions (see [Getting started](#getting-started))
- Simple Python project root detection
- Allow copy to user-specified register
- No LSP setup required

# Installation

Requires Neovim >=0.7.0.

With [folke/lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
-- Stable version
{ 'AnsonH/copy-python-path.nvim', version = '*' }
```

With [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
-- Stable version
use {"AnsonH/copy-python-path.nvim", tag = "*" }
```

# Getting started

Open a Python file and place the cursor on the following supported symbols:

- Function definitions (e.g. `def func_1()`, `async def func_2()`)
- Class definitions (e.g. `class MyClass:`)
- Class methods and inner classes
- Module-level variable definitions
- Imported symbols (e.g. `import numpy as np`, `from some.module import func_1`)

Then, run the command `:CopyPythonPath <format>` to copy to clipboard:

- `:CopyPythonPath dotted` - Copies the dotted path (e.g. `some.module.func_1`)
- `:CopyPythonPath import` - Copies the import path (e.g. `from some.module import func_1`)

## Path format examples

Let's say we have a file called `app.py`:

```py
""" app.py """
import numpy as np
from user.models import User

# (1) 👇
def func_1():
    pass

# (2) 👇
async def func_2():
    pass

# (3) 👇
class MyClass:
    # (4) 👇
    class Meta:
        pass

    # (5) 👇
    def method_1(self):
        # (6) 👇
        User()
        #  (7) 👇
        return np.array([])

# (8) 👇
MODULE_VAR = 'foo'
```

| Cursor Location                | `:CopyPythonPath dotted` | `:CopyPythonPath import`        |
| ------------------------------ | ------------------------ | ------------------------------- |
| (1) Function definition        | `app.func_1`             | `from app import func_1`        |
| (2) Async function definition  | `app.func_2`             | `from app import func_2`        |
| (3) Class definition           | `app.MyClass`            | `from app import MyClass`       |
| (4) Inner class                | `app.MyClass.Meta`       | `from app import MyClass`¹      |
| (5) Class method               | `app.MyClass.method_1`   | `from app import MyClass`¹      |
| (6) Imported symbol            | `user.models.User`       | `from user.models import User`² |
| (7) Imported symbol with alias | `numpy`                  | `import numpy`                  |
| (8) Module-level variable      | `app.MODULE_VAR`         | `from app import MODULE_VAR`    |
| Elsewhere in the file          | `app`                    | `from app import `              |

Notes:

1. Inner classes and class methods cannot be directly imported, so it only imports the outer class.
2. When the symbol is imported, it copies the original path of where it was imported from.

## Custom keymappings

This plugin does NOT set up any keymappings by default. You can define custom keymappings in your Neovim config, for example:

```lua
vim.api.nvim_set_keymap('n', '<Leader>yd', ':CopyPythonPath dotted<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>yi', ':CopyPythonPath import<CR>', { noremap = true, silent = true })
```

# Command

```
:CopyPythonPath <format> [<register>]
```

Copies the reference path of the Python symbol under the cursor.

| Argument   | Description                        | Accepted Values         | Default Value   |
| ---------- | ---------------------------------- | ----------------------- | --------------- |
| `format`   | The path format to copy            | `dotted`, `import`      | N.A. (required) |
| `register` | (optional) The register to copy to | Any valid register name | `+` (clipboard) |

# API

The plugin API is available via:

```lua
local copy_python_path = require('copy-python-path')
```

## `get_path_under_cursor`

Gets the Python path of the symbol underneath the cursor.

```lua
--- Gets the Python path of the symbol underneath the cursor.
---@param format string The Python path format. Accepted values are:
---  - `"dotted"`: Dotted path (e.g. `user.models.User`)
---  - `"import"`: Import statement (e.g. `from user.models import User`)
---@return string path
copy_python_path.get_path_under_cursor(format)
```

Example: Copy the shell command for running a Django test:

```lua
-- e.g. `./manage.py test some.module.func_1`
vim.api.nvim_create_user_command("CopyDjangoTestCommand", function(opts)
    local copy_python_path = require("copy-python-path")

    local path = copy_python_path.get_path_under_cursor("dotted")
    local command = "./manage.py test " .. path

    vim.fn.setreg("+", command)
end, {})
```

# Similar Work

- [kawamataryo/copy-python-path](https://github.com/kawamataryo/copy-python-path) - VS Code plugin that inspired this project
- [ranelpadon/python-copy-reference.vim](https://github.com/ranelpadon/python-copy-reference.vim) - Vim Script plugin with similar functionality

Special thanks to [neovim-plugin-boilerplate](https://github.com/shortcuts/neovim-plugin-boilerplate) for the plugin boilerplate code.
