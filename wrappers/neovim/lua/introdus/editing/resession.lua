return {
  'resession',
  lazy = false,
  after = function()
    local resession = require('resession')
    resession.setup({
      autosave = {
        enabled = true,
        interval = 30,
        notify = false,
      },
      extensions = {
        lualine = {},
        tabby = {},
        terminal = {},
      },
    })

    -- stylua: ignore start
    local l = "<leader>S"
    vim.keymap.set('n', l .. 's', resession.save,   { desc = 'Save session' })
    vim.keymap.set('n', l .. 'S', function()
        resession.detach()
        resession.save()
    end,   { desc = 'Save session as' })
    vim.keymap.set('n', l .. 'l', resession.load,   { desc = 'Load session' })
    vim.keymap.set('n', l .. 'L', function()
        vim.print(resession.list)
        end,   { desc = 'Print sessions' })
    vim.keymap.set('n', l .. 'r', function()
        local current = resession.get_current()
        resession.detach()
        resession.save()
        resession.delete(current)
        end,   { desc = 'Rename session' })
    vim.keymap.set('n', l .. 'd', resession.delete, { desc = 'Delete session' })
    vim.keymap.set('n', l .. 'x', resession.detach, { desc = 'Close session' })
    -- stylua: ignore end

    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        -- Always save a special session named "last"
        resession.save('last')
      end,
    })
  end,
}
