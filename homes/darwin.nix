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
    mtr
    mas
    buildkit
  ];

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".source = ln ../config/fonts.conf;

  programs.kitty.enable = true;
  programs.kitty.theme = "One Dark";
  programs.kitty.extraConfig = ''
    # include ${config.home.homeDirectory}/.nix/config/kitty.conf
    include ${ln ../config/kitty.conf}
  '';
  # home.file.".config/kitty/kitty.conf".source = ln "${config.home.homeDirectory}/.nix/config/kitty.conf";

  programs.alacritty.enable = true;
  programs.alacritty.package = pkgs.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.mac.yml;

  home.file.".zprofile".source = ln ../config/.zprofile;
  home.file.".zshrc.mac".source = ln ../config/.zshrc.mac;
}
