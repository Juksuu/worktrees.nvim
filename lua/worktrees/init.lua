local jobs = require("worktrees.jobs")
local utils = require("worktrees.utils")

local M = {}

M._default_options = {}

M.setup = function(opts)
    local options = opts or {}
    M._options = vim.tbl_deep_extend("force", options, M._default_options)

    vim.notify_once("Worktree plugin initialized")

    vim.api.nvim_add_user_command("GitWorktreeCreate", function(input)
        local args = input.args:split_string(" ")
        if not args[1] then
            return
        end

        local create_opts = {
            branch = args[1],
            folder = args[2],
            base_branch = args[3],
        }

        M.new_worktree(create_opts)
    end, { nargs = "*" })

    vim.api.nvim_add_user_command("GitWorktreeSwitch", function(input)
        local args = input.args:split_string(" ")

        if not args[1] then
            return
        end

        M.switch_worktree(args[1])
    end, { nargs = 1 })

    vim.api.nvim_add_user_command("GitWorktreeTrack", function(input)
        local args = input.args:split_string(" ")

        if not args[1] or not args[2] then
            return
        end
        M.new_worktree_track(args[1], args[2])
    end, { nargs = "*" })
end

M.new_worktree = function(opts)
    vim.notify("Creating new worktree")

    if not opts.branch then
        return
    end

    local folder = opts.folder or opts.branch
    local relative_path = utils.get_worktree_path(folder)

    -- Create custom job for creating new worktree
    local cmd = "git"
    local args = {
        "worktree",
        "add",
        "-b",
        opts.branch,
        relative_path,
    }

    if opts.base_branch then
        table.insert(args, opts.base_branch)
    end

    local create_job = jobs.custom_job(cmd, args)
    create_job:sync()
end

M.switch_worktree = function(input)
    vim.notify("Switching to another worktree")

    -- Save git info before changing directory
    local before_git_path_info = utils.get_git_path_info()

    local worktrees = utils.get_worktrees()
    local path = nil
    for _, worktree in ipairs(worktrees) do
        if worktree.folder == input or worktree.branch == input then
            path = worktree.path
            break
        end
    end

    -- Change neovim cwd
    vim.loop.chdir(path)

    -- Clear jumplist so that no file in the old worktree is present
    -- in the jumplist for accidental switching of worktrees
    vim.cmd("clearjumps")

    utils.update_current_buffer(before_git_path_info)
end

M.new_worktree_track = function(folder, branch)
    vim.notify_once(
        "Creating new worktree and setting it up to track remote branch"
    )

    if not folder or not branch then
        return
    end

    local relative_path = utils.get_worktree_path(folder)

    -- Create custom job for creating new worktree
    local cmd = "git"
    local args = {
        "worktree",
        "add",
        relative_path,
        branch,
    }

    local create_job = jobs.custom_job(cmd, args)
    create_job:sync()
end

return M
