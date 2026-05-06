return {
  {
    'markdown-preview.nvim',
    cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
    ft = 'markdown',
    -- stylua: ignore
    keys = {
      { "<leader>Mp", vim.cmd.MarkdownPreview,       mode = { "n" }, noremap = true, desc = "markdown preview" },
      { "<leader>Ms", vim.cmd.MarkdownPreviewStop,   mode = { "n" }, noremap = true, desc = "markdown preview stop" },
      { "<leader>Mt", vim.cmd.MarkdownPreviewToggle, mode = { "n" }, noremap = true, desc = "markdown preview toggle" },
    },
    before = function(_plugin)
      vim.g.mkdp_auto_close = 0
    end,
  },
}
