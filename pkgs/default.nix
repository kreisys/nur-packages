{ pkgs }:

{
  consulate = pkgs.callPackage ./consulate { };
  nvim = pkgs.callPackage ./nvim { };
}

