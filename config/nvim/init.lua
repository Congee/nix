local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

local __file__ = debug.getinfo(1).short_src
local vimrc = __file__:match("@?(.*/)") .. 'vimrc'
vim.api.nvim_command('source ' .. vimrc)

require("lazy").setup("plugins", {
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'netrwPlugin',
        'rplugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    }
  }
})

-- https://www.reddit.com/r/neovim/comments/1kcz8un/great_improvements_to_the_cmdline_in_nightly/
require('vim._core.ui2').enable({})

vim.cmd.packadd 'nvim.undotree'
