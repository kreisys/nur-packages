{ stdenv, rustPlatform, sources }:

let
  inherit (stdenv.lib) substring;
  src = sources.image-to-ascii;
in rustPlatform.buildRustPackage rec {
  pname = "image-to-ascii";
  version = substring 0 7 src.rev;

  inherit src;

  cargoSha256 = "sha256-o10EpVZDOpNO1wHxMXk7M+DllFr6qbIjw8KYFq/NH0M=";

  meta = {
    inherit (src) description;
    platforms = stdenv.lib.platforms.unix;
  };
}
