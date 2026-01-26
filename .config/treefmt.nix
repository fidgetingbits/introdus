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
