{ darwin, sources, stdenv, rustPlatform, openssl, pkgconfig, libiconv }:

rustPlatform.buildRustPackage rec {
  pname   = "silver";
  version = sources.silver.version;
  src     = sources.silver;

  buildInputs = [ pkgconfig openssl libiconv ]
              ++ stdenv.lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.Security;

  cargoSha256 = "sha256:0chdy38nl4yi20klraml9v1jpn1r10aicbyqjpi7q99kmvx06vnq";

  OPENSSL_LIB_DIR = openssl.out + "/lib";
  OPENSSL_INCLUDE_DIR = openssl.dev + "/include";

  meta = with stdenv.lib; {
    inherit (sources.silver) description homepage;
    license   = licenses.unlicense;
    platforms = platforms.all;
  };
}
