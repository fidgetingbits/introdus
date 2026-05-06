-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
vim.api.nvim_create_autocmd('FileType', {
  desc = 'remove formatoptions',
  callback = function()
    vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.hl.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Return to most recent tab on tab closure ]]
local tablisttrack = vim.api.nvim_create_augroup('TabListTrack', { clear = true })
vim.g.last_tabs = { vim.api.nvim_get_current_tabpage(), vim.api.nvim_get_current_tabpage() }

vim.api.nvim_create_autocmd('TabEnter', {
  callback = function()
    local tabs = vim.g.last_tabs
    tabs[1] = tabs[2]
    tabs[2] = vim.api.nvim_get_current_tabpage()
    vim.g.last_tabs = tabs
  end,
  group = tablisttrack,
})

vim.api.nvim_create_autocmd('TabClosed', {
  callback = function()
    local last_tab = vim.g.last_tabs[1]
    if vim.api.nvim_tabpage_is_valid(last_tab) then
      vim.api.nvim_set_current_tabpage(last_tab)
    end
  end,
  group = tablisttrack,
})

-- [[ Named Tab Retention ]]
--
-- Don't completely remove a named tabpage when the last window closes
-- FIXME: This should maybe spawn a dashboard or something. probably make it configurable
--

-- FIXME: This sometimes prevents a new buffer entering with telescope picker so need to diagnose
-- vim.api.nvim_create_autocmd({ 'BufDelete', 'BufHidden' }, {
--   callback = function(args)
--     if vim.v.exiting ~= vim.NIL then
--       return
--     end
--     for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
--       local success, name = pcall(require('tabby.feature.tab_name').get_raw, tab)
--       if not success or #name == 0 then
--         return
--       end
--       local wins = vim.api.nvim_tabpage_list_wins(tab)
--       if #wins > 1 then
--         return
--       end
--       for _, win in ipairs(wins) do
--         if vim.api.nvim_win_get_buf(win) == args.buf then
--           local placeholder = vim.api.nvim_create_buf(true, false)
--           vim.api.win_set_buf(win, placeholder)
--         end
--       end
--     end
--   end,
--   group = tablisttrack,
-- })
