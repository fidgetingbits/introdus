return {
  {
    'smart-splits.nvim',
    lazy = false,
    event = 'DeferredUIEnter',
    after = function(plugin)
      require('smart-splits').setup({
        cursor_follows_swapped_bufs = true,
        at_edge = function(ctx)
          if ctx.direction == 'left' then
            vim.cmd('tabprevious')
          elseif ctx.direction == 'right' then
            vim.cmd('tabnext')
          end
        end,
      })

      -- stylua: ignore start
      local ss = require('smart-splits')
      local modes = { 't', 'n', 'x' }
      vim.keymap.set(modes, '<A-h>',     ss.move_cursor_left,  { desc = "Move pane left" })
      vim.keymap.set(modes, '<A-j>',     ss.move_cursor_down,  { desc = "Move pane left" })
      vim.keymap.set(modes, '<A-k>',     ss.move_cursor_up,    { desc = "Move pane left" })
      vim.keymap.set(modes, '<A-l>',     ss.move_cursor_right, { desc = "Move pane left" })

      modes = { 't', 'x', 'i', 'n' }
      vim.keymap.set(modes, '<A-S-h>',   ss.swap_buf_left,     { desc = "Swap pane left" })
      vim.keymap.set(modes, '<A-S-j>',   ss.swap_buf_down,     { desc = "Swap pane down" })
      vim.keymap.set(modes, '<A-S-k>',   ss.swap_buf_up,       { desc = "Swap pane up" })
      vim.keymap.set(modes, '<A-S-l>',   ss.swap_buf_right,    { desc = "Swap pane right" })

      -- NOTE: these accept a range: `10<A-left>` will `resize_left` by `(10 * config.default_amount)`
      vim.keymap.set(modes, '<A-left>',  ss.resize_left,       { desc = "Resize pane left" })
      vim.keymap.set(modes, '<A-down>',  ss.resize_down,       { desc = "Resize pane down" } )
      vim.keymap.set(modes, '<A-up>',    ss.resize_up,         { desc = "Resize pane up" } )
      vim.keymap.set(modes, '<A-right>', ss.resize_right,      { desc = "Resize pane right" })
      vim.keymap.set(modes, '<A-=>', function() vim.cmd("wincmd =") end,      { desc = "Resize pane right" })

      vim.keymap.set(modes, '<A-q>', function() vim.api.nvim_win_close(0, false) end, { desc = "Close current window" })
      -- stylua: ignore end
    end,
  },
}
