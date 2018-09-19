{ stdenv, ncurses5, imagemagick, graphicsmagick, autoconf }:

let
  rev = "b4d8fa1679e6971abe2dc44ba4b371345a5c35bf";

in stdenv.mkDerivation {
  name = "imgcat-${rev}";

  nativeBuildInputs = [ autoconf ];
  buildInputs = [ ncurses5 imagemagick graphicsmagick ];

  src = builtins.fetchGit {
    url = git://github.com/eddieantonio/imgcat;
    inherit rev;
  };

  preConfigure = ''
    sed -i -e "s|-ltermcap|-lncurses|" Makefile
  '';

  installPhase = ''
    make install PREFIX=$out
  '';
}
