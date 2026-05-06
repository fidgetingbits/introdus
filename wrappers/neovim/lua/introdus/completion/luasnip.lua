return {
  {
    -- NOTE: See blink for keymap
    'luasnip',
    lazy = false,
    dep_of = { 'blink.cmp' },
    after = function(_)
      local ls = require('luasnip')
      local filetype_funcs = require('luasnip.extras.filetype_functions')
      ls.config.setup({
        -- Keeps the last snippet around, so you can jump back in if needed
        history = true,
        -- Updates as you type
        updateevents = 'TextChanged,TextChangedI',
        -- Deletes choice node floating text after leaving snippet
        -- NOTE: has perf cost https://github.com/L3MON4D3/LuaSnip/issues/298
        delete_check_events = 'TextChanged,CursorMoved',

        -- Mark a visual selection for snippets to access it via TM_SELECTED_TEXT env
        -- store_selection_keys = '<C-s>',
        store_selection_keys = '<Tab>',

        -- Add choice node indicator
        ext_opts = {
          [require('luasnip.util.types').choiceNode] = {
            active = {
              -- use :Telescope highlights to find colors like @character
              --             text, color
              virt_text = { { '', '@character' } },
            },
          },
        },
        -- Tweak when snippets are loaded to support "injection" locations inside other languages
        -- for instance, if in nix you have:
        -- foo = # bash '' <some bash> '';
        -- then bash snippets will load when inside the '' '' block
        ft_func = filetype_funcs.from_cursor_pos,
        -- In order for the above to work, all possible language snippets need to be loaded for
        -- that file type. See :h luasnip-extras-filetype-functions
        load_ft_func = filetype_funcs.extend_load_ft({
          nix = { 'markdown', 'lua', 'sh', 'python' },
          markdown = { 'nix', 'markdown', 'lua', 'sh', 'python' },
          just = { 'sh' },
        }),
      })

      -- Load snippets from runtime paths. To load introdus snippets
      -- for now, your neovim config should be adding the snippets/
      -- folder to the runtime path during init.
      --
      -- NOTE: Luasnip snippets are auto-reloaded on change, so if
      -- your introdus/neovim folders are impure, you don't need
      -- to manually reload.
      require('luasnip.loaders.from_vscode').lazy_load()
      require('luasnip.loaders.from_lua').lazy_load()

      -- Load snipmate snippets (NOTE: lots of duplicates)
      --
      -- snipmate globals use '_' identifier for all
      -- ls.filetype_extend('all', { '_' })
      -- require('luasnip.loaders.from_snipmate').lazy_load()

      vim.keymap.set({ 'i', 's' }, '<c-k>', function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      end, { silent = true })

      vim.keymap.set({ 'i', 's' }, '<c-j>', function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true })

      vim.keymap.set({ 'i', 's' }, '<c-l>', function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })

      vim.keymap.set({ 'i', 's' }, '<C-f>', function()
        if ls.choice_active() then
          require('luasnip.extras.select_choice')()
        end
      end, { desc = 'Select luasnip choice' })
    end,
  },
  {
    'friendly-snippets',
    lazy = true,
    dep_of = { 'luasnip' },
  },
  {
    'vim-snippets',
    lazy = true,
    dep_of = { 'luasnip' },
  },
}
