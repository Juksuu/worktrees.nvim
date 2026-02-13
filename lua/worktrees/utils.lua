local Path = require("plenary.path")
local jobs = require("worktrees.jobs")
local status = require("worktrees.status")

local M = {}

-- Setup string splitting
M.split_string = function(s, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    local _ = s:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)

    return fields
end

M.str_to_boolean = function(str)
    return str == "true"
end

M.get_git_path_info = function()
    local git_info = {}

    local is_bare_repo = jobs.is_bare_repo()
    if is_bare_repo == nil then
        return nil
    end

    git_info.is_bare_repo = M.str_to_boolean(table.concat(is_bare_repo))

    local toplevel = jobs.toplevel_dir()
    if toplevel == nil then
        git_info.toplevel_path = nil
    else
        git_info.toplevel_path = Path:new(table.concat(toplevel)):parent()
    end

    return git_info
end

local function get_path_basename(path)
    local split_path = M.split_string(path, "/")
    return split_path[#split_path]
end

local function get_project_name()
    local toplevel = jobs.toplevel_dir()
    local projectname

    if toplevel ~= nil then
        projectname = get_path_basename(table.concat(toplevel))
    end

    if projectname == nil or projectname == "" then
        projectname = get_path_basename(vim.loop.cwd())
    end

    projectname = projectname:gsub("%.git$", "")
    if projectname == "" then
        projectname = "project"
    end

    return projectname
end

M.get_worktree_path = function(folder, worktree_path)
    local git_info = M.get_git_path_info()
    if git_info == nil then
        return nil
    end

    local path
    if worktree_path == ".." then
        -- If repository is bare we can just use the folder name as path
        -- Otherwise append folder name to git toplevel path
        if git_info.is_bare_repo then
            path = Path:new(folder)
        else
            if git_info.toplevel_path == nil then
                status.warn(
                    "Repo is not bare and could not get git toplevel. Aborting..."
                )
                return nil
            end

            path = Path:new(git_info.toplevel_path:joinpath(folder):absolute())
        end
    else
        local configured_root = vim.fn.expand(worktree_path)
        if configured_root == "" then
            configured_root = "."
        end

        local root_path = Path:new(configured_root)
        if not root_path:is_absolute() then
            root_path = Path:new(vim.loop.cwd() .. "/" .. configured_root)
        end

        local projectname = get_project_name()
        path = Path:new(
            root_path:joinpath(projectname):joinpath(folder):absolute()
        )
    end

    return path:make_relative(vim.loop.cwd())
end

M.get_worktrees = function()
    local worktrees = jobs.list_worktrees()
    if worktrees == nil then
        return nil
    end

    local output = {}

    -- Parse worktree data from `git worktree list --porcelain` command
    local sha, path, branch, folder, is_bare = nil, nil, nil, nil, false
    for _, worktree_data in ipairs(worktrees) do
        worktree_data = M.split_string(worktree_data, " ")

        -- Data has an empty line between worktrees
        if not worktree_data[1] and not is_bare then
            local data = {
                sha = sha,
                path = path,
                branch = branch,
                folder = folder,
            }
            table.insert(output, data)

            status:info(string.format("Parsed worktree: %s", vim.inspect(data)))

            sha, path, branch = nil, nil, nil
        elseif worktree_data[1] == "worktree" then
            is_bare = false
            path = worktree_data[2]

            local split_path = M.split_string(worktree_data[2], "/")
            folder = split_path[#split_path]
        elseif worktree_data[1] == "HEAD" then
            sha = worktree_data[2]
        elseif worktree_data[1] == "branch" then
            local split_path = M.split_string(worktree_data[2], "/")
            branch = split_path[#split_path]
        elseif worktree_data[1] == "detached" then
            branch = "detached HEAD"
        elseif worktree_data[1] == "bare" then
            is_bare = true
        end
    end

    return output
end

M.update_current_buffer = function(git_path_info, use_netrw)
    local cwd = vim.loop.cwd()

    -- Check if buffer is a file and cwd is not bare repo
    local buffer_path = Path:new(vim.api.nvim_buf_get_name(0))
    if not buffer_path:is_file() or git_path_info.is_bare_repo then
        M.open_netrw_if_enabled(use_netrw)
        return
    end

    -- Construct path where file would exists in worktree where we are changing to
    -- Example: worktree/test/text.txt -> new_worktree/test/text.txt
    local relative_path =
        buffer_path:make_relative(git_path_info.toplevel_path:absolute())
    local split_path = M.split_string(relative_path, "/")
    table.remove(split_path, 1)
    local buffer_path_in_new_cwd =
        Path:new(cwd .. "/" .. table.concat(split_path, "/"))

    if not buffer_path_in_new_cwd:exists() then
        M.open_netrw_if_enabled(use_netrw)
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

M.open_netrw_if_enabled = function(enabled, dir)
    if enabled then
        vim.cmd("Ex " .. (dir or ""))
    end
end

return M
