{
  self,
  inputs,
  system,
  pkgs,
  formatter,
  ...
}:
let
  lib = pkgs.lib;
  introdusLib = self.lib.mkIntrodusLib { inherit lib; };
in
{
  bats-test =
    pkgs.runCommand "bats-test"
      {
        src = ../.;
        buildInputs = lib.attrValues {
          inherit (pkgs)
            bats
            inetutils
            ;
          inherit (pkgs.introdus)
            introdus-helpers
            ;
        };
      }
      ''
        cd $src
        export HELPERS_PATH="${pkgs.introdus.introdus-helpers}/share/introdus-helpers/helpers.sh"
        bats -x tests
        touch $out
      '';

  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = ../.;
    default_stages = [
      "pre-commit"
      "manual"
    ];
    hooks = lib.recursiveUpdate (introdusLib.checks.mkPreCommitHooks pkgs formatter) {
      destroyed-symlinks = {
        enable = true;
        name = "destroyed-symlinks";
        description = "detects symlinks which are changed to regular files with a content of a path which that symlink was pointing to.";
        package = inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks;
        entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
        types = [ "symlink" ];
      };
      conventional-commit-lint = {
        enable = true;
        name = "conventional-commit-lint";
        description = "ensure commit follows conventional commit specification.";
        stages = [ "commit-msg" ];
        entry = "${lib.getExe' pkgs.cocogitto "cog"} verify -f";
        language = "script";
      };
    };
  };
}
