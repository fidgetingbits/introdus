# Introdus Neovim Wrapper

This is a [neovim
wrapper](https://github.com/BirdeeHub/nix-wrapper-modules/blob/main/templates/neovim/README.md)
that serves as a baseline configuration for Introdus users. The assumption is
it will be extended further by another standalone flake or similar.

An example of how this wrapper can be extended into a more personalized neovim
experience can be seen [here](https://github.com/fidgetingbits/neovim).

## Design

There are three pieces involved when using neovim with introdus:

1. The introdus neovim wrapper, which defines a baseline set of plugins, nix
   packages, and lua configuration.

2. Some external neovim wrapper extending (1), which provides additional lua
   configuration, plugins and nix packages.

3. The introdus homeManager [module](./../../modules/home/neovim.nix), used
   per-user for nix setups that can set specific options that influence the
   wrapper.

## Usage

There are three small steps for extending the introdus neovim wrapper.

### REQUIRED: Import the wrapper

The neovim wrapper extending the introdus wrapper MUST import the
introdus wrapper module:

```nix
imports = [
    inputs.introdus.wrapperModules.neovim
];
```

### REQUIRED: Initializing the base config

The wrapper extending introdus must initialize the introdus lua config
manually. To do this, it needs to be passed the path of the introdus
config code at runtime.

This is required because introdus baseline itself isn't some external plugin,
but rather an additional configuration we want to preload in order to setup all
of our functionality, which in turn lets us load plugins, etc.

The introdus path can be set in nix using the `settings.baseCofig` option,
which should point to the introdus neovim wrapper path. For example:

```nix
    settings.baseCofig = "${inputs.introdus}/wrappers/neovim";
```

This path will be passed at runtime to nvim using the `NVIM_BASE_CONFIG`
environment variable, which can be read by and loaded by lua. To load the
introdus config at startup, the following lua code needs to be added to the
`init.lua` config file of the wrapper extending introdus:

```lua
-- This config is derived from the introdus neovim wrapper
-- so have introdus set things up for us
local introdus_config = os.getenv('NVIM_BASE_CONFIG')
if introdus_config then
  vim.opt.runtimepath:prepend(introdus_config)
  require('introdus')
else
  print([[ERROR: This config cannot run without introdus.
      Use settings.baseConfig in your wrapper to specify the introdus path]])
end
```

Any code following this block can now reference `nixInfo`, load plugins, etc as
you would in a normal neovim wrapper.

You can see this in practice
[here](https://github.com/fidgetingbits/neovim/blob/main/init.lua).

### OPTIONAL: Hot reloading

You can "hot reload" some parts of the neovim config without rebuilding. This
is currently limited to things like snippets, and the `plugin/` folder. We
don't support reloading modules with lze, as need to look into it.

The introdus neovim wrapper uses two options to determine where to load your
neovim config:

The `wrappedConfig` is the default and is meant to be a pure path, so will
point into `/nix/store`.

`unwrappedConfig` is impure and is meant to point to your actual nix config on
disk. By default the `settings.devMode` boolean set to true will use
`unwrappedConfig`, however it can be toggled on/off independent of `devMode` by
using the `settings.hotReload` boolean.

To configure these variables you can either set the values in your
neovim flake's `module.nix` file or in your nix config. The
`hostSpec.isDevelopment` flag from your nix config will determine the default
value of `settings.devMode`, which in turn will determine if hot reloading is enabled by default.

If you want to set them in your nixos-config you can do something like this:

```nix
{
  ...
}:
{
  introdus.neovim = {
    enable = true;
    wrapper = "fidgetingvim";
  };

  wrappers.neovim = {
    settings.unwrappedConfig = "<foo>";
  };
}
```

### OPTIONAL: Specifying external plugin sources

This is only required if you are using neovim plugins that are not in nixpkgs,
and that aren't already defined by the introdus wrapper.

There is a `nvim-lib.pluginInputs` option that can be used to specify all the
input locations that provide external neovim plugins that are not available in
nix packages. By default only plugins specified by introdus are processed, so
when a wrapper extends it, it must specify that it's own inputs provide
additional plugins.

```nix
    nvim-lib.pluginInputs = [
      inputs
      inputs.introdus
    ];
```

This leverages a feature of base nix-wrapper-modules neovim wrapper, which
allows you to specify a `plugin-` prefixed input name and point it to a git repository,
and expose

## Testing

The wrapper is exposed as a standalone package without needing to be further
wrapped. Run `nix build .#neovim` to build it. You should be able to then run
`result/bin/nvim`.

## Development

### Adding a new plugin

When you add a new plugin there are a few steps:

1) Modify `./module.nix` to install the plugin. If there is an existing package in nixpkgs, install it in the relevant category (defined in `specs` attrset) using the `pkgs.vimPlugins` set. If there is no package, import the git repo directly andthen access it using the `config.nvim-lib.neovimPlugins` set. In order to add the git repo you will need to add a new input to `../../flake.nix`.

You add something like this:

```nix
    plugins-zen-mode = {
      url = "github:fidgetingbits/zen-mode.nvim?ref=fix-terminal";
      flake = false;
    };
```

Then access it from `config.nvim-lib.neovimPlugins` with the `plugins-` part removed, like:

```nix
  specs = {
    ...
    ui = {
      after = [ "core" ];
      lazy = true;
      data = lib.attrValues {
          inherit (config.nvim-lib.neovimPlugins)
            zen-mode # Using fork to fix a terminal mode error
            ;
      };
    ...
    };
  ...
  };
```

2) Import the actual module for the related category. Above in the example for `zen-mode` it is part of `ui`. So you would need to modify to include an entry to import a new `zen-mode.lua` file you will place in `lua/introdus/ui/` folder:

```lua
local MP = ...
return {
  ...
  { import = MP:relpath('zen-mode') },
  ...
}
```

3) Finally inside `zen-mode.lua` you configure the plugin settings. It will look something like this:

```lua
return {
  {
    'zen-mode',
    event = 'DeferredUIEnter',
    after = function(plugin)
      require('zen-mode').setup()
      vim.keymap.set('n', '<leader>zz', vim.cmd.ZenMode, { desc = 'Toggle zen mode' })
    end,
  },
}
```

There is one quirk here, which is the name to use to require the module, which is the first entry of the table. Above it is `zen-mode`, however if you look at the installation notes for the official project [here](https://github.com/folke/zen-mode.nvim) you will see they say to use `zen-mode.nvim`. The naming will sometimes differ from the official recommendation if you are using a dedicated flake input, etc.

In order to be sure what the actual name is there is a simple way to debug. From your neovim wrapper dev shell, run `nix build .#full`. This will give you the `result/` folder that contains the installed neovim packages. Enter the folder and run something like `fd zen-mode`. This will tell the exact folder name, which is what you need to use in the first field:

```bash
❯ fd zen-mode
nvim-packdir/pack/myNeovimPackages/opt/zen-mode
```
