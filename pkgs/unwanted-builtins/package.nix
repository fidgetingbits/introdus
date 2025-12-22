{
  lib,
  pkgs,
  ripgrep,
  ...
}:
let

  allLibNames =
    lib.mapAttrsRecursive (path: value: if (lib.isFunction value) then path else null) lib
    |> lib.attrNames
    |> lib.filter (x: !(builtins.isNull x));
  regexPattern =
    lib.attrNames builtins
    |> lib.filter (b: !(lib.elem b allLibNames))
    # nixfmt hack
    |> lib.concatStringsSep "|";
in
pkgs.writeShellApplication {
  name = "unwanted-builtins";
  runtimeInputs = [ ripgrep ];
  text = # bash
    ''
      shopt -u expand_aliases
      # Flag anything that isn't builtins-only
      matches=$(rg "builtins\." "$@" | \
                rg --pcre2 -v "builtins\.(${regexPattern})" || true)
      if [ -n "$matches" ]; then
        echo "Found non-white listed builtins call(s):"
        echo "$matches"
        exit 1
      fi
    '';
}
