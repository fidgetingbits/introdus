if vim.g.neovide then
  --[[ Neovide keymaps ]]
  -- stylua: ignore start
  vim.keymap.set({ 'i', "", "x", "v" }, '<C-S-v>', '<C-r>+',
    { noremap = true, silent = true, desc = 'Paste from clipboard from within most modes' })
  -- IMPORTANT: without `silent = false` pasting into cmdline mode won't show up immediately in neovide
  vim.keymap.set({ 'c', }, '<C-S-v>', '<C-r>+', { noremap = true, silent = false, desc = 'Paste from clipboard from within all modes' })
  vim.api.nvim_set_keymap('t', '<C-S-v>', '<C-\\><C-n>"+Pi', {noremap = true, silent = true, desc = 'Paste from clipboard from terminal mode'})
  -- Tweak font sizes
  vim.keymap.set({ "t", "n", "v" }, "<C-+>", function()
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
  end)
  vim.keymap.set({ "t", "n", "v" }, "<C-->", function()
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
  end)
  vim.keymap.set({ "t", "n", "v" }, "<C-=>", function()
    vim.g.neovide_scale_factor = 1
  end)
  -- stylua: ignore end
end
