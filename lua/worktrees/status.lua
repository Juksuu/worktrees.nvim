local log = require("plenary.log")
local Status = {}

local log_levels = { "trace", "debug", "info", "warn", "error" }

function Status:init(log_level, log_to_nvim)
    self._log_to_nvim = log_to_nvim
    self._logger = log.new({
        plugin = "worktrees.nvim",
        level = log_levels[log_level + 1],
    })
end

function Status:info_nvim(msg)
    if self._log_to_nvim then
        vim.notify("[Worktree.nvim] " .. msg)
    end
    self._logger.info(msg)
end

function Status:info(msg)
    self._logger.info(msg)
end

function Status:warn(msg)
    self._logger.warn(msg)
end

function Status:logger()
    return self._logger
end

return Status
