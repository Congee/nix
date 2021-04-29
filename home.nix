{ config, pkgs, lib, ... }:

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
  ];

  programs.zsh.enable = true;
  programs.zsh.plugins = [
    {
      name = "forgit";
      file = "forgit.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/wfxr/forgit";
        rev = "7806fc3ab37ac479c315eb54b164f67ba9ed17ea";
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
  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink ./.zshrc;

  programs.neovim.enable = true;
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink ./nvim;

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "TwoDark";
    style = "plain";
  };

  # pass
  programs.password-store.enable = true;

  programs.ssh.enable = true;
  home.file.".ssh/config".source = config.lib.file.mkOutOfStoreSymlink ./ssh_config;

  programs.git = {
    enable = true;
    includes = [
      { path = ./gitconfig; }
    ];
    attributes = lib.splitString "\n" (builtins.readFile ./gitattributes);
  };

  programs.htop.enable = true;
  programs.tmux.enable = true;
  programs.fzf.enable = true;
  programs.z-lua.enable = true;
  programs.z-lua.options = [ "fzf" ];
}
