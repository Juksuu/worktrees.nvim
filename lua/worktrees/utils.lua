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
        table.concat(jobs.is_bare_repo():sync())
    )

    local toplevel = table.concat(jobs.toplevel_dir():sync())
    git_info.toplevel_path = Path:new(toplevel):parent()

    return git_info
end

M.get_worktree_path = function(folder)
    local git_info = M.get_git_path_info()
    local not_bare_path = git_info.toplevel_path:joinpath(folder)

    -- If repository is bare we can just use the folder name as path
    -- Otherwise append folder name to git toplevel path
    local path = Path:new(
        (git_info.is_bare_repo and folder or not_bare_path:absolute())
    )

    return path:make_relative(vim.loop.cwd())
end

M.get_worktrees = function()
    local worktrees = jobs.list_worktrees():sync()
    local output = {}

    -- Parse worktree data from `git worktree list --porcelain` command
    local sha, path, branch, folder, is_bare = nil, nil, nil, nil, false
    for _, worktree_data in ipairs(worktrees) do
        worktree_data = worktree_data:split_string(" ")

        -- Data has an empty line between worktrees
        if not worktree_data[1] and not is_bare then
            table.insert(output, {
                sha = sha,
                path = path,
                branch = branch,
                folder = folder,
            })

            sha, path, branch = nil, nil, nil
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

M.update_current_buffer = function(git_path_info)
    local cwd = vim.loop.cwd()

    -- Check if buffer is a file and cwd is not bare repo
    local buffer_path = Path:new(vim.api.nvim_buf_get_name(0))
    if not buffer_path:is_file() or git_path_info.is_bare_repo then
        vim.cmd("e .")
        return
    end

    -- Construct path where file would exists in worktree where we are changing to
    -- Example: worktree/test/text.txt -> new_worktree/test/text.txt
    local relative_path = buffer_path:make_relative(
        git_path_info.toplevel_path:absolute()
    )
    local split_path = relative_path:split_string("/")
    table.remove(split_path, 1)
    local buffer_path_in_new_cwd = Path:new(
        cwd .. "/" .. table.concat(split_path, "/")
    )

    if not buffer_path_in_new_cwd:exists() then
        vim.cmd("e .")
        return
    end

    -- Create new buffer from file path and delete old buffer
    vim.schedule(function()
        vim.fn.bufnr(buffer_path_in_new_cwd:absolute(), true)
        vim.api.nvim_buf_delete(0, {})
    end)

    -- Switch to newly created buffer
    vim.schedule(function()
        local bufnr = vim.fn.bufnr(buffer_path_in_new_cwd:absolute(), false)
        vim.api.nvim_set_current_buf(bufnr)
    end)
end

return M
