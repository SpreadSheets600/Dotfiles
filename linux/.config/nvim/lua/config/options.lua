-- Options are automatically loaded before lazy.nvim startup.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Only put personal overrides here.

-- Use the system clipboard (Wayland: wl-clipboard is installed).
vim.opt.clipboard = "unnamedplus"

-- Comfortable editing.
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.colorcolumn = "100"
vim.opt.cursorline = true

-- Keep undo history between sessions (LazyVim enables this by default, kept explicit).
vim.opt.undofile = true

-- Show a subtle column at 100 chars only in code buffers.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("personal_options", { clear = true }),
  callback = function()
    vim.opt_local.colorcolumn = "100"
  end,
})
