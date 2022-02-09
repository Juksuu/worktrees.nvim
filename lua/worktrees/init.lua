local jobs = require("worktrees.jobs")
local utils = require("worktrees.utils")
local status = require("worktrees.status")

local M = {}

M._default_options = {
    log_level = vim.log.levels.WARN,
    log_status = true,
}

M.setup = function(opts)
    local options = opts or {}
    M._options = vim.tbl_deep_extend("force", options, M._default_options)

    status:init(M._options.log_level, M._options.log_status)

    vim.api.nvim_add_user_command("GitWorktreeCreate", function(input)
        local args = input.args:split_string(" ")
        if not args[1] then
            status:warn("Not enough arguments passed. Aborting...")
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
            status:warn("Not enough arguments passed. Aborting...")
            return
        end

        M.switch_worktree(args[1])
    end, { nargs = 1 })

    vim.api.nvim_add_user_command("GitWorktreeTrack", function(input)
        local args = input.args:split_string(" ")

        if not args[1] or not args[2] then
            status:warn("Not enough arguments passed. Aborting...")
            return
        end
        M.new_worktree_track(args[1], args[2])
    end, { nargs = "*" })
end

M.new_worktree = function(opts)
    if not opts.branch then
        status:warn("Not enough arguments passed. Aborting...")
        return
    end

    local folder = opts.folder or opts.branch
    local relative_path = utils.get_worktree_path(folder)
    if relative_path == nil then
        return
    end

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

    local _, code = jobs.custom_job(cmd, args):sync()
    if code ~= 0 then
        status:warn("Could not create worktree with arguments. Aborting...")
        return
    end

    status:info_nvim("Worktree created")

    M.switch_worktree(nil, relative_path)
end

M.switch_worktree = function(input, path)
    local found_path = path
    if input then
        status:info_nvim("Finding worktree path")
        local worktrees = utils.get_worktrees()
        for _, worktree in ipairs(worktrees) do
            if worktree.folder == input or worktree.branch == input then
                found_path = worktree.path
                break
            end
        end
    end

    if found_path == nil then
        status:warn("Could not determine path to switch to. Aborting...")
        return
    end

    if found_path == vim.loop.cwd() then
        return
    end

    -- Save git info before changing directory
    local before_git_path_info = utils.get_git_path_info()
    if before_git_path_info == nil then
        return
    end

    vim.schedule(function()
        -- Change neovim cwd
        vim.loop.chdir(found_path)

        -- Clear jumplist so that no file in the old worktree is present
        -- in the jumplist for accidental switching of worktrees
        vim.cmd("clearjumps")

        utils.update_current_buffer(before_git_path_info)
        status:info_nvim("Updating buffer")
    end)
end

M.new_worktree_track = function(folder, branch)
    if not folder or not branch then
        status:warn("Not enough arguments passed. Aborting...")
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

    local _, code = jobs.custom_job(cmd, args):sync()
    if code ~= 0 then
        status:warn("Could not create worktree with arguments. Aborting...")
        return
    end
    status:info_nvim("New worktree created for branch")

    M.switch_worktree(nil, relative_path)
end

return M
