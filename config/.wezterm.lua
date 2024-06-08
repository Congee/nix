-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.unix_domains = {
	{
		name = "unix",
    skip_permissions_check = true,
	},
}

-- This causes `wezterm` to act as though it was started as
-- `wezterm connect unix` by default, connecting to the unix
-- domain on startup.
-- If you prefer to connect manually, leave out this line.
config.default_gui_startup_args = { "connect", "unix" }
config.default_prog = { 'zsh', '--login' }

-- For example, changing the color scheme:
config.color_scheme = "nightfox"
-- config.default_cursor_style = "BlinkingBlock"
config.font = wezterm.font("CodeNewRoman Nerd Font Mono")
config.font_size = 15.0
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.enable_tab_bar = true
config.tab_and_split_indices_are_zero_based = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_tabs_in_tab_bar = true;
config.show_new_tab_button_in_tab_bar = false
config.colors = {
  tab_bar = {
    background = '#1a1a1a',
    inactive_tab = {
      fg_color = '#b4b4b4',
      bg_color = '#1a1a1a',
    }
  },
}
config.window_frame = {
  border_left_width = '0cell',
  border_right_width = '0cell',
  border_bottom_height = '0cell',
  border_top_height = '0cell',
}

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

local function last(array) return array[#array]; end

local function get_active_window()
  local workspace = wezterm.mux.get_active_workspace()
  for _, window in ipairs(wezterm.mux.all_windows()) do
    if window:get_workspace() == workspace then
      return window;
    end
  end

  return nil;
end

wezterm.on('gui-attached', function(domain)
  get_active_window():gui_window():maximize();
end)

wezterm.on('mux-startup', function()
  local _, init_pane, window = wezterm.mux.spawn_window {}

  local tbl = {
    { cwd = '~/.nix', title = 'personal' },
    { cwd = '~/OneDrive/Apps/remotely-save/obsidian', cmd = "nvim TODO.md", title = 'notes', },
    { cwd = '~/dev/speedify', title = 'work' },
  };

  local expand = function(dir) return dir:gsub('~', wezterm.home_dir); end

  for _, cfg in ipairs(tbl) do
    local args = {};

    if cfg.cwd ~= nil then
      args.cwd = expand(cfg.cwd);
    end

    local tab, pane, _ = window:spawn_tab(args);
    if cfg.cmd ~= nil then
      pane:send_text(cfg.cmd .. '\n');
    end

    if cfg.title ~= nil then
      tab:set_title(cfg.title);
    end
  end

  init_pane:send_text('exit\n');
end)

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end


wezterm.on('format-tab-title', function(tab_info, tabs, panes, cfg, hover, max_width)
  return ' ' .. tab_info.tab_index .. ':' .. tab_title(tab_info) .. ' ';
end)


wezterm.on('user-var-changed', function(window, pane, name, value)
  -- wezterm.log_info(name, value, pane:pane_id())
end)

--- @param str string
local function gap_statusline(str)
  local lo = 0;
  local hi = 0;
  local best_lo = 0;
  local best_hi = 0;

  local isspace = function(s) return s:match("%s") ~= nil end

  for i = 1, #str do
    local ch = str:sub(i, i);

    if not isspace(ch) then
      lo = i;
      hi = i;
      goto continue;
    end

    hi = hi + 1;

    if hi - lo > best_hi - best_lo then
      best_hi = hi;
      best_lo = lo;
    end

    ::continue::
  end

  return best_lo, best_hi
end

---@param str string
---@param start string
local function startswith(str, start) return str:sub(1, #start) == start end;

---@class Group
---@field fg? string|number
---@field bold? boolean

---@class Highlight
---@field group Group
---@field start number

---@class StatusLine
---@field str string
---@field width number Display width of the statusline.
---@field highlights Highlight[]

---@param group Group
---@param text string
local function parse_item(group, text)
  -- TODO: parse all attributes https://neovim.io/doc/user/builtin.html#synIDattr()
  local format_item = { 'ResetAttributes' };

  if group.fg then
    local fg = type(group.fg) == 'number' and string.format('#%x', group.fg) or group.fg;
    table.insert(format_item, { Foreground = { Color = fg } });
  end

  if group.bold then
    table.insert(format_item, { Attribute = { Intensity = 'Bold' } });
  end

  table.insert(format_item, { Text = text });

  return format_item
end

---@param lhs table
---@param rhs table
function table.merge(lhs, rhs)
  local copy = lhs;
  for i=1, #rhs do
    copy[#copy+1] = rhs[i];
  end
  return copy;
end

---@param s string
---@param i number
---@param j number
function utf8.sub(s, i, j)
	i = utf8.offset(s, i)
	j = utf8.offset(s, j + 1) - 1
	return string.sub(s, i, j)
end

---@param stl StatusLine
---@param right_lo number
---@param max_left number
local function parse(stl, right_lo, max_left)
  local left = {}
  local right = {}
  local cnt = 0;
  local truncated = false;

  for i, hilit in ipairs(stl.highlights) do
    local next = i == #stl.highlights and stl.str:len() or stl.highlights[i + 1].start;
    local segment = string.sub(stl.str, hilit.start + 1, next);
    local text = segment;
    if cnt + utf8.len(segment) >= max_left and not truncated then
      text = wezterm.truncate_right(segment, max_left - cnt);
      truncated = true;
    end
    cnt = cnt + utf8.len(text);

    local target = hilit.start + 1 <= right_lo and left or right;
    table.merge(target, parse_item(hilit.group, text));
  end

  return left, right
end

wezterm.on("update-status", function(gui_window, pane)
  ---@type StatusLine?
  local statusline = wezterm.json_parse(pane:get_user_vars().statusline or 'null');
  local tabs = gui_window:mux_window():tabs();
  local mid_width = 0;
  for idx, tab in ipairs(tabs) do
    local title = tab:get_title();
    mid_width = mid_width + math.floor(math.log(idx, 10)) + 1
    mid_width = mid_width + 2 + #title + 1
  end
  local tab_width = gui_window:active_tab():get_size().cols;
  local max_left = tab_width / 2 - mid_width / 2;

  if statusline == nil then
    gui_window:set_left_status(wezterm.pad_left(' ', max_left))
    gui_window:set_right_status('')
    return;
  end

  local left_hi, right_lo = gap_statusline(statusline.str);
  local left_status, right_status = parse(statusline, right_lo, max_left);

	gui_window:set_left_status(wezterm.format(left_status))
	gui_window:set_right_status(wezterm.format(right_status))
end)

wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Rename tab',
      icon = 'md_rename_box',

      action = wezterm.action.PromptInputLine {
        description = 'Enter new name for tab',
        action = wezterm.action_callback(function(window, pane, name)
          if name then
            window:active_tab():set_title(name)
          end
        end),
      },
    },
  };
end)

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "s",
		mods = "LEADER|CTRL",
		action = wezterm.action.SendKey({ key = "s", mods = "CTRL" }),
	},
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }),
	},
	{
		key = '"',
		mods = "LEADER|SHIFT",
		action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }),
	},
	{
		key = "%",
		mods = "LEADER",
		action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
	},
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action({ ActivatePaneDirection = "Left" }),
	},
	{
		key = "j",
		mods = "LEADER",
		action = wezterm.action({ ActivatePaneDirection = "Down" }),
	},
	{
		key = "k",
		mods = "LEADER",
		action = wezterm.action({ ActivatePaneDirection = "Up" }),
	},
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action({ ActivatePaneDirection = "Right" }),
	},
	{
		key = "H",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ AdjustPaneSize = { "Left", 5 } }),
	},
	{
		key = "J",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ AdjustPaneSize = { "Down", 5 } }),
	},
	{
		key = "K",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ AdjustPaneSize = { "Up", 5 } }),
	},
	{
		key = "L",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ AdjustPaneSize = { "Right", 5 } }),
	},
	{ key = "0", mods = "LEADER", action = wezterm.action({ ActivateTab = 0 }) },
	{ key = "1", mods = "LEADER", action = wezterm.action({ ActivateTab = 1 }) },
	{ key = "2", mods = "LEADER", action = wezterm.action({ ActivateTab = 2 }) },
	{ key = "3", mods = "LEADER", action = wezterm.action({ ActivateTab = 3 }) },
	{ key = "4", mods = "LEADER", action = wezterm.action({ ActivateTab = 4 }) },
	{ key = "5", mods = "LEADER", action = wezterm.action({ ActivateTab = 5 }) },
	{ key = "6", mods = "LEADER", action = wezterm.action({ ActivateTab = 6 }) },
	{ key = "7", mods = "LEADER", action = wezterm.action({ ActivateTab = 7 }) },
	{ key = "8", mods = "LEADER", action = wezterm.action({ ActivateTab = 8 }) },
	{ key = "9", mods = "LEADER", action = wezterm.action({ ActivateTab = 8 }) },
	{ key = "-", mods = "LEADER", action = wezterm.action.ActivateTabRelativeNoWrap(1024 - 1) },
	{ key = "=", mods = "LEADER", action = wezterm.action.ActivateLastTab },
	{ key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelativeNoWrap(-1) },
	{ key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelativeNoWrap(1) },
	{
		key = "o",
		mods = "LEADER",
		action = "TogglePaneZoomState",
	},
	{
		key = "z",
		mods = "LEADER",
		action = "TogglePaneZoomState",
	},
}

-- and finally, return the configuration to wezterm
return config
