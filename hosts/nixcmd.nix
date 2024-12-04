{ inputs, lib, pkgs, ... }:

{
  nix = {
    settings.trusted-users = [ "@admin" "@wheel" ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    package = pkgs.nix.overrideAttrs (old: { patches = old.patches ++ [ ./0001-setenv-IN_NIX_SHELL-to-impure.patch ]; });

    # Binary Cache for Haskell.nix
    settings.trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    settings.substituters = [
      "https://cache.iog.io/"
      "https://nixpkgs-wayland.cachix.org"
      "https://nix-community.cachix.org/"
    ];
  };
}
