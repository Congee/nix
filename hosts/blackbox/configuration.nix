# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # xanmod has a problem with cgroups for k3s
  linuxPackages = pkgs.linuxPackages;
  corefreq = config.boot.kernelPackages.callPackage ./corefreq.nix { };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
      ../nixcmd.nix
    ];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Droidcam
  boot.extraModulePackages = [ linuxPackages.v4l2loopback corefreq ];
  boot.kernelModules = [ "v4l2loopback" "snd-aloop" "corefreqk" "binder_linux" ];
  boot.extraModprobeConfig = ''
    # 2 for droidcam hw=2,1,0
    options snd_aloop index=2
  '';
  boot.kernelPackages = linuxPackages;

  boot.crashDump.enable = true;
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/kernel_administration_guide/kernel_crash_dump_guide#sect-memory-requirements
  # Y@offset is required for x86 architecture
  # https://www.kernel.org/doc/Documentation/kdump/kdump.txt
  # 160M + 2bits per 4KB = 160MB + 6MB
  boot.crashDump.reservedMemory = "192M@0M";
  boot.tmp.useTmpfs = true;

  # will be available next
  # programs.droidcam.enable = true;

  networking.hostName = "blackbox"; # Define your hostname.
  # NOTE: nmcli does not really connect to a fixed bssid
  # See https://unix.stackexchange.com/a/612469/195575
  networking.wireless.iwd.enable = false;
  networking.wireless.iwd.package = import ./iwd.nix { inherit pkgs; };
  # man iwd.config(5)
  networking.wireless.iwd.settings = {
    Settings = { Hidden = true; };
    General = {
      EnableNetworkConfiguration = true;
      RoamThreshold = "-55";  # 2.4G, default = -70
      RoamThreshold5G = "-80"; # 5G, default = -76
    };
    Network = { EnableIPv6 = true; };
  };

  services.tailscale.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services.resolved.enable = true;
  services.resolved.extraConfig = "DNSOverTLS=opportunistic";

  # Set your time zone.
  time.timeZone = "America/New_York";

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

  services.nixseparatedebuginfod.enable = true;
  services.preload.enable = true;

  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [
    git
    at-spi2-core  # pkgs.xdg-desktop-portal-gtk
    corefreq
    nixos-option
    virt-manager
  ];
  programs.adb.enable = true;

  # TODO: move to userland
  # https://github.com/NixOS/nixpkgs/issues/31293
  programs.dconf.enable = true;
  programs.xwayland.enable = true;  # xcb (Qt), chromium and electron

  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk  # gtk apps need it anyway?
  ];

  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.userServices = true;
  services.geoclue2.enable = true;
  services.geoclue2.appConfig = {
    "geoclue-where-am-i" = {
      isAllowed = true;
      isSystem = false;
      users = [ "1000" ];
    };
  };

  # FIXME: do not login until graphical.target is ready
  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      # command = ''${pkgs.greetd.greetd}/bin/agreety --cmd "wayfire >/tmp/wayfire.out 2>/tmp/wayfire.err"'';
      command = ''${pkgs.greetd.greetd}/bin/agreety --cmd "zsh --login"'';
    };
  };

  services.usbmuxd.enable = true;
  services.upower.enable = true;
  services.fstrim.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.greetd.sshAgentAuth = true;
  security.pam.enableSSHAgentAuth = true;

  security.tpm2.enable = true;
  security.tpm2.abrmd.enable = true;

  services.pcscd.enable = true;  # smart card

  # List services that you want to enable:
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.enable = true;
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    5900  # vnc. why doesn't it work?
    6443  # k3s
    10250 # k3s metrics-server
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.

  systemd.packages = [ corefreq ];
  # rootless k3s isn't ready yet.
  # rootlesskit --net=slirp4netns --copy-up=/etc --disable-host-loopback buildkitd --addr unix://$XDG_RUNTIME_DIR/buildkit/rootless --containerd-worker-addr /run/k3s/containerd/containerd.sock
  systemd.sockets.buildkit = {
    socketConfig = {
      ListenStream = "%t/buildkit/buildkitd.sock";
      SocketMode = "0660";
    };
    wantedBy = [ "sockets.target" ];
  };

  systemd.services.buildkit = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "containerd.service" ];
    after = [ "containerd.service" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.buildkit}/bin/buildkitd --addr unix://%t/buildkit/buildkitd.sock --containerd-worker-addr %t/containerd/containerd.sock";
    };
  };

  virtualisation.containerd.enable = true;
  virtualisation.containerd.settings.version = 2;
  virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri" = {
    cni.conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d/";
    cni.bin_dir = let plugins = pkgs.buildEnv {
      name = "full-cni";
      paths = with pkgs; [ cni-plugins cni-plugin-flannel ];
    }; in "${plugins}/bin";
  };

  systemd.services.k3s = {
    wants = [ "containerd.service" ];
    after = [ "containerd.service" ];
  };

  services.k3s.enable = true;
  services.k3s.clusterInit = true;
  services.k3s.disableAgent = false;
  services.k3s.extraFlags = builtins.toString [
    "--container-runtime-endpoint unix:///run/containerd/containerd.sock"
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_24;
  virtualisation.docker.daemon.settings = {
    containerd = "/run/containerd/containerd.sock";
    containerd-namespace = "k8s.io";
    features = {
      containerd-snapshotter = true;
    };
    experimental = true;
    debug = true;
  };

  virtualisation.waydroid.enable = false;
}
