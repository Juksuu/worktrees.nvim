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
    vim.api.nvim_add_user_command("GitWorktreeTrack", M.new_worktree_track, {})
end

M.new_worktree = function(opts)
    vim.notify("Creating new worktree")

    vim.notify(vim.inspect(opts))

    if not opts.branch then
        return
    end

    local folder = opts.folder or opts.branch
    local relative_path = utils.get_relative_worktree_path(folder)

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

M.new_worktree_track = function()
    vim.notify_once(
        "Creating new worktree and setting it up to track remote branch"
    )

    -- TODO: Create new worktree to track remote branch
end

return M
