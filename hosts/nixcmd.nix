{ inputs, lib, pkgs, ... }:

{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      keep-outputs = true
      keep-derivations = true
    '';
    package = pkgs.nix.overrideAttrs (old: { patches = old.patches ++ [ ./0001-setenv-IN_NIX_SHELL-to-impure.patch ]; });

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
