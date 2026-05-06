vim.filetype.add({
  filename = {
    ['zshrc'] = 'zsh',
    ['zshenv'] = 'zsh',
  },
  pattern = {
    ['env.*'] = 'sh',
    ['.*zshrc'] = 'zsh',
    ['.*zsh'] = 'zsh',
    ['.*zsh.theme'] = 'zsh',
  },
})
