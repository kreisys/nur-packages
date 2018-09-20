{ pkgs }:

let
  # Here mk stands for mark
  mkB0rked = pkgs.lib.addMetaAttrs { broken = true; };
in
{
  consulate = pkgs.callPackage ./consulate { };
  nvim = mkB0rked (pkgs.callPackage ./nvim { });
}

