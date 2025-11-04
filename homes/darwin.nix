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
    dbeaver-bin
    hidden-bar
    plistwatch
    # nerd-fonts.code-new-roman
    swiftdefaultapps # swda getUTIs | rg -i mpv
    wireshark
    mtr
    stats
    docker docker-credential-helpers
    oxker
    macmon
    pinentry_mac
    applesauce
    # (writeScriptBin "realpath" ''${coreutils}/bin/realpath "$@"'')
    swift-format
    (pkgs.writeShellScriptBin "ggrep" "exec -a $0 ${gnugrep}/bin/grep $@")
    (pkgs.writeShellScriptBin "gsed" "exec -a $0 ${gnused}/bin/sed $@")
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
  programs.wezterm.enable = false;
  programs.wezterm.package = pkgs.wezterm;
  home.file.".config/alacritty/alacritty.yml".source = ln ../config/alacritty.macos.yml;

  home.file.".zprofile".source = ln ../config/.zprofile;
  home.file.".zshrc.mac".source = ln ../config/.zshrc.mac;
}
