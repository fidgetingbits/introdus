inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
let
  configSource = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./init.lua
      ./lua
      ./after
      ./plugin
    ];
  };
in
{
  imports = [ wlib.wrapperModules.neovim ];
  options = {
    settings = {
      devMode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = false;
        description = ''
          Enables additional development plugins.

          Also implicitly uses unwrappedConfig unless
        '';
      };

      terminalMode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = false;
        description = ''
          Enable features for using neovim as your terminal and terminal multiplexer.

          For gui environments this is best paired when using neovide instead
          of ghostty/kitty/wezterm/etc.
        '';
      };

      hotReload = lib.mkOption {
        type = lib.types.bool;
        default = config.settings.devMode;
        example = false;
        description = ''
          When enabled, neovim will use a mutable impure config path.

          This allows hot reloading of some settings. Defaults to `devMode`, but
          can be forced off.

          When disabled, an immutable pure config in the `/nix/store` will be used.
        '';
      };

      # Have neovim use immutable config from /nix/store
      wrappedConfig = lib.mkOption {
        type = lib.types.either wlib.types.stringable lib.types.luaInline;
        default = "${configSource}";
        description = "Set of lua config files loaded into the /nix/store.";
      };

      # Have neovim use raw config folder for faster prototyping
      unwrappedConfig = lib.mkOption {
        type = lib.types.nullOr (lib.types.either wlib.types.stringable lib.types.luaInline);
        default = null;
        example = ''lib.generators.mkLuaInline "vim.uv.os_homedir() .. '/dev/nix/neovim'"'';
        description = ''
          Set can impure config path to load your config from. This can also be lua, but isn't explictily required.

          This value is used when hotReload is true.'';
      };

      extraConfig = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Specify a base neovim config to load from a wrapper extending the
          introdus neovim module.

          This allows the introdus neovim config to be loaded at runtime.

          When a neovim flake extends from the introdus wrapper, we still want to
          load the introdus lua files as a config, so pass it as an environment variable
          NVIM_BASE_CONFIG to the executed nvim process, so it can be be add to the runtime
          in the other flake
        '';
      };

      defaultCommand = lib.mkOption rec {
        type = lib.types.str;
        default = "luaeval('Snacks.dashboard()')";
        example = "execute('enew')";
        description = ''
          A default expression to be run when invoking bare nvim/vim/vi command
          while already nested inside a neovim terminal. The expression will be
          passed through lib.escapeShellArg.
        '';
      };

      neovide = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable a neovide wrapper around the the generated nvim binary.
        '';
      };

      guifont = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Font to set from external nix config";
      };

      # extraSpecs = lib.mkOption {
      #   type = lib.types.attrsOf lib.types.any;
      #   default = { };
      #   description = "Extra specs to integrate";
      # };

      # Inform lua which top level specs are enabled
      cats = lib.mkOption {
        readOnly = true;
        type = lib.types.attrsOf lib.types.bool;
        default = lib.mapAttrs (_: v: v.enable) config.specs;
      };
    };

    nvim-lib = {
      pluginInputs = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf wlib.types.stringable);
        default = [ inputs ];
        description = "List of inputs that may have external neovim plugin dependencies.";
      };
      neovimPlugins = lib.mkOption {
        readOnly = true;
        type = lib.types.attrsOf wlib.types.stringable;
        # Makes plugins autobuilt from our inputs available with
        # `config.nvim-lib.neovimPlugins.<name_without_prefix>`
        default = config.nvim-lib.pluginsFromPrefix "plugins-" (
          lib.foldl lib.recursiveUpdate { } config.nvim-lib.pluginInputs
        );
      };

      # This is from the official template and allows you to build plugins
      # that aren't in nixpkgs yet.
      pluginsFromPrefix = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
        default =
          prefix: inputs:
          lib.pipe inputs [
            lib.attrNames
            (lib.filter (s: lib.hasPrefix prefix s))
            (map (
              input:
              let
                name = lib.removePrefix prefix input;
              in
              {
                inherit name;
                value = config.nvim-lib.mkPlugin name inputs.${input};
              }
            ))
            lib.listToAttrs
          ];
      };
    };
  };

  config = {
    # Build a neovide wrapper
    hosts.neovide.nvim-host.enable = config.settings.neovide;

    settings.config_directory =
      assert ((config.settings.hotReload == false) || (config.settings.unwrappedConfig != null));
      if config.settings.hotReload then
        config.settings.unwrappedConfig
      else
        config.settings.wrappedConfig;

    settings.aliases = [
      "vi"
      "vim"
    ];

    # If run nested inside a neovim terminal, deal with it appropriately. --remote will pass args
    # to ':drop', but if no argument was specified it will error, so just run some default expression.
    # Otherwise, pass all the args through --remote. If not in nvim, just run as normal.
    runShell = [
      # bash
      ''

        # If we are nested in nvim already, and didn't provide arguments, run
        # some sane default.
        # If neovide is trying to run us, don't bother using rpc
        if ! ps -o ppid,comm -p $PPID | grep -q neovide && [[ $NVIM ]]; then
          if [ $# -eq 0 ]; then
            set -- --server $NVIM --remote-expr ${lib.escapeShellArg config.settings.defaultCommand}
          else
            set -- --server $NVIM --remote "$@"
          fi
        fi

        # This won't be set by neovide, but some terminal stuff expects it (checkhealth, etc)
        export TERM=xterm-256color
        ${
          if config.settings.extraConfig != null then
            "export NVIM_BASE_CONFIG=${config.settings.extraConfig}"
          else
            ""
        }
      ''
    ];

    # NOTE: Specs are enabled by default
    specs = {
      core = {
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            lze
            lzextras
            mini-icons
            nvim-web-devicons
            plenary-nvim
            vim-repeat
            ;
        };

        extraPackages = lib.attrValues {
          inherit (pkgs)
            fd
            ripgrep
            tree-sitter
            universal-ctags
            ;
        };
      };

      lsp = {
        enable = config.settings.devMode;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            lazydev-nvim # FIXME: switch this to specs.lua eventually
            SchemaStore-nvim # json schemas
            nvim-lspconfig
            ;
        };

        extraPackages = lib.attrValues {
          inherit (pkgs)
            bash-language-server
            just-lsp
            lua-language-server # lua_ls
            marksman # markdown
            nixd
            nix-doc
            ruff # python
            taplo # toml
            typos-lsp
            vscode-json-languageserver # jsonls
            ;
        };
      };

      search = {
        after = [ "core" ];
        lazy = true;
        data =
          lib.attrValues {
            inherit (pkgs.vimPlugins)
              telescope-nvim
              telescope-fzf-native-nvim
              telescope-ui-select-nvim
              telescope-zoxide
              flash-nvim
              ;
          }
          ++ lib.optionals config.settings.devMode (
            lib.attrValues {
              inherit (config.nvim-lib.neovimPlugins)
                telescope-luasnip
                ;
            }
          );
        extraPackages = lib.attrValues {
          inherit (pkgs)
            zoxide
            ;
        };
      };

      ui = {
        after = [ "core" ];
        lazy = true;
        data =
          lib.attrValues {
            inherit (pkgs.vimPlugins)
              # catppuccin-nvim
              fidget-nvim
              hardtime-nvim
              lualine-nvim
              neo-tree-nvim
              noice-nvim
              nvim-notify
              smart-splits-nvim
              snacks-nvim
              tabby-nvim
              todo-comments-nvim
              trouble-nvim
              which-key-nvim
              ;
            inherit (config.nvim-lib.neovimPlugins)
              zen-mode # Using fork to fix a terminal mode error
              ;
          }
          ++ lib.optionals config.settings.neovide (
            lib.attrValues {
              inherit (config.nvim-lib.neovimPlugins)
                # Only in neovide because quitting closes the outer window
                confirm-quit
                ;
            }
          )
          ++ lib.optionals config.settings.terminalMode (
            lib.attrValues {
              inherit (config.nvim-lib.neovimPlugins)
                telescope-toggleterm
                ;
            }
          );

        extraPackages = lib.attrValues {
          inherit (pkgs)
            chafa
            ;
        };
      };

      git = {
        after = [ "core" ];
        enable = config.settings.devMode;
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            gitsigns-nvim
            neogit
            ;
        };
      };

      format = {
        after = [ "core" ];
        enable = config.settings.devMode;
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            conform-nvim
            ;
        };
        extraPackages = lib.attrValues {
          inherit (pkgs)
            fixjson
            kdlfmt
            shfmt
            shellharden
            nixfmt
            rustfmt
            ruff
            yamlfmt
            prettier
            stylua
            ;
        };
      };

      kdl = {
        after = [ "format" ];
        enable = config.settings.devMode;
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            kdl-vim
            ;
        };
      };

      markdown = {
        after = [ "core" ];
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            vim-markdown-toc
            markdown-preview-nvim
            obsidian-nvim
            ;
        };
      };

      ai = {
        after = [ "ui" ];
        enable = config.settings.devMode;
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            codecompanion-nvim
            ;
        };
      };

      completion = {
        after = [ "core" ];
        lazy = true;
        data = lib.attrValues {
          inherit (pkgs.vimPlugins)
            blink-cmp
            blink-cmp-conventional-commits
            blink-cmp-spell
            colorful-menu-nvim # provide additional info for completion suggestions
            # FIXME: should snippets be on dev only?
            friendly-snippets
            vim-snippets
            luasnip
            ;
        };
      };

      editing =
        let
          treesitterDevPlugins = pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins:
            lib.attrValues {
              inherit (plugins)
                asm
                c
                cmake
                cpp
                git_config
                gitcommit
                gitignore
                go
                java
                javascript
                jinja
                jq
                kconfig
                kdl
                lua
                nasm
                regex
                rust
                ;
            }
          );
        in
        {
          after = [ "core" ];
          lazy = true;
          data =
            lib.attrValues {
              inherit (pkgs.vimPlugins)
                comment-nvim
                cutlass-nvim
                indent-blankline-nvim
                mini-ai
                mini-surround
                resession-nvim
                vim-easy-align
                nvim-treesitter
                nvim-treesitter-textobjects
                nvim-treesitter-context
                ;
              inherit (config.nvim-lib.neovimPlugins)
                nvim-toggler
                nvim-better-n
                pick-resession
                ;
            }
            ++ [
              (pkgs.vimPlugins.nvim-treesitter.withPlugins (
                plugins: with plugins; [
                  bash
                  html
                  json
                  json5
                  just
                  markdown
                  nix
                  python
                  query # treesitter scm queries
                  toml
                  yaml
                  zsh
                ]
              ))
            ]
            ++ lib.optionals config.settings.devMode [
              treesitterDevPlugins
            ]
            ++ (lib.attrValues {
              inherit (pkgs.vimPlugins)
                nvim-ts-autotag
                ;
            });

        };
    };

    # https://birdeehub.github.io/nix-wrapper-modules/neovim.html#tips-and-tricks
    specMods =
      {
        # parentSpec ? null,
        # parentOpts ? null,
        # parentName ? null,
        # config,
        ...
      }:
      {
        # add an extraPackages field to the specs themselves
        options.extraPackages = lib.mkOption {
          type = lib.types.listOf wlib.types.stringable;
          default = [ ];
          description = "An extraPackages spec field to put packages to suffix to the PATH";
        };
      };
    extraPackages = config.specCollect (acc: v: acc ++ (v.extraPackages or [ ])) [ ];

  };
}
