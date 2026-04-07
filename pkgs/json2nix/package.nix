{
  pkgs,
  lib,
  makeWrapper,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication rec {
  name = "neovim-python-scripts";
  version = "0.0.1";
  format = "other";
  buildInputs = [
    makeWrapper
    (pkgs.python3.withPackages (pythonPackages: lib.attrValues { }))
  ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/
    install -Dm755 ${./json2nix.py} $out/share/json2nix.py
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup

    makeWrapper ${python3Packages.python}/bin/python "$out/bin/json2nix" \
      --set PYTHONPATH "$PYTHONPATH" \
      --add-flags "$out/share/json2nix.py"

    runHook postFixup
  '';
}
