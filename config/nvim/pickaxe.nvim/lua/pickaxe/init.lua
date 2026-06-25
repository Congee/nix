local config = require('pickaxe.config')
local git = require('pickaxe.git')
local ui = require('pickaxe.ui')

local M = {}

--- @class pickaxe.State
--- @field root string|nil
--- @field entries pickaxe.Entry[]
--- @field index integer        1-based cursor into `entries`; 1 is the newest.
--- @field show_diff boolean
local state = { root = nil, entries = {}, index = 0, show_diff = true }

--- @return pickaxe.Entry|nil
local function current()
  return state.entries[state.index]
end

local handlers = {}

local function render()
  local entry = current()
  if not entry then
    return
  end
  -- Show the History counter whenever the line actually has deeper history,
  -- even on the first screen. `index < #entries` means an older entry is already
  -- loaded; otherwise probe (memoized) for one we haven't fetched yet.
  local has_older = state.index < #state.entries or git.has_older(entry)
  ui.render({
    entry = entry,
    index = state.index,
    has_older = has_older,
    show_diff = state.show_diff,
    handlers = handlers,
  })
end

function handlers.close()
  ui.close()
end

--- Walk one commit older in the blame stack, fetching across renames on demand.
function handlers.older()
  local entry = current()
  if not entry or not git.is_committed(entry) then
    return
  end

  if state.index < #state.entries then
    state.index = state.index + 1
    render()
    return
  end

  local next_entry = git.older_entry(entry)
  if not next_entry then
    git.notify('No older blame entry found; this is probably the introduction point.', vim.log.levels.INFO)
    return
  end

  table.insert(state.entries, next_entry)
  state.index = #state.entries
  render()
end

--- Walk one commit newer (back toward the working tree).
function handlers.newer()
  if state.index > 1 then
    state.index = state.index - 1
    render()
  end
end

function handlers.toggle_diff()
  state.show_diff = not state.show_diff
  render()
end

function handlers.yank()
  local entry = current()
  if not entry or not entry.hash then
    return
  end
  vim.fn.setreg('+', entry.hash)
  git.notify('Copied ' .. entry.hash)
end

function handlers.pickaxe()
  M.search()
end

function handlers.help()
  git.notify(table.concat({
    'pickaxe keys:',
    '  o / <C-n>   older commit',
    '  O / <C-p>   newer commit',
    '  d           toggle diff',
    '  p           pickaxe -S search for this line',
    '  y           yank commit hash',
    '  q / <Esc>   close',
  }, '\n'))
end

--- Resolve the (root, text) used for a pickaxe search from the popup if open,
--- otherwise from the current buffer's cursor line.
--- @return string|nil root, string|nil needle
local function search_context()
  local entry = current()
  if ui.is_open() and entry then
    return entry.root, entry.text
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    git.notify('Current buffer has no file name', vim.log.levels.WARN)
    return nil, nil
  end
  file = vim.fn.fnamemodify(file, ':p')
  local root = git.git_root(file)
  if not root then
    return nil, nil
  end
  local needle = vim.api.nvim_get_current_line()
  return root, needle
end

--- Pickaxe search: open a scratch buffer listing every commit that changed the
--- number of occurrences of the line's text (`git log -S`). This is the fallback
--- for refactor-heavy history that blame traversal can't follow.
function M.search()
  local root, text = search_context()
  if not root then
    return
  end

  local lines, needle = git.pickaxe_log(root, text)
  if not needle then
    git.notify('No line text to search for', vim.log.levels.WARN)
    return
  end

  if not lines or (#lines == 1 and lines[1] == '') then
    lines = { 'No pickaxe hits for:', needle }
  else
    table.insert(lines, 1, 'Pickaxe -S hits for: ' .. needle)
    table.insert(lines, 2, '')
  end

  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, 'pickaxe-search')
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'git'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

--- Open the blame popup for the line under the cursor.
function M.open()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    git.notify('Current buffer has no file name', vim.log.levels.WARN)
    return
  end
  file = vim.fn.fnamemodify(file, ':p')

  local root = git.git_root(file)
  if not root then
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local entry = git.blame_at(root, nil, git.relpath(root, file), line, false)
  if not entry then
    return
  end

  state.root = root
  state.entries = { entry }
  state.index = 1
  state.show_diff = config.options.show_diff
  render()
end

--- @param opts pickaxe.Config?
function M.setup(opts)
  local options = config.setup(opts)
  if type(options.keymap) == 'string' then
    vim.keymap.set('n', options.keymap, M.open, { desc = 'Pickaxe blame stack' })
  end
end

return M
