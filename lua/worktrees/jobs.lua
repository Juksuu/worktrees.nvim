local Job = require("plenary.job")

local M = {}

M.custom_job = function(cmd, args)
    return Job:new({
        command = cmd,
        args = args,
        cwd = vim.loop.cwd(),
    })
end

M.is_bare_repo = function()
    return Job:new({
        "git",
        "rev-parse",
        "--is-bare-repository",
        cwd = vim.loop.cwd(),
    })
end

M.toplevel_dir = function()
    return Job:new({
        "git",
        "rev-parse",
        "--show-toplevel",
        cwd = vim.loop.cwd(),
    })
end

M.list_worktrees = function()
    return Job:new({
        "git",
        "worktree",
        "list",
        "--porcelain",
        cwd = vim.loop.cwd(),
    })
end

return M
