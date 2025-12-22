{
  lib,
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "introdus-helpers";
  version = "0.1.0";
  src = ./.;
  propagatedBuildInputs = lib.attrValues {
    inherit (pkgs)
      git
      yq-go
      sops
      coreutils
      findutils
      age
      ripgrep
      ;
  };
  installPhase = ''
    mkdir -p $out/share/introdus-helpers
    cp -r . $out/share/introdus-helpers/
  '';
}
