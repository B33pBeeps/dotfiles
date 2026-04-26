#!/usr/bin/env bash
# Cross-platform dotfiles installer (Linux / macOS / WSL).
# Installs missing dependencies via the system package manager, symlinks all
# config files, and ensures zsh is the login shell.

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ─── Helpers ─────────────────────────────────────────────────────────
info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m !\033[0m %s\n' "$*"; }

link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
    ok "already linked: $dst"
    return
  fi
  if [[ -e "$dst" ]] || [[ -L "$dst" ]]; then
    warn "backup $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -s "$src" "$dst"
  ok "linked $dst → $src"
}

have() { command -v "$1" >/dev/null 2>&1; }

# ─── Platform detection ─────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux*)   PLATFORM=linux ;;
  Darwin*)  PLATFORM=macos ;;
  *)        PLATFORM=unknown ;;
esac
info "Platform: $PLATFORM"

# ─── Install dependencies ───────────────────────────────────────────
install_deps() {
  info "Ensuring dependencies are installed"

  # Homebrew — install if missing (works on macOS and Linux)
  if ! have brew; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Shell env for this script
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  # Core tools via brew (works on all platforms we support)
  local brew_pkgs=(zsh tmux eza fzf zoxide bat ripgrep fd lazygit btop gh neovim glow jq git oh-my-posh)
  for pkg in "${brew_pkgs[@]}"; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
      info "brew install $pkg"
      brew install "$pkg" || warn "failed to install $pkg"
    fi
  done

  # Platform-specific extras
  if [[ $PLATFORM == linux ]] && have apt-get; then
    # playerctl is a Linux-only media controller (brew doesn't ship it for Linux)
    if ! have playerctl; then
      info "apt install playerctl"
      sudo apt-get install -y playerctl || warn "failed to install playerctl"
    fi
  fi

  # fzf shell integration (generates ~/.fzf.zsh if brew-installed)
  if [[ -x "$(brew --prefix)/opt/fzf/install" ]]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null 2>&1 || true
  fi

  # Zinit
  local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ ! -d $zinit_home/.git ]]; then
    info "Installing zinit"
    mkdir -p "$(dirname "$zinit_home")"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
  fi

  # tmux plugin manager
  if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

# ─── Symlink config files ───────────────────────────────────────────
link_configs() {
  info "Symlinking dotfiles"
  link "zsh/.zshrc"                          "$HOME/.zshrc"
  link "oh-my-posh/zen.toml"                 "$HOME/.config/oh-my-posh/zen.toml"
  link "tmux/.tmux.conf"                     "$HOME/.tmux.conf"
  link "alacritty/alacritty.toml"            "$HOME/.config/alacritty/alacritty.toml"
  link "alacritty/catppuccin-macchiato.toml" "$HOME/.config/alacritty/catppuccin-macchiato.toml"
  link "fzf/.fzf.zsh"                        "$HOME/.fzf.zsh"
  link "bat/config"                          "$HOME/.config/bat/config"
  link "lazygit/config.yml"                  "$HOME/.config/lazygit/config.yml"
  link "nvim"                                "$HOME/.config/nvim"
}

# ─── Set zsh as login shell ─────────────────────────────────────────
set_login_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)" || { warn "zsh not found, skipping chsh"; return; }

  # Add to /etc/shells if missing (chsh requires the path to be listed there)
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    info "adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "$SHELL" != "$zsh_path" ]]; then
    info "changing login shell to $zsh_path"
    chsh -s "$zsh_path" || warn "chsh failed — run it manually"
  else
    ok "login shell already zsh"
  fi
}

# ─── Run ────────────────────────────────────────────────────────────
install_deps
link_configs
set_login_shell

cat <<EOF

$(printf '\033[1;32m✓ Done!\033[0m')

Next steps:
  1. Open a new terminal (fresh zsh session).
  2. Zinit downloads plugins on first launch (~30s).
  3. oh-my-posh loads ~/.config/oh-my-posh/zen.toml automatically.
  4. Inside tmux: Ctrl+s I to install tmux plugins.

EOF
