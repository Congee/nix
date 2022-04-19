{ config, pkgs, lib, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
  nur = pkgs.nur.repos.congee;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "CascadiaCode" "CodeNewRoman" ]; })
    mtr
    mas
    buildkit
    pinentry_mac nur.pinentry-touchid
    nur.pam-reattach
    (writeScriptBin "realpath" ''${coreutils}/bin/realpath "$@"'')
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

  home.file.".zprofile".source = ln ../config/.zprofile;
  home.file.".zshrc.mac".source = ln ../config/.zshrc.mac;
}
