{ config, pkgs, lib, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
  ];

  programs.zsh.plugins = [
    {
      name = "zsh-notify";
      file = "notify.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/marzocchi/zsh-notify";
        rev = "eb389765cb1bd3358e88ac31939ef2edfd539825";
      };
    }
  ];

  home.file.".zprofile".source = ln ../config/.zprofile;
}
