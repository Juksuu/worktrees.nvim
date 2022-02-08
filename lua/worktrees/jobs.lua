local Job = require("plenary.job")

local M = {}

M.custom_job = function(cmd, args)
    return Job:new({
        command = cmd,
        args = args,
        cwd = vim.loop.cwd(),
    })
end

M.is_bare_repo = Job:new({
    "git",
    "rev-parse",
    "--is-bare-repository",
    cwd = vim.loop.cwd(),
})

M.toplevel_dir = Job:new({
    "git",
    "rev-parse",
    "--show-toplevel",
    cwd = vim.loop.cwd(),
})

M.list_worktrees = Job:new({
    "git",
    "worktree",
    "list",
    "--porcelain",
    cwd = vim.loop.cwd(),
})

return M
