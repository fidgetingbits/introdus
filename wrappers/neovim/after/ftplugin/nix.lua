vim.b.minisurround_config = vim.tbl_deep_extend('force', vim.b.minisurround_config or {}, {
  custom_surroundings = {
    -- Raw strings ''
    r = {
      input = { "''().-()''" },
      output = { left = "''", right = "''" },
    },
    -- Variable expansions
    e = {
      input = { '${().-()}' },
      output = { left = '${', right = '}' },
    },
  },
})

vim.b.miniai_config = vim.tbl_deep_extend('force', vim.b.miniai_config or {}, {
  custom_textobjects = {

    -- Raw strings
    r = { "''().-()''" },
    -- Variable expansions
    e = { '${().-()}' },
  },
})
