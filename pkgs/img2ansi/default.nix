{ stdenv, lib, buildGoPackage }:

let
  rev = "1b5600c638db787130d33940b4ea4349dd5517d5";
  goPackagePath = "github.com/lloiser/img2ansi";
in buildGoPackage {
  name = "img2ansi-1.0.0";

  inherit goPackagePath;

  goDeps = ./deps.nix;

  src = builtins.fetchGit {
    url = git:// + goPackagePath;
    inherit rev;
  };

  meta = with stdenv.lib; {
    description = "Converts an image to ANSI (using SGR escape sequences)";
    homepage = https:// + goPackagePath;
    license = licenses.mit;
  };
}
