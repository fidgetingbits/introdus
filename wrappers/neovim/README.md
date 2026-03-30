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

The introdus path can be set in nix using the `settings.extraConfig` option,
which should point to the introdus neovim wrapper path. For example:

```nix
    settings.extraConfig = "${inputs.introdus}/wrappers/neovim";
```

This path will be passed at runtime to nvim using the `NVIM_BASE_CONFIG`
environment variable, which can be read by and loaded by lua. To load the
introdus config at startup, the following lua code needs to be prefixed to the
`init.lua` config file of the wrapper extending introdus:

```lua
local introdus_config = os.getenv('NVIM_BASE_CONFIG')
if introdus_config then
  -- Prepend so B's lua/ directory is searchable immediately
  vim.opt.rtp:prepend(introdus_config)

  -- Prepend to packpath so B's plugins (if any) are found
  vim.opt.packpath:prepend(introdus_config)

  -- Handle the 'after' directory correctly
  local introdus_after = introdus_config .. '/after'
  if vim.fn.isdirectory(introdus_after) == 1 then
    vim.opt.rtp:append(introdus_after)
  end
  require('introdus')
else
  print([[ERROR: This config cannot run without introdus.
    Use settings.extraConfig in your wrapper to specify the introdus path.]])
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

To configure these variables (for now) you can either set the values in your
neovim flake's `module.nix` file or in your nix config. The
`hostSpec.isDevelopment` flag from your nix config will determine the default
value of `settings.devMode`.

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
