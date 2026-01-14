{
  description = "Introdus";
  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      treefmt-nix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        overlays = import ./overlays { inherit inputs lib; };
        # Builds the introdus library for use in an external flake
        lib = {
          mkIntrodusLib =
            {
              lib,
              secrets ? { },
            }:
            import ./lib { inherit lib secrets; };
        };
        nixosModules = {
          default = self.nixosModules.introdus;
          introdus = ./modules/nixos;
        };

        homeManagerModules = {
          default = self.homeManagerModules.introdus;
          introdus = ./modules/home;
        };
      };
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        { system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./.config/treefmt.nix;
          formatter = treefmtEval.config.build.wrapper;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
          };
        in
        rec {
          packages = lib.packagesFromDirectoryRecursive {
            callPackage = lib.callPackageWith pkgs;
            directory = ./pkgs;
          };
          checks =
            import ./checks {
              inherit
                self
                inputs
                pkgs
                system
                lib
                formatter
                ;
            }
            // {
              formatting = treefmtEval.config.build.check self;
            };

          inherit formatter;
          devShells.default = pkgs.mkShell {
            NIX_CONFIG = "extra-experimental-features = nix-command flakes pipe-operators";
            NIXPKGS_ALLOW_UNFREE = "1";

            inherit (checks.pre-commit-check) shellHook;
            buildInputs = checks.pre-commit-check.enabledPackages;

            nativeBuildInputs = lib.attrValues {
              inherit (pkgs)
                nix
                git
                just
                pre-commit
                cocogitto
                forgejo-runner
                bats
                ;
              inherit (pkgs.introdus)
                introdus-helpers # get transient dependencies for manual bats testing
                unwanted-builtins
                ;
            };
          };
        };
    };
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
