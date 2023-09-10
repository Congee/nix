{
  description = "home-mamager";

  inputs = {
    nur.url                             = "github:nix-community/NUR";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url                           = "github:NixOS/nixpkgs/nixos-23.05";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    # https://github.com/nix-community/neovim-nightly-overlay/issues/176#issuecomment-1528902953
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay/a9719c5050b1abbb0adada7dd9f98e0cdbd3ed53";
    home-manager.url                    = "github:nix-community/home-manager";
    # home-manager.url                    = "github:Congee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url                          = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows       = "nixpkgs";
    nixseparatedebuginfod.url           = "github:symphorien/nixseparatedebuginfod";
    flake-compat.url                    = "github:edolstra/flake-compat";
    flake-compat.flake                  = false;
  };

  outputs = { self, home-manager, darwin, nixpkgs, nixos, ... } @ inputs: {
    # home-manager
    homeConfigurations = {
      desktop = home-manager.lib.homeManagerConfiguration {
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
            nixpkgs.config.allowUnfreePredicate = (_: true);
            # for goldendict
            nixpkgs.config.permittedInsecurePackages = [ "qtwebkit-5.212.0-alpha4" ];
          }
        ];

      };
      wsl = home-manager.lib.homeManagerConfiguration {
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
      };
      mac = home-manager.lib.homeManagerConfiguration {
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
      };
    };
    desktop = self.homeConfigurations.desktop.activationPackage;
    wsl = self.homeConfigurations.wsl.activationPackage;

    # FIXME: https://github.com/nix-community/home-manager/issues/2848
    apps.x86_64-linux.update-home = {
      type = "app";
      program = (nixpkgs.legacyPackages.x86_64-linux.writeScript "update-home" ''
        set -euo pipefail
        old_profile=$(nix profile list | grep home-manager-path | head -n1 | awk '{print $4}')
        echo $old_profile
        nix profile remove $old_profile
        ${self.desktop}/activate || (echo "restoring old profile"; ${nixpkgs.legacyPackages.x86_64-linux.nix}/bin/nix profile install $old_profile)
      '').outPath;
    };

    nixosConfigurations.blackbox = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (_: prev: { inherit (nixpkgs.legacyPackages.${prev.system}) docker_24; })
            (_: prev: { inherit (nixpkgs.legacyPackages.${prev.system}) nix; })
            (_: prev: { inherit (nixpkgs.legacyPackages.${prev.system}) gnupg; })
            (_: prev: {  # https://github.com/NixOS/nixpkgs/issues/97855#issuecomment-1075818028
              nixos-option = let
                # consider --impure with bultins.getEnv "HOME"
                prefix = ''(import ${inputs.flake-compat} { src = /home/cwu/nix; }).defaultNix.nixosConfigurations.blackbox'';
              in prev.runCommandNoCC "nixos-option" { buildInputs = [ prev.makeWrapper ]; } ''
                makeWrapper ${prev.nixos-option}/bin/nixos-option $out/bin/nixos-option \
                  --add-flags --config_expr \
                  --add-flags "\"${prefix}.config\"" \
                  --add-flags --options_expr \
                  --add-flags "\"${prefix}.options\""
            '';
            })
          ];
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixos.lib.getName pkg) [
            "steam"
            "steam-run"
            "steam-original"
            "steam-runtime"
          ];
        }
        inputs.nixseparatedebuginfod.nixosModules.default
        ./hosts/blackbox/configuration.nix
      ];
      specialArgs = { inherit inputs; };
    };

    darwinConfigurations.mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./hosts/mac.nix ];
      specialArgs = { inherit inputs; };
    };
    inherit (self.darwinConfigurations) mac;
  };
}
