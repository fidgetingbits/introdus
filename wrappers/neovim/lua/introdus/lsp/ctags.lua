return {
  {
    'ctags_lsp',
    enabled = nixInfo(false, 'settings', 'devMode'),
    lsp = {
      filetypes = { 'c', 'cpp' },
      settings = {
        ctags_lsp = {},
      },

      -- ctags_lsp will noisily complain about this not existing sometimes
      handlers = {
        ['workspace/didChangeConfiguration'] = function() end,
      },
    },
  },
}
