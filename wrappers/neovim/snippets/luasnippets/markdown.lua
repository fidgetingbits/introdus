---@diagnostic disable: undefined-global

return {
  -- Zola Page Frontmatter
  -- Example:
  --
  -- +++
  -- title = "Page title"
  -- date = 2026-06-09
  -- draft = true
  --
  -- [taxonomies]
  -- categories = ["research"]
  -- tags = ["nix"]
  --
  -- [extra]
  -- toc = true
  -- +++
  s({ trig = 'fm', desc = 'Insert Basic Zola Page Frontmatter' }, {
    t({ '+++', '' }),
    t({ 'title = "' }),
    i(1, 'Page Title'),
    t({ '"', '' }),
    t({ 'date = ' }),
    i(2, os.date('%Y-%m-%d')),
    t({ '', 'draft = ' }),
    i(3, 'true'),
    t({ '', '', '[taxonomies]', '' }),
    t({ 'categories = [' }),
    i(4, '"programming"'),
    t({ ']', '' }),
    t({ 'tags = [' }),
    i(5, '"nix"'),
    t({ ']', '' }),
    t({ '', '[extra]', '' }),
    t({ 'toc = ' }),
    i(6, 'true'),
    t({ '', '+++' }),
    i(0),
  }),
}
