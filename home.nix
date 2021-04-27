{ config, pkgs, ... }:

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
    jq
    tree
    htop
    fd
    ripgrep
    croc
    bat
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
    awscli2
    aws-vault
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
  ];
  programs.neovim.enable = true;
  programs.neovim.withPython3 = true;
  programs.neovim.viAlias = true;

  # pass
  programs.password-store.enable = true;

  programs.gh.enable = true;
  programs.gh.gitProtocol = "ssh";
  programs.git = {
    enable = true;
    userName = "Congee";
    userEmail = "***REMOVED***";
  };
  programs.tmux.enable = true;
  programs.fzf.enable = true;
  programs.z-lua.enable = true;
  programs.z-lua.options = [ "fzf" ];

  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink ./.zshrc;
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink ./nvim;
}
