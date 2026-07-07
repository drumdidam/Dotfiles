-- Emacs-style compile-mode: run compile/build commands in a buffer and
-- jump between errors.  https://github.com/ej-shafran/compile-mode.nvim
return {
  'ej-shafran/compile-mode.nvim',
  version = '^5.0.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- Optional: coloring of ANSI escape codes in the compilation output.
    { 'm00qek/baleia.nvim', tag = 'v1.3.0' },
  },
  -- Load lazily on the commands and keymaps below.
  cmd = { 'Compile', 'Recompile', 'NextError', 'PrevError' },
  keys = {
    { '<leader>cc', '<cmd>Compile<cr>', desc = '[C]ompile' },
    { '<leader>cr', '<cmd>Recompile<cr>', desc = '[C]ompile: [R]ecompile' },
    { '<leader>cn', '<cmd>NextError<cr>', desc = '[C]ompile: [N]ext error' },
    { '<leader>cp', '<cmd>PrevError<cr>', desc = '[C]ompile: [P]revious error' },
  },
  config = function()
    ---@type CompileModeOpts
    vim.g.compile_mode = {
      -- Default text shown at the compile prompt.
      default_command = 'make -k ',
      -- Enable ANSI color parsing via baleia.nvim (dependency above).
      baleia_setup = true,
      -- Jump straight to the first error when compilation finishes.
      auto_jump_to_first_error = true,
    }
  end,
}
