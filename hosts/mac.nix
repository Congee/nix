{ lib, config, pkgs, inputs, ... }:

{

  imports = [
    ./nixcmd.nix
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.home-manager
    pkgs.mpv
  ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # `auth sufficient pam_tid.so`
  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Homebrew looks for `git` only from a few places. We have to make sure our
  # `git` is used.
  # ln -s /Users/cwu/.nix-profile/bin/git $HOMEBREW_PREFIX/bin/
  homebrew.enable = true;  # still have to manually install homebrew
  homebrew.global.brewfile = true;
  homebrew.casks = [
    "adobe-acrobat-reader"
    "aldente"
    "audacity"
    "aws-vpn-client"
    "dbeaver-community"
    "dozer"
    "firefox"
    "itsycal"
    "musicbrainz-picard"
    "postman"
    "rancher"
    "rectangle"
    "secretive"
    "sekey"
    "stats"
    "tunnelblick"
  ];
  homebrew.extraConfig = ''
    tap "conduktor/brew"
    cask "conduktor", greedy: true
    cask "zoom", greedy: true
    cask "spotify", greedy: true
  '';
  # This is painfully slow
  homebrew.masApps = (if true then { } else {
    "Bible Study" = 472790630;
    Bitwarden     = 1352778147;
    EuDic         = 434350458;
    GIF           = 1081413713;
    GarageBand    = 682658836;
    Gifski        = 1351639930;
    OneDrive      = 823766827;
    QQ            = 451108668;
    Telegram      = 747648890;
    WeChat        = 836500024;
  });

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.defaults.dock.autohide = true;
  system.defaults.dock.show-recents = false;
  system.defaults.trackpad.Clicking = true;
  system.defaults.trackpad.TrackpadThreeFingerDrag = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 25;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
}
