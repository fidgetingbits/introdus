vim.filetype.add({
  filename = {
    ['zshrc'] = 'zsh',
    ['zshenv'] = 'zsh',
    ['sieve'] = 'sieve',
  },
  pattern = {
    ['env.*'] = 'sh',
    ['.*zshrc'] = 'zsh',
    ['.*zsh'] = 'zsh',
    ['.*zsh.theme'] = 'zsh',
  },
})
