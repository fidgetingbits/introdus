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
  },
}
