# A module that provides a configurable git-color-cc utility that can be used
# to color git log --online output to better differentiate conventional commits
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.introdus.color-conventional-commits;
  # Official list of types as per:
  # https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional#type-enum
  defaultTypeColors = {
    build = "green";
    chore = "green";
    ci = "green";
    docs = "green";
    feat = "green";
    fix = "green";
    perf = "green";
    refactor = "green";
    revert = "green";
    style = "green";
    test = "green";
  };
  supportedColors = [
    "BLACK"
    "RED"
    "GREEN"
    "YELLOW"
    "BLUE"
    "PURPLE"
    "CYAN"
    "LGRAY"
    "GRAY"
    "LRED"
    "LGREEN"
    "LYELLOW"
    "LBLUE"
    "LPURPLE"
    "LCYAN"
    "WHITE"
  ];
  git-color-cc = pkgs.writeShellApplication {
    name = "git-color-cc";
    runtimeInputs = lib.attrValues {
      inherit (pkgs)
        git
        gnused
        ;
    };
    excludeShellChecks = [
      "SC2034"
    ];
    text =
      let
        bc = cfg.bracketColor;
        sc = cfg.scopeColor;
        allTypeColors = cfg.typeColors // cfg.extraTypeColors;

        /*
          Given log lines like these:

          ```
          4519957 fix(git-dev): support additional remote urls
          2c00abd (HEAD -> aa, origin/aa) feat(worktree-add): support base branch argument
          ```

          typeMatch isolates fix/feat
          scopeMatch isolates git-dev/work-tree-add
        */

        typeMatch =
          type:
          let
            color = allTypeColors.${type};
          in

          /*
            (${type})      Match first instance of the type name, eg "feat"
            (\([^)]+\))?   Optionally match any parens and inner text
            :              Literal delimiter
          */
          # bash
          ''s/(${type})(\([^)]+\))?:/''${${color}}\1''${RESTORE}\2:/g'';

        scopeMatch =
          /*
            Regex:
            ([^ ])         Match any non-white space
            \(([^)]+)\)    Match following parens and inner text
            :              Literal delimiter
          */
          # bash
          ''s/([^ ])\(([^)]+)\):/\1''${${bc}}(''${${sc}}\2''${${bc}})$RESTORE:/g'';
      in
      # bash
      ''
        RESTORE='\x1b[0m'

        BLACK='\x1b[00;30m'
        BLUE='\x1b[00;34m'
        CYAN='\x1b[00;36m'
        GRAY='\x1b[01;30m'
        GREEN='\x1b[00;32m'
        PURPLE='\x1b[00;35m'
        RED='\x1b[00;31m'
        WHITE='\x1b[01;37m'
        YELLOW='\x1b[00;33m'

        LBLUE='\x1b[01;34m'
        LCYAN='\x1b[01;36m'
        LGRAY='\x1b[00;37m'
        LGREEN='\x1b[01;32m'
        LPURPLE='\x1b[01;35m'
        LRED='\x1b[01;31m'
        LYELLOW='\x1b[01;33m'

        sed -E "${
          lib.attrNames cfg.typeColors
          |> lib.map (c: typeMatch c)
          # nixfmt hack
          |> lib.concatStringsSep ";"
        } ; ${scopeMatch}"
      '';
  };
in
{
  imports = [ ];
  options =
    let
      colorType = lib.types.coercedTo lib.types.str lib.toUpper (
        lib.types.addCheck lib.types.str (s: lib.elem s supportedColors)
      );
      colorTypes = (lib.types.attrsOf colorType);
      colorTypesCheck = attrs: lib.all (name: lib.hasAttr name defaultTypeColors) (lib.attrNames attrs);
    in
    {
      introdus.color-conventional-commits = {
        enable = lib.mkEnableOption "Enables git log conventional commit coloring by default by overriding shell aliases";
        typeColors = lib.mkOption {
          type = lib.types.addCheck colorTypes colorTypesCheck;
          default = defaultTypeColors;
          example = {
            feat = "green";
          };
          description = "Color map for official conventional commit types";
          apply = colors: lib.mapAttrs (name: value: lib.toUpper value) (defaultTypeColors // colors);
        };
        extraTypeColors = lib.mkOption {
          type = colorTypes;
          default = { };
          example = {
            custom = "blue";
          };
          description = "Color map for extra commit types";
          apply = colors: lib.mapAttrs (name: value: lib.toUpper value) colors;
        };
        scopeColor = lib.mkOption {
          type = colorType;
          default = "lgray";
          example = "lgray";
        };
        bracketColor = lib.mkOption {
          type = colorType;
          default = "gray";
          example = "gray";
        };
      };
    };
  config = {
    home.packages = [
      git-color-cc
    ];

    programs.zsh = {
      shellAliases = {
        glo =
          lib.mkForce # bash
            ''f() { git log --color=always --oneline --decorate=short "$@" | ${lib.getExe git-color-cc} | $(git var GIT_PAGER) }; f'';
      };
    };
  };
}
