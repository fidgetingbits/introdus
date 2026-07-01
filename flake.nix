{
  description = "Introdus";
  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      treefmt-nix,
      wrappers,
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

        # Expose base neovim wrapper to be further extended by personal configs
        wrappers = {
          neovim = nixpkgs.lib.modules.importApply ./wrappers/neovim inputs;
        };
        # Expose base neovim wrapper to be further extended by personal configs
        flake.wrappers = {
          neovim = nixpkgs.lib.modules.importApply ./wrappers/neovim inputs;
        };
      };
      systems = [
        "x86_64-linux"
      ];
      imports = [ wrappers.flakeModules.wrappers ];

      perSystem =
        { system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./.config/treefmt.nix;
          formatter = treefmtEval.config.build.wrapper;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              # NOTE: Inject stable nixos pkgs for use by some packages (eg: unwanted-builtins)
              # and unstable for standalone introdus use such as automated checks
              (final: prev: {
                stable = import inputs.nixpkgs-stable {
                  system = final.stdenv.hostPlatform.system;
                  config.allowUnfree = true;
                };
                unstable = import inputs.nixpkgs-unstable {
                  system = final.stdenv.hostPlatform.system;
                  config.allowUnfree = true;
                };
              })
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ##
    # Neovim plugins not tracked by nixpkgs or that require newer versions
    ##
    plugins-nvim-toggler = {
      url = "github:nguyenvukhang/nvim-toggler";
      flake = false;
    };
    plugins-nvim-better-n = {
      url = "github:jonatan-branting/nvim-better-n";
      flake = false;
    };
    plugins-telescope-luasnip = {
      url = "github:benfowler/telescope-luasnip.nvim";
      flake = false;
    };
    plugins-confirm-quit = {
      url = "github:yutkat/confirm-quit.nvim";
      flake = false;
    };
    plugins-treesitter-textobjects = {
      url = "github:nvim-treesitter/nvim-treesitter-textobjects";
      flake = false;
    };
    plugins-pick-resession = {
      url = "github:scottmckendry/pick-resession.nvim";
      flake = false;
    };
    plugins-zen-mode = {
      url = "github:fidgetingbits/zen-mode.nvim?ref=fix-terminal";
      flake = false;
    };
    plugins-resession = {
      url = "github:fidgetingbits/resession.nvim?ref=visual-mode-fix";
      flake = false;
    };
  };
}
