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

  # fzf shell integration (generates ~/.fzf.zsh if brew-installed).
  # Skip when ~/.fzf.zsh exists — it's a repo symlink and the installer
  # would rewrite the repo file through it.
  if [[ ! -e $HOME/.fzf.zsh && -x "$(brew --prefix)/opt/fzf/install" ]]; then
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

  # Alacritty themes — large theme collection consumed by `theme` picker
  if [[ -d $HOME/.config/alacritty/themes/.git ]]; then
    git -C "$HOME/.config/alacritty/themes" pull --ff-only --quiet \
      || warn "alacritty-theme pull failed (offline?)"
  else
    info "Cloning alacritty-theme collection"
    git clone --depth=1 https://github.com/alacritty/alacritty-theme "$HOME/.config/alacritty/themes"
  fi

  # nock — pinned command palette storage
  mkdir -p "$HOME/.config/nock/sessions"
}

# ─── Symlink config files ───────────────────────────────────────────
link_configs() {
  info "Symlinking dotfiles"
  link "zsh/.zshrc"                          "$HOME/.zshrc"
  link "zsh/.zshenv"                         "$HOME/.zshenv"
  link "oh-my-posh/zen.toml"                 "$HOME/.config/oh-my-posh/zen.toml"
  link "tmux/.tmux.conf"                     "$HOME/.tmux.conf"
  link "alacritty/alacritty.toml"            "$HOME/.config/alacritty/alacritty.toml"
  link "alacritty/catppuccin-macchiato.toml" "$HOME/.config/alacritty/catppuccin-macchiato.toml"
  link "fzf/.fzf.zsh"                        "$HOME/.fzf.zsh"
  link "bat/config"                          "$HOME/.config/bat/config"
  link "ripgrep/config"                      "$HOME/.config/ripgrep/config"
  link "lazygit/config.yml"                  "$HOME/.config/lazygit/config.yml"
  link "nvim"                                "$HOME/.config/nvim"
  link "kitty/kitty.conf"                    "$HOME/.config/kitty/kitty.conf"
  link "foot/foot.ini"                       "$HOME/.config/foot/foot.ini"
  link "elio/theme.toml"                     "$HOME/.config/elio/theme.toml"
}

# ─── Symlink user-facing scripts into ~/.local/bin ───────────────────
# Reachable from popups, scripts, and non-interactive shells — not just
# via zshrc aliases (see the May-27 lesson in the zsh configs).
link_bins() {
  info "Symlinking user-facing scripts to ~/.local/bin"
  link "scripts/set-theme.sh"        "$HOME/.local/bin/set-theme"
  link "scripts/alacritty-theme.sh"  "$HOME/.local/bin/alacritty-theme"
  link "scripts/nock.sh"             "$HOME/.local/bin/nock"
  link "scripts/doctor.sh"           "$HOME/.local/bin/dotfiles-doctor"
  link "scripts/tmux-sessionizer.sh" "$HOME/.local/bin/tmux-sessionizer"
}

# ─── Install tmux plugins non-interactively ─────────────────────────
install_tmux_plugins() {
  local tpm_bin="$HOME/.tmux/plugins/tpm/bin/install_plugins"
  [[ -x $tpm_bin ]] || { warn "tpm not found, skipping plugin install"; return; }
  info "Installing tmux plugins"
  "$tpm_bin" >/dev/null 2>&1 && ok "tmux plugins installed" || warn "tpm install_plugins failed"
}

# ─── Set zsh as login shell ─────────────────────────────────────────
set_login_shell() {
  local zsh_path
  # Any zsh counts — don't chsh from /usr/bin/zsh to a brew zsh on every run
  if [[ "$(basename "${SHELL:-}")" == zsh ]]; then
    ok "login shell already zsh ($SHELL)"
    return
  fi
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
link_bins
install_tmux_plugins   # after link_configs — needs ~/.tmux.conf in place
set_login_shell

cat <<EOF

$(printf '\033[1;32m✓ Done!\033[0m')

Next steps:
  1. Open a new terminal (fresh zsh session).
  2. Zinit downloads plugins on first launch (~30s).
  3. oh-my-posh loads ~/.config/oh-my-posh/zen.toml automatically.

Run 'dotfiles-doctor' any time to verify the setup.

EOF
