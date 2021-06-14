{ config, pkgs, lib, ... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
  wayland = import (builtins.fetchGit {
    url = https://github.com/colemickens/nixpkgs-wayland;
    rev = "226aa9c2a6019dce37787b32ed7274c23034ffb0";
  });

  ln = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ./common.nix
  ];

  home.file.".zprofile".source = ln ../config/.zprofile;
}
