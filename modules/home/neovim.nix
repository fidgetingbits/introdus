{
  pkgs,
  inputs,
  lib,
  config,
  osConfig,
  ...
}:
let
  cfg = config.introdus.neovim;
in
{
  imports = [
    (inputs.wrappers.lib.mkInstallModule {
      loc = [
        "home"
        "packages"
      ];
      name = "neovim";
      value = inputs.${cfg.wrapper}.wrapperModules.neovim;
    })
  ];

  options.introdus.neovim = {
    enable = lib.mkEnableOption "Enable neovim wrapper";
    wrapper = lib.mkOption {
      type = lib.types.str;
      example = "fidgetingvim";
      description = "Name of neovim wrapper flake input";
    };
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

    programs.zsh = {
      initContent =
        let
          nvr = lib.getExe pkgs.neovim-remote;
        in
        lib.optionalString osConfig.hostSpec.useNeovimTerminal
          # bash
          ''
            if [[ $NVIM ]]; then
                # FIXME: This should use wrapper
                export MANPAGER='${nvr} --remote-tab +Man! -'
                # FIXME: replace with nvim once --remote-wait is supported:
                # https://github.com/neovim/neovim/issues/24788
                export GIT_EDITOR="${nvr} --remote-wait-silent -cc split"

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

    home = {
      packages = [
        pkgs.neovim-remote
      ];
    };
  };
}
