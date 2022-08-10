{ config, pkgs, lib, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;

  wsudo = (pkgs.writeScriptBin "wsudo" ''
    #small script to enable root access to x-windows system
    xhost +SI:localuser:root
    sudo --shell "$@"
    #disable root access after application terminates
    xhost -SI:localuser:root
    #print access status to allow verification that root access was removed
    xhost
  '').overrideAttrs (_: { prefreLocalBuild = true; buildInputs = [pkgs.xorg.xhost]; });
in
{
  home.enableNixpkgsReleaseCheck = false;
  home.packages = with pkgs; [

    # wayland
    waybar
    wayfire
    unstable.wcm  # wayfire config manager
    # XXX: wofi does not pick up envs from ~/.pam_environment 😠
    (symlinkJoin {
      name = "wofi";
      paths = [ wofi ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/wofi \
          --set GTK_IM_MODULE "fcitx" \
          --set QT_IM_MODULE "fcitx" \
          --set SDL_IM_MODULE "fcitx" \
          --set XMODIFIERS "@im=fcitx"
      '';
    })
    mako  # notifacation daemon
    gtk-layer-shell
    aml  # vnc server
    clipman
    wev  # like xev to show keyboard events
    pamixer  # pamixer to control volume
    wlay  # graphical output management
    pavucontrol
    playerctl  # prev/next/play/pause music
    grim slurp swappy # screenshot
    imv  # image viewer
    wayvnc
    wf-recorder
    gnome.nautilus
    gnome.zenity  # --color-selection
    kanshi  # display configuration tool
    greetd.tuigreet  # display/login manager
    xdg-utils  # xdg-open
    xvfb-run
    psmisc  # pstree, fuser
    progress
    lshw
    ltrace
    weechat
    mold
    gcc
    bind  # dig

    wavemon  # wifi signal strength
    pciutils  # lspci
    usbutils  # lsusb
    guvcview
    onedrive
    tlaplus
    tlaplusToolbox

    nerdctl
    buildkit

    wl-clipboard
    goldendict
    evolution
    element-desktop
    nheko

    xorg.xhost
    wsudo
    wireshark
    termshark
    scrcpy
    tdesktop  # telegram
    musescore
    thunderbird
    slack-dark
    spotify
    spicetify-cli
    postman
    insomnia
    charles
    dbeaver
    zoom-us
    mpv
    (writeScriptBin "whereami" ''${geoclue2}/libexec/geoclue-2.0/demos/where-am-i "$@"'')

    (nerdfonts.override { fonts = [ "CascadiaCode" "CodeNewRoman" ]; })
    # depends on services.resolved.enable = true
    (openvpn.overrideAttrs (_: rec {
      patches = [
        (fetchpatch {
          url = "https://raw.githubusercontent.com/samm-git/aws-vpn-client/master/openvpn-v2.5.1-aws.patch";
          sha256 = "sha256-9ijhANqqWXVPa00RBCRACtMIsjiBqYVa91V62L4mNas=";
        })
      ];
    }))

    # pacmd load-module module-alsa-source device=hw:2,1,0 source_properties=device.description=droidcam
    droidcam

    glib
    # FIXME: No schemas installed https://github.com/NixOS/nixpkgs/issues/72282
    # https://github.com/NixOS/nixpkgs/blob/28a0d6d7a2c80f7bd6975312bfd0470fae2486e2/pkgs/development/libraries/gtk/3.x.nix#L204
    # FIXME: wrapProgram?
    # wrapGAppsHook should do it https://github.com/NixOS/nixpkgs/pull/32210
    gsettings-desktop-schemas
    capitaine-cursors
  ];

  i18n.inputMethod.enabled = "fcitx5";
  i18n.inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ rime ];
  i18n.inputMethod.fcitx5.addons = with pkgs; [ fcitx5-rime fcitx5-with-addons ];
  pam.sessionVariables = {
    # actually cannot be picked up by wofi 😠
    GTK_IM_MODULE="fcitx";
    QT_IM_MODULE="fcitx";
    SDL_IM_MODULE="fcitx";
    XMODIFIERS="@im=fcitx";
  };
  xdg.configFile."fcitx5/conf/classicui.conf".source = ln "${config.home.homeDirectory}/nix/config/fcitx5/conf/classicui.conf";
  home.file.".local/share/fcitx5/rime/default.custom.yaml".source = ln "${config.home.homeDirectory}/nix/config/rime/default.custom.yaml";
  home.file.".local/share/fcitx5/rime/double_pinyin.custom.yaml".source = ln "${config.home.homeDirectory}/nix/config/rime/double_pinyin.custom.yaml";
  home.file.".local/share/fcitx5/rime/double_pinyin.schema.yaml".source = ln "${config.home.homeDirectory}/nix/config/rime/double_pinyin.schema.yaml";
  home.file.".local/share/fcitx5/rime/emoji.schema.yaml".source = ln "${config.home.homeDirectory}/nix/config/rime/emoji.schema.yaml";
  home.file.".local/share/fcitx5/themes/Nord-Dark".source = ln "${config.home.homeDirectory}/nix/config/fcitx5/themes/fcitx5-nord/Nord-Dark";

  home.file.".zshrc.linux".source = ln ../config/.zshrc.linux;

  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "${pkgs.llvmPackages_latest.clang.outPath}/bin/clang"
    rustflags = [
      "-C", "link-arg=-fuse-ld=${pkgs.mold.outPath}/bin/mold",
      # "-C", "link-arg=-fuse-ld=${pkgs.llvmPackages_latest.lld.outPath}/bin/lld",
      # "-C", "link-arg=-fuse-ld=gold",
    ]
  '';


  xdg.configFile."kanshi/config".source = ln ../config/kanshi.conf;
  # services.kanshi.enable = true;
  # services.kanshi.systemdTarget = "graphical.target";

  programs.zathura.enable = true;
  programs.zathura.package = pkgs.zathura;

  programs.obs-studio.enable = false;
  programs.obs-studio.package = [pkgs.obs-studio];
  programs.obs-studio.plugins = [pkgs.obs-studio-plugins.wlrobs];

  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;
  xdg.configFile."waybar".source = ln ../config/waybar;

  xdg.configFile."wayfire.ini".source = ln ../config/wayfire.conf;
  xdg.configFile."wofi/config".source = ln ../config/wofi/config;
  xdg.configFile."wofi/style.css".source = ln ../config/wofi/style.css;

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".source = ln ../config/fonts.conf;

  programs.alacritty.enable = true;
  programs.alacritty.package = pkgs.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.nixos.yml;

  home.sessionVariables = {
    # https://github.com/NixOS/nixpkgs/issues/91218#issuecomment-822142127
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";  # electron 12 uses XWayland. apps cannot open link to firefox
    XDG_CURRENT_DESKTOP = "Wayfire";
    XDG_SESSION_TYPE = "wayland";
  };

  programs.chromium.enable = true;
  programs.chromium.commandLineArgs = [
    "--enable-features=UseOzonePlatform"
    "--ozone-platform=wayland"
  ];
  programs.chromium.extensions = [
    { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
    { id = "laankejkbhbdhmipfmgcngdelahlfoji"; }  # stayfocused
  ];

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
      # A NixOS issue. It always asks if it's the default browser
      "browser.shell.checkDefaultBrowser" = false;
    };
  };

  gtk.enable = true;
  gtk.font.name = "Noto Sans";
  gtk.font.package = pkgs.noto-fonts;
  gtk.theme.name = "Dracula";
  gtk.theme.package = pkgs.dracula-theme;
  gtk.iconTheme.name = "Papirus-Dark-Maia";  # Candy and Tela also look good
  gtk.iconTheme.package = pkgs.papirus-maia-icon-theme;
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
