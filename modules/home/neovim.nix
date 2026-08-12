{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  cfg = config.introdus.neovim;
in
{
  options.introdus.neovim = {
    enable = lib.mkEnableOption "Enable neovim wrapper";
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      example = 12;
      description = "Font size to pass to configured fonts";
    };
  };

  config = lib.mkIf cfg.enable {
    wrappers.neovim = {
      enable = true;
      settings = {
        neovide = osConfig.hostSpec.useWindowManager;
        # NOTE: This means you need the neovim source at the specified
        # unwrapped_config path ex ~/dev/nix/neovim
        devMode = osConfig.hostSpec.isDevelopment;
        terminalMode = osConfig.hostSpec.useNeovimTerminal;
        guifont =
          # FIXME: Doesn't seem to work when setting all fonts, so just defaulting to first for now
          [ (lib.head osConfig.fonts.fontconfig.defaultFonts.monospace) ]
          |> map (f: "${f}:h${toString config.introdus.neovim.fontSize}")
          |> lib.concatStringsSep ",";
        compile_generated_lua = false; # Temporary for debugging
      };
    };

    xdg.desktopEntries.nvim-neovide = {
      name = "Neovide (Nvim Wrapper)";
      genericName = "Text Editor";
      exec = "nvim-neovide %F";
      icon = "nvim";
      terminal = false;
      categories = [
        "Utility"
        "TextEditor"
      ];
      settings = {
        StartupWMClass = "neovide";
      };
    };

    programs.zsh = {
      initContent =
        let
          nvr = lib.getExe pkgs.neovim-remote;
        in
        lib.optionalString osConfig.hostSpec.useNeovimTerminal
          # bash
          ''
            # Add an option for forcing files into a new tabpage
            # FIXME: Would be good to send a PR to add -T or similar
            nv_wrapper() {
                extra_args=()
                args=("$@")
                for ((i=0; i<"''${#args[@]}"; ++i)); do
                    case "''${args[i]}" in
                        -T)
                            unset "args[$i]"
                            extra_args=(-e 'wincmd T')
                            break
                            ;;
                    esac
                done
                nv "''${extra_args[@]}" "''${args[@]}"
            }
            alias nv=nv_wrapper

            if [[ $NVIM ]]; then
                # FIXME: This should use wrapper
                export MANPAGER='${nvr} --remote-tab +Man! -'
                # FIXME: replace with nvim once --remote-wait is supported:
                # https://github.com/neovim/neovim/issues/24788
                export GIT_EDITOR="${nvr} --remote-wait-silent -cc split"
                export SOPS_EDITOR="${nvr} --remote-wait-silent -cc split"

                # Specifically update local-window scoped working directory
                # only, as otherwise breaks tab workspaces
                autocd_nvim() {
                    nvim --headless --server "$NVIM" \
                        --remote-expr "luaeval('vim.cmd [[silent lcd "$PWD" ]]')"
                }
                chpwd_functions+=(autocd_nvim)
            fi

          '';
    };

    home =
      let
        # Wrapper in the vein of nvr, but shorter commands and using the wrapper
      in
      {
        packages = [
          pkgs.neovim-remote
        ]
        # Tool to allow you to easily open files from terminal in splits, etc
        ++ lib.optional osConfig.hostSpec.useNeovimTerminal pkgs.page;
      };
  };
}
