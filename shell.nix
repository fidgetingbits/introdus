{
  pkgs ?
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
    in
    import nixpkgs { overlays = [ ]; },
  checks,
  ...
}:
let
  lib = pkgs.lib;
in
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes pipe-operators";

    inherit (checks.pre-commit-check) shellHook;
    buildInputs = checks.pre-commit-check.enabledPackages;

    nativeBuildInputs = lib.attrValues {
      inherit (pkgs)
        nix
        nh
        git
        just
        pre-commit
        deadnix
        ripgrep
        ;
    };
  };
}
