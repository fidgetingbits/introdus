# NOTE: Hooks are run in alphabetical order
{
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
}
