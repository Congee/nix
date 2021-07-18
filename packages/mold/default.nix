let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
in
pkgs.stdenv.mkDerivation rec {
  pname = "mold";
  version = "0.9.2";

  src = builtins.fetchGit {
    url = "https://github.com/rui314/mold.git";
    # ref = "v${version}";  # FIXME
    rev = "2bf2da4822a21bb9783bcd6a34f4345365dc6f56";
  };

  buildInputs = with pkgs; [ tbb zlib openssl ];
  nativeBuildInputs = with pkgs; [ llvmPackages_latest.clang autoPatchelfHook cmake xxHash ];

  dontUseCmakeConfigure = true;
  EXTRA_LDFLAGS = "-fuse-ld=${pkgs.llvmPackages_latest.lld}/bin/ld.lld";
  LTO = 1;
  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = with lib; {
    description = "A high performance drop-in replacement for existing unix linkers";
    homepage = "https://github.com/rui314/mold";
    license = lib.licenses.agpl3Plus;
    maintainers = with maintainers; [ nitsky ];
    broken = pkgs.stdenv.isAarch64;
  };
}
