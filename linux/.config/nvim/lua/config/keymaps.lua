-- Personal keymaps. LazyVim already provides a large default set:
-- https://www.lazyvim.org/keymaps
-- Add only genuinely new bindings here.

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>W", "<cmd>wall<cr>", { desc = "Save all buffers" })
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
