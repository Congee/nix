{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    xvfb-run
    gcc
    bind  # dig
  ];

  # ~/.zprofile is managed by common.nix via programs.zsh.profileExtra; declaring
  # it again here would collide with the zsh module's generated ~/.zprofile.
}
