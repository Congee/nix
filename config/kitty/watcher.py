# ~/.config/kitty/mywatcher.py
from typing import Any

from kitty.boss import Boss
from kitty.window import Window


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    # This is a special function that is called just once when this watcher
    # module is first loaded, can be used to perform any initializztion/one
    # time setup. Any exceptions in this function are printed to kitty's
    # STDERR but otherwise ignored.
    ...

def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # Here data will contain old_geometry and new_geometry
    # Note that resize is also called the first time a window is created
    # which can be detected as old_geometry will have all zero values, in
    # particular, old_geometry.xnum and old_geometry.ynum will be zero.
    ...

def on_focus_change(boss: Boss, window: Window, data: dict[str, Any])-> None:
    # Here data will contain focused
    ...

def on_close(boss: Boss, window: Window, data: dict[str, Any])-> None:
    # called when window is closed, typically when the program running in
    # it exits
    ...

def on_set_user_var(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # called when a "user variable" is set or deleted on a window. Here
    # data will contain key and value
    tm = boss.active_tab_manager
    if tm is not None:
        tm.update_tab_bar_data()
        with open('/tmp/test', 'a+') as f:
            f.write(f'updated with -> {data=:}\n')

def on_title_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # called when the window title is changed on a window. Here
    # data will contain title and from_child. from_child will be True
    # when a title change was requested via escape code from the program
    # running in the terminal
    ...

def on_cmd_startstop(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # called when the shell starts/stops executing a command. Here
    # data will contain is_start, cmdline and time.
    ...

def on_color_scheme_preference_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # called when the color scheme preference of this window changes from
    # light to dark or vice versa. data contains is_dark and via_escape_code
    # the latter will be true if the color scheme was changed via escape
    # code received from the program running in the window
    ...
