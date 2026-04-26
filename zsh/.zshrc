# Powerlevel10k instant prompt (must be near the top, before anything prints)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
zstyle ':completion:*:descriptions' format '%F{#8aadf4}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{#ed8796}no matches%f'
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
# Theme
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting

# Replay shell completions
autoload -Uz compinit && compinit
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

# ─── Tool initialization (all optional — skipped if not installed) ───
# Homebrew — detects Linux, macOS Apple Silicon, macOS Intel
for brew_path in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x $brew_path ]] && eval "$($brew_path shellenv)" && break
done

# Suppress conda's (env) prefix — p10k renders its own conda segment
export CONDA_CHANGEPS1=false

# Conda — auto-detect common install locations
for conda_path in "$HOME/anaconda3" "$HOME/miniconda3" "$HOME/miniforge3" /opt/anaconda3 /opt/homebrew/anaconda3; do
  if [[ -x "$conda_path/bin/conda" ]]; then
    __conda_setup="$("$conda_path/bin/conda" shell.zsh hook 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
      eval "$__conda_setup"
    elif [[ -f "$conda_path/etc/profile.d/conda.sh" ]]; then
      . "$conda_path/etc/profile.d/conda.sh"
    else
      export PATH="$conda_path/bin:$PATH"
    fi
    unset __conda_setup
    break
  fi
done

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# fzf — Catppuccin Macchiato colors (applies to fzf-tab too)
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
  --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
  --preview 'bat --style=numbers --color=always --line-range :500 {}' \
  --preview-window right:50%:wrap"

# Ctrl+R history search — show the command nicely, not a file preview
export FZF_CTRL_R_OPTS="
  --preview 'echo {} | bat --color=always --language=bash --style=plain --paging=never'
  --preview-window 'down:5:wrap:hidden'
  --bind 'ctrl-/:toggle-preview'
  --header 'Ctrl+/ to toggle preview'"

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Cargo
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Omarchy layout (optional per-user overlay)
[[ -f "$HOME/code/opensource/terminal-configs/omarchy-shell.sh" ]] && \
  source "$HOME/code/opensource/terminal-configs/omarchy-shell.sh"

# ─── PATH ────────────────────────────────────────────────────────────
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ─── Powerlevel10k config ────────────────────────────────────────────
# Run `p10k configure` to customize, produces ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ─── Custom p10k additions ───────────────────────────────────────────
[[ ! -f ~/.p10k-custom.zsh ]] || source ~/.p10k-custom.zsh

# --- redthread / go ---
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"
alias rtdev='( cd "$HOME/code/personal/redthread" && go run ./cmd/redthread )'
