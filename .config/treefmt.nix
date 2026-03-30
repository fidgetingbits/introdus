{ lib, ... }:
rec {
  projectRootFile = "flake.nix";
  programs = {
    kdlfmt = {
      enable = true; # kdl
    };
    nixfmt.enable = true; # nix
    ruff.enable = true; # python
    shfmt = {
      enable = true;
      indent_size = 4; # Seems not to pick up .editorconfig?

    };
    stylua = {
      enable = true; # lua
      settings = {
        # From https://github.com/neovim/neovim/blob/master/.stylua.toml
        # call_parantheses changed for consistency
        column_width = 100;
        line_endings = "Unix";
        indent_type = "Spaces";
        indent_width = 2;
        quote_style = "AutoPreferSingle";
        call_parentheses = "Always";
      };
    };
    yamlfmt.enable = true; # yaml
  };
  settings.formatter = lib.optionalAttrs programs.kdlfmt.enable {
    kdlfmt = {
      options = [
        "format"
        # This is needed for niri config files not to break various quoted things
        "--kdl-version"
        "v1"
      ];
    };
  };
}
