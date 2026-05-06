local MP = ...

return {
  { import = MP:relpath('markdown-preview') },
  { import = MP:relpath('render-markdown') },
}
