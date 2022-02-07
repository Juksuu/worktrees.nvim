local Job = require("plenary.job")

local M = {}

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

M.new_job = function(cmd, args)
    return Job:new({
        command = cmd,
        args = args,
        cwd = vim.loop.cwd(),
    })
end

return M
