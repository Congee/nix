{ lib, config, pkgs, ... }:

{

  imports = [
    # ./common.nix
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

  nix = {
     extraOptions = ''
       experimental-features = nix-command flakes
       keep-outputs = true
       keep-derivations = true
     '';
     # Make `nix search nixpkgs#hello` use caches. `nix registry list` shows
     # by default `global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable`
     # in which the `nixpkgs` is frequently pulled. It results in more bandwidth
     # and cache misses.
     #
     # See https://github.com/NixOS/nixpkgs/issues/151533#issuecomment-999894356
     registry.nixpkgs.flake = inputs.nixpkgs;
     nixPath = { nixpkgs = "${inputs.nixpkgs}"; };
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  homebrew.enable = true;  # still have to manually install homebrew
  homebrew.casks = [
    "adobe-acrobat-reader"
    "aldente"
    "audacity"
    "aws-vpn-client"
    "dbeaver-community"
    "dozer"
    "firefox"
    "itsycal"
    "karabiner-elements"
    "musicbrainz-picard"
    "rancher"
    "rectangle"
    "secretive"
    "sekey"
    "spotify"
    "stats"
    "tunnelblick"
    "zoom"
  ];
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

  # Binary Cache for Haskell.nix
  nix.binaryCachePublicKeys = [
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
  ];
  nix.binaryCaches = [
    "https://hydra.iohk.io"
    "https://nixpkgs-wayland.cachix.org"
  ];
}
