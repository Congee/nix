{
  description = "home-mamager";

  inputs = {
    nur.url                             = "github:nix-community/NUR";
    utils.url                           = "github:numtide/flake-utils";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url                           = "github:NixOS/nixpkgs/nixos-21.11";
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
              inputs.nur.overlay
              inputs.wayland.overlay
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
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
              inputs.nur.overlay
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
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
              inputs.nur.overlay
              inputs.neovim-nightly.overlay
              (final: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
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

    nixosConfigurations.blackbox = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
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
