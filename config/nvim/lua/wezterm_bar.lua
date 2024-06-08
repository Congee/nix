---@param str string
local function send(str)
  -- uv.hrtime()
  local template = '\x1b]1337;SetUserVar=statusline=%s\a';
  local osc = template:format(vim.base64.encode(str));
  vim.api.nvim_chan_send(vim.v.stderr, osc)
end

local function do_update()
  local stl = vim.api.nvim_eval_statusline(vim.o.stl, { highlights = 1 })
  local ns_id = math.max(vim.api.nvim_get_hl_ns({ winid = vim.fn.win_getid()}), 0);

  for _, hilit in ipairs(stl.highlights) do
    hilit.group = vim.api.nvim_get_hl(ns_id, { name = hilit.group });
  end

  send(vim.fn.json_encode(stl));
end

local function do_cleanup()
  send('null');
end

-- https://github.com/vimpostor/vim-tpipeline/blob/5dd3832bd6e239feccb11cadca583cdcf9d5bda1/autoload/tpipeline.vim#L18
local group = vim.api.nvim_create_augroup("Statusline", {})
vim.api.nvim_create_autocmd({
	"FocusGained",
	"BufEnter",
	"InsertLeave",
	"CursorHold",
	"CursorHoldI",
	"ModeChanged",
	"CmdlineEnter",
	"CursorMoved",
}, {
	callback = do_update,
	group = group,
})
vim.api.nvim_create_autocmd({'OptionSet'}, {
  pattern = 'statusline',
	callback = do_update,
  group = group,
})
vim.api.nvim_create_autocmd({'FocusLost', 'VimLeavePre'}, {
	callback = do_cleanup,
  group = group,
})
