{ config, pkgs, ... }:

{

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cwu = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # home-manager  # just for bootstrapping; to be managed by home-manager itself
    git
    vim
  ];

  nix = {
     package = pkgs.nixUnstable;
     autoOptimiseStore = true;  # Replace identical files in the store by hard links.
     extraOptions = ''
       experimental-features = nix-command flakes
       keep-outputs = true
       keep-derivations = true
     '';
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;  # implies: programs.ssh.startAgent = true;
    pinentryFlavor = "tty";  # default null for the poor man's wayfire DE
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

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
