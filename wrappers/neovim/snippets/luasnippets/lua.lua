---@diagnostic disable: undefined-global

return {
  s('ignore', {
    t('-- stylua: ignore start'),
    t({ '', '' }),
    f(function(_args, snip)
      return snip.env.TM_SELECTED_TEXT
    end, {}),
    i(0),
    t({ '', '-- stylua: ignore end' }),
  }),
}
