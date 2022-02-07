# worktrees.nvim

Git worktree wrapper for neovim

## Requirements<a name="requirements"></a>

-   neovim nightly (0.7+)
-   plenary.nvim

## Installation<a name="installation"></a>

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

## Usage<a name="usage"></a>

Currently this plugin only provides a way to create worktrees,
but plan is to have a way for switching worktrees and for tracking remote branches

### Creating new worktree

New worktree can be created using the provided command GitWorktreeCreate

```
:GitWorktreeCreate <branch> <folder>(optional) <base branch>(optional)
```

or with lua

```lua
:lua require("worktrees").new_worktree({
    branch = <branch>,
    folder = <folder>(optional)
    base_branch = <base branch>(optional)
})
```
