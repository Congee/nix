local pid = vim.fn.getpid()
local in_wezterm = os.getenv('WEZTERM_PANE') ~= nil
local in_kitty = os.getenv('KITTY_LISTEN_ON') ~= nil

local kitty_pipe = (function()
  local env = os.getenv('KITTY_LISTEN_ON')
  if env == nil then return function() return nil end end
  local addr = string.sub(env, 6, -1) -- remove 'unix:'
  local pipe = vim.uv.new_pipe(true);
  if pipe == nil then return function() return nil end end

  vim.api.nvim_create_autocmd('VimLeave', {
    callback = function() pipe:close() end
  });
  return function()
    if pipe:is_writable() then return pipe end

    pipe:connect(addr);
    return pipe;
  end
end)();

---@param statusline? { str: string, width: integer, hilights: { group: vim.api.keyset.hl_info, start: integer }[] }
local function send(statusline)
  if in_kitty and false then
    local action = {
      cmd = 'set-user-vars',
      version = { 0, 41, 1 },
      no_response = true,
      payload = {
        var = {
          'vim=' .. vim.fn.json_encode({ pid = pid, statusline = statusline }),
          'time=' .. vim.fn.strftime('%T'),
        },
        match = 'all',
      },
    };

    local msg = vim.fn.json_encode(statusline and action)
    local osc = ('\x1bP@kitty-cmd%s\x1b\\'):format(msg)
    kitty_pipe():write(osc)
  elseif in_wezterm then
    local msg = vim.fn.json_encode(statusline and { pid = pid, statusline = statusline })
    local template = '\x1b]1337;SetUserVar=vim=%s\a';
    local osc = template:format(vim.base64.encode(msg));
    vim.api.nvim_chan_send(vim.v.stderr, osc)
  end
end

local function do_update()
  if not in_wezterm and not in_kitty then return end

  --- @type { highlights: { group: string, start: integer }[], str: string, width: integer }
  local stl = vim.api.nvim_eval_statusline(vim.o.stl, { highlights = true })
  local ns_id = math.max(vim.api.nvim_get_hl_ns({ winid = vim.fn.win_getid()}), 0);

  --- @param hi { group: string, start: integer }
  local fn = function(hi)
    local group = vim.api.nvim_get_hl(ns_id, { name = hi.group });
    return { group = group, start = hi.start }
  end

  --- @type { group: vim.api.keyset.hl_info, start: integer }[]
  local hilights = vim.iter(stl.highlights):map(fn):totable()

  send({ str = stl.str, width = stl.width, highlights = hilights });
  _G.wtf = { str = stl.str, width = stl.width, highlights = hilights }
end

local function do_cleanup()
  send(nil);
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
