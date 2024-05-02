{ config, pkgs, lib, ... } @ inputs:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
  nur = pkgs.nur.repos.congee;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "CodeNewRoman" ]; })
    swiftdefaultapps # swda getUTIs | rg -i mpv 
    mtr
    mas
    kubectl
    docker docker-credential-helpers
    pinentry_mac
    # (writeScriptBin "realpath" ''${coreutils}/bin/realpath "$@"'')
    swift-format
  ];

  home.activation.gsettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # The system ncurses 5.7 is too old to have terminfo of tmux-256color
    find $HOME/.terminfo -name tmux-256color -delete 2>/dev/null || true
    mkdir -p $HOME/.terminfo
    zsh -c '/usr/bin/tic -x =(${pkgs.ncurses}/bin/infocmp -x tmux-256color)'
  '';

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".source = ln ../config/fonts.conf;
  home.sessionVariables = {
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
  };

  programs.alacritty.enable = true;
  programs.alacritty.package = pkgs.alacritty;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.macos.yml;

  home.file.".zprofile".source = ln ../config/.zprofile;
  home.file.".zshrc.mac".source = ln ../config/.zshrc.mac;
}
