# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  linuxPackages = pkgs.linuxPackages_xanmod;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
    ];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Droidcam
  boot.extraModulePackages = [ linuxPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" "snd-aloop" ];
  boot.extraModprobeConfig = ''
    # 2 for droidcam hw=2,1,0
    options snd_aloop index=2
  '';
  boot.kernelPackages = linuxPackages;
  boot.kernelParams = [ "console=ttyS0" ];

  # will be available next
  # programs.droidcam.enable = true;

  networking.hostName = "blackbox"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlo1.useDHCP = true;
  services.resolved.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    at-spi2-core  # pkgs.xdg-desktop-portal-gtk
  ];
  programs.adb.enable = true;

  # TODO: move to userland
  # https://github.com/NixOS/nixpkgs/issues/31293
  programs.dconf.enable = true;
  programs.xwayland.enable = true;  # xcb (Qt), chromium and electron

  xdg.portal.enable = true;
  xdg.portal.gtkUsePortal = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk  # gtk apps need it anyway?
    pkgs.xdg-desktop-portal-wlr
  ];

  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;
  services.geoclue2.enable = true;
  # services.geoclue2.appConfig = {
  #   "yo.congee.me" = {
  #     isAllowed = true;
  #     isSystem = false;
  #     users = [ "1000" ];
  #   };
  # };

  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.greetd}/bin/agreety --cmd wayfire";
    };
  };

  services.usbmuxd.enable = true;
  services.upower.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.greetd.sshAgentAuth = true;
  security.pam.enableSSHAgentAuth = true;

  # List services that you want to enable:
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.enable = true;
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 5900 ];  # vnc. why doesn't it work?
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.

  virtualisation.docker.enable = true;
  virtualisation.waydroid.enable = true;
}
