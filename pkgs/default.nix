{ pkgs }:

let
  # Here mk stands for mark
  mkB0rked = pkgs.lib.addMetaAttrs { broken = true; };
  mkBashCli = pkgs.callPackage ./make-bash-cli.nix {
    inherit (import ../lib { inherit pkgs; }) grid;
  };

  hydra.lastWorking.nixpkgs = pkgs.fetchFromGitHub {
    owner   = "NixOS";
    repo    = "nixpkgs-channels";
    rev     = "61c3169a0e17d789c566d5b241bfe309ce4a6275";
    sha256  = "0qbycg7wkb71v20rchlkafrjfpbk2fnlvvbh3ai9pyfisci5wxvq";
  };

in
{
  consulate = pkgs.callPackage ./consulate { };

  fishPlugins = pkgs.recurseIntoAttrs (pkgs.callPackages ./fish-plugins { });

  img2ansi = pkgs.callPackage ./img2ansi   { };
  krec2    = pkgs.callPackage ./krec2.nix  { inherit mkBashCli; };
  kretty   = pkgs.callPackage ./kretty.nix { inherit mkBashCli; };
  nvim     = pkgs.callPackage ./nvim       { };
  oksh     = pkgs.callPackage ./ok.sh      { };
  webhook  = pkgs.callPackage ./webhook    { };
  xinomorf = (pkgs.callPackage ./xinomorf  { }).cli;

  hydra = let pkgs' = import hydra.lastWorking.nixpkgs { inherit (pkgs) system; };
    in pkgs'.callPackage ./hydra {};
}
