{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.introdus.signal;
in
{
  options.introdus.signal = {
    enable = lib.mkEnableOption "Enable signal with introdus settings";
    package = lib.mkOption {
      description = "Signal package to use";
      type = lib.types.package;
      default = pkgs.unstable.signal-desktop;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # the override handles an issue that occurs when using signal in gnome as
      # well as other window managers
      (cfg.package.override {
        commandLineArgs = "--password-store='gnome-libsecret'";
      })
    ];

    xdg = lib.mkIf config.xdg.mimeApps.enable {
      mimeApps.defaultApplications = {
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
      };
    };
  };
}
