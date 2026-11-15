{
  description = "home-mamager";

  inputs = {
    nur.url                             = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows          = "nixpkgs";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixos-unstable";
    nixos.url                           = "github:NixOS/nixpkgs/nixos-26.05";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    # nixpkgs 1.6.0 panics on Esc; drop once nixpkgs has >= 1.7.1
    wayshot.url                         = "github:waycrate/wayshot/v1.7.1-wayshot";
    wayshot.inputs.nixpkgs.follows      = "nixpkgs";
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay";
    home-manager.url                    = "github:nix-community/home-manager";
    # home-manager.url                    = "github:Congee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url                          = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows       = "nixpkgs";
    flake-compat.url                    = "github:edolstra/flake-compat";
    flake-compat.flake                  = false;

    bootvine.url                        = "git+https://codeberg.org/wvhulle/bootvine";
    bootvine.inputs.nixpkgs.follows     = "nixos";

    llm-agents.url                      = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows   = "nixpkgs";

    angrr.url                           = "github:linyinfeng/angrr";
    angrr.inputs.nixpkgs.follows        = "nixpkgs";

    # Out-of-tree identity (username). The committed default is a placeholder;
    # keep your real username outside the repo and select it per-invocation with:
    #   --override-input identity path:$HOME/.secrets/identity.nix
    identity.url                        = "path:./identity.default.nix";
    identity.flake                      = false;

    # Per-machine list of package names to replace with an empty no-op (see the
    # stubOverlay below), so an in-progress nixpkgs bump still builds when a leaf
    # tool is temporarily broken upstream (e.g. the cctools-ld64 crash on darwin,
    # nixpkgs #540408). Committed default stubs nothing; put names in the
    # gitignored ~/.nix/stubs.nix (e.g. `[ "unar" "watchexec" "stats" ]`) and
    # select it per-invocation (a path override reads the ignored file and stays
    # pure -> no --impure) with:
    #   --override-input stubs path:$HOME/.nix/stubs.nix
    stubs.url                           = "path:./stubs.default.nix";
    stubs.flake                         = false;
  };

  outputs = { self, home-manager, darwin, nixpkgs, bootvine, nixos, ... } @ inputs:
  let
    username = (import inputs.identity).username;

    stubbedPackages = import inputs.stubs;
    stubOverlay = final: _prev:
      builtins.listToAttrs (map (name: {
        inherit name;
        value = final.runCommandLocal "${name}-stub" { } "mkdir -p $out";
      }) stubbedPackages);

  in {
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
              inputs.nur.overlays.default
              inputs.wayland.overlay
              inputs.wayshot.overlays.default
              inputs.neovim-nightly.overlays.default
              inputs.llm-agents.overlays.shared-nixpkgs
              # unstable dropped dracula-theme with gtk-engine-murrine (GTK 2,
              # unmaintained). Stable still ships it, so keep the same look.
              (_: prev: { inherit (nixos.legacyPackages.${prev.stdenv.hostPlatform.system}) dracula-theme; })
              stubOverlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}; })
            ];
            nixpkgs.config.allowUnfreePredicate = (_: true);
            # for goldendict
            nixpkgs.config.permittedInsecurePackages = [];
          }
        ];
        extraSpecialArgs = { inherit nixpkgs username; };
      };
      wsl = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [
          ./homes/common.nix
          ./homes/wsl.nix
          {
            nixpkgs.overlays = [
              inputs.nur.overlays.default
              inputs.neovim-nightly.overlays.default
              inputs.llm-agents.overlays.shared-nixpkgs
              stubOverlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}; })
            ];
          }
        ];
        extraSpecialArgs = { inherit nixpkgs username; };
      };
      mac = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        modules = [
          ./homes/common.nix
          ./homes/darwin.nix
          {
            nixpkgs.overlays = [
              inputs.nur.overlays.default
              inputs.neovim-nightly.overlays.default
              inputs.llm-agents.overlays.shared-nixpkgs
              stubOverlay
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}; })
            ];
          }
        ];
        extraSpecialArgs = { inherit nixpkgs username; };
      };
    };
    desktop = self.homeConfigurations.desktop.activationPackage;
    wsl = self.homeConfigurations.wsl.activationPackage;

    nixosConfigurations.blackbox = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixos.lib.getName pkg) [
            "steam"
            "steam-run"
            "steam-original"
            "steam-runtime"
          ];
        }
        bootvine.nixosModules.default
        inputs.angrr.nixosModules.angrr
        ./hosts/blackbox/configuration.nix
      ];
      specialArgs = { inherit inputs username; };
    };

    darwinConfigurations.mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        inputs.angrr.darwinModules.angrr
        ./hosts/mac.nix
      ];
      specialArgs = { inherit inputs username; };
    };
    inherit (self.darwinConfigurations) mac;
  };
}
