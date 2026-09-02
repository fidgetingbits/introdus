[private]
default:
    @just --list

# Run nix flake checks and formatting
[group("building")]
check:
    nix fmt
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure --show-trace -L

[group("release")]
bump:
    # This is needed because libgit2 doesn't support includeIf, but we want the
    # email to be good for signature verification
    #
    # https://github.com/cocogitto/cocogitto/issues/527
    # https://github.com/libgit2/libgit2/issues/6641
    #
    @git config set user.email emergentmind@noreply.codeberg.org
    cog bump -a
    @git config unset user.email
