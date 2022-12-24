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

require("lazy").setup("plugins")
