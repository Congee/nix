{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
  wayland = import (builtins.fetchGit {
    url = https://github.com/colemickens/nixpkgs-wayland;
    rev = "226aa9c2a6019dce37787b32ed7274c23034ffb0";
  });

  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  nixpkgs.overlays = [
    wayland
  ];

  home.packages = with pkgs; [
    # wayland
    waybar
    wayfire
    unstable.wcm  # wayfire config manager
    wofi
    mako  # notifacation daemon
    gtk-layer-shell
    aml  # vnc server
    clipman
    wev  # like xev to show keyboard events
    pamixer  # pamixer to control volume
    wlay  # graphical output management
    pavucontrol
    playerctl  # prev/next/play/pause music
    grim slurp  # screenshot
    imv  # image viewer
    wayvnc
    wf-recorder
    gnome.nautilus
    kanshi  # display configuration tool
    greetd.tuigreet  # display/login manager
    xdg-utils  # xdg-open

    pciutils  # lspci
    usbutils  # lsusb

    wl-clipboard
    unstable.goldendict
    unstable.evolution
    unstable.zathura
    element-desktop
    nheko

    tdesktop  # telegram
    thunderbird
    unstable.slack-dark
    unstable.spotify
    unstable.spicetify-cli
    unstable.postman
    unstable.insomnia
    unstable.charles
    unstable.ungoogled-chromium
    mpv

    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
    openvpn  # depends on services.resolved.enable = true

    # pacmd load-module module-alsa-source device=hw:2,1,0 source_properties=device.description=droidcam
    unstable.droidcam

    glib
    # FIXME: No schemas installed https://github.com/NixOS/nixpkgs/issues/72282
    # https://github.com/NixOS/nixpkgs/blob/28a0d6d7a2c80f7bd6975312bfd0470fae2486e2/pkgs/development/libraries/gtk/3.x.nix#L204
    # FIXME: wrapProgram?
    # wrapGAppsHook should do it https://github.com/NixOS/nixpkgs/pull/32210
    gsettings-desktop-schemas
    unstable.capitaine-cursors
  ];

  xdg.configFile."kanshi/config".source = ln ../config/kanshi.conf;

  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;
  xdg.configFile."waybar".source = ln ../config/waybar;

  xdg.configFile."wayfire.ini".source = ln ../config/wayfire.conf;
  xdg.configFile."wofi/config".source = ln ../config/wofi/config;
  xdg.configFile."wofi/style.css".source = ln ../config/wofi/style.css;

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".source = ln ../config/fonts.conf;

  programs.alacritty.enable = true;
  programs.alacritty.package = unstable.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.yml;

  home.sessionVariables = {
    # https://github.com/NixOS/nixpkgs/issues/91218#issuecomment-822142127
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";  # electron 12 uses XWayland. apps cannot open link to firefox
    XDG_CURRENT_DESKTOP = "Wayfire";
    XDG_SESSION_TYPE = "wayland";
  };

  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-wayland;
  programs.firefox.profiles.default = {
    id = 0;  # means default
    isDefault = true;  # also sets to default if id is not 0
    path = "40rx423a.default";  # keep using the auto-generated default path

    # This creates the user.js that overrides settings of the default prefs.js.
    # Safe!
    settings = {
      # FIXME: not working, why?
      # "ui.key.accelKey" = 91;  # 91 -> Super, 17 -> Control
      "layout.css.devPixelsPerPx" = "1.25";  # HiDPI scaling factor
    };
  };

  gtk.enable = true;
  gtk.font.name = "Noto Sans";
  gtk.font.package = pkgs.noto-fonts;
  gtk.theme.name = "Dracula";
  gtk.theme.package = unstable.dracula-theme;
  gtk.iconTheme.name = "Papirus-Dark-Maia";  # Candy and Tela also look good
  gtk.iconTheme.package = unstable.papirus-maia-icon-theme;
  gtk.gtk3.extraConfig = {
    gtk-application-prefer-dark-theme = true;
    gtk-key-theme-name    = "Emacs";
    gtk-icon-theme-name   = "Papirus-Dark-Maia";
    gtk-cursor-theme-name = "capitaine-cursors";
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-key-theme = "Emacs";
      cursor-theme = "Capitaine Cursors";
    };
  };
  xdg.systemDirs.data = [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

  # gtk.gtk3.extraCss = ''
  #   bind "<super>c" { "copy-clipboard"  () };
  #   bind "<super>v" { "paste-clipboard" () };
  #   bind "<super>x" { "cut-clipboard"   () };
  # '';

  # home.activation.gsettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   # https://askubuntu.com/questions/140255/how-to-override-the-new-limited-keyboard-repeat-rate-limit
  #   $DRY_RUN_CMD gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 24
  #   $DRY_RUN_CMD gsettings set org.gnome.desktop.peripherals.keyboard delay 300

  #   $DRY_RUN_CMD gsettings set org.gnome.desktop.session idle-delay $((60 * 15))  # black screen
  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout $((60 * 45))

  #   # Super_L already does the job, no need for <Super>s
  #   $DRY_RUN_CMD gsettings set org.gnome.shell.keybindings toggle-overview '[]'
  #   $DRY_RUN_CMD gsettings set org.gnome.shell.keybindings toggle-application-view '[]'  # I don't need <Super>a
  #   $DRY_RUN_CMD gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"  # remove <Super>v

  #   # The concept of tab, window, and application are not so different in gnome
  #   # $DRY_RUN_CMD gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"

  #   # Show Activities
  #   # $DRY_RUN_CMD gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Super>Space']"
  #   # $DRY_RUN_CMD gsettings set org.gnome.mutter overlay-key ""

  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys previous "['<Super>a']"
  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys next "['<Super>s']"
  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys play "['<Super>d']"
  #   $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>BackSpace']"

  #   # dconf dump / > dconf.settings
  #   $DRY_RUN_CMD dconf write /org/gnome/shell/enabled-extensions "['openweather-extension@jenslody.de', 'appindicatorsupport@rgcjonas.gmail.com', 'no-title-bar@jonaspoehler.de']"
  # '';
}