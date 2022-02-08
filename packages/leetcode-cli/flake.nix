{
  description = "Leet your code in command-line.";

  inputs.nixpkgs.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  inputs.utils.url        = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, rust-overlay, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlay ]; };

        platform = with pkgs; makeRustPlatform {
          rustc = rust-bin.nightly.latest.minimal;
          cargo = rust-bin.nightly.latest.minimal;
        };
        package = with pkgs; platform.buildRustPackage rec {
          pname = "leetcode-cli";
          version = "0.3.9";

          src = fetchCrate {
            inherit pname version;
            sha256 = "1aiksg4iyrhkmwl4djy7bm3xjras4qqfixi6ml8k6pz0s9ynknws";
          };

          cargoSha256 = "1ldzr2bspy288nydk2lnkc4akc2myk2jk7aw87vr4kmzl0jmh329";

          # a nightly compiler is required unless we use this cheat code.
          RUSTC_BOOTSTRAP = 0;

          # CFG_RELEASE = "${rustPlatform.rust.rustc.version}-nightly";
          CFG_RELEASE_CHANNEL = "ngihtly";

          nativeBuildInputs = [
            pkg-config
            rust-bin.nightly."2021-05-16".minimal
          ];

          buildInputs = [
            openssl
            dbus
            sqlite
          ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security ];

          meta = with pkgs.lib; {
            description = "Leet your code in command-line.";
            homepage = "https://github.com/clearloop/leetcode-cli";
            licenses = licenses.mit;
            maintainers = with maintainers; [ congee ];
            mainProgram = "leetcode";
          };
        };
      in
      {
        defaultPackage = package;
        overlay = final: prev: { leetcode-cli = package; };
      }
    );
}
