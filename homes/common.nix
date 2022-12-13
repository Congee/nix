{ config, pkgs, lib, inputs, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
  nur = pkgs.nur.repos.congee;
in
{
  manual.manpages.enable = false;
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cwu";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/cwu" else "/home/cwu";
  # xdg.configFile."nixpkgs/home.nix".source = ln ./home.nix;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  programs.home-manager.enable = true;  # to use the unstable in nix-channel
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    leetcode-cli

    nur.sncli
    nur.devspace
    nur.kim

    difftastic
    delta
    expect
    man-pages
    pandoc
    gnumake
    moreutils # sponge
    jo
    jq
    yq
    tree
    fd
    ripgrep
    croc
    unzip
    binutils  # ar for libluajit.a
    sumneko-lua-language-server
    luajit
    luajitPackages.luarocks
    socat
    ccache
    # racket
    python3
    nodejs
    yarn
    duf
    ncdu
    (gitstatus.overrideAttrs (_: _: { doInstallCheck = false;}))  # fails on mac
    gh
    awscli2
    aws-vault
    sl
    gti
    cmatrix
    cowsay
    lolcat
    doge
    fortune
    file
    zip
    zbar  # qrcode
    p7zip
    nixfmt
    nil
    rnix-lsp
    nix-index
    nix-tree
    nix-diff  # diff .drv files
    statix  # nix linter
    patchelf
    lsof
    xh
    exercism
    litecli
    nmap
    # fx  # json viewer. I don't like cli written in js tho
    mkcert  # https on localhost
    cargo  # for shell completion
    cargo-edit
    cargo-clone  # download .crate files
    rust-analyzer
    gdb
    scc
    navi # cheat sheet
    # haskellPackages.stack
    haskellPackages.cabal-install
    haskellPackages.ghc
    # haskellPackages.haskell-language-server
    haskellPackages.implicit-hie
    haskellPackages.hoogle
    rbw pinentry
    yt-dlp-light
    ffmpeg
    # llvmPackages_latest.clang also ships this binary but bin/cc is in
    # conflict with gcc/*/bin/cc
    clang-tools
    stylua

    hadolint  # lint Dockerfile
    rancher
    # -- Already provided by Rancher Desktop
    # lima
    # kubernetes
    # for k3s + helm without sudo `kubectl config view --raw >~/.kube/config`
    kubernetes-helm  # kept for zsh-completion
    kubectl
    # kubectl-tree
    # kompose
    sops age rage ssh-to-age

    flac
    shntool
    cuetools

    earthly
    pulumi-bin

    tmate
    tmux
    tmuxinator
  ];

  xdg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

  home.file.".snclirc".source = ln ../config/.snclirc;

  # must be put before zsh, or some zsh settings are overriden
  # programs.tmux.enable = true;
  # programs.tmux.tmuxinator.enable = true;
  home.file.".tmux.conf".text = with pkgs;
  (builtins.readFile ../config/.tmux.conf) + lib.optionalString stdenv.isDarwin
  ''
    # Make pam_tid.so work in tmux
    __helper="${nur.pam-reattach}/bin/reattach-to-session-namespace";
    set-option -g default-command "$__helper zsh"
  '';
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
        rev = "55d07cc57750eb90f8b02be3ddf42c206ecf17b1";
      };
    }
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/wfxr/forgit";
        rev = "e0d3552d4597f42c5c965daa5abd79845990f63a";
      };
    }
    {
      name = "gitstatus";
      file = "gitstatus.prompt.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/romkatv/gitstatus";
        rev = "6dc0738c0e5199b0ae47d9693874e7d43c7f8f29";
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
  programs.zsh.enableCompletion = false;  # the nix-zsh-completions is too old;
  programs.zsh.initExtraBeforeCompInit = "autoload -U compinit && compinit";
  programs.zsh.initExtra = builtins.concatStringsSep "\n" [
    "${builtins.readFile ../config/.zshrc}"
    # it's already set but not inherited to home-manager zsh
    ''export GPG_TTY="$(tty)"''
  ];
  # tmux new sessions do not source .zshrc which is for an _interactive_ shell.
  # .zprofile -> .zshrc -> .zlogin -> .zlogout, in that sourcing order
  home.file.".zlogin".source = ln ../config/.zlogin;

  programs.dircolors.enable = true;

  programs.broot.enable = true;
  programs.readline.enable = true;
  programs.exa.enable = true;
  programs.zsh.shellAliases = { e = "${pkgs.exa}/bin/exa"; };

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  programs.java.enable = true;
  programs.neovim.enable = true;
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;
  programs.neovim.withNodeJs = true;

  # packer.nvim claims everything in packer/. To prevent it from manage itself,
  # install it in a random name like nixpacker. Anything inside
  # will be sourced ~/.local/share/nvim/site/pack/*/start
  # https://github.com/nix-community/home-manager/issues/1907#issuecomment-934316296
  # xdg.dataFile."nvim/site/pack/nixpacker/start/packer.nvim".source = "${pkgs.vimPlugins.packer-nvim}";
  xdg.dataFile."nvim/site/pack/nixpacker/start/packer.nvim".source = "${pkgs.vimPlugins.packer-nvim.overrideAttrs (_: _: {
    src = pkgs.fetchFromGitHub {
      owner = "wbthomason";
      repo = "packer.nvim";
      rev = "4dedd3b08f8c6e3f84afbce0c23b66320cd2a8f2";
      sha256 = "dGmvrQOscGZ+Qk/RCJKJEOxUOcFrAHBGxpASNKZyWCc=";
    };
  })}";
  xdg.configFile."coc/extensions/coc-sumneko-lua-data/sumneko-lua-ls/extension/server/bin/lua-language-server".source = ln "${pkgs.sumneko-lua-language-server}/bin/lua-language-server";
  # xdg.configFile."nvim".source = ln ../config/nvim;

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "DarkNeon";
    style = "plain";
  };
  home.file.".clang-format".source = ln ../config/.clang-format;

  # pass
  programs.password-store.enable = true;
  home.sessionVariables = {
    AWS_VAULT_PASS_PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    DIRENV_LOG_FORMAT = "";  # quiet direnv
  };

  home.file.".ssh/config".source = ln ../config/ssh/config;
  home.file.".ssh/allowed_signers".source = ln ../config/ssh/allowed_signers;

  programs.git = {
    enable = true;
    difftastic.enable = true;
    difftastic.background = "dark";
    includes = [
      { path = ../config/gitconfig; }
      { path = builtins.toString (builtins.fetchGit "https://github.com/dandavison/delta") + "/themes.gitconfig"; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ../config/gitattributes);
  };

  programs.htop.enable = true;
  programs.htop.settings.highlight_basename = true;
  programs.htop.settings.hide_userland_threads = true;
  programs.htop.settings.show_program_path = false;
  programs.htop.settings.tree_view = false;
}
