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

  # Expose a set of default hooks for use by external configs
  # NOTE: Hooks are run in alphabetical order
  mkPreCommitHooks = pkgs: {
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

    unwanted-builtins =
      let
        unwantedScript = pkgs.writeShellApplication {
          name = "unwanted-builtins.sh";
          runtimeInputs = [ pkgs.ripgrep ];
          text = ''
            # Flag anything that isn't builtins-only
            # WARNING: This list is incomplete. Things will have to be added to it overtime
            rg -g "*.nix" "builtins" | rg -v '(toString|toFile|readDir|currentTime|getFlake|getEnv|isNull)'
          '';
        };
      in
      {
        enable = true;
        name = "unwanted builtins function calls";
        entry = lib.getExe' unwantedScript "unwanted-builtins.sh";
        files = ".*";
        language = "script";
      };
  };
}
