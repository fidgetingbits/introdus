{
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
