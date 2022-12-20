{pkgs}:

with pkgs;
let
  ellpkg = let version = "0.55"; in ell.overrideAttrs (_: prev: {
    inherit version;
    src = fetchgit {
      url = "https://git.kernel.org/pub/scm/libs/ell/ell.git";
      rev = version;
      sha256 = "sha256-vMWs+0iaszq+p55Z9AhqkNHWeOwlgt2iq7uuA8xGjJ4=";
    };
  });
in let version = "2.1"; in iwd.overrideAttrs (_:prev: {
  inherit version;
  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/network/wireless/iwd.git";
    rev = version;
    sha256 = "sha256-Aq038SG8vuxCA6mYOP5I6VWCUty5vgdbpAa9J+bIfZM=";
  };
  buildInputs = [ ellpkg python3Packages.python readline ];
})
