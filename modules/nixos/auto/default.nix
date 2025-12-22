{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
  options = {
    introdus = {
      autoModules = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Auto-loads opinionated nixos/home-manager module settings";
      };
    };
  };
}
