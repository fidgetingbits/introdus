-- Reloads /plugin files for now only
-- NOTE: You can use ":restart" as of nvim 0.12 but it's slow (~15s on this config), so for
-- small changes, it's still better to use this
vim.api.nvim_create_user_command('ReloadConfig', function()
  -- Source init.lua
  config_folder = nixInfo(false, 'settings', 'config_directory')
  -- FIXME:LZE complains on reload, with 'attempted to add <foo> twice' error spam
  -- need to figure out if there is a way to do that
  -- dofile(config_folder .. '/init.lua')

  -- Reload some critical runtime files
  local function source_files(path)
    local files = vim.fn.glob(path, false, true)
    for _, file in ipairs(files) do
      local ok, err = pcall(vim.cmd, 'silent! source ' .. file)
      if not ok then
        print('Error sourcing ' .. file .. ': ' .. err)
      end
      -- print('Loaded ' .. file)
    end
  end
  source_files(config_folder .. '/plugin/**/*.vim')
  source_files(config_folder .. '/plugin/**/*.lua')
  source_files(config_folder .. '/ftplugin/**/*.vim')
  source_files(config_folder .. '/ftplugin/**/*.lua')

  -- Force re-detection of filetype for the current buffer
  vim.cmd('filetype detect')

  print('Configuration reloaded!')
end, {})

vim.api.nvim_create_user_command('Inspect', function(opts)
  local chunk, err = load('return ' .. opts.args)
  if not chunk then
    vim.notify('Error: ' .. err, vim.log.levels.ERROR)
    return
  end

  local success, result = pcall(chunk)
  if not success then
    vim.notify('Error evaluating: ' .. result, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.cmd('vnew')
  vim.api.nvim_win_set_buf(0, buf)

  local lines = vim.split(vim.inspect(result), '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
end, { nargs = 1 })
