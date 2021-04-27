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
    ripgrep
    croc
    bat
    fzf
    lua
    socat
    ccache
    bind  # dig
  ];

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

  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink ./.zshrc;
}
