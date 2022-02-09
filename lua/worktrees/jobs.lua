local Job = require("plenary.job")
local status = require("worktrees.status")

local M = {}

M.custom_job = function(cmd, args)
    local command_string = cmd .. " " .. table.concat(args, " ")
    status:info("Running command: " .. command_string)

    return Job:new({
        command = cmd,
        args = args,
        cwd = vim.loop.cwd(),
    })
end

M.is_bare_repo = function()
    status:info("Running command: " .. "git rev-parse --is-bare-repository")

    local output, code = Job
        :new({
            "git",
            "rev-parse",
            "--is-bare-repository",
            cwd = vim.loop.cwd(),
        })
        :sync()

    if code ~= 0 then
        status:warn("Unable to check if repo is bare. Aborting...")
        return nil
    end

    return output
end

M.toplevel_dir = function()
    status:info("Running command: " .. "git rev-parse --show-toplevel")

    local output, code = Job
        :new({
            "git",
            "rev-parse",
            "--show-toplevel",
            cwd = vim.loop.cwd(),
        })
        :sync()

    if code ~= 0 then
        -- Only info when this fails as it is expected when repo is bare
        status:info("Unable to find git toplevel.")
        return nil
    end

    return output
end

M.list_worktrees = function()
    status:info("Running command: " .. "git worktree list --porcelain")

    local output, code = Job
        :new({
            "git",
            "worktree",
            "list",
            "--porcelain",
            cwd = vim.loop.cwd(),
        })
        :sync()

    if code ~= 0 then
        status:warn("Unable to list git worktrees. Aborting...")
        return nil
    end

    return output
end

return M
