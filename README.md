# .nix

Every command passes the out-of-tree `identity` and `stubs` inputs (see `flake.nix`).

## Home Manager

`homeConfigurations.mac` (macOS):

```sh
nh home build .#mac \
  --backup-extension bak \
  --log-format internal-json \
  --keep-failed --keep-going \
  --override-input identity path:$HOME/.secrets/identity.nix \
  --override-input stubs path:$HOME/.nix/stubs.nix \
  --impure
```

`homeConfigurations.desktop` (Linux):

```sh
nh home build .#desktop \
  --backup-extension bak \
  --log-format internal-json \
  --keep-failed --keep-going \
  --override-input identity path:$HOME/.secrets/identity.nix \
  --override-input stubs path:$HOME/.nix/stubs.nix \
  --impure
```

## System

`darwinConfigurations.darwin` (nix-darwin):

```sh
nh darwin switch .#darwin --ask \
  --override-input identity path:$HOME/.secrets/identity.nix \
  --override-input stubs path:$HOME/.nix/stubs.nix
```

`nixosConfigurations.blackbox` (NixOS):

```sh
nh os switch .#blackbox --ask \
  --override-input identity path:$HOME/.secrets/identity.nix \
  --override-input stubs path:$HOME/.nix/stubs.nix
```
