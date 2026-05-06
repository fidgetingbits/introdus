return {
  {
    'ruff',
    enabled = nixInfo(false, 'settings', 'devMode'),
    lsp = {
      settings = {
        ruff = {},
      },
    },
  },
  {
    'pyright',
    enabled = nixInfo(false, 'settings', 'devMode'),
    lsp = {
      settings = {
        pyright = {
          capabilities = {
            textDocument = {
              publishDiagnostics = {
                tagSupport = {
                  valueSet = { 2 },
                },
              },
            },
          },
          disableOrganizeImports = true, -- Using Ruff
        },
        python = {
          analysis = {
            ignore = { '*' }, -- Using Ruff
            -- Maybe set this to to keep type checking, but disable duplicate with ruff
            -- see https://github.com/astral-sh/ruff-lsp/issues/384
            -- diagnosticSeverityOverrides = {
            --   -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
            --   reportUndefinedVariable = 'none', -- Avoid ruff duplication
            -- },
          },
        },
      },
    },
  },
}
