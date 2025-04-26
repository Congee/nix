#!/usr/bin/env python
# License: GPL v3 Copyright: 2018, Kovid Goyal <kovid at kovidgoyal.net>

import os
import re
from collections.abc import Callable, Sequence
from functools import lru_cache, partial, wraps
from string import Formatter as StringFormatter
from typing import (
    cast,
    Any,
    NamedTuple,
)

from kitty.borders import Border, BorderColor
from kitty.constants import config_dir
from kitty.boss import Boss
from kitty.fast_data_types import (
    BOTTOM_EDGE,
    DECAWM,
    Color,
    Region,
    Screen,
    cell_size_for_window,
    get_boss,
    get_options,
    pt_to_px,
    set_tab_bar_render_data,
    update_tab_bar_edge_colors,
    viewport_for_window,
    wcswidth,
)
from kitty.progress import ProgressState
from kitty.rgb import alpha_blend, color_as_sgr, color_from_int, to_color
from kitty.types import WindowGeometry, run_once
from kitty.typing import EdgeLiteral, PowerlineStyle
from kitty.utils import color_as_int, log_error, sgr_sanitizer_pat


class TabBarData(NamedTuple):
    title: str
    is_active: bool
    needs_attention: bool
    tab_id: int
    num_windows: int
    num_window_groups: int
    layout_name: str
    has_activity_since_last_focus: bool
    active_fg: int | None
    active_bg: int | None
    inactive_fg: int | None
    inactive_bg: int | None
    num_of_windows_with_progress: int
    total_progress: int
    last_focused_window_with_progress_id: int

class DrawData(NamedTuple):
    leading_spaces: int
    sep: str
    trailing_spaces: int
    bell_on_tab: str
    alpha: Sequence[float]
    active_fg: Color
    active_bg: Color
    inactive_fg: Color
    inactive_bg: Color
    default_bg: Color
    title_template: str
    active_title_template: str | None
    tab_activity_symbol: str
    powerline_style: PowerlineStyle
    tab_bar_edge: EdgeLiteral
    max_tab_title_length: int

    def tab_fg(self, tab: TabBarData) -> int:
        if tab.is_active:
            if tab.active_fg is not None:
                return tab.active_fg
            return int(self.active_fg)
        if tab.inactive_fg is not None:
            return tab.inactive_fg
        return int(self.inactive_fg)

    def tab_bg(self, tab: TabBarData) -> int:
        if tab.is_active:
            if tab.active_bg is not None:
                return tab.active_bg
            return int(self.active_bg)
        if tab.inactive_bg is not None:
            return tab.inactive_bg
        return int(self.inactive_bg)

class ExtraData:
    prev_tab: TabBarData | None = None
    next_tab: TabBarData | None = None
    # true if the draw_tab function is called just for layout. In such cases,
    # if drawing is expensive the draw_tab function should avoid drawing and
    # just move the cursor to its final position, as if drawing was performed.
    for_layout: bool = False


def as_rgb(x: int) -> int:
    return (x << 8) | 2

def draw_tab_with_fade(
    draw_data: DrawData, screen: Screen, tab: TabBarData,
    before: int, max_tab_length: int, index: int, is_last: bool,
    extra_data: ExtraData
) -> int:
    orig_bg = screen.cursor.bg
    tab_bg = color_from_int(orig_bg >> 8)
    fade_colors = [as_rgb(color_as_int(alpha_blend(tab_bg, draw_data.default_bg, alpha))) for alpha in draw_data.alpha]
    for bg in fade_colors:
        screen.cursor.bg = bg
        screen.draw(' ')
    screen.cursor.bg = orig_bg
    # draw_title(draw_data, screen, tab, index, max(0, max_tab_length - 8))
    extra = screen.cursor.x - before - max_tab_length
    if extra > 0:
        screen.cursor.x = before
        # draw_title(draw_data, screen, tab, index, max(0, max_tab_length - 4))
        extra = screen.cursor.x - before - max_tab_length
        if extra > 0:
            screen.cursor.x -= extra + 1
            screen.draw('…')
    for bg in reversed(fade_colors):
        if extra >= 0:
            break
        extra += 1
        screen.cursor.bg = bg
        screen.draw(' ')
    end = screen.cursor.x
    screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
    screen.draw(' ')
    return end

def get_user_vars(boss: Boss):
    if (window := cast(Boss, get_boss()).active_window) is not None:
        return window.user_vars

def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    import datetime as dt
    user_vars = get_user_vars(cast(Boss, get_boss()))
    # raise SyntaxError(f'{user_vars=:}, now={dt.datetime.now()}')
    # return draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
    with open('/tmp/test', 'w+') as f:
        f.write(f'{user_vars=:}')

    return 0
