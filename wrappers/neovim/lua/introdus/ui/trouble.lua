return {
  {
    'trouble.nvim',
    cmd = 'Trouble',

    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        mode = { 'n', 'x' },
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        mode = { 'n', 'x' },
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>xs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        mode = { 'n', 'x' },
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>xl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        mode = { 'n', 'x' },
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        mode = { 'n', 'x' },
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        mode = { 'n', 'x' },
        desc = 'Quickfix List (Trouble)',
      },
    },
    after = function(plugin)
      require('trouble').setup({})
    end,
  },
}
