{ lib, ... }:
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
      {
        imports = map (name: "${cwd}/${name}") microvms;

        microvm.vms = lib.foldl' (
          acc: name:
          acc
          // {
            ${name} = {
              specialArgs = {
                inherit inputs lib;
                namespace = "vm-${name}";
              };
              config = {
                imports = [
                  (lib.custom.relativeToRoot "microvms/hosts/common/core/")
                ];
              };
            };
          }
        ) { } microvms;
      }
    else
      { };

  # Run the provided function over each of specified host's microvm specifications
  mapHostMicrovms =
    vms: func:
    vms
    |> lib.attrNames
    |> map (
      name:
      let
        vmSpecs = vms.${name}.specialArgs.vmSpecs;
      in
      (func vmSpecs)
    );
}
