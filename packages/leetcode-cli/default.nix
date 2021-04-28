with import <nixpkgs> {};

rustPlatform.buildRustPackage rec{
  pname = "leetcode-cli";
  version = "0.3.3";

  src = fetchCrate {
    inherit pname version;
    sha256 = "162imf5qc70l7qhjir7jbiv139lgls4jxzjdasmq6q2v9yy1phf8";
  };

  cargoSha256 = "0mhlx4xpfgg6babg24vp8310ldg9nxb1acs66ksq8xn2i8abs9n3";
  
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
