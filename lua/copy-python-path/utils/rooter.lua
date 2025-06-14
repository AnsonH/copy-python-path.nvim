local M = {}

local markers = {
    -- Version control systems
    ".git",
    ".hg",
    ".svn",

    -- Python specific project markers
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "poetry.lock",

    -- Configuration files often at project root
    ".python-version",
    "tox.ini",
    "pytest.ini",
    ".flake8",
    ".isort.cfg",
    "mypy.ini",
}

--- Find the absolute path of the Python project's root. Defaults to `path`'s current directory
--- opened file if failed to locate the root.
---@param path string The absolute path to search from
---@return string root_dir_path Normalized absolute path of the project root directory.
function M.find_root_dir_path(path)
    local current_dir = vim.fs.dirname(path)

    local marker_path = vim.fs.find(markers, {
        path = path,
        upward = true,
        limit = 1,
    })[1]

    return marker_path and vim.fs.dirname(marker_path) or current_dir
end

return M
