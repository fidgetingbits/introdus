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

      # Some packages like unwanted-builtins need pkgs.stable both when introdus is
      # used as a module and standalone (devshell, checks, etc). Due to the latter, we
      # can't rely on this overlay coming from a module consumer like our nix-config
      # flake.
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
