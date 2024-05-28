local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local telescope_utils = require("telescope.utils")
local conf = require("telescope.config").values

local worktrees = require("worktrees")
local worktrees_utils = require("worktrees.utils")

local switch_worktree = function(prompt_bufnr)
    local path = action_state.get_selected_entry(prompt_bufnr).path
    actions.close(prompt_bufnr)

    if path ~= nil then
        worktrees.switch_worktree(path)
    end
end

local telescope_list_worktrees = function(opts)
    opts = opts or {}

    local found_worktrees = worktrees_utils.get_worktrees()
    if found_worktrees == nil then
        return
    end

    local widths = {
        sha = 0,
        path = 0,
        branch = 0,
    }

    for _, worktree in ipairs(found_worktrees) do
        widths.sha = math.max(widths.sha, #worktree.sha)
        widths.path = math.max(widths.path, #worktree.path)
        widths.branch = math.max(widths.branch, #worktree.branch)
    end

    local displayer = require("telescope.pickers.entry_display").create({
        separator = " ",
        items = {
            { width = widths.branch },
            { width = widths.sha },
            { width = widths.path },
        },
    })

    local make_display = function(entry)
        return displayer({
            { entry.branch, "TelescopeResultsIdentifier" },
            {
                telescope_utils.transform_path(opts, entry.path),
                "TelescopeResultsField",
            },
            { entry.sha, "TelescopeResultsNumber" },
        })
    end

    pickers
        .new(opts or {}, {
            prompt_title = "Git Worktrees",
            finder = finders.new_table({
                results = found_worktrees,
                entry_maker = function(entry)
                    entry.value = entry.branch
                    entry.ordinal = entry.branch
                    entry.display = make_display
                    return entry
                end,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, _)
                actions.select_default:replace(switch_worktree)
                return true
            end,
        })
        :find()
end

return require("telescope").register_extension({
    exports = {
        list_worktrees = telescope_list_worktrees,
    },
})
