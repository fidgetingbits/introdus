{
  self,
  inputs,
  system,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  introdusLib = self.lib.mkIntrodusLib lib { };
in
rec {
  # NOTE: off for now to avoid build failure on empty dirs
  # bats-test =
  #   pkgs.runCommand "bats-test"
  #     {
  #       src = ../.;
  #       buildInputs = builtins.attrValues { inherit (pkgs) bats yq-go inetutils; };
  #     }
  #     ''
  #       cd $src
  #       bats tests
  #       touch $out
  #     '';

  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = ./.;
    default_stages = [ "pre-commit" ];
    hooks = lib.recursiveUpdate (introdusLib.mkPreCommitHooks pkgs) {
      destroyed-symlinks = {
        enable = true;
        name = "destroyed-symlinks";
        description = "detects symlinks which are changed to regular files with a content of a path which that symlink was pointing to.";
        package = inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks;
        entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
        types = [ "symlink" ];
      };
    };
  };
}
