{
  description = "home-mamager";

  inputs = {
    nur.url                             = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows          = "nixpkgs";
    nixpkgs.url                         = "github:NixOS/nixpkgs/nixos-unstable";
    nixos.url                           = "github:NixOS/nixpkgs/nixos-25.11";
    wayland.url                         = "github:nix-community/nixpkgs-wayland";
    neovim-nightly.url                  = "github:nix-community/neovim-nightly-overlay";
    home-manager.url                    = "github:nix-community/home-manager";
    # home-manager.url                    = "github:Congee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url                          = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows       = "nixpkgs";
    flake-compat.url                    = "github:edolstra/flake-compat";
    flake-compat.flake                  = false;

    llm-agents.url                      = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows   = "nixpkgs";

    angrr.url                           = "github:linyinfeng/angrr";
    angrr.inputs.nixpkgs.follows        = "nixpkgs";
    angrr.inputs.flake-compat.follows   = "flake-compat";

    # Out-of-tree identity (username). The committed default is a placeholder;
    # keep your real username outside the repo and select it per-invocation with:
    #   --override-input identity path:$HOME/.secrets/identity.nix
    identity.url                        = "path:./identity.default.nix";
    identity.flake                      = false;
  };

  outputs = { self, home-manager, darwin, nixpkgs, nixos, ... } @ inputs:
  let
    username = (import inputs.identity).username;

    # Work around an upstream package that fails to *build* (not eval) against
    # the current nixpkgs pin. Kept minimal so the rest of the closure stays
    # cache-hit on Cachix. litecli's dep cli-helpers has failing pytest cases
    # after a Pygments bump; skip its test phase (runtime is unaffected).
    buildFixes = _: prev: {
      litecli = prev.litecli.override {
        python3Packages = prev.python3Packages // {
          cli-helpers = prev.python3Packages.cli-helpers.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      };
    };

    # desktop-only: on this nixpkgs pin the wayfire stack (wf-config 0.10,
    # wayfire 0.10.1, incl. its wf-touch subproject) enables doctest unit tests,
    # but their test binaries link `-ldoctest` while nixpkgs' doctest 2.5.0 is
    # header-only -> `ld: cannot find -ldoctest`. The libraries themselves build
    # fine (and older pins built because the tests were gated differently), so
    # turn the tests off. Affects nixpkgs and the wayland overlay equally; only
    # the desktop config pulls wayfire. (wcm has no tests; it just needs wayfire.)
    desktopBuildFixes = _: prev: {
      wf-config = prev.wf-config.overrideAttrs (o: {
        doCheck = false;
        mesonFlags = (o.mesonFlags or [ ]) ++ [ "-Dtests=disabled" ];
      });
      wayfire = prev.wayfire.overrideAttrs (o: {
        doCheck = false;
        mesonFlags = (o.mesonFlags or [ ]) ++ [ "-Dtests=disabled" "-Dwf-touch:tests=disabled" ];
      });
    };
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
              inputs.neovim-nightly.overlays.default
              inputs.llm-agents.overlays.default
              buildFixes
              desktopBuildFixes
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
            ];
            nixpkgs.config.allowUnfreePredicate = (_: true);
            # for goldendict
            nixpkgs.config.permittedInsecurePackages = [ "qtwebkit-5.212.0-alpha4" ];
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
              inputs.llm-agents.overlays.default
              buildFixes
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
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
              inputs.llm-agents.overlays.default
              buildFixes
              (_: prev: { unstable = nixpkgs.legacyPackages.${prev.system}; })
            ];
          }
        ];
        extraSpecialArgs = { inherit nixpkgs username; };
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
            (_: prev: { inherit (nixpkgs.legacyPackages.${prev.system}) nix; })
            (_: prev: { inherit (nixpkgs.legacyPackages.${prev.system}) gnupg; })
          ];
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixos.lib.getName pkg) [
            "steam"
            "steam-run"
            "steam-original"
            "steam-runtime"
          ];
        }
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
