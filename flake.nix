{
  description = "home-mamager";

  inputs = {
    utils.url                           = "github:numtide/flake-utils";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixpkgs-unstable";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay";
    leetcode-cli.url                    = "path:./packages/leetcode-cli";
    home-manager.url                    = "github:nix-community/home-manager";
    # home-manager.url                    = "github:Congee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url                          = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows       = "nixpkgs";
  };

  outputs = { self, home-manager, darwin, nixpkgs, ... } @ inputs: {
    homeConfigurations = let
      common = {
        stateVersion = "21.11";
        username = "cwu";
        extraSpecialArgs = { inherit inputs; };
      };
    in
      {
        desktop = home-manager.lib.homeManagerConfiguration (common // {
          system = "x86_64-linux";
	  homeDirectory = "/home/cwu";
          configuration = { pkgs, config, lib, ... }: {
            # on being new: overlay > unstable > stable
            nixpkgs.overlays = [
              inputs.wayland.overlay
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
              inputs.leetcode-cli.overlay."x86_64-linux"
            ];
            imports = [
              ./homes/common.nix
              ./homes/desktop.nix
            ];
          };
        });
        wsl = home-manager.lib.homeManagerConfiguration (common // {
          system = "x86_64-linux";
	  homeDirectory = "/home/cwu";
          configuration = { pkgs, config, lib, ... }: {
            nixpkgs.overlays = [
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
              inputs.leetcode-cli.overlay."x86_64-linux"
            ];
            imports = [
              ./homes/common.nix
              ./homes/wsl.nix
            ];
          };
        });
        mac = home-manager.lib.homeManagerConfiguration (common // {
          system = "aarch64-darwin";
	  homeDirectory = "/Users/cwu";
          configuration = { pkgs, config, lib, ... }: {
            nixpkgs.overlays = [
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
              inputs.leetcode-cli.overlay."aarch64-darwin"
            ];
            imports = [
              ./homes/common.nix
              ./homes/darwin.nix
            ];
          };
        });

      };
    desktop = self.homeConfigurations.desktop.activationPackage;
    wsl = self.homeConfigurations.wsl.activationPackage;

    darwinConfigurations.mac = darwin.lib.darwinSystem {
	system = "aarch64-darwin";
	modules = [ ./hosts/mac.nix darwin.darwinModules.simple ];
    };
    mac = self.darwinConfigurations.mac;
  };
}
