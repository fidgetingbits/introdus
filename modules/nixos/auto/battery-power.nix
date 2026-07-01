{
  config,
  lib,
  ...
}:
let
  cfg = config.introdus.batteryPowerServices;
in
{
  options.introdus.batteryPowerServices = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.hostSpec.isRoaming;
      description = "Enable battery power services for roaming devices.";
    };
  };
  config = lib.mkIf (cfg.enable && config.introdus.autoModules) {
    # These are the ones used by noctalia
    services = {
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };
  };
}
