{
  inputs,
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

      # Some packages like unwanted-builtins need pkgs.stable when introdus is
      # used as a module. This needs to be in introdus rather than our own config
      # so that introdus itself (checks, dev shell, etc) can still access it.
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
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
