{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "buildkite-cli-${version}";
  version = "0.3.0";
  rev = "v${version}";

  goPackagePath = "github.com/buildkite/cli";

  src = fetchFromGitHub {
    inherit rev;
    owner = "buildkite";
    repo  = "cli";
    sha256 = "18rdnx1a9gwz0gg2l4q7h0imammskavpn9w4la93zjr9fdl4w9jm";
  };

  goDeps = ./deps.nix;

  meta = with stdenv.lib; {
    description = "A command line interface for Buildkite";
    homepage = https://github.com/buildkite/cli;
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.mit;
  };
}
