return {
  {
    'scope.nvim',
    lazy = false,
    after = function(_)
      require('scope').setup({})
    end,
  },
}
