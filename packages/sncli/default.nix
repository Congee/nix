with import <nixpkgs> {};

let
  __Simperium3 = python3.pkgs.pythonPackages.buildPythonPackage rec {
    pname = "Simperium3";
    version = "0.1.3";

    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "d71ce5923b04b9853c7fc500a466ac724a767b5e33616c122564a71165233cc8";
    };

    propagatedBuildInputs = with python3.pkgs; [ requests ];
  };
in
  python3.pkgs.pythonPackages.buildPythonPackage rec {
    pname = "sncli";
    version = "0.4.1";

    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "6027cdbadc5dabb995be9d91088e5cb34a6a247b53400781486facd3a0d7ad89";
    };

    propagatedBuildInputs = with python3.pkgs; [ urwid requests __Simperium3 ];

    doCheck = false;

    meta = with lib; {
      homepage = "https://github.com/insanum/sncli";
      maintainers = with maintainers; [ Congee ];
      licenses = licenses.mit;
      description = "Simplenote CLI";
    };
  }