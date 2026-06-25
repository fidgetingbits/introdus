local common_languages = {
  a = 'asm',
  b = 'bash',
  c = 'cpp',
  g = 'go',
  h = 'html',
  j = 'json',
  l = 'lua',
  p = 'python',
  r = 'rust',
  t = 'typescript',
  y = 'yaml',
  z = 'zsh',
}
vim.b.minisurround_config = {
  custom_surroundings = {
    -- turns foo into [foo](<clipboard url>)
    l = {
      output = function()
        local url = vim.fn.getreg('+'):gsub('%s+', '')
        return { left = '[', right = '](' .. url .. ')' }
      end,
    },
    -- turns foo into [foo]()
    L = {
      output = function()
        return { left = '[', right = ']()' }
      end,
    },
    -- https://github.com/nvim-mini/mini.nvim/discussions/462
    -- turns foo into:
    -- ```
    -- foo
    -- ```
    c = {
      output = function()
        return { left = '```\n', right = '\n```\n' }
      end,
    },

    -- turns foo into a codeblock with the specific lang:
    -- ```lua
    -- foo
    -- ```
    C = {
      output = function()
        local input = vim.fn.input('Lang (e.g. r, lua): ')
        input = vim.trim(input)
        if input == '' then
          return { left = '```\n', right = '\n```\n' }
        end

        local final_lang = common_languages[input] or input
        return { left = '```' .. final_lang .. '\n', right = '\n```\n' }
      end,
    },
  },
}
