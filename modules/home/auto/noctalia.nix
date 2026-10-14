{
  config,
  lib,
  inputs,
  # pkgs,
  ...
}:
let
in
{
  imports = [ inputs.noctalia.homeModules.default ];
  config = lib.mkIf config.programs.noctalia.enable {
    programs.noctalia.settings = {
      plugins = {
        enabled = [
          "introdus/yubikey-sound-notification"
        ];
        source = [
          {
            enabled = true;
            kind = "path";
            location = ../../../extras/noctalia/plugins;
            name = "introdus";
          }
        ];
      };
      widget.yubikey-sound.type = "introdus/yubikey-sound-notification:yubikey-sound";
    };
  };
}
