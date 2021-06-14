{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
  neovim-nightly = import (builtins.fetchGit {
    url = https://github.com/nix-community/neovim-nightly-overlay;
    rev = "8d8e974dd60b5ea5fa854bb2ce5db24eadf2b7df";
  });

  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  nixpkgs.overlays = [
    neovim-nightly
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cwu";
  home.homeDirectory = "/home/cwu";
  # xdg.configFile."nixpkgs/home.nix".source = ln ./home.nix;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";

  programs.home-manager.enable = true;  # to use the unstable in nix-channel
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    (import ../packages/leetcode-cli)
    (import ../packages/xh)
    (import ../packages/sncli)
    unstable.nixUnstable


    moreutils # sponge
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
    youtube-dl-light

    tmate
    tmux
    tmuxinator

    unstable.vimPlugins.packer-nvim
  ];

  xdg.enable = true;
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  # must be put before zsh, or some zsh settings are overriden
  # programs.tmux.enable = true;
  # programs.tmux.tmuxinator.enable = true;
  home.file.".tmux.conf".source = ln ../config/.tmux.conf;
  home.file.".tmuxinator.yml".source = ln ../config/.tmuxinator.yml;

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
  # programs.mcfly.enable = true;
  programs.zsh.initExtra = builtins.readFile ../config/.zshrc;
  # tmux new sessions do not source .zshrc which is for an _interactive_ shell.
  # .zprofile -> .zshrc -> .zlogin -> .zlogout, in that sourcing order
  home.file.".zlogin".source = ln ../config/.zlogin;

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
  # xdg.configFile."nvim".source = ln ../config/nvim;

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "TwoDark";
    style = "plain";
  };

  # pass
  programs.password-store.enable = true;

  programs.ssh.enable = true;
  home.file.".ssh/config".source = ln ../config/ssh_config;

  programs.git = {
    enable = true;
    includes = [
      { path = ../config/gitconfig; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ../config/gitattributes);
  };

  programs.htop.enable = true;
  programs.htop.settings.highlight_basename = true;
  programs.htop.settings.hide_threads = true;
  programs.htop.settings.show_program_path = false;
  programs.htop.settings.tree_view = true;
}
