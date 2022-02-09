# Worktrees.nvim

Git worktree wrapper for neovim

After using [git-worktree.nvim](https://github.com/ThePrimeagen/git-worktree.nvim) plugin for quite some time I decided to make my own git worktree plugin with a different api and flow/usage.

## Requirements

- neovim nightly (0.7+)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional)

## Installation

Install the plugin and dependencies with prefered plugin manager

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

### Creating new worktree

New worktree can be created using the provided command GitWorktreeCreate

```
:GitWorktreeCreate <branch> <folder>(optional) <base branch>(optional)
```

or with lua

```lua
:lua require("worktrees").new_worktree({
    branch = <branch>,
    folder = <folder>(optional),
    base_branch = <base branch>(optional)
})
```

### Switching to another worktree

Switching to another worktree requires a parameter that can be either branch name or folder name.

If a file is open in a buffer when switching, the plugin will try to find the file in the other worktree, if it exists it will change the buffer to correspond to the new worktree file. Otherwise Ex is opened (will most likely change this to be configurable)

Switching can be done using the provided command GitWorktreeSwitch

```
:GitWorktreeSwitch <branch/folder>
```

or with lua

```lua
:lua require("worktrees").switch_worktree(<branch/folder>)
```

### Tracking an existing branch to worktree

Tracking and existing branch to worktree can be done with the provided command GitWorktreeTrack

```
:GitWorktreeTrack <branch> <folder>
```

or with lua 

```lua
:lua require("worktrees").new_worktree_track(<branch>, <folder>)
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

- [ ]  Possibly use vim.fn.input in commands and functions instead of parameters
- [ ]  Adding telescope prompt for selecting base branch or branch to track (would work well with using vim.fn.input)
- [ ]  Options to customize behavior
