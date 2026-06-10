-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Hot-reload colorscheme when set-theme.sh updates ~/.config/dotfiles-theme.
-- Fires on focus return (tmux has focus-events on) and on fg after ctrl-z.
local theme_file = vim.fn.expand("~/.config/dotfiles-theme")
local schemes = { catppuccin = "catppuccin-macchiato", gruvbox = "gruvbox-material" }
vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  group = vim.api.nvim_create_augroup("dotfiles_theme_reload", { clear = true }),
  callback = function()
    if vim.fn.filereadable(theme_file) ~= 1 then
      return
    end
    local name = vim.trim(vim.fn.readfile(theme_file)[1] or "")
    if schemes[name] and vim.g.dotfiles_theme ~= name then
      vim.g.dotfiles_theme = name
      vim.cmd.colorscheme(schemes[name])
    end
  end,
})
