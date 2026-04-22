# NOTE: this module is enabled by introdus.silent-sddm
{
  lib,
  config,
  ...
}:
let
  cfg = config.introdus.services.x11;
in
{
  options.introdus.services.x11 = {
    enable = lib.mkEnableOption "Enable the X11 windowing system.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;

      dpi = if config.hostSpec.hdr then 192 else 96;
      upscaleDefaultCursor = config.hostSpec.hdr;

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
