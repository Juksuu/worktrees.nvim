local worktrees = require("worktrees")
local worktrees_utils = require("worktrees.utils")

local M = {
    preview = "preview",
}

---@param opts snacks.picker.Config
---@type snacks.picker.finder
function M.finder(opts, filter)
    local found_worktrees = worktrees_utils.get_worktrees()
    if found_worktrees == nil then
        found_worktrees = {}
    end

    ---@async
    ---@param cb async fun(item: snacks.picker.finder.Item)
    return function(cb)
        for i, worktree in ipairs(found_worktrees) do
            --stylua: ignore
            local item = {
                idx = i,
                text = worktree.branch,
                file = worktree.path,
                preview = {
                    text = worktree.path .. "\t" .. worktree.branch .. "\t" .. worktree.sha,
                },
                path = worktree.path,
                branch = worktree.branch,
                sha = worktree.sha,
            }

            cb(item)
        end
    end
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
function M.format(item, picker)
    local ret = {} --@type snacks.picker.Highlight[]
    ret[#ret + 1] = { item.branch, "SnacksPickerGitBranch" }
    ret[#ret + 1] = { " " }

    local file_name = Snacks.picker.format.filename(item, picker)
    vim.list_extend(ret, file_name)
    return ret
end

---@param picker snacks.Picker
---@param item? snacks.picker.Item
function M.confirm(picker, item)
    picker:close()

    if item ~= nil then
        worktrees.switch_worktree(item.file)
    end
end

return M
