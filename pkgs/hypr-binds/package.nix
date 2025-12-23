{
  #config,
  lib,
  pkgs,
  writeShellScriptBin,
}:
let
  dependencies = [
    pkgs.jq
    pkgs.jtbl
    pkgs.fzf
    # FIXME: This should somehow use whatever version of hyprland is already in
    # use elsewhere by the user
    (if (pkgs ? unstable) then pkgs.unstable.hyprland else pkgs.hyprland)
  ];
in
writeShellScriptBin "hypr-binds" (
  ''
    export PATH=${lib.makeBinPath dependencies}:$PATH
  ''
  + (lib.readFile ./hypr-binds.sh)
)
