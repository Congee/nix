-- ghostty_bar.lua — Send neovim statusline to ghostty's status bar.
--
-- Evaluates the heirline statusline, extracts highlight segments, converts
-- them to ghostty SET-COMPONENTS JSON, and sends over the control socket.
--
-- Splits at %= so left-of-Align → zone "left", right-of-Align → zone "right".
-- Ghostty renders tabs in the center zone independently.
--
-- Requires: GHOSTTY_SOCKET env var pointing to the control socket.

local M = {}

local socket_path = os.getenv("GHOSTTY_SOCKET")

local source = "nvim-" .. vim.fn.getpid()

--- Send one or more commands to the ghostty control socket.
--- Creates a fresh connection each time (server closes after each read).
local function send_cmds(cmds)
  if type(cmds) == "string" then cmds = { cmds } end

  local p = vim.uv.new_pipe(false)
  if not p then return end

  local ok, _ = pcall(function()
    p:connect(socket_path)
  end)
  if not ok then
    p:close()
    return
  end

  local payload = table.concat(cmds, "\n") .. "\n"
  pcall(function()
    p:write(payload, function()
      pcall(function() p:close() end)
    end)
  end)
end

--- Convert a vim highlight group to an RGB hex string (#rrggbb).
--- Returns nil if the group has no fg color.
local function hl_to_hex(group_info)
  local fg = group_info.fg
  if not fg then return nil end
  return string.format("#%06x", fg)
end

local function hl_bg_to_hex(group_info)
  local bg = group_info.bg
  if not bg then return nil end
  return string.format("#%06x", bg)
end

--- Extract styled components from an nvim_eval_statusline result.
local function extract_components(ns_id, stl)
  local str = stl.str
  local highlights = stl.highlights or {}
  local components = {}

  for i, hi in ipairs(highlights) do
    local seg_start = hi.start + 1 -- lua is 1-indexed
    local seg_end = (highlights[i + 1] and highlights[i + 1].start) or #str
    local text = string.sub(str, seg_start, seg_end)

    if #text > 0 then
      local group = vim.api.nvim_get_hl(ns_id, { name = hi.group, link = false })
      local style = {}
      local fg = hl_to_hex(group)
      local bg = hl_bg_to_hex(group)
      if fg then style.fg = fg end
      if bg then style.bg = bg end
      if group.bold then style.bold = true end
      if group.italic then style.italic = true end
      if group.underline then style.underline = true end
      if group.strikethrough then style.strikethrough = true end

      table.insert(components, {
        text = text,
        style = next(style) and style or nil,
      })
    end
  end

  return components
end

--- Evaluate the current statusline and send SET-COMPONENTS to ghostty.
function M.update()
  if not socket_path then return end

  local ns_id = math.max(vim.api.nvim_get_hl_ns({ winid = vim.fn.win_getid() }), 0)
  local opts = { highlights = true }

  local ok, full_stl = pcall(vim.api.nvim_eval_statusline, vim.o.stl, opts)
  if not ok or not full_stl then return end

  local comps = extract_components(ns_id, full_stl)
  if #comps == 0 then return end

  -- Detect the %= alignment padding: the widest whitespace-only segment.
  -- Use >= so later candidates of equal width win (%= comes after left-side spaces).
  local split_idx = nil
  local max_space_len = 0
  for i, comp in ipairs(comps) do
    if comp.text:match("^%s+$") and #comp.text >= max_space_len and #comp.text >= 3 then
      max_space_len = #comp.text
      split_idx = i
    end
  end

  local cmds = {}

  if split_idx then
    local left_comps = {}
    for i = 1, split_idx - 1 do
      table.insert(left_comps, comps[i])
    end
    local right_comps = {}
    for i = split_idx + 1, #comps do
      table.insert(right_comps, comps[i])
    end

    if #left_comps > 0 then
      table.insert(cmds, "SET-COMPONENTS " .. vim.fn.json_encode({
        zone = "left",
        source = source,
        components = left_comps,
      }))
    end
    if #right_comps > 0 then
      table.insert(cmds, "SET-COMPONENTS " .. vim.fn.json_encode({
        zone = "right",
        source = source,
        components = right_comps,
      }))
    end
  else
    table.insert(cmds, "SET-COMPONENTS " .. vim.fn.json_encode({
      zone = "left",
      source = source,
      components = comps,
    }))
  end

  if #cmds > 0 then
    send_cmds(cmds)
  end
end

--- Clear our components from the ghostty status bar.
function M.cleanup()
  send_cmds("CLEAR-COMPONENTS " .. source)
end

--- Set up autocommands to drive the updates.
function M.setup()
  if not socket_path then return end

  local group = vim.api.nvim_create_augroup("GhosttyBar", { clear = true })

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
    callback = M.update,
    group = group,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    pattern = "statusline",
    callback = M.update,
    group = group,
  })

  vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, {
    callback = M.cleanup,
    group = group,
  })

  -- Initial update
  vim.defer_fn(M.update, 100)
end

M.setup()

return M
