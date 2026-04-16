# Setup fzf
# ---------
if [[ ! "$PATH" == */home/juan/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/juan/.fzf/bin"
fi

eval "$(fzf --zsh)"
