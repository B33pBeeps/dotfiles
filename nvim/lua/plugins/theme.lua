-- Theme that follows the dotfiles set-theme state.
-- Reads ~/.config/dotfiles-theme (one of: catppuccin | gruvbox)
local theme_file = vim.fn.expand("~/.config/dotfiles-theme")
local theme = "catppuccin"
if vim.fn.filereadable(theme_file) == 1 then
  theme = vim.fn.trim(vim.fn.readfile(theme_file)[1] or "catppuccin")
end

local colorscheme = (theme == "gruvbox") and "gruvbox-material" or "catppuccin-macchiato"

-- Tracked by the hot-reload autocmd (see config/autocmds.lua)
vim.g.dotfiles_theme = theme

return {
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = colorscheme },
  },
}
