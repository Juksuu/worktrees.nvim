local jobs = require("worktrees.jobs")
local Path = require("plenary.path")

local M = {}

-- Setup string splitting
function string:split_string(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    local _ = self:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)

    return fields
end

M.str_to_boolean = function(str)
    return str == "true"
end

M.get_git_info = function()
    local git_info = {}
    git_info.is_bare_repo = M.str_to_boolean(
        table.concat(jobs.is_bare_repo:sync())
    )

    local toplevel = table.concat(jobs.toplevel_dir:sync())
    git_info.toplevel_path = Path:new(toplevel):parent()

    return git_info
end

M.get_relative_worktree_path = function(folder)
    local git_info = M.get_git_info()
    local not_bare_path = git_info.toplevel_path:joinpath(folder)
    local path = Path:new(
        (git_info.is_bare_repo and folder or not_bare_path:absolute())
    )

    return path:make_relative(vim.loop.cwd())
end

return M
