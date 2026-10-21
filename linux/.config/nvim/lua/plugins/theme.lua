-- DMS-synced theme with Catppuccin as an offline fallback.
-- DankMaterialShell writes ~/.config/nvim/colors/dms.lua and the matching
-- lualine theme whenever the wallpaper / DMS color scheme changes.
return {
  {
    "AvengeMedia/base46",
    lazy = true,
    opts = {},
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      term_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = { bold = true },
        types = { italic = true },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local dms = vim.fs.joinpath(vim.fn.stdpath("config"), "colors", "dms.lua")
        if vim.uv.fs_stat(dms) then
          vim.cmd.colorscheme("dms")
        else
          vim.cmd.colorscheme("catppuccin")
        end
      end,
    },
  },
}
