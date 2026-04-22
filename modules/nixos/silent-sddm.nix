# NOTE: `silentSDDM` must be an input to your nix-config flake that follows
# nixpkgs-unstable. inputs.SilentSDDM.url = "github:uiriansan/SilentSDDM"
# Also, enabling this module will enable introdus.x11
{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.introdus.services.silent-sddm;
in
{
  options.introdus.services.silent-sddm = {
    enable = lib.mkEnableOption "Enable sddm service via SilentSDDM";
    theme = lib.mkOption {
      type = lib.types.str;
      default = "rei";
      description = "The name of the sddm theme within the theme package.";
    };
  };

  imports = [ inputs.silentSDDM.nixosModules.default ];
  config = lib.mkIf cfg.enable {
    # Use X11 because SDDM fails to run properly on multiple hosts with Radeon 9070
    introdus.services.x11.enable = true;

    programs.silentSDDM = {
      enable = true;
      theme = cfg.theme;
      settings.General =
        let
          greeterEnvVars = lib.flatten (
            lib.optional config.hostSpec.hdr [
              "QT_SCREEN_SCALE_FACTORS=${config.hostSpec.scaling}"
              "QT_FONT_DPI=${toString config.services.xserver.dpi}"
            ]
          );
        in
        {
          GreeterEnvironment = lib.concatStringsSep "," greeterEnvVars;
        };
    };

    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
