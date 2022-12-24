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
    duf ncdu gdu dua du-dust nix-du
    iotop bottom btop gtop
    procs
    curlie xh
    lsd
    dogdns
    (gitstatus.overrideAttrs (_: _: { doInstallCheck = false;}))  # fails on mac
    git-fire git-imerge # git-trim
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
    manix
    patchelf
    lsof
    xh
    watchexec
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

    act # run github actions locally
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
        rev = "7b8bb64cbb2014de66204b800bdac9ea149b6932";
      };
    }
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/wfxr/forgit";
        rev = "8ca463b5c69e95ed100dd66e1134427319cf407c";
      };
    }
    {
      name = "gitstatus";
      file = "gitstatus.prompt.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/romkatv/gitstatus";
        rev = "4b47ca047be1d482dbebec7279386a9365b946c6";
      };
    }
    {
      name = "zsh-async";
      file = "async.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/mafredri/zsh-async";
        rev = "3ba6e2d1ea874bfb6badb8522ab86c1ae272923d";
      };
    }
    {
      name = "zsh-nix-shell";
      file = "nix-shell.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/chisui/zsh-nix-shell";
        rev = "af6f8a266ea1875b9a3e86e14796cadbe1cfbf08";
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

  # Need this environment to build some native stuff
  # nix shell nixpkgs#llvmPackages_14.clang nixpkgs#zig nixpkgs#tree-sitter
  xdg.configFile."coc/extensions/coc-sumneko-lua-data/sumneko-lua-ls/extension/server/bin/lua-language-server".source = ln "${pkgs.sumneko-lua-language-server}/bin/lua-language-server";

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
