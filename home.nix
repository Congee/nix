{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cwu";
  home.homeDirectory = "/home/cwu";

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
    jq
    tree
    fd
    ripgrep
    croc
    fzf
    lua
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
    exa
    # unstable.fx  # json viewer. I don't like cli written in js tho
    unstable.scc
    unstable.navi # cheat sheet
    unstable.haskellPackages.cabal-install
    unstable.haskellPackages.ghc
    unstable.haskellPackages.implicit-hie
    unstable.haskellPackages.hoogle
    wl-clipboard

    tdesktop  # telegram
    youtube-dl-light
    unstable.wofi  # rofi but with wayland
    thunderbird
    unstable.slack-dark
    unstable.spotify
    mpv
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  fonts.fontconfig.enable = true;

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
        rev = "e14d47010ac7fc096d6701585b42d89b6a59293c";
      };
    }
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/wfxr/forgit";
        rev = "7806fc3ab37ac479c315eb54b164f67ba9ed17ea";
      };
    }
    {
      name = "gitstatus";
      file = "gitstatus.prompt.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/romkatv/gitstatus";
        rev = "97c2aa170a7a81b06c48279a3f3a875030a28ee2";
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
    {  # TODO: make it work with `nix flake develop`
      name = "zsh-nix-shell";
      file = "nix-shell.plugin.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "chisui";
        repo = "zsh-nix-shell";
        rev = "v0.1.0";
        sha256 = "0snhch9hfy83d4amkyxx33izvkhbwmindy0zjjk28hih1a9l2jmx";
      };
    }
  ];
  programs.zsh.initExtra = builtins.readFile ./config/.zshrc;

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  programs.tmux.enable = true;
  programs.tmux.tmuxinator.enable = true;
  home.file.".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink ./config/.tmux.conf;
  home.file.".tmuxinator".source = config.lib.file.mkOutOfStoreSymlink ./config/.tmuxinator.yml;


  programs.neovim.enable = true;
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink ./config/nvim;

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "TwoDark";
    style = "plain";
  };

  # pass
  programs.password-store.enable = true;

  programs.ssh.enable = true;
  home.file.".ssh/config".source = config.lib.file.mkOutOfStoreSymlink ./config/ssh_config;

  programs.git = {
    enable = true;
    includes = [
      { path = ./config/gitconfig; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ./config/gitattributes);
  };

  programs.htop.enable = true;
  programs.htop.highlightBaseName = true;
  programs.htop.hideThreads = true;
  programs.htop.showProgramPath = false;
  programs.htop.treeView = true;

  programs.zathura.enable = true;  # pdf

  programs.fzf.enable = true;
  programs.alacritty.enable = true;
  home.file.".config/alacritty/alacritty.yml".source = config.lib.file.mkOutOfStoreSymlink ./config/alacritty.yml;

  services.flameshot.enable = true;

  programs.firefox.enable = true;
  programs.firefox.enableGnomeExtensions = true;

  gtk.enable = true;
  gtk.theme.name = "Dracula";
  gtk.theme.package = unstable.dracula-theme;
  gtk.iconTheme.name = "Paper";  # Candy and Tela also look good
  gtk.iconTheme.package = unstable.paper-icon-theme;

  home.activation.gsettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # https://askubuntu.com/questions/140255/how-to-override-the-new-limited-keyboard-repeat-rate-limit
    $DRY_RUN_CMD gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 24
    $DRY_RUN_CMD gsettings set org.gnome.desktop.peripherals.keyboard delay 300

    $DRY_RUN_CMD gsettings set org.gnome.desktop.session idle-delay $((60 * 15))  # black screen
    $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout $((60 * 45))

    $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys play "['<Super>c']"
    $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys previous "['<Super>z']"
    $DRY_RUN_CMD gsettings set org.gnome.settings-daemon.plugins.media-keys next "['<Super>x']"

    # dconf dump / > dconf.settings
    $DRY_RUN_CMD dconf write /org/gnome/shell/enabled-extensions "['openweather-extension@jenslody.de', 'appindicatorsupport@rgcjonas.gmail.com']"
  '';
}
