{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
  neovim-nightly = import (builtins.fetchGit {
    url = https://github.com/nix-community/neovim-nightly-overlay;
    rev = "8d8e974dd60b5ea5fa854bb2ce5db24eadf2b7df";
  });
  wayland = import (builtins.fetchGit {
    url = https://github.com/colemickens/nixpkgs-wayland;
    rev = "226aa9c2a6019dce37787b32ed7274c23034ffb0";
  });

  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  nixpkgs.overlays = [
    neovim-nightly
    wayland
  ];


  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cwu";
  home.homeDirectory = "/home/cwu";
  xdg.configFile."nixpkgs/home.nix".source = ln ./home.nix;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";

  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    (import ./packages/leetcode-cli)
    (import ./packages/xh)
    (import ./packages/sncli)
    unstable.nixUnstable

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

    # FIXME: No schemas installed https://github.com/NixOS/nixpkgs/issues/72282
    glib
    gsettings_desktop_schemas

    moreutils # sponge
    pciutils  # lspci
    usbutils  # lsusb
    jq
    tree
    fd
    ripgrep
    croc
    gcc
    unzip
    luajit
    luajitPackages.luarocks
    socat
    ccache
    bind  # dig
    python3
    onedrive
    nodejs
    ncdu
    gitAndTools.gitstatus
    gitAndTools.gh
    awscli2
    aws-vault
    sl
    gti
    cmatrix
    cowsay
    fortune
    file
    p7zip
    rnix-lsp
    lshw
    nix-index
    nix-tree
    patchelf
    ltrace
    lsof
    # unstable.fx  # json viewer. I don't like cli written in js tho
    unstable.mkcert  # https on localhost
    unstable.weechat
    unstable.gdb
    unstable.scc unstable.navi # cheat sheet
    unstable.haskellPackages.cabal-install
    unstable.haskellPackages.ghc
    unstable.haskellPackages.implicit-hie
    unstable.haskellPackages.hoogle
    unstable.rbw pinentry
    wl-clipboard
    unstable.goldendict
    unstable.evolution
    unstable.zathura
    element-desktop
    nheko

    # pacmd load-module module-alsa-source device=hw:2,1,0 source_properties=device.description=droidcam
    unstable.droidcam
    tdesktop  # telegram
    youtube-dl-light
    thunderbird
    unstable.slack-dark
    unstable.spotify
    unstable.spicetify-cli
    unstable.postman
    unstable.insomnia
    unstable.charles
    unstable.ungoogled-chromium
    mpv
    tmate
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })

    openvpn  # depends on services.resolved.enable = true

    tmux
    tmuxinator

    unstable.vimPlugins.packer-nvim
  ];

  xdg.enable = true;
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  xdg.configFile."kanshi/config".source = ln ./config/kanshi.conf;

  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;
  xdg.configFile."waybar".source = ln ./config/waybar;

  xdg.configFile."wayfire.ini".source = ln ./config/wayfire.conf;
  xdg.configFile."wofi/config".source = ln ./config/wofi/config;
  xdg.configFile."wofi/style.css".source = ln ./config/wofi/style.css;

  fonts.fontconfig.enable = true;

  # must be put before zsh, or some zsh settings are overriden
  # programs.tmux.enable = true;
  # programs.tmux.tmuxinator.enable = true;
  home.file.".tmux.conf".source = ln ./config/.tmux.conf;
  home.file.".tmuxinator.yml".source = ln ./config/.tmuxinator.yml;

  programs.zsh.enable = true;
  programs.zsh.plugins = [
    # OMG this is sick, aggresive
    # {
    #   name = "zsh-autocomplete";
    #   file = "zsh-autocomplete.plugin.zsh";
    #   src = builtins.fetchGit {
    #     url = "https://github.com/marlonrichert/zsh-autocomplete";
    #     rev = "306e221bfec548b8cb54f1cc333a13d02e4cbe80";
    #   };
    # }
    {
      name = "zsh-completions";
      file = "zsh-completions.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/zsh-users/zsh-completions";
        rev = "9dfd5c667072a9aef13a237fe3c3cc857ca9917f";
      };
    }
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/wfxr/forgit";
        rev = "2db37aa4ecc94e41247a0eecb1b11896fa25cded";
      };
    }
    {
      name = "gitstatus";
      file = "gitstatus.prompt.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/romkatv/gitstatus";
        rev = "96b520b248ca872646e27b3df4535898356e4637";
      };
    }
    {
      name = "zsh-async";
      file = "async.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/mafredri/zsh-async";
        rev = "a61239dd55028eec173374883809f439c93d292b";
      };
    }
    {
      name = "zsh-nix-shell";
      file = "nix-shell.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/chisui/zsh-nix-shell";
        rev = "a2139b32fc1429160fc40658c9e16177c20597fc";
      };
    }
  ];
  programs.zsh.initExtra = builtins.readFile ./config/.zshrc;
  # tmux new sessions do not source .zshrc which is for an _interactive_ shell.
  # .zprofile -> .zshrc -> .zlogin -> .zlogout, in that sourcing order
  home.file.".zlogin".source = ln ./config/.zlogin;

  programs.readline.enable = true;
  programs.exa.enable = true;
  programs.zsh.shellAliases = { e = "${pkgs.exa}/bin/exa -al"; };

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  programs.neovim.enable = true;
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;
  programs.neovim.withNodeJs = true;

  # packer.nvim claims everything in packer/. To prevent it from manage itself,
  # install it in a random name like nixpacker. Anything inside
  # will be sourced ~/.local/share/nvim/site/pack/*/start
  xdg.dataFile."nvim/site/pack/nixpacker/start/packer.nvim".source = "${unstable.vimPlugins.packer-nvim}/share/vim-plugins/packer-nvim/";
  xdg.dataFile."nvim/site/plugin/fzf.vim".source = "${pkgs.fzf}/share/vim-plugins/fzf/plugin/fzf.vim";
  xdg.configFile."nvim".source = ln ./config/nvim;

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "TwoDark";
    style = "plain";
  };

  # pass
  programs.password-store.enable = true;

  programs.ssh.enable = true;
  home.file.".ssh/config".source = ln ./config/ssh_config;

  programs.git = {
    enable = true;
    includes = [
      { path = ./config/gitconfig; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ./config/gitattributes);
  };

  programs.htop.enable = true;
  programs.htop.settings.highlight_basename = true;
  programs.htop.settings.hide_threads = true;
  programs.htop.settings.show_program_path = false;
  programs.htop.settings.tree_view = true;

  # programs.mcfly.enable = true;

  programs.alacritty.enable = true;
  programs.alacritty.package = unstable.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ./config/alacritty.yml;

  home.sessionVariables = {
    # https://github.com/NixOS/nixpkgs/issues/91218#issuecomment-822142127
    MOZ_ENABLE_WAYLAND = "1";
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
      "ui.key.accelKey" = 91;  # 91 -> Super, 17 -> Control
      "layout.css.devPixelsPerPx" = "1.25";  # HiDPI scaling factor
    };
  };

  gtk.enable = true;
  gtk.theme.name = "Dracula";
  gtk.theme.package = unstable.dracula-theme;
  gtk.iconTheme.name = "Papirus";  # Candy and Tela also look good
  gtk.iconTheme.package = unstable.papirus-icon-theme;
  gtk.gtk3.extraConfig = {
    gtk-application-prefer-dark-theme = true;
    gtk-key-theme-name = "Emacs";
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-key-theme = "Emacs";
    };
  };

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
