{ lib, ... }:
{
  # NOTE:
  #  - formatting changes are done by treefmt (see .config/treefmt.nix), linting
  #  checks are done by pre-commit
  #  - hooks are run in alphabetical order
  mkPreCommitHooks = pkgs: formatter: {
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
    treefmt = {
      enable = true;
      package = formatter;
    };

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

    unwanted-builtins = {
      enable = true;
      name = "unwanted builtins function calls";
      entry = lib.getExe' pkgs.introdus.unwanted-builtins "unwanted-builtins";
      files = "\\.nix$";
      language = "script";
    };
  };
}
