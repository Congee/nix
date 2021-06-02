with import <nixpkgs> {};

rustPlatform.buildRustPackage rec{
  pname = "leetcode-cli";
  version = "0.3.5";

  src = fetchCrate {
    inherit pname version;
    sha256 = "09zf17awssrb8kr4ag5lbisng2abx7yazmaaxvf5j2l4pafivgfb";
  };

  cargoSha256 = "1mwvyb4f48y5nixddl5zh32s5d77zxsd4864db6lbjpdk0vfrsfr";
  
  # a nightly compiler is required unless we use this cheat code.
  RUSTC_BOOTSTRAP = 1;

  CFG_RELEASE = "${rustPlatform.rust.rustc.version}-nightly";
  CFG_RELEASE_CHANNEL = "ngihtly";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    dbus
    sqlite
  ];

  meta = with lib; {
    description = "Leet your code in command-line.";
    homepage = "https://github.com/clearloop/leetcode-cli";
    licenses = licenses.mit;
    maintainers = with maintainers; [ congee ];
    mainProgram = "leetcode";
  };
}
