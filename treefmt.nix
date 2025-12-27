{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nix
    shfmt.enable = true; # shell scripts
    ruff.enable = true; # python
    rustfmt.enable = true; # rust
    yamlfmt.enable = true; # yaml
  };
}
