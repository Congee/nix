{ lib, config, pkgs, inputs, ... }:

{

  imports = [
    ./nixcmd.nix
  ];
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.cacert
    pkgs.home-manager
    pkgs.mpv
  ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # required for services.tailscale.magicDNS
  # networking.dns = [
  #   "1.1.1.1"
  #   "8.8.8.8"
  #   "2606:4700:4700::1111"
  #   "2606:4700:4700::1001"
  #   "2001:4860:4860::8888"
  #   "2001:4860:4860::8844"
  # ];
  services.tailscale.enable = true;

  # Delete old nix-direnv roots
  services.angrr.enable = true;
  services.angrr.period = "1month";

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # `auth sufficient pam_tid.so`
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Homebrew looks for `git` only from a few places. We have to make sure our
  # `git` is used.
  # ln -s /Users/cwu/.nix-profile/bin/git $HOMEBREW_PREFIX/bin/
  homebrew.enable = true;  # still have to manually install homebrew
  homebrew.global.brewfile = true;
  homebrew.casks = [
    "battery"
    # need to figure out how to install proprietary apps
    # might also give Energiza Pro a try
    "monokle"
    "cloudflare-warp"
    # "jordanbaird-ice"
    "firefox"
    "itsycal"
    "obsidian"
    "orbstack"
    "pearcleaner"
    "rapidapi"
    "raycast"
    "rectangle"
    "red-canary-mac-monitor"  # replaces dtruss
    "secretive"
    "selfcontrol"
    "swiftdefaultappsprefpane"
    "zed"
    "moonlight"
  ];
  # This is painfully slow
  homebrew.masApps = if true then { } else {
    "Spotica Menu"= 570549457;
    Bitwarden     = 1352778147;
    EuDic         = 434350458;
    GIF           = 1081413713;
    GarageBand    = 682658836;
    Gifski        = 1351639930;
    Monodraw      = 920404675;
    OneDrive      = 823766827;
    QQ            = 451108668;
    Telegram      = 747648890;
    WeChat        = 836500024;
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.defaults.finder.FXDefaultSearchScope = "SCcf"; # current folder
  system.defaults.dock.autohide = true;
  system.defaults.dock.show-recents = false;
  system.defaults.trackpad.Clicking = true;
  system.defaults.trackpad.TrackpadThreeFingerDrag = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 25;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain.AppleFontSmoothing = 0;  # unfortunately global
  # https://flaky.build/native-fix-for-applications-hiding-under-the-macbook-pro-notch
  system.defaults.CustomSystemPreferences = {
    NSGlobalDomain = {
      NSStatusItemSelectionPadding = 6;
      NSStatusItemSpacing = 6;
    };
  };
  # System Preferences -> Privacy -> Full Disk Access
  # https://apple.stackexchange.com/a/360610/167199
  # https://superuser.com/questions/526183/remove-applications-from-location-services-in-security-privacy-on-mac-os-x-10
  system.defaults.CustomUserPreferences = {
    "com.apple.mail" = {};
  };
}
