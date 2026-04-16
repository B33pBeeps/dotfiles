#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  backup  $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -s "$src" "$dst"
  echo "  linked  $dst → $src"
}

echo "Installing dotfiles from $DOTFILES"
echo ""

link "zsh/.zshrc"                          "$HOME/.zshrc"
link "tmux/.tmux.conf"                     "$HOME/.tmux.conf"
link "alacritty/alacritty.toml"            "$HOME/.config/alacritty/alacritty.toml"
link "alacritty/catppuccin-macchiato.toml" "$HOME/.config/alacritty/catppuccin-macchiato.toml"
link "fzf/.fzf.zsh"                        "$HOME/.fzf.zsh"
link "bat/config"                          "$HOME/.config/bat/config"
link "lazygit/config.yml"                  "$HOME/.config/lazygit/config.yml"
link "nvim"                                "$HOME/.config/nvim"

echo ""
echo "Done! Restart your terminal or run: exec zsh"
