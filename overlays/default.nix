{
  inputs,
  ...
}:
let
  overlays = {
    additions =
      final: prev:
      prev.lib.packagesFromDirectoryRecursive {
        callPackage = final.lib.callPackageWith final;
        directory = ../pkgs;
      };

    # Override unstable entries exposed via pkgs.unstable
    unstable-packages = final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        overlays = [
        ];
      };
    };
  };
in
{
  default =
    final: prev:
    prev.lib.attrNames overlays
    |> map (name: (overlays.${name} final prev))
    # nixfmt hack
    |> prev.lib.mergeAttrsList;
}
