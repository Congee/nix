local git = require('pickaxe.git')
local config = require('pickaxe.config')

local M = {}

--- @class pickaxe.UIState
--- @field win integer|nil
--- @field buf integer|nil
local state = { win = nil, buf = nil }

-- Monotonic counter so each popup buffer gets a unique name, even when a
-- reopened popup shows the same commit as a just-wiped one.
local buf_seq = 0

--- Parse git's "+HHMM"/"-HHMM" tz offset into seconds (0 when absent/malformed).
--- @param tz string|nil
--- @return integer
local function tz_offset(tz)
  local sign, hh, mm = (tz or ''):match('^([+-])(%d%d)(%d%d)$')
  if not sign then
    return 0
  end
  local secs = tonumber(hh) * 3600 + tonumber(mm) * 60
  return sign == '-' and -secs or secs
end

--- Render a commit timestamp in the commit's own recorded timezone (not the
--- viewer's), with the offset appended — e.g. "Wed Jun 25 14:58:00 2026 -0500".
--- @param epoch integer|nil  UTC seconds reported by git.
--- @param tz string|nil      Git tz offset like "-0500".
--- @return string
local function format_time(epoch, tz)
  if not epoch then
    return 'unknown date'
  end
  -- `!` makes os.date treat the (offset-shifted) epoch as UTC, so the result is
  -- the commit's local wall-clock time regardless of the viewer's timezone.
  local stamp = os.date('!' .. config.options.date_format, epoch + tz_offset(tz)) --[[@as string]]
  if tz and tz ~= '' then
    return stamp .. ' ' .. tz
  end
  return stamp
end

--- Append a block (body/diff) to `lines`, separated from the previous content by
--- a single blank line. Leading blanks in the block are stripped, and an empty
--- block contributes nothing — so there's no dangling separator or trailing pad
--- (the float's border supplies the visual framing instead).
--- @param lines string[]
--- @param more string[]
local function append_block(lines, more)
  local started = false
  for _, line in ipairs(more) do
    if not started and line == '' then
      -- strip leading blanks from the block
    else
      if not started then
        started = true
        lines[#lines + 1] = ''
      end
      lines[#lines + 1] = line
    end
  end
end

--- @param entry pickaxe.Entry
--- @param index integer  1-based position in the blame stack.
--- @param has_older boolean  Whether an older entry is reachable from here.
--- @param show_diff boolean
--- @return string[]
local function build_lines(entry, index, has_older, show_diff)
  local lines = {}

  local author = entry.author or 'unknown'
  local author_mail = entry.author_mail and (' <' .. entry.author_mail .. '>') or ''
  local headers = {}
  -- Surface the stack position whenever navigation is possible: either we can
  -- step newer (index > 1) or older history exists to step into.
  if index > 1 or has_older then
    headers[#headers + 1] = { 'History', '#' .. tostring(index - 1) }
  end
  headers[#headers + 1] = { 'Commit', entry.hash }
  headers[#headers + 1] = { 'Author', author .. author_mail }

  if entry.committer and entry.committer ~= entry.author then
    local committer_mail = entry.committer_mail and (' <' .. entry.committer_mail .. '>') or ''
    headers[#headers + 1] = { 'Committer', entry.committer .. committer_mail }
  end

  if entry.committer_time and entry.author_time and entry.committer_time ~= entry.author_time then
    headers[#headers + 1] = { 'Author Date', format_time(entry.author_time, entry.author_tz) }
    headers[#headers + 1] = { 'Committer Date', format_time(entry.committer_time, entry.committer_tz) }
  else
    headers[#headers + 1] = { 'Date', format_time(entry.author_time, entry.author_tz) }
  end

  local header_width = 0
  for _, header in ipairs(headers) do
    header_width = math.max(header_width, #header[1])
  end

  for _, header in ipairs(headers) do
    local key, value = header[1], header[2]
    lines[#lines + 1] = ('%s:%s %s'):format(key, string.rep(' ', header_width - #key), value)
  end

  local summary = (not git.is_committed(entry)) and 'This line is not committed yet' or (entry.summary or '')
  lines[#lines + 1] = ''
  lines[#lines + 1] = summary

  append_block(lines, git.commit_body(entry))

  if show_diff then
    append_block(lines, git.commit_diff(entry))
  end

  return lines
end

--- @param lines string[]
--- @return integer width, integer height
local function popup_size(lines)
  local width = math.min(config.options.width, math.max(50, vim.o.columns - 8))
  -- Fit the height to the content (#lines), capped by the configured max and the
  -- available rows — no artificial floor, so short popups don't pad with blanks.
  local height = math.max(1, math.min(config.options.height, vim.o.lines - 6, #lines))
  return width, height
end

function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

--- Render (or re-render) the popup for the given view.
--- @param view { entry: pickaxe.Entry, index: integer, has_older: boolean, show_diff: boolean, handlers: table<string, function> }
function M.render(view)
  local entry = view.entry
  if not entry then
    return
  end

  local lines = build_lines(entry, view.index, view.has_older, view.show_diff)

  M.close()
  buf_seq = buf_seq + 1
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buf, ('pickaxe://%d/%s'):format(buf_seq, entry.hash or 'working-tree'))
  vim.bo[state.buf].buftype = 'nofile'
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].swapfile = false
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  local width, height = popup_size(lines)
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = 'cursor',
    row = 1,
    col = 1,
    width = width,
    height = height,
    border = config.options.border,
    style = 'minimal',
    title = ' pickaxe ',
    title_pos = 'center',
    footer = ' o/<C-n> older  O/<C-p> newer  d diff  p pickaxe  y yank  ? help  q close ',
    footer_pos = 'center',
  })

  -- Set the filetype only after the buffer is shown in (and owned by) the float.
  -- Setting it while the buffer is still hidden can leave a reopened popup
  -- unhighlighted until the next redraw, because the syntax engine attaches to a
  -- buffer that has no window to repaint.
  vim.bo[state.buf].filetype = 'pickaxe'

  local h = view.handlers
  local function map(lhs, rhs)
    vim.keymap.set('n', lhs, rhs, { buffer = state.buf, nowait = true, silent = true })
  end
  map('q', h.close)
  map('<Esc>', h.close)
  map('o', h.older)
  map('O', h.newer)
  map('<C-n>', h.older)
  map('<C-p>', h.newer)
  map('d', h.toggle_diff)
  map('p', h.pickaxe)
  map('y', h.yank)
  map('?', h.help)
end

return M
