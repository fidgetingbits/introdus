{ lib, secrets, ... }:
rec {
  # sub libs
  time = import ./time.nix;
  network = import ./network.nix {
    inherit lib;
    inherit (secrets) ports;
  };

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;

  # Imports any .nix file in the specific directory, and any folder that
  # contains a default.nix. Note this means that a folder containing
  # `default.nix` and other *.nix files is expected to use the other *.nix
  # files in that folder as supplementary, and not distinct modules
  scanPaths =
    path:
    lib.map (f: (path + "/${f}")) (
      builtins.readDir path
      |> lib.attrsets.filterAttrs (
        file: _type:
        (_type == "directory" && lib.pathExists (path + "/${file}/default.nix"))
        || (file != "default.nix" && lib.strings.hasSuffix ".nix" file)
      )
      |> lib.attrNames
    );

  leaf = str: lib.last (lib.splitString "/" str);
  scanPathsFilterPlatform =
    path:
    lib.filter (
      path: lib.match "nixos.nix|darwin.nix|nixos|darwin" (leaf (builtins.toString path)) == null
    ) (scanPaths path);

  # NOTE: Hooks are run in alphabetical order
  preCommitHooks = {
    # General
    check-added-large-files.enable = true;
    check-case-conflicts.enable = true;
    check-executables-have-shebangs.enable = true;
    check-shebang-scripts-are-executable.enable = false;
    check-merge-conflicts.enable = true;
    fix-byte-order-marker.enable = true;
    mixed-line-endings.enable = true;
    trim-trailing-whitespace.enable = true;

    # nix
    nixfmt.enable = true;
    deadnix = {
      enable = true;
      settings = {
        noLambdaArg = true;
      };
    };
    # statix.enable = true;

    # shellscripts
    shfmt.enable = true;
    shellcheck.enable = true;

    # python
    ruff.enable = true;

    # rust
    rustfmt.enable = true;
    clippy.enable = true;
    cargo-check.enable = true;

    end-of-file-fixer.enable = true;

    unwanted-builtins = {
      enable = true;
      name = "unwanted builtins function calls";
      # FIXME: chaneg with a build package with it's own runtimeInputs
      entry = "${./unwanted-builtins.sh}";
      files = ".*";
      language = "script";
    };
  };
}
