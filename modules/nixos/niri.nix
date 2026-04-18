{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.introdus.niri;
in
{
  options.introdus.niri = {
    enable = lib.mkEnableOption "Enable Niri managed by UWSM.";
  };
  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = pkgs.unstable.niri;
    };
    environment.systemPackages = lib.attrValues {
      inherit (pkgs)
        xwayland-satellite # xwayland support
        ;
    };
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        niri = {
          prettyName = "niri";
          comment = "Niri compositor managed by UWSM";
          binPath = pkgs.writeShellScript "niri" ''
            ${lib.getExe config.programs.niri.package} --session
          '';
        };
      };
    };
  };
}
