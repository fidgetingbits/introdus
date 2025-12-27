{ lib, ... }:
{
  # Expose a set of default hooks for use by external configs
  # Note formatting changes are done by treefmt (see treefmt.nix), linting checks are done by pre-commit
  # NOTE: Hooks are run in alphabetical order
  mkPreCommitHooks = pkgs: {
    # General
    check-added-large-files.enable = true;
    check-case-conflicts.enable = true;
    # FIXME: These might be candidates for moving to nix fmt eventually
    check-executables-have-shebangs.enable = true;
    check-shebang-scripts-are-executable.enable = false;
    check-merge-conflicts.enable = true;
    fix-byte-order-marker.enable = true;
    mixed-line-endings.enable = true;
    trim-trailing-whitespace.enable = true;

    # nix
    deadnix = {
      enable = true;
      settings = {
        noLambdaArg = true;
      };
    };

    # shellscripts
    shellcheck.enable = true;

    # rust
    # clippy.enable = true;
    # cargo-check.enable = true;

    # yaml
    yamllint =
      let
        preset = "relaxed"; # Avoid 'missing document start "---"  (document-start)' and similar
      in
      {
        enable = true;
        settings = {
          preset = preset;
          configuration = ''
            extends: ${preset}

            rules:
              line-length:
                max: 120
          '';
        };
      };

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
