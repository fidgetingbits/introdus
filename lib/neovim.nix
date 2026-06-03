{ lib, ... }:
{
  configSource =
    root:
    lib.fileset.toSource {
      inherit root;
      fileset =
        map (p: lib.optional (lib.pathExists p) p) [
          ./init.lua
          ./lua
          ./after
          ./plugin
          ./snippets
        ]
        |> lib.flatten
        |> lib.fileset.unions;
    };
}
