if vim.g.loaded_pickaxe then
  return
end
vim.g.loaded_pickaxe = true

vim.api.nvim_create_user_command('Pickaxe', function()
  require('pickaxe').open()
end, { desc = 'Pickaxe: blame-stack popup for the current line' })

vim.api.nvim_create_user_command('PickaxeSearch', function()
  require('pickaxe').search()
end, { desc = 'Pickaxe: git log -S search for the current line' })
