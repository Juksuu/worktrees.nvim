local jobs = require("worktrees.jobs")
local utils = require("worktrees.utils")
local status = require("worktrees.status")

local M = {}

M._default_options = {
    log_level = vim.log.levels.WARN,
    log_status = true,
    worktree_path = "..",
}

M.setup = function(opts)
    local options = opts or {}
    M._options = vim.tbl_deep_extend("force", M._default_options, options)

    status:init(M._options.log_level, M._options.log_status)

    vim.api.nvim_create_user_command("GitWorktreeCreate", function()
        M.new_worktree(false)
    end, { nargs = 0 })

    vim.api.nvim_create_user_command("GitWorktreeSwitch", function()
        M.switch_worktree()
    end, { nargs = 0 })

    vim.api.nvim_create_user_command("GitWorktreeCreateExisting", function()
        M.new_worktree(true)
    end, { nargs = 0 })

    vim.api.nvim_create_user_command("GitWorktreeRemove", function()
        M.remove_worktree()
    end, { nargs = 0 })

    if Snacks and pcall(require, "snacks.picker") then
        local snacks = require("worktrees.snacks")
        Snacks.picker.sources.worktrees = snacks.switch
        Snacks.picker.sources.worktrees_new = snacks.new
        Snacks.picker.sources.worktrees_remove = snacks.remove
    end
end

---@param existing_branch? boolean Use existing branch
---@param branch_name? string Branch name to use. Prompts for the name if not provided
M.new_worktree = function(existing_branch, branch_name)
    local branch = branch_name or vim.fn.input("Branch name: ")
    if branch == "" then
        status:warn("No branch name provided. Aborting...")
        return
    end

    local folder = vim.fn.input("Folder name (optional): ")
    folder = folder == "" and branch or folder

    local relative_path =
        utils.get_worktree_path(folder, M._options.worktree_path)
    if relative_path == nil then
        return
    end

    -- Create custom job for creating new worktree
    local cmd = "git"
    local args = {
        "worktree",
        "add",
    }

    if not existing_branch then
        table.insert(args, "-b")
        table.insert(args, branch)
        table.insert(args, relative_path)

        local base_branch = vim.fn.input("Base branch name (optional): ")

        if base_branch ~= "" then
            table.insert(args, base_branch)
        end
    else
        table.insert(args, relative_path)
        table.insert(args, branch)
    end

    local _, code = jobs.custom_job(cmd, args):sync()
    if code ~= 0 then
        status:warn("Could not create worktree with arguments. Aborting...")
        return
    end

    status:info_nvim("Worktree created")

    M.switch_worktree(relative_path)

    if existing_branch then
        vim.schedule(function()
            -- Update upstream for new branch
            local upstream_args = {
                "branch",
                "--set-upstream-to=origin/" .. branch,
            }

            local _, upstream_code = jobs.custom_job(cmd, upstream_args):sync()
            if upstream_code ~= 0 then
                status:warn("Could not set upstream for current worktree")
                return
            end
            status:info_nvim("Successfully set upstream")
        end)
    end
end

M.switch_worktree = function(path)
    local found_path = path
    if not found_path then
        local input = vim.fn.input("Branch/folder to switch to: ")
        status:info_nvim("Finding worktree path")
        local worktrees = utils.get_worktrees()
        if worktrees ~= nil then
            for _, worktree in ipairs(worktrees) do
                if worktree.folder == input or worktree.branch == input then
                    found_path = worktree.path
                    break
                end
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
        vim.cmd("cd " .. found_path)

        -- Clear jumplist so that no file in the old worktree is present
        -- in the jumplist for accidental switching of worktrees
        vim.cmd("clearjumps")

        utils.update_current_buffer(before_git_path_info)
        status:info_nvim("Updating buffer")
    end)
end

M.remove_worktree = function(path)
    local found_path = path
    if not found_path then
        local input = vim.fn.input("Worktree branch/folder to remove: ")
        status:info_nvim("Finding worktree path")
        local worktrees = utils.get_worktrees()
        if worktrees ~= nil then
            for _, worktree in ipairs(worktrees) do
                if worktree.folder == input or worktree.branch == input then
                    found_path = worktree.path
                    break
                end
            end
        end
    end

    if found_path == nil then
        status:warn("Could not determine path to remove. Aborting...")
        return
    end

    if found_path == vim.loop.cwd() then
        local before_git_path_info = utils.get_git_path_info()
        if before_git_path_info == nil then
            return
        end

        vim.schedule(function()
            -- Change neovim cwd
            vim.cmd("cd " .. before_git_path_info.toplevel_path:absolute())

            -- Clear jumplist so that no file in the old worktree is present
            -- in the jumplist for accidental switching of worktrees
            vim.cmd("clearjumps")

            local buffers = vim.api.nvim_list_bufs()
            for _, buffer_id in ipairs(buffers) do
                vim.api.nvim_buf_delete(buffer_id, {})
            end

            vim.cmd("e .")
        end)
    end

    -- Create custom job for creating new worktree
    local cmd = "git"
    local args = {
        "worktree",
        "remove",
        found_path,
    }

    local _, code = jobs.custom_job(cmd, args):sync()
    if code ~= 0 then
        status:warn("Could not delete worktree with arguments. Aborting...")
        return
    end

    status:info_nvim("Worktree removed")
end

return M
