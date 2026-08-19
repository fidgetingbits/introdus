return {
  -- Defaults: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/clangd.lua
  {
    'clangd',
    lsp = {
      cmd = { 'clangd', '--background-index', '--clang-tidy' },
      -- Some C projects are quite simple, and the default isn't aggressive enough
      -- so to prevent having to always drop .clangd into a project folder. Also
      -- if you have something like .clang-format in your $HOME it may be found
      -- before a .git/ folder. So overwrite the root_dir to be a little less dumb
      root_dir = function(bufnr, on_dir)
        local primary_root_markers = {
          '.clangd',
          '.clang-tidy',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac', -- AutoTools
          'configure', -- Simple configure script
        }
        -- Deprioritize .clang-format since it might be in $HOME
        local secondary_root_markers = {
          '.git',
          '.clang-format',
        }
        -- FIXME: See https://github.com/Martins3/My-Linux-Config/blob/9b6ebd12efa060e70bfcfa6b2b195421c6cd1556/nvim/lua/usr/lsp_roots.lua
        -- for some extra ways we could detect other folders like linux kernel, with combination of files, etc
        -- Example we probably also want like { COPYRIGHT, Makefile, configure } to flag a root for instance
        on_dir(vim.fs.root(bufnr, { primary_root_markers, secondary_root_markers }))
      end,
    },
  },
}
