{
  lib,
  config,
  osConfig,
  ...
}:
lib.mkIf (osConfig.introdus.autoModules && config.programs.git.enable) {
  programs.git.settings.url =
    let
      urls = [
        "github.com"
        "gist.github.com"
        "gitlab.com"
        "codeberg.org"
        "sr.ht"
      ];
    in
    urls
    |> lib.map (host: {
      "ssh://git@${host}" = {
        pushInsteadOf = [ "https://${host}" ];
      };
    })
    |> lib.mergeAttrsList;
  # FIXME: Remove this once we confirm the iso doesn't matter
  # |> lib.optionalAttrs (!config.hostSpec.isMinimal);
}
