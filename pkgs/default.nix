{ pkgs }:

let
  # Here mk stands for mark
  mkB0rked = pkgs.lib.addMetaAttrs { broken = true; };
  mkBashCli = pkgs.callPackage ./make-bash-cli.nix {
    inherit (import ../lib { inherit pkgs; }) grid;
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

  hydra = let
    lastWorkingNixpkgsVersion = pkgs.fetchFromGitHub {
      owner   = "NixOS";
      repo    = "nixpkgs-channels";
      rev     = "61c3169a0e17d789c566d5b241bfe309ce4a6275";
      sha256  = "0qbycg7wkb71v20rchlkafrjfpbk2fnlvvbh3ai9pyfisci5wxvq";
    };

    lastWorkingNixpkgs = import lastWorkingNixpkgsVersion { inherit (pkgs) system; };

  in lastWorkingNixpkgs.hydra.overrideAttrs (_: rec {
    name    = "hydra-${version}";
    version = "2018-10-15";
    patchs  = [ ./hydra-no-restricteval.diff ];
    src     = pkgs.fetchFromGitHub {
      owner   = "kreisys";
      repo    = "hydra";
      rev     = "e0f204f3da6245fbaf5cb9ef59568b775ddcb929";
      sha256  = "039s5j4dixf9xhrakxa349lwkfwd2l9sdds0j646k9w32659di61";
    };
  });
}
