{
  pkgs,
  lib,
  git,
  just,
  openssh,
  nix,
  gnused,
  hostname,
  coreutils,
  ripgrep,
  gawk,
  ...
}:
pkgs.writeShellApplication {
  name = "pin-systemd-boot-entry";
  runtimeInputs = [
    git
    just
    openssh
    nix
    gnused
    hostname
    coreutils
    ripgrep
    gawk
  ];

  text = ''
    # shellcheck disable=SC1091
    source ${pkgs.introdus.introdus-helpers}/share/introdus-helpers/helpers.sh
    ${lib.readFile ./pin-systemd-boot-entry.sh}
  '';
}
