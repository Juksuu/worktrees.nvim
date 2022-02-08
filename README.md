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

If a file is open in a buffer when switching, the plugin will try to find the file in the other worktree, if it exists it will change the buffer to correspond to  the new worktree file. Otherwise Ex is opened (will most likely change this to be configurable)

Switching can be done using the provided command GitWorktreeSwitch

```
:GitWorktreeSwitch <branch/folder>
```

or with lua

```lua
:lua require("worktrees").switch_worktree(<branch/folder>)
```

## TODO

- [x]  Creation of new worktrees
- [x]  Switching to another worktree
- [ ]  Tracking branch from remote to worktree
- [ ]  Error handling
- [ ]  Options to customize behavior
