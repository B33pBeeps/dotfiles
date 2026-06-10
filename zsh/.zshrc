# ─── History ─────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# ─── Directory navigation ────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# ─── Key bindings ────────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ─── Completion styling ──────────────────────────────────────────────
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#7daea3}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{#ea6962}no matches%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' complete-options true

# fzf-tab preview for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 --color=always $realpath'

# ─── Zinit ───────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# ─── Plugins ─────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting

# Completion: full rebuild (with security audit) at most once a day, else the
# fast -C path (~13ms). compinit doesn't bump the dump mtime itself — touch it.
autoload -Uz compinit
() {
  setopt localoptions extendedglob
  if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit && touch ~/.zcompdump
  else
    compinit -C
  fi
}
zinit cdreplay -q

# ─── Aliases ─────────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias l='eza --icons --group-directories-first'
alias lt='eza -T --icons --level=2'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias md='mkdir -p'
alias dualagent='tmux new-session -d "claude --dangerously-skip-permissions" \; split-window -v "codex --yolo" \; select-layout even-vertical \; set-window-option synchronize-panes on \; bind-key -n C-w setw synchronize-panes \; attach'
alias rt-update='GOPROXY=direct go install github.com/B33pBeeps/redthread/cmd/redthread@main'
alias slides='$HOME/code/personal/dotfiles/scripts/slides-auto.sh'
alias theme="$HOME/code/personal/dotfiles/scripts/alacritty-theme.sh"
alias set-theme="$HOME/code/personal/dotfiles/scripts/set-theme.sh"
alias zbench="hyperfine --warmup 3 --runs 10 'zsh -i -c exit'"

# PATH note: ~/bin, ~/.local/bin, ~/.cargo/bin and the cached nvm node bin are
# prepended in ~/.zshenv so they exist for EVERY zsh, not just interactive ones.

# ─── Tool initialization (all optional — skipped if not installed) ───
# Homebrew — static for Linuxbrew (mirrors `brew shellenv` output exactly,
# saves ~17ms/start); eval fallback for the macOS paths.
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
  export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
  fpath[1,0]="/home/linuxbrew/.linuxbrew/share/zsh/site-functions"
  export FPATH
  path=(/home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin $path)
  [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
  export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
else
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $brew_path ]] && eval "$($brew_path shellenv)" && break
  done
fi

# Suppress conda's (env) prefix — oh-my-posh renders its own
export CONDA_CHANGEPS1=false

# Conda — pure-shell dispatcher + cached base activation (no python at startup).
# Same end state as `eval "$(conda shell.zsh hook)"` (~106ms): conda.sh defines
# the conda() dispatcher (<1ms, handles activate/deactivate), and the base
# activation is replayed from a cache that invalidates when conda changes.
# Reset: rm ~/.cache/zsh/conda-base-activate.zsh
for conda_root in "$HOME/anaconda3" "$HOME/miniconda3" "$HOME/miniforge3" /opt/anaconda3 /opt/homebrew/anaconda3; do
  [[ -x "$conda_root/bin/conda" ]] || continue
  . "$conda_root/etc/profile.d/conda.sh"

  if ! grep -qsE '^[[:space:]]*auto_activate_base:[[:space:]]*false' ~/.condarc; then
    __conda_cache="$HOME/.cache/zsh/conda-base-activate.zsh"
    if [[ ! -s $__conda_cache \
          || "$conda_root/bin/conda" -nt $__conda_cache \
          || "$conda_root/conda-meta/history" -nt $__conda_cache \
          || "$conda_root/etc/conda/activate.d" -nt $__conda_cache ]]; then
      mkdir -p "$HOME/.cache/zsh"
      __conda_tmp="$(mktemp "$HOME/.cache/zsh/conda-base.XXXXXX")"
      if env -i HOME="$HOME" CONDA_CHANGEPS1=false PATH=/usr/bin:/bin \
             "$conda_root/bin/conda" shell.zsh activate base 2>/dev/null \
           | sed "s|^export PATH=.*|path=(\"$conda_root/bin\" \$path)|" >| "$__conda_tmp" \
         && grep -q CONDA_PREFIX "$__conda_tmp"; then
        mv -f "$__conda_tmp" "$__conda_cache"
      else
        rm -f "$__conda_tmp"      # never install an empty/garbage cache
      fi
      unset __conda_tmp
    fi
    if [[ -z $CONDA_SHLVL || $CONDA_SHLVL == 0 ]]; then
      [[ -s $__conda_cache ]] && . "$__conda_cache"
    elif [[ $CONDA_DEFAULT_ENV != base ]]; then
      conda activate base   # nested shell in a non-base env: match old reset-to-base
    fi
    unset __conda_cache
  fi
  break
