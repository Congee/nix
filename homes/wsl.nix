{ config, pkgs, lib, ... }:

let
  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    xvfb-run
    gcc
  ];

  home.file.".zprofile".source = ln ../config/.zprofile;
}
