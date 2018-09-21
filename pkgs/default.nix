{ pkgs }:

let
  # Here mk stands for mark
  mkB0rked = pkgs.lib.addMetaAttrs { broken = true; };
in
{
  consulate = pkgs.callPackage ./consulate { };
  img2ansi = pkgs.callPackage ./img2ansi { };
  nvim = mkB0rked (pkgs.callPackage ./nvim { });
  webhook = pkgs.callPackage ./webhook { };
}

