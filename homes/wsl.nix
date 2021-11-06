{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };

  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    xvfb-run
  ];

  home.file.".zprofile".source = ln ../config/.zprofile;
}
