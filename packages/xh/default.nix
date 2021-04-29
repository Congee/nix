with import <nixpkgs> {};

rustPlatform.buildRustPackage rec{
  pname = "xh";
  version = "0.9.2";

  src = fetchCrate {
    inherit pname version;
    sha256 = "0wrh0wrbwazfvs4b4zhjc4j1rzh6sa75v78x71lnfzn6qgp6dhd8";
  };

  cargoSha256 = "1l6lw3srjd8c679872whm2jisgv2zvfjp23h10zamkxxwiiry7g4";

  # a nightly compiler is required unless we use this cheat code.
  # RUSTC_BOOTSTRAP = 1;

  # CFG_RELEASE = "${rustPlatform.rust.rustc.version}-nightly";
  # CFG_RELEASE_CHANNEL = "ngihtly";

  nativeBuildInputs = [
    pkg-config
    perl
    jq
    tree
    installShellFiles
  ];

  buildInputs = [
    # openssl
    # dbus
    # sqlite
  ];

  # DNS look up error upon badssl.com
  doCheck = false;

  installPhase = ''
    runHook preInstall

    # /build/xh-0.9.2.tar.gz/target/x86_64-unknown-linux-gnu/release
    eval $(rustc --print cfg | fgrep target)
    triple=$target_arch-$target_vendor-$target_os-$target_env
    target=$(cargo metadata --format-version 1 | jq --raw-output .target_directory)
    exe=$target/$triple/release/xh

    install -Dm755 $exe --no-target-directory $out/bin/xh
    install -Dm755 $exe --no-target-directory $out/bin/xhs

    installManPage doc/xh.1

    installShellCompletion --zsh  completions/_xh
    installShellCompletion --bash completions/xh.bash
    installShellCompletion --fish completions/xh.fish

    runHook postInstall
  '';

  meta = with lib; {
    description = "Friendly and fast tool for sending HTTP requests";
    homepage = "https://github.com/ducaale/xh";
    licenses = licenses.mit;
    maintainers = with maintainers; [ congee ];
    mainProgram = "leetcode";
  };
}
