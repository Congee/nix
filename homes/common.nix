{ config, pkgs, lib, nixpkgs, ... }:

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

  # NOTE: remember to run darwin-rebuild or nixos-rebuild to have
  # `nix registry list` to output the latest nixpkgs after doing
  # `nix flake lock --update-input nixpkgs`
  # https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-registry#description
  # https://rycee.gitlab.io/home-manager/options.xhtml#opt-nix.registry
  nix.registry.nixpkgs = {
    flake = nixpkgs;
    from = { id = "nixpkgs"; type = "indirect"; };
    to = { type = "path"; path = nixpkgs.outPath; };
  };

  programs.home-manager.enable = true;  # to use the unstable in nix-channel
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    leetcode-cli

    exiftool
    qrencode
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
    socat
    websocat
    ccache
    # racket
    python3
    nodejs
    yarn
    duf gdu dua du-dust # nix-du
    bottom btop gtop
    procs
    curlie xh
    lsd
    dogdns
    doggo
    gitstatus
    git-fire git-imerge # git-trim
    gh
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
    unar
    yamlfmt
    nix-search-cli
    nix-weather
    nix-inspect
    nix-output-monitor
    nixfmt-rfc-style
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
    zola
    cloudflared
    doctl civo
    hostctl
    nmap
    # fx  # json viewer. I don't like cli written in js tho
    mkcert  # https on localhost
    cargo  # for shell completion
    cargo-edit
    cargo-clone  # download .crate files
    cargo-generate
    cargo-show-asm
    cargo-expand
    ra-multiplex
    # (ra-multiplex.overrideAttrs(drv: rec {
    #   name = "ra-multiplex";
    #   version = "0.2.5";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "pr2502";
    #     repo = name;
    #     rev = "v${version}";
    #     hash = "sha256-aBrn9g+MGXLAsOmHqw1Tt6NPFGJTyYv/L9UI/vQU4i8=";
    #   };
    #   cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
    #     name = "${name}-${version}-verndor.tar.gz";
    #     inherit src;
    #     outputHash = "sha256-RWheS0ureDj0mVubPlXGprRoZcv4cqfy4XmIgeLFNFw=";
    #   });
    #   postInstall = ''
    #       wrapProgram $out/bin/ra-multiplex \
    #       --suffix PATH : ${lib.makeBinPath [ rust-analyzer ]}
    #   '';
    # }))
    # gdb
    # gdbgui
    scc
    navi # cheat sheet
    # haskellPackages.stack
    haskellPackages.cabal-install
    haskellPackages.ghc
    # haskellPackages.haskell-language-server
    haskellPackages.implicit-hie
    haskellPackages.hoogle
    rbw
    yt-dlp-light
    ffmpeg
    imagemagick
    timg # imgcat abstraction
    # llvmPackages_latest.clang also ships this binary but bin/cc is in
    # conflict with gcc/*/bin/cc
    shellcheck
    jwt-cli

    # vscode-langservers-extracted # json-lsp bin/vscode-json-languageserver
    ansible-language-server
    # autopep8
    bash-language-server
    biome
    buf
    clang-tools
    docker-compose-language-service
    dockerfile-language-server-nodejs
    eslint_d
    docker-language-server
    golangci-lint-langserver
    gopls
    harper
    helm-ls
    vscode-langservers-extracted # html-lsp bin/vscode-html-language-server
    lua-language-server luajit luajitPackages.luarocks
    markdownlint-cli2 mermaid-cli
    mesonlsp
    nil
    # pyright
    ruff
    ra-multiplex

    stylua
    typescript-language-server
    nodePackages_latest."@vue/language-server"
    # nodePackages_latest."some-sass-language-server"
    vim-language-server
    yaml-language-server

    # ◍ markdownlint (keywords: markdown)


    skaffold
    # hadolint  # lint Dockerfile
    rancher
    # for k3s + helm without sudo `kubectl config view --raw >~/.kube/config`
    kubernetes-helm  # kept for zsh-completion
    k9s
    kustomize
    helmfile
    kubectl
    k9s
    dive
    # kubectl-tree
    # kompose
    sops age rage ssh-to-age

    flac
    shntool
    cuetools

    act # run github actions locally

    tmate
    tmux
    tmuxinator
    zsh-forgit # for completions
  ];

  xdg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

  # must be put before zsh, or some zsh settings are overriden
  # programs.tmux.enable = true;
  # programs.tmux.tmuxinator.enable = true;
  home.file.".tmux.conf".text = with pkgs;
  (builtins.readFile ../config/.tmux.conf) + lib.optionalString stdenv.isDarwin
  ''
    # Make pam_tid.so work in tmux
    __helper="${pam-reattach}/bin/reattach-to-session-namespace";
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
      src = "${pkgs.zsh-completions.overrideAttrs (final: prev: { postFixup = ''
        ln -s $out/share/zsh/site-functions $out/share/zsh/src
        install -D --target-directory=$out/share/zsh zsh-completions.plugin.zsh
      ''; } )}/share/zsh";
    }
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = "${pkgs.zsh-forgit}/share/zsh/zsh-forgit";
    }
    {
      name = "gitstatus";
      file = "gitstatus.prompt.zsh";
      src = "${pkgs.gitstatus}/share/gitstatus";
    }
    {
      name = "zsh-nix-shell";
      file = "nix-shell.plugin.zsh";
      src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
    }
  ];
  # programs.mcfly.enable = true;
  programs.zsh.enableCompletion = false;  # the nix-zsh-completions is too old;
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 850 "autoload -U compinit && compinit")
    (lib.mkOrder 1200 (builtins.concatStringsSep "\n" [
      "${builtins.readFile ../config/.zshrc}"
      # it's already set but not inherited to home-manager zsh
      ''export GPG_TTY="$(tty)"''
    ]))
  ];
  # tmux new sessions do not source .zshrc which is for an _interactive_ shell.
  # .zprofile -> .zshrc -> .zlogin -> .zlogout, in that sourcing order
  home.file.".zlogin".source = ln ../config/.zlogin;
  home.activation.fpath = lib.hm.dag.entryAfter ["wrieBoundary"] ''
    mkdir -p ${config.xdg.dataHome}/zsh/site-functions
  '';
  xdg.dataFile."zsh/site-functions/_git-fixup".text = ''
    _git-fixup() { _arguments '1:commit:__git_recent_commits' }
  '';

  programs.dircolors.enable = true;

  programs.broot.enable = true;
  programs.readline.enable = true;
  programs.eza.enable = true;
  programs.zsh.shellAliases = { e = "${pkgs.eza}/bin/eza"; };

  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  programs.atuin.enable = true;
  programs.atuin.settings = {
    auto_sync = false;
    update_check = false;
    style = "compact";
    keys.prefix = "s";
  };
  programs.atuin.flags = [
    "--disable-up-arrow"
  ];
  programs.atuin.enableZshIntegration = true;

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.fzf.defaultOptions = [
    "--bind alt-y:preview-up,alt-e:preview-down"
    "--bind alt-up:preview-top,alt-down:preview-bottom"
  ];

  programs.java.enable = true;

  # Need this environment to build some native stuff
  # nix shell nixpkgs#llvmPackages_14.clang nixpkgs#zig nixpkgs#tree-sitter
  programs.neovim.enable = true;
  programs.neovim.package = pkgs.neovim;
  programs.neovim.extraPackages = [pkgs.llvmPackages_latest.clang];
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;
  programs.neovim.withNodeJs = true;

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
    difftastic.color = "always";
    extraConfig = {
      core.pager = "${pkgs.less}/bin/less -XF";
    };
    includes = [
      { path = ../config/git/config; }
      { path = builtins.toString (builtins.fetchGit {
        url = "https://github.com/dandavison/delta";
        rev = "42da5adab68c46277e20757f7a1f3b68eb874b0e";
        # ref = "refs/tags/0.18.2";
      }) + "/themes.gitconfig"; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ../config/git/gitattributes);
  };
  xdg.configFile."git/hooks".source = ln ../config/git/hooks;

  xdg.dataFile."helm/plugins/helm-diff".source = "${pkgs.kubernetes-helmPlugins.helm-diff}/helm-diff";
  xdg.dataFile."helm/plugins/helm-secrets".source = "${pkgs.kubernetes-helmPlugins.helm-secrets}/helm-secrets";
  xdg.dataFile."helm/plugins/helm-git".source = "${pkgs.kubernetes-helmPlugins.helm-git}/helm-git";
  xdg.dataFile."helm/plugins/helm-s3".source = let helm-s3 =
    pkgs.kubernetes-helmPlugins.helm-s3.overrideAttrs( old: { ldflags = [ "-s" "-w" "-X main.version=${old.version}" ]; });
  in "${helm-s3}/helm-s3";

  programs.htop.enable = true;
  programs.htop.settings.highlight_basename = true;
  programs.htop.settings.hide_userland_threads = true;
  programs.htop.settings.show_program_path = false;
  programs.htop.settings.tree_view = false;
}
