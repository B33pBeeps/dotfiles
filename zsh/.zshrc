# History
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

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Key bindings - emacs mode (familiar arrow key behavior)
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#8aadf4}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{#ed8796}no matches%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' complete-options true

# Colors
autoload -Uz colors && colors

# Git info for prompt
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats       ' %F{#eed49f} (%b%m%F{#eed49f})'
zstyle ':vcs_info:git:*' actionformats ' %F{#eed49f} (%b|%F{#ed8796}%a%f%m%F{#eed49f})'
zstyle ':vcs_info:git+set-message:*' hooks git-status

# Combine staged / unstaged / untracked / ahead / behind into a single misc field
+vi-git-status() {
  local status_out staged="" unstaged="" untracked="" ahead="" behind="" info=""
  status_out=$(git status --porcelain 2>/dev/null)
  [[ -n $status_out ]] && {
    grep -q '^[MADRC]' <<< "$status_out" && staged='%F{#a6da95}+'
    grep -q '^.[MD]'  <<< "$status_out" && unstaged='%F{#f5a97f}!'
    grep -q '^??'     <<< "$status_out" && untracked='%F{#8aadf4}?'
  }
  local a b
  a=$(git rev-list --count @{u}..HEAD 2>/dev/null)
  b=$(git rev-list --count HEAD..@{u} 2>/dev/null)
  [[ -n $a && $a -gt 0 ]] && ahead="%F{#a6da95}↑${a}"
  [[ -n $b && $b -gt 0 ]] && behind="%F{#ed8796}↓${b}"
  info="${staged}${unstaged}${untracked}${ahead}${behind}"
  [[ -n $info ]] && hook_com[misc]=" ${info}"
}

# Project version — cached per git-repo
typeset -gA _prj_ver_cache
_project_version() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  if [[ -n ${_prj_ver_cache[$root]+x} ]]; then
    echo ${_prj_ver_cache[$root]}
    return
  fi

  local ver=""

  # Top-level manifests
  if [[ -f $root/package.json ]]; then
    ver=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' $root/package.json | head -1)
  elif [[ -f $root/pyproject.toml ]]; then
    ver=$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' $root/pyproject.toml | head -1)
  elif [[ -f $root/Cargo.toml ]]; then
    ver=$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' $root/Cargo.toml | head -1)
  elif [[ -f $root/VERSION ]]; then
    ver=$(head -1 $root/VERSION)
  fi

  # Most recent version-bump commit on master (e.g. "1.0.42")
  if [[ -z $ver ]] && git -C $root rev-parse --verify master >/dev/null 2>&1; then
    ver=$(git -C $root log master --pretty=%s 2>/dev/null | grep -m1 -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$')
  fi

  # Sub-manifest fallback
  if [[ -z $ver ]]; then
    local f
    f=$(fd -t f -d 4 -E node_modules --glob "package.json" $root 2>/dev/null | head -1)
    [[ -n $f ]] && ver=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' $f | head -1)
  fi

  _prj_ver_cache[$root]=$ver
  echo $ver
}

_prj_ver=""
_conda_env=""
precmd() {
  vcs_info
  _prj_ver=$(_project_version)
  [[ -n $_prj_ver ]] && _prj_ver=" %F{#c6a0f6} ${_prj_ver}%f"
  if [[ -n $CONDA_DEFAULT_ENV && $CONDA_DEFAULT_ENV != "base" ]]; then
    _conda_env="%F{#f5bde6} ${CONDA_DEFAULT_ENV}%f "
  else
    _conda_env=""
  fi
}
setopt PROMPT_SUBST

# Suppress conda's default (env) prefix — we render our own
export CONDA_CHANGEPS1=false

# Prompt — bold throughout (including typed commands)
PROMPT='${_conda_env}%F{#89b4fa} %~%f${vcs_info_msg_0_}${_prj_ver} %F{#a6e3a1}❯%f '
RPROMPT='%(?.%F{#6e738d}%*%f.%F{#ed8796}✘ %?%f)'

# Aliases
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

# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Conda
__conda_setup="$('/home/juan/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/juan/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/juan/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/juan/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# fzf — Catppuccin Macchiato colors
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
  --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
  --preview 'bat --style=numbers --color=always --line-range :500 {}' \
  --preview-window right:50%:wrap"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide
eval "$(zoxide init zsh)"

# Cargo
. "$HOME/.cargo/env"

# Omarchy layout
source "/home/juan/code/opensource/terminal-configs/omarchy-shell.sh"

# Custom aliases
alias dualagent='tmux new-session -d "claude --dangerously-skip-permissions" \; split-window -v "codex --yolo" \; select-layout even-vertical \; set-window-option synchronize-panes on \; bind-key -n C-w setw synchronize-panes \; attach'

# PATH additions
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Plugins (must be at the end)
source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Catppuccin syntax highlighting colors
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ed8796'
ZSH_HIGHLIGHT_STYLES[command]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[function]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#a6da95,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#8aadf4'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#c6a0f6'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#eed49f'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#eed49f'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#f5bde6'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#f5bde6'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#cad3f5'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#f5a97f'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6e738d'
