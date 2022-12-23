{ inputs, ... }:

{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      keep-outputs = true
      keep-derivations = true
    '';
    # Make `nix search nixpkgs#hello` use caches. `nix registry list` shows
    # by default `global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable`
    # in which the `nixpkgs` is frequently pulled. It results in more bandwidth
    # and cache misses.
    #
    # See https://github.com/NixOS/nixpkgs/issues/151533#issuecomment-999894356
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # Binary Cache for Haskell.nix
    settings.trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
    settings.substituters = [
      "https://cache.iog.io/"
      "https://nixpkgs-wayland.cachix.org"
    ];
  };
}