done
unset conda_root

# NVM — PATH comes from the ~/.zshenv cache; full nvm.sh loads on first `nvm` call.
__nvm_refresh_cache() {
  local cache="$HOME/.cache/zsh/nvm-default-bin" v tmp
  mkdir -p "${cache:h}"
  if (( $+functions[nvm_version] )); then
    v="$(nvm_version default)"
  else
    v="$(zsh -c ". \"$NVM_DIR/nvm.sh\" --no-use >/dev/null 2>&1; nvm_version default" 2>/dev/null)"
  fi
  if [[ -n $v && $v != "N/A" && -d "$NVM_DIR/versions/node/$v/bin" ]]; then
    tmp="$(mktemp "${cache}.XXXXXX")" \
      && print -r -- "$NVM_DIR/versions/node/$v/bin" >| "$tmp" \
      && mv -f "$tmp" "$cache"
  fi
}

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # regenerate cache when the default alias or installed set changed (rare, ~130ms)
  if [[ ! -s "$HOME/.cache/zsh/nvm-default-bin" \
        || "$NVM_DIR/alias/default" -nt "$HOME/.cache/zsh/nvm-default-bin" \
        || "$NVM_DIR/versions/node" -nt "$HOME/.cache/zsh/nvm-default-bin" ]]; then
    __nvm_refresh_cache
  fi
  # Interactive shells always reset to the default node (parity with nvm.sh
  # auto-use) and keep it ahead of anaconda3/bin from the conda block above.
  if [[ -r "$HOME/.cache/zsh/nvm-default-bin" ]]; then
    NVM_BIN="$(<"$HOME/.cache/zsh/nvm-default-bin")"
    if [[ -d $NVM_BIN ]]; then
      export NVM_BIN
      export NVM_INC="${NVM_BIN%/bin}/include/node"
      path=("$NVM_BIN" ${path:#$NVM_DIR/versions/node/*/bin})
      typeset -U path
    fi
  fi
  nvm() {
    unfunction nvm
    . "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
    nvm "$@"
    local rc=$?
    __nvm_refresh_cache       # nvm install/alias/use keep the cache current
    return $rc
  }
fi

# User bins outrank nvm/conda/brew (same precedence as the old config's late
# PATH block); typeset -U drops the earlier duplicates from ~/.zshenv.
path=("$HOME/bin"(N) "$HOME/.local/bin"(N) "$HOME/.cargo/bin"(N) $path)
typeset -U path

# fzf — Catppuccin Macchiato colors (applies to fzf-tab too)
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#32302f,bg:#282828,spinner:#ddc7a1,hl:#ea6962 \
  --color=fg:#d4be98,header:#ea6962,info:#d3869b,pointer:#ddc7a1 \
  --color=marker:#ddc7a1,fg+:#d4be98,prompt:#d3869b,hl+:#ea6962 \
  --preview 'bat --style=numbers --color=always --line-range :500 {}' \
  --preview-window right:50%:wrap"

# Ctrl+R history search — show the command nicely, not a file preview
export FZF_CTRL_R_OPTS="
  --preview 'echo {} | bat --color=always --language=bash --style=plain --paging=never'
  --preview-window 'down:5:wrap:hidden'
  --bind 'ctrl-/:toggle-preview'
  --header 'Ctrl+/ to toggle preview'"

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ripgrep — use the tuned config (smart-case, hidden, sane ignores)
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Cargo — ~/.cargo/bin is prepended in ~/.zshenv

# Omarchy layout (optional per-user overlay)
[[ -f "$HOME/code/opensource/terminal-configs/omarchy-shell.sh" ]] && \
  source "$HOME/code/opensource/terminal-configs/omarchy-shell.sh"

# ─── oh-my-posh ──────────────────────────────────────────────────────
# Initialize oh-my-posh
command -v oh-my-posh >/dev/null && \
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/zen.toml)"

# --- redthread / go ---
path=("$HOME/.local/go/bin"(N) "$HOME/go/bin"(N) $path)
alias rtdev='( cd "$HOME/code/personal/redthread" && go run ./cmd/redthread )'

# --- Android SDK (only if present) ---
if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  path=("$ANDROID_HOME/platform-tools"(N) "$ANDROID_HOME/emulator"(N) "$ANDROID_HOME/cmdline-tools/latest/bin"(N) $path)
  () {
    local -a ndk=("$ANDROID_HOME"/ndk/*(N/nOn))
    (( $#ndk )) && export NDK_HOME="$ndk[1]"
  }
fi
[[ -d /snap/android-studio/current/jbr ]] && export JAVA_HOME="/snap/android-studio/current/jbr"
