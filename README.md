# Worktrees.nvim

Git worktree wrapper for neovim

After using [git-worktree.nvim](https://github.com/ThePrimeagen/git-worktree.nvim) plugin for quite some time I decided to make my own git worktree plugin with a different api and flow/usage.

## Requirements

- neovim nightly (0.7+)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

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

Currently this plugin only provides a way to create worktrees, but plan is to have a way for switching worktrees and for tracking remote branches

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

## TODO

- [x]  Creation of new worktrees
- [ ]  Switching to another worktree
- [ ]  Tracking branch from remote to worktree
