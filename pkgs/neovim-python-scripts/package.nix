{
  stdenv,
  pkgs,
  lib,
  ...
}:
stdenv.mkDerivation {
  name = "neovim-python-scripts";
  buildInputs = [
    (pkgs.python312.withPackages (pythonPackages: lib.attrValues { inherit (pythonPackages) pynvim; }))
  ];
  dontUnpack = true;
  installPhase = ''
    install -Dm755 ${./scripts/neovim-sudoedit.py} $out/bin/neovim-sudoedit
    install -Dm755 ${./scripts/neovim-change-bg-color.py} $out/bin/neovim-change-bg-color
  '';
}
