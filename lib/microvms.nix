{
  mkMicrovms =
    # Automatic microvm setup based on a host defining microvms
    # in hosts/nixos/microvms/ folder
    cwd:
    {
      lib,
      inputs,
      ...
    }:
    let
      vmPath = lib.custom.relativeToRoot "hosts/nixos/${lib.baseNameOf (lib.dirOf cwd)}/microvms/";
      vmFolders = lib.attrNames (lib.readDir vmPath);
      microvms = lib.filter (name: (lib.pathIsDirectory "${cwd}/${name}")) vmFolders;
    in

    if (lib.pathExists vmPath) then
      (
        microvms
        |> lib.map (name: {
          imports = [ "${cwd}/${name}" ];

          microvm.vms.${name} = {
            specialArgs = {
              inherit inputs lib;
              namespace = "vm-${name}";
            };
            # Config of the microvm itself
            config = {
              imports = [
                (lib.custom.relativeToRoot "microvms/hosts/common/core/")
              ];
            };
          };
        })
        |> lib.foldl' lib.recursiveUpdate { }
      )
    else
      { };
}
