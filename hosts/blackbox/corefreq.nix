{ lib
, stdenv
, fetchgit
, util-linux
, linuxPackages_latest
, kernel ? linuxPackages_latest.kernel
}:

let
  version = "1.93.1";
in
stdenv.mkDerivation {
  pname = "CoreFreq";
  inherit version;

  src = fetchgit {
    url = "https://github.com/cyring/CoreFreq.git";
    rev = version;
    sha256 = "sha256-CLM5RtgHLQa8QSZkeYIrI9y56KA3iZeRNKI55ioLN7M=";
  };

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;
  preBuild = ''
    substituteInPlace Makefile --replace "modules_install" "INSTALL_MOD_PATH=$out modules_install"
    substituteInPlace Makefile --replace "-j1" "-j"
    substituteInPlace corefreqd.service --replace "/bin/kill" "${util-linux}/bin/kill"
    substituteInPlace corefreqd.service --replace "corefreqd" "$out/bin/corefreqd"
  '';
  KERNELDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";

  installPhase = "make install PREFIX=$out";

  meta = with lib; {
    description = "CoreFreq is a CPU monitoring software designed for the 64-bits Processors.";
    homepage = "https://www.cyring.fr";
    license = licenses.gpl2;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ congee ];
  };
}
