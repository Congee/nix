{ lib, pkgs, config, modulesPath, ... }:

with lib;
let
  defaultUser = "cwu";
  syschdemd = import ./syschdemd.nix { inherit lib pkgs config defaultUser; };
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ./nixcmd.nix
  ];

  # WSL is closer to a container than anything else
  boot.isContainer = true;
  boot.kernelParams = [ "console=ttyS0" ];

  environment.etc.hosts.enable = false;
  environment.etc."resolv.conf".enable = false;
  networking.dhcpcd.enable = false;
  networking.hostName = "wsl";
  environment.etc."wsl.conf".text = ''
    [network]
    hostname = ${config.networking.hostName}
  '';

  environment.systemPackages = [
    pkgs.home-manager
    pkgs.git
    pkgs.vim
  ];

  users.users.root = {
    shell = "${syschdemd}/bin/syschdemd";
    # Otherwise WSL fails to login as root with "initgroups failed 5"
    extraGroups = [ "root" ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable systemd units that don't make sense on WSL
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  systemd.services.firewall.enable = false;
  systemd.services.systemd-resolved.enable = false;
  systemd.services.systemd-udevd.enable = false;

  virtualisation.docker.enable = true;

  # welp, this is embarrassing. ConditionVirtualization=!container
  # services.timesyncd.enable = true;

  # Don't allow emergency mode, because we don't have a console.
  systemd.enableEmergencyMode = false;
}
