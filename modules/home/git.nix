{ lib, config, ... }:
lib.mkIf config.programs.git.enable {
  programs.git.settings.url =
    let
      urls = [
        "github.com"
        "gist.github.com"
        "gitlab.com"
        "codeberg.org"
      ];
    in
    urls
    |> lib.map (host: {
      "ssh://git@${host}" = {
        pushInsteadOf = [ "https://${host}" ];
      };
    })
    |> lib.mergeAttrsList
    |> lib.optionalAttrs (!config.hostSpec.isMinimal);
}
