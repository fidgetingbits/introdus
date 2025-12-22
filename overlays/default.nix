{
  ...
}:
let
  overlays = {
    additions = final: prev: {
      # All packages exposed by introdus go into introdus namespace
      introdus = prev.lib.packagesFromDirectoryRecursive {
        callPackage = final.lib.callPackageWith final;
        directory = ../pkgs;
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
