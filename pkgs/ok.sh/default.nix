{ stdenv, fetchurl, jq }:

let version = "0.2.3"; in
stdenv.mkDerivation {
  name = "ok.sh-${version}";

  src = fetchurl {
    url = "https://github.com/whiteinge/ok.sh/archive/${version}.tar.gz";
    sha256 = "1xhzxxcgw9ylw3rdqjh0ivcgl74fn0z47zghlhvsqnjh4fksk8b7";
  };

  buildInputs = [ jq ];
  buildPhase = "true";
  installPhase = ''
    install -D ok.sh $out/bin/ok.sh
  '';
}
