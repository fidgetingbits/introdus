return {
  {
    'render-markdown.nvim',
    ft = { 'markdown', 'codecompanion' },
    after = function(_plugin)
      require('render-markdown').setup({
        render_modes = true, -- Render in ALL modes
        sign = {
          enabled = false, -- Turn off in the status column
        },
        file_types = { 'markdown', 'codecompanion' },
      })
    end,
  },
}
