{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf osConfig.hostSpec.useWindowManager {
      programs.firefox = {
        enable = true;
        profiles = {
          default = {
            search = import ./search.nix { inherit lib pkgs; };
          };
        };
      };
    })
  ];
}
