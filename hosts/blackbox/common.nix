{ config, pkgs, ... }:

{

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cwu = {
    isNormalUser = true;
    shell = pkgs.zsh;  # per user
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # home-manager  # just for bootstrapping; to be managed by home-manager itself
    git
    vim
  ];

  programs.zsh.enable = true;  # default for all users, implies programs.zsh.enableCompletion
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    enableSSHSupport = true;  # implies: programs.ssh.startAgent = true;
    pinentryFlavor = "tty";
    # TODO: ~/.gnupg/scdaemon.conf
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
