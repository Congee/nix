# pickaxe.nvim

A Lua reimplementation of [git-messenger.vim][gm]'s blame popup, with a smarter
"explore older commits" algorithm.

git-messenger.vim already supports stepping back through history, but plain blame
becomes misleading after refactors. pickaxe.nvim walks a blame **stack** that
follows the line across renames and moved code, and falls back to a `git log -S`
pickaxe search when even that loses the trail — hence the name.

## How the stack works

From the commit that last touched the line, pickaxe re-blames the parent
(`<hash>^`) at the *introducing* line. When the file was renamed in that commit
the parent path is gone, so it follows the `previous <rev> <path>` pair reported
by `git blame --line-porcelain`. Blame runs with `-w -M -C -C` and honors a
`.git-blame-ignore-revs` file when the repo has one.

When the stack dead-ends on a heavy refactor, `:PickaxeSearch` (or `p` in the
popup) runs `git log -S <line>` to list every commit that changed the number of
occurrences of that exact line of code.

## Install (lazy.nvim)

```lua
{
  'congee/pickaxe.nvim', -- or dir = '/path/to/pickaxe.nvim' for a local copy
  cmd = { 'Pickaxe', 'PickaxeSearch' },
  keys = {
    { '<leader>gp', function() require('pickaxe').open() end, desc = 'Pickaxe blame stack' },
  },
  opts = {},
}
```

## Usage

| Where   | Key / command     | Action                                            |
| ------- | ----------------- | ------------------------------------------------- |
| Buffer  | `:Pickaxe`        | Open the blame popup for the current line          |
| Buffer  | `:PickaxeSearch`  | `git log -S` search for the current line           |
| Popup   | `o` / `<C-n>`     | Older commit                                       |
| Popup   | `O` / `<C-p>`     | Newer commit                                       |
| Popup   | `d`               | Toggle the embedded diff                           |
| Popup   | `p`               | Pickaxe search for the current line                |
| Popup   | `y`               | Yank the commit hash                               |
| Popup   | `?`               | Key help                                           |
| Popup   | `q` / `<Esc>`     | Close                                              |

`<C-p>` is buffer-local to the popup, so it won't clash with a global picker
mapping.

## Configuration

See `:help pickaxe.setup` for all options and defaults.

[gm]: https://github.com/rhysd/git-messenger.vim
