{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.anki-cli;
in
{
  options.programs.anki-cli = {
    enable = lib.mkEnableOption "anki-cli";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.introdus.anki-cli;
      description = "The anki-cli package to use.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          backend = {
            prefer = "ankiconnect";
            ankiconnect_url = "http://127.0.0.1:8765";
          };
        }
      '';
      description = "Configuration settings written to <filename>~/.config/anki-cli/config.toml</filename>.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."anki-cli/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = (pkgs.formats.toml { }).generate "anki-cli-config" cfg.settings;
    };
  };
}
