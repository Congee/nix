{
  description = "home-mamager";

  inputs = {
    utils.url                           = "github:numtide/flake-utils";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixpkgs-unstable";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay";
    leetcode-cli.url                    = "path:./packages/leetcode-cli";
    home-manager.url                    = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, home-manager, nixpkgs, ... } @ inputs: {
    homeConfigurations = let
      common = {
        system = "x86_64-linux";
        stateVersion = "21.11";
        username = "cwu";
        homeDirectory = "/home/cwu";
        extraSpecialArgs = { inherit inputs; };
      };
    in
      {
        desktop = home-manager.lib.homeManagerConfiguration (common // {
          configuration = { pkgs, config, lib, ... }: {
            # on being new: overlay > unstable > stable
            nixpkgs.overlays = [
              inputs.wayland.overlay
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
              inputs.leetcode-cli.overlay.${common.system}
            ];
            imports = [
              ./homes/common.nix
              ./homes/desktop.nix
            ];
          };
        });
        wsl = home-manager.lib.homeManagerConfiguration (common // {
          configuration = { pkgs, config, lib, ... }: {
            nixpkgs.overlays = [
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
              inputs.leetcode-cli.overlay.${common.system}
            ];
            imports = [
              ./homes/common.nix
              ./homes/wsl.nix
            ];
          };
        });
      };
    desktop = self.homeConfigurations.desktop.activationPackage;
    wsl = self.homeConfigurations.wsl.activationPackage;
  };
}
