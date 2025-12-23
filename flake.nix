{
  description = "Introdus";
  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
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
          mkIntrodusLib = lib: secrets: import ./lib { inherit lib secrets; };
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
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        rec {
          packages = lib.packagesFromDirectoryRecursive {
            callPackage = lib.callPackageWith pkgs;
            directory = ./pkgs;
          };
          checks = import ./checks {
            inherit
              self
              inputs
              pkgs
              system
              lib
              ;
          };
          formatter = pkgs.nixfmt;
          devShells = import ./shell.nix {
            inherit
              checks
              inputs
              system
              pkgs
              lib
              ;
          };
        };
    };
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
