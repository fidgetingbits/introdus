[group("building")]
check:
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure --show-trace -L
