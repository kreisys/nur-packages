{ stdenv, jq }:

let version = "0.2.3"; in
stdenv.mkDerivation {
  name = "ok.sh-${version}";
  src = builtins.fetchTarball {
    url = "https://github.com/whiteinge/ok.sh/archive/${version}.tar.gz";
    sha256 = "10afpws7vika15yf5ja7ghr9p0i081wirb05hl6l6r8g0lgdmalj";
  };

  buildInputs = [ jq ];
  buildPhase = "true";
  installPhase = ''
    install -D $src/ok.sh $out/bin/ok.sh
  '';
}
