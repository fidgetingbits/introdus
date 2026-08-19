-- FIXME: There is some sort of weird delay where some which-key items only
-- show up if you delay keypress ~10s
--
-- https://www.reddit.com/r/neovim/comments/1cx91gu/whichkey_and_miniai_custom_textobjects/
-- https://github.com/nvim-mini/mini.nvim/issues/192
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/mini.lua
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/coding.lua#L174-L176

-- register all text objects with which-key
---@param opts table
local function ai_whichkey(opts)
  local objects = {
    { ' ', desc = 'whitespace' },
    { '"', desc = '" string' },
    { "'", desc = "' string" },
    { '(', desc = '() block' },
    { ')', desc = '() block with ws' },
    { '<', desc = '<> block' },
    { '>', desc = '<> block with ws' },
    { '?', desc = 'user prompt' },
    { 'U', desc = 'use/call without dot' },
    { '[', desc = '[] block' },
    { ']', desc = '[] block with ws' },
    { '_', desc = 'underscore' },
    { '`', desc = '` string' },
    { 'a', desc = 'argument' },
    { 'b', desc = ')]} block' },
    { 'c', desc = 'class' },
    { 'd', desc = 'digit(s)' },
    { 'e', desc = 'CamelCase / snake_case' },
    { 'f', desc = 'function' },
    { 'g', desc = 'entire file' },
    { 'i', desc = 'indent' },
    { 'o', desc = 'block, conditional, loop' },
    { 'q', desc = 'quote `"\'' },
    { 't', desc = 'tag' },
    { 'u', desc = 'use/call' },
    { '{', desc = '{} block' },
    { '}', desc = '{} with ws' },
  }

  ---@type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'al',
    inside_next = 'il',
    around_last = 'ap',
    inside_last = 'ip',
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == 'i' then
        desc = desc:gsub(' with ws', '')
      end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  require('which-key').add(ret, { notify = false })
end

return {
  {
    -- Better in and around targeting that includes treesitter support
    'mini.ai',
    -- event = 'DeferredUIEnter',
    lazy = false,
    after = function(_plugin)
      local ai = require('mini.ai')
      local ai_opts = {
        mappings = {
          around_next = 'an',
          inside_next = 'in',
          around_last = 'ap',
          inside_last = 'ip',
        },
        custom_textobjects = {
              -- stylua: ignore start
              a = ai.gen_spec.treesitter({ a = '@parameter.outer',   i = '@parameter.inner' }),
              c = ai.gen_spec.treesitter({ a = '@class.outer',       i = '@class.inner' }),
              f = ai.gen_spec.treesitter({ a = '@function.outer',    i = '@function.inner' }),
              i = ai.gen_spec.treesitter({ a = '@conditional.outer', i = '@conditional.inner' }),
              l = ai.gen_spec.treesitter({ a = '@loop.outer',        i = '@loop.inner' }),
              n = ai.gen_spec.treesitter({ a = '@assignment.lhs',    i = '@assignment.lhs' }),
              r = ai.gen_spec.treesitter({ a = '@return.outer',      i = '@return.inner' }),
              t = ai.gen_spec.treesitter({ a = '@comment.outer',     i = '@comment.comment' }),
              v = ai.gen_spec.treesitter({ a = '@assignment.rhs',    i = '@assignment.rhs' }),
          -- stylua: ignore end
        },
      }
      ai.setup(ai_opts)
      ai_whichkey(ai_opts)
    end,
  },

  -- NOTE: which-key moved to introdus for ordering, since we load introdus config first,
  -- and mini-ai uses it.
  {
    'which-key.nvim',
    event = 'DeferredUIEnter',
    dep_of = { 'mini.ai' },
    after = function(_)
      require('which-key').setup({
        preset = 'modern',
        delay = 150,
        icons = {
          mappings = true,
          keys = {},
        },
        spec = {
          -- stylua: ignore start
          { "<leader>", mode = { "s" }, hidden = true },
          { '<leader>a',  group = '[a]i' },
          { '<leader>b',  group = '[b]uffer' },
          { '<leader>f',  group = '[f]ind' },
          { '<leader>F',  group = '[F]ormatting' },
          { '<leader>g',  group = '[g]it' },
          { '<leader>i',  group = '[i]nverse value' },
          { '<leader>l',  group = '[l]sp' },
          { '<leader>m',  group = '[m]arks' }, -- Won't show up due to built-in, but is in use
          { '<leader>M',  group = '[M]arkdown' },
          { '<leader>n',  group = '[n]eotree' },
          { '<leader>N',  group = '[N]otifications' },
          { '<leader>o',  group = '[o]bsidian' },
          { '<leader>p',  group = '[p]aste <motion>' },
          { '<leader>u',  group = '[u]ndotree' },
          { '<leader>s',  group = '[s]ubstitute' },
          { '<leader>S',  group = '[S]ession' },
          { '<leader>t',  group = '[t]oggle settings' },
          { '<leader>x',  group = 'quickfi[x] & diagnostics' },
          { '<leader>y',  group = '[y]ank' },
          { '<leader>z',  group = 'folds/zen' },
          { '<leader><leader>', group = 'misc' },
          { "[", group = "prev" },
          { "]", group = "next" },
          -- stylua: ignore end
        },
        triggers = {
          { '<auto>', mode = 'nixsotc' },
          { 'a', mode = { 'o', 'x' } },
          { 'i', mode = { 'o', 'x' } },
          { 'm', mode = { 'o', 'x' } },
        },
      })
    end,
  },
}
