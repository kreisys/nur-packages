{ stdenv, ncurses5, imagemagick, graphicsmagick, autoconf }:

let
  version = "2.3.0";
  sha256 = "0m83c33rzxvs0w214njql2c7q3fg06wnyijch3l2s88i7frl121f";

in stdenv.mkDerivation {
  name = "imgcat-${version}";

  nativeBuildInputs = [ autoconf ];
  buildInputs = [ ncurses5 imagemagick graphicsmagick ];

  src = builtins.fetchTarball {
    url = https://github.com/eddieantonio/imgcat/archive/ + "v${version}.tar.gz";
    inherit sha256;
  };

  preConfigure = ''
    sed -i -e "s|-ltermcap|-lncurses|" Makefile
  '';

  installPhase = ''
    make install PREFIX=$out
  '';
}
