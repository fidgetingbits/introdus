return {
  {
    'mini.surround',
    event = 'DeferredUIEnter',
    lazy = false,
    after = function(plugin)
      -- NOTE: See ./../../../after/ftplugin/ for some custom_surroundings entries
      require('mini.surround').setup({
        -- flash.nvim uses s/S, so we use m (and remap m to <leader> m elsewhere for marks)
        -- Think of m like matching surrounding chars
        mappings = {
          add = 'ma', -- Add surrounding in Normal and Visual modes
          delete = 'md', -- Delete surrounding
          find = 'mf', -- Find surrounding (to the right)
          find_left = 'mF', -- Find surrounding (to the left)
          highlight = 'mh', -- Highlight surrounding
          replace = 'mr', -- Replace surrounding
        },
      })
    end,
  },
}
