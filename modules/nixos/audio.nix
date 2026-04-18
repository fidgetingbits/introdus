{
  config,
  lib,
  ...
}:
let
  cfg = config.introdus.services.audio;
in
{
  options.introdus.services.audio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable pipewire audio and related services";
    };
  };
  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
