{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nix
    shfmt = {
      enable = true;
      indent_size = 4; # Seems not to pick up .editorconfig?
    };
    # rustfmt.enable = true; # rust
    yamlfmt.enable = true; # yaml
  };
}
