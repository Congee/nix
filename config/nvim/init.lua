require('packer.luarocks').install_commands()
require('plugins')

local __file__ = debug.getinfo(1).short_src
local vimrc = __file__:match("@?(.*/)") .. 'vimrc'
vim.api.nvim_command('source ' .. vimrc)
