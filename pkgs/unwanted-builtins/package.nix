# IMPORTANT: The lib this tool uses must be OLDER than or equal to the lib used
# by whatever lib is used by the configuration being checked for unwanted-builtins
# Otherwise it will complain about a builtin that it thinks is in it's own lib, but
# not might actually be in the lib on the configuration being validated.
#
# For example, where nixpkgs below is 25.11, `lib.div` will not exist:
# ```bash
# nix eval --inputs-from . nixpkgs-unstable#lib.div
# nix eval --inputs-from . nixpkgs#lib.div
# ```
# This means if this tool was built with unstable, it would fail on the use of
# builtins.div, even though lib.div is not valid on 25.11
{
  lib,
  pkgs,
  ripgrep,
  ...
}:
let
  # impureBuiltins show up in the repl, but not in `lib.attrNames builtins`
  # when generating the script. Not _entirely_ sure why
  impureBuiltins = [
    "currentTime"
    "currentSystem"
  ];
  allLibNames =
    lib.mapAttrsRecursive (path: value: if (lib.isFunction value) then path else null) pkgs.stable.lib
    |> lib.attrNames
    |> lib.filter (x: !(builtins.isNull x));

  regexPattern =
    (lib.attrNames builtins ++ impureBuiltins)
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
