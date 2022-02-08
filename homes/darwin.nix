{ config, pkgs, lib, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    alacritty
    (nerdfonts.override { fonts = [ "CascadiaCode" "CodeNewRoman" ]; })
  ];

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".source = ln ../config/fonts.conf;

  programs.alacritty.enable = true;
  programs.alacritty.package = pkgs.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.mac.yml;

  home.file.".zprofile".source = ln ../config/.zprofile;
}
