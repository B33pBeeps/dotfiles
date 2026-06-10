#!/usr/bin/env bash
# dotfiles doctor — verify symlinks, tools, theme consistency, leftovers,
# non-interactive shell health, and zsh startup time.
# Usage: dotfiles-doctor [bench]
set -u

DOTFILES="$HOME/code/personal/dotfiles"
FAILED=0

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m ✗\033[0m %s\n' "$*"; FAILED=1; }

check_links() {
  info "Symlinks (parsed from install.sh)"
  local _ src dst
  while read -r _ src dst; do
    src="${src//\"/}"; dst="${dst//\"/}"; dst="${dst/\$HOME/$HOME}"
    if [[ -L $dst && $(readlink "$dst") == "$DOTFILES/$src" ]]; then
      ok "$dst"
    else
      fail "$dst → expected link to $DOTFILES/$src"
    fi
    [[ -e "${dst}.bak" || -L "${dst}.bak" ]] && warn "leftover backup: ${dst}.bak (rm it once the link is confirmed)"
  done < <(grep -E '^\s+(\[\[.*\]\] && )?link "' "$DOTFILES/install.sh" | sed 's/.*link /link /')
}

check_tools() {
  info "Required tools (parsed from install.sh brew_pkgs)"
  local pkgs pkg bin
  pkgs=$(sed -n 's/.*brew_pkgs=(\(.*\)).*/\1/p' "$DOTFILES/install.sh")
  for pkg in $pkgs playerctl hyperfine; do
    case $pkg in neovim) bin=nvim ;; ripgrep) bin=rg ;; *) bin=$pkg ;; esac
    if command -v "$bin" >/dev/null || { [[ $bin == bat ]] && command -v batcat >/dev/null; } \
                                    || { [[ $bin == fd ]] && command -v fdfind >/dev/null; }; then
      ok "$bin"
    elif [[ $pkg == hyperfine ]]; then
      warn "$bin missing (bench falls back to time)"
    else
      fail "$bin missing"
    fi
  done
  [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git" ]] && ok "zinit" || fail "zinit missing"
  [[ -d $HOME/.tmux/plugins/tpm ]] && ok "tpm" || fail "tpm missing"
}

check_theme() {
  info "Theme consistency"
  local state="" bat_want import_want
  [[ -f $HOME/.config/dotfiles-theme ]] && state=$(<"$HOME/.config/dotfiles-theme")
  case $state in
    catppuccin) bat_want='Catppuccin-macchiato'; import_want='catppuccin-macchiato.toml' ;;
    gruvbox)    bat_want='gruvbox-dark';         import_want='gruvbox_material.toml' ;;
    *) fail "~/.config/dotfiles-theme missing/unknown: '$state' (run set-theme)"; return ;;
  esac
  ok "state: $state"
  grep -q -- "--theme=\"$bat_want\"" "$DOTFILES/bat/config" \
    && ok "bat theme matches" || fail "bat/config != $bat_want"
  grep -q "$import_want" "$HOME/.config/alacritty/alacritty.toml" \
    && ok "alacritty import matches" \
    || warn "alacritty import diverges (fine if you picked one via the 'theme' live picker)"
}

check_shells() {
  info "Non-interactive shell health (the May-27 breakage class)"
  local b
  for b in node npm; do
    zsh -c "command -v $b" >/dev/null 2>&1 \
      && ok "$b visible to non-interactive zsh" \
      || fail "$b NOT visible to non-interactive zsh — agents/npm scripts/tmux run-shell will break"
    /bin/sh -c "command -v $b" >/dev/null 2>&1 \
      && ok "$b visible to /bin/sh" || warn "$b not visible to /bin/sh"
  done
  grep -q 'profile-path.sh' "$HOME/.profile" 2>/dev/null \
    && ok "~/.profile sources shell/profile-path.sh" \
    || warn "~/.profile missing the dotfiles block (bash/sh login contexts lose node)"
  [[ -s $HOME/.cache/zsh/nvm-default-bin ]] \
    && ok "nvm default-bin cache: $(<"$HOME/.cache/zsh/nvm-default-bin")" \
    || warn "nvm cache missing — first interactive zsh will regenerate it"
  local extra
  extra=$(find "$HOME" -maxdepth 1 -name '.zcompdump.*' 2>/dev/null)
  [[ -n $extra ]] && warn "stale completion dumps: $extra" || ok "no stale zcompdump copies"
}

bench() {
  local budget="${DOTFILES_ZSH_BUDGET_MS:-150}" mean
  info "zsh startup benchmark (budget: ${budget}ms)"
  if command -v hyperfine >/dev/null && command -v jq >/dev/null; then
    local tmp; tmp=$(mktemp)
    hyperfine --warmup 2 --runs 5 'zsh -i -c exit' --export-json "$tmp" >/dev/null 2>&1
    mean=$(jq -r '.results[0].mean * 1000 | floor' "$tmp"); rm -f "$tmp"
  else
    local t0 t1; t0=$(date +%s%N); zsh -i -c exit; t1=$(date +%s%N)
    mean=$(( (t1 - t0) / 1000000 ))
  fi
  if (( mean <= budget )); then ok "startup ${mean}ms (budget ${budget}ms)"
  else warn "startup ${mean}ms exceeds ${budget}ms budget"; fi
}

if [[ "${1:-}" == bench ]]; then bench; exit 0; fi
check_links; check_tools; check_theme; check_shells; bench
echo
if (( FAILED )); then printf '\033[1;31m✗ issues found\033[0m\n'; exit 1
else printf '\033[1;32m✓ all checks passed\033[0m\n'; fi
