{
  description = "home-mamager";

  inputs = {
    nur.url                             = "github:nix-community/NUR";
    utils.url                           = "github:numtide/flake-utils";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url                           = "github:NixOS/nixpkgs/nixos-22.05";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay";
    home-manager.url                    = "github:nix-community/home-manager";
    # home-manager.url                    = "github:Congee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url                          = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows       = "nixpkgs";
  };

  outputs = { self, home-manager, darwin, nixpkgs, nixos, ... } @ inputs: {
    # home-manager
    homeConfigurations = {
      desktop = home-manager.lib.homeManagerConfiguration ({
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [
          ./homes/common.nix
          ./homes/desktop.nix
          {
            # on being new: overlay > unstable > stable
            nixpkgs.overlays = [
              inputs.nur.overlay
              inputs.wayland.overlay
              inputs.neovim-nightly.overlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
            ];
          }
        ];

      });
      wsl = home-manager.lib.homeManagerConfiguration ({
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [
          ./homes/common.nix
          ./homes/wsl.nix
          {
            nixpkgs.overlays = [
              inputs.nur.overlay
              inputs.neovim-nightly.overlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
            ];
          }
        ];
      });
      mac = home-manager.lib.homeManagerConfiguration ({
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        modules = [
          ./homes/common.nix
          ./homes/darwin.nix
          {
            nixpkgs.overlays = [
              inputs.nur.overlay
              inputs.neovim-nightly.overlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
            ];
          }
        ];
      });
    };
    desktop = self.homeConfigurations.desktop.activationPackage;
    wsl = self.homeConfigurations.wsl.activationPackage;

    nixosConfigurations.blackbox = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (_: prev: { gnupg = nixpkgs.legacyPackages.${prev.system}.gnupg; })
          ];
        }
        ./hosts/blackbox/configuration.nix
      ];
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations.mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./hosts/mac.nix ];
    };
    mac = self.darwinConfigurations.mac;
  };
}
