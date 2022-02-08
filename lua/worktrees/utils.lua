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

M.get_git_path_info = function()
    local git_info = {}
    git_info.is_bare_repo = M.str_to_boolean(
        table.concat(jobs.is_bare_repo:sync())
    )

    local toplevel = table.concat(jobs.toplevel_dir:sync())
    git_info.toplevel_path = Path:new(toplevel):parent()

    return git_info
end

M.get_relative_worktree_path = function(folder)
    local git_info = M.get_git_path_info()
    local not_bare_path = git_info.toplevel_path:joinpath(folder)
    local path = Path:new(
        (git_info.is_bare_repo and folder or not_bare_path:absolute())
    )

    return path:make_relative(vim.loop.cwd())
end

M.get_worktrees = function()
    local worktrees = jobs.list_worktrees:sync()
    local output = {}

    local sha = nil
    local path = nil
    local branch = nil
    local folder = nil
    local is_bare = false
    for _, worktree_data in pairs(worktrees) do
        worktree_data = worktree_data:split_string(" ")

        if not worktree_data[1] and not is_bare then
            table.insert(
                output,
                { sha = sha, path = path, branch = branch, folder = folder }
            )

            sha = nil
            path = nil
            branch = nil
        elseif worktree_data[1] == "worktree" then
            is_bare = false
            path = worktree_data[2]

            local split_path = worktree_data[2]:split_string("/")
            folder = split_path[#split_path]
        elseif worktree_data[1] == "HEAD" then
            sha = worktree_data[2]
        elseif worktree_data[1] == "branch" then
            local split_path = worktree_data[2]:split_string("/")
            branch = split_path[#split_path]
        elseif worktree_data[1] == "bare" then
            is_bare = true
        end
    end

    return output
end
return M
