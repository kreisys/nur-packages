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
  xinomorf = mkB0rked (pkgs.callPackage ./xinomorf   { });

  # Linux only packages go here
  hydra = pkgs.hydra.overrideAttrs (_: rec {
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
