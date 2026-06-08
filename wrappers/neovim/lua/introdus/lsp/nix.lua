local get_nixd_opts = nixInfo(nil, 'info', 'nixdExtras', 'get_configs')
return {
  {
    'nixd',
    lsp = {
      filetypes = { 'nix' },
      cmd = { 'nixd', '--log=error', '--inlay-hints=true', '--semantic-tokens=true', '--pretty' },
      settings = {
        nixd = {
          nixpkgs = {
            expr = nixInfo('import <nixpkgs> {}', 'info', 'nixdExtras', 'nixpkgs'),
          },
          options = {
            -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${lib.toString inputs.self.outPath}").nixosConfigurations.configname.options''
            nixos = {
              expr = get_nixd_opts
                and get_nixd_opts('nixos', nixInfo(nil, 'info', 'nixdExtras', 'flake-path')),
            },
            -- (builtins.getFlake "path:${lib.toString <path_to_system_flake>}").legacyPackages.<system>.homeConfigurations."<user@host>".options
            ['home-manager'] = {
              expr = get_nixd_opts
                and get_nixd_opts('home-manager', nixInfo(nil, 'info', 'nixdExtras', 'flake-path')), -- <-  if flake-path is nil it will be lsp root dir
            },
            target = {
              args = {},
            },
          },
          formatting = {
            command = { 'nixfmt' },
          },
          diagnostic = {
            suppress = {},
          },
          completion = {
            enable = true,
            priority = 10,
            insertSingleCandidateImmediately = true,
          },
          eval = {
            target = {
              args = {},
            },
            depth = 10,
          },
        },
      },
    },
  },
}
