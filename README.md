# Worktrees.nvim

Git worktree wrapper for neovim

After using [git-worktree.nvim](https://github.com/ThePrimeagen/git-worktree.nvim) plugin for quite some time I decided to make my own git worktree plugin with a different api and flow/usage.

## Requirements

- neovim nightly (0.7+)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional)
- [snacks.nvim](https://github.com/folke/snacks.nvim) (optional)

## Installation

Install the plugin and dependencies with preferred plugin manager

### Packer

```lua
use("nvim-lua/plenary.nvim")

use({
    "Juksuu/worktrees.nvim",
    config = function()
        require("worktrees").setup()
    end,
})
```

## Usage

All the commands and functions this plugin provides utilizes the vim.fn.input function to ask users for required or optional parameters. Optional parameters are indicated with (optional) in the input prompt

### Creating new worktree

New worktree can be created using the provided command GitWorktreeCreate

```
:GitWorktreeCreate
```

or with lua

```lua
:lua require("worktrees").new_worktree()
```

### Switching to another worktree

If a file is open in a buffer when switching, the plugin will try to find the file in the other worktree, if it exists it will change the buffer to correspond to the new worktree file. Otherwise Ex is opened (will most likely change this to be configurable)

Switching can be done using the provided command GitWorktreeSwitch

```
:GitWorktreeSwitch
```

or with lua

```lua
:lua require("worktrees").switch_worktree()
```

### Creating worktree for existing branch

Creating worktree for existing branch can be done with the provided command GitWorktreeCreateExisting

```
:GitWorktreeCreateExisting
```

or with lua

```lua
:lua require("worktrees").new_worktree(true)
```

### Remove existing worktree

Creating worktree for existing branch can be done with the provided command GitWorktreeRemove

```
:GitWorktreeRemove
```

or with lua

```lua
:lua require("worktrees").remove_worktree()
```

## Telescope

The extension can be loaded with telescope

```lua
require("telescope").load_extension("worktrees")
```

### Switching worktrees with telescope

```lua
require("telescope").extensions.worktrees.list_worktrees(opts)
-- <Enter> - switches to that worktree
```

## Snacks.nvim

Worktrees can also be created, switched and removed using snacks.nvim

```lua
vim.keymap.set("n", "<leader>gws", function() Snacks.picker.worktrees() end)
vim.keymap.set("n", "<leader>gwn", function() Snacks.picker.worktrees_new() end)
vim.keymap.set("n", "<leader>gwr", function() Snacks.picker.worktrees_remove() end)
```

## Troubleshooting

This plugin provides logging to a file which can be used to debug bugs etc.

The log file resides in neovims cache path and the logging level can be changed by changing the `log_level` option in setup. Status logs in neovim messages can also be toggled in the options

```lua
require("worktrees").setup({
    log_level = <one of vim.log.levels> -- default vim.log.levels.WARN,
    log_status = <boolean> -- default true
})
```

### Upstream setup

For this plugin to work correctly the upstream fetch config needs to be setup correctly. This seems to not be the case when using bare repositories. To check if it is setup correctly run the following command and check that it returns as shown below

```bash
git config --get remote.origin.fetch

+refs/heads/*:refs/remotes/origin/*
```

If not run the following command to fix it

```bash
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
```

## TODO

- [ ]  Options to customize behavior
