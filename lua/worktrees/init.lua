local jobs = require("worktrees.jobs")
local utils = require("worktrees.utils")

local M = {}

M._default_options = {}

M.setup = function(opts)
    local options = opts or {}
    M._options = vim.tbl_deep_extend("force", options, M._default_options)

    vim.notify_once("Worktree plugin initialized")

    vim.api.nvim_add_user_command(
        "GitWorktreeCreate",
        M.new_worktree_command,
        { nargs = "*" }
    )
    vim.api.nvim_add_user_command(
        "GitWorktreeSwitch",
        M.switch_worktree_command,
        { nargs = 1 }
    )
    vim.api.nvim_add_user_command("GitWorktreeTrack", M.new_worktree_track, {})
end

M.new_worktree_command = function(input)
    local args = input.args:split_string(" ")

    if not args[1] then
        return
    end

    local create_opts = { branch = args[1] }
    if args[2] then
        create_opts["folder"] = args[2]
    end
    if args[3] then
        create_opts["base_branch"] = args[3]
    end

    M.new_worktree(create_opts)
end

M.new_worktree = function(opts)
    vim.notify("Creating new worktree")

    if not opts.branch then
        return
    end

    local folder = opts.folder or opts.branch
    local relative_path = utils.get_relative_worktree_path(folder)

    vim.notify(vim.inspect(relative_path))

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

M.switch_worktree_command = function(input)
    local args = input.args:split_string(" ")

    if not args[1] then
        return
    end

    M.switch_worktree(args[1])
end

M.switch_worktree = function(input)
    vim.notify("Switching to another worktree")

    local worktrees = utils.get_worktrees()
    local path = nil
    for _, worktree in pairs(worktrees) do
        if worktree.folder == input or worktree.branch == input then
            path = worktree.path
            break
        end
    end
    vim.loop.chdir(path)
end

M.new_worktree_track = function()
    vim.notify_once(
        "Creating new worktree and setting it up to track remote branch"
    )

    -- TODO: Create new worktree to track remote branch
end

return M
