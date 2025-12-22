{ stdenv, ... }:
stdenv.mkDerivation {
  pname = "introdus-helpers";
  version = "0.1.0";
  src = ./.;
  installPhase = ''
    mkdir -p $out/share/introdus-helpers
    cp -r . $out/share/introdus-helpers/
  '';
}
