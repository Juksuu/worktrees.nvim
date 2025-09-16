local worktrees = require("worktrees")
local worktrees_utils = require("worktrees.utils")

---@type snacks.picker.finder
function CustomFinder(_, _)
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
function CustomFormat(item, picker)
    local ret = {} --@type snacks.picker.Highlight[]
    ret[#ret + 1] = { item.branch, "SnacksPickerGitBranch" }
    ret[#ret + 1] = { " " }

    local file_name = Snacks.picker.format.filename(item, picker)
    vim.list_extend(ret, file_name)
    return ret
end

---@type snacks.picker.Config
local New = {
    title = "New Worktree",
    finder = "git_branches",
    format = "git_branch",
    preview = "git_log",
}

---@param picker snacks.Picker
---@param item? snacks.picker.Item
function New.confirm(picker, item)
    picker:close()

    local existing_branch = false
    local branch_name = picker.finder.filter.pattern
    if item ~= nil then
        existing_branch = true
        branch_name = item.branch
    end

    worktrees.new_worktree(existing_branch, branch_name)
end

---@type snacks.picker.Config
local Switch = {
    title = "Worktrees",
    preview = "preview",
    finder = CustomFinder,
    format = CustomFormat,
}

---@param picker snacks.Picker
---@param item? snacks.picker.Item
function Switch.confirm(picker, item)
    picker:close()

    if item ~= nil then
        worktrees.switch_worktree(item.file)
    end
end

---@type snacks.picker.Config
local Remove = {
    title = "Worktrees",
    preview = "preview",
    finder = CustomFinder,
    format = CustomFormat,
}

---@param picker snacks.Picker
---@param item? snacks.picker.Item
function Remove.confirm(picker, item)
    picker:close()

    if item ~= nil then
        worktrees.remove_worktree(item.file)
    end
end

---@type table<snacks.picker.Config>
return {
    new = New,
    switch = Switch,
    remove = Remove,
}
