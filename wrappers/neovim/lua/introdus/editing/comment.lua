return {
  {
    'comment.nvim',
    event = 'DeferredUIEnter',
    after = function(plugin)
      require('Comment').setup()
      local ft = require('Comment.ft')
      ft.set('sieve', '#%s')
    end,
  },
}
