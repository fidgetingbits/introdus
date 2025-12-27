{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nix
    shfmt.enable = true; # shell scripts
    # rustfmt.enable = true; # rust
    yamlfmt.enable = true; # yaml
  };
}
