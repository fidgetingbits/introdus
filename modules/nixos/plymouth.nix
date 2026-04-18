{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.introdus.plymouth;
in
{
  options.introdus.plymouth = {
    enable = lib.mkEnableOption "Enable plymouth bootscreen.";
    theme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "hexagon_hud";
      description = "A theme from adi1090x-plymouth-themes. To display the NixOS logo, leave this option unset.";
    };
  };
  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
    }
    // lib.optionalAttrs (cfg.theme != null) {
      theme = lib.mkForce cfg.theme;
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ cfg.theme ]; })
      ];
    };
    boot.kernelParams = [
      "quiet" # shut up kernel output prior to prompts
    ];
  };
}
