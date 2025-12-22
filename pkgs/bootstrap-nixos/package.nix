{
  pkgs,
  lib,
  introdus-helpers,
  rsync,
  openssh,
  git,
  nix,
  sops,
  ...
}:
pkgs.writeShellApplication {
  name = "bootstrap-nixos";
  runtimeInputs = [
    rsync
    openssh
    git
    nix
    sops

  ];

  runtimeEnv = {
    INTRODUS_HELPERS_PATH = "${introdus-helpers}/share/introdus-helpers/";
  };
  text = lib.readFile ./bootstrap-nixos.sh;
}
