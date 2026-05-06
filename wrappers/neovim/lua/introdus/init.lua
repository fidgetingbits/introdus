-- birdeevim trick: https://github.com/BirdeeHub/birdeevim/blob/fbf665/init.lua
--
-- NOTE: `local MP = ...` stores the module path passed by require() (eg
--  "introdus.ui") because in lua ... accesses arguments. Then
--  MP:relpath("nixInfo") can be used to reference "introdus.nixInfo", which
--  eases refactoring when changing module paths.

local MP = ...

string.relpath = function(str, sub, n)
  local result = {}
  n = type(sub) == 'string' and n or sub
  if type(n) == 'number' and n > 0 then
    for match in (str .. '.'):gmatch('(.-)%.') do
      table.insert(result, match)
    end
    while n > 0 do
      table.remove(result)
      n = n - 1
    end
  else
    table.insert(result, str)
  end
  if type(sub) == 'string' then
    table.insert(result, sub)
  end
  return #result == 1 and result[1] or table.concat(result, '.')
end

local path = debug.getinfo(1, 'S').source:gsub('^@', '')
local dir = vim.fn.fnamemodify(path, ':h:h:h')
vim.opt.rtp:prepend(dir .. '/snippets/')
vim.opt.rtp:prepend(dir .. '/snippets/vscode')
vim.opt.packpath:prepend(dir)
local introdus_after = dir .. '/after'
if vim.fn.isdirectory(introdus_after) == 1 then
  vim.opt.rtp:append(introdus_after)
end

vim.loader.enable() -- byte code caching

require(MP:relpath('nixinfo')) -- setup nixInfo and lze

-- NOTE: neovim flakes that extend from introdus will include more plugins.
--  Also see auto-loaded files in ./../plugin/ for options, keymaps, etc.
nixInfo.lze.load({
  {
    import = MP:relpath('completion'),
    category = 'completion',
  },
  {
    import = MP:relpath('editing'),
    category = 'editing',
  },
  {
    import = MP:relpath('format'),
    category = 'format',
  },
  {
    import = MP:relpath('lsp'),
    category = 'lsp',
    enabled = nixInfo(false, 'settings', 'devMode'),
  },
  {
    import = MP:relpath('markdown'),
    category = 'markdown',
  },
  {
    import = MP:relpath('search'),
    category = 'search',
  },
  {
    import = MP:relpath('ui'),
    category = 'ui',
  },
})
