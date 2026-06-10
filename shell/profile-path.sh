# Sourced from ~/.profile — node + conda PATH for non-zsh login contexts
# (bash -l, sh -l, GUI sessions) that never read ~/.zshenv. POSIX sh only.

if [ -r "$HOME/.cache/zsh/nvm-default-bin" ]; then
  __nvm_bin="$(cat "$HOME/.cache/zsh/nvm-default-bin")"
  case ":$PATH:" in
    *":$__nvm_bin:"*) ;;                 # already present
    *"/.nvm/versions/node/"*) ;;         # parent already chose a node — inherit
    *) [ -d "$__nvm_bin" ] && PATH="$__nvm_bin:$PATH" ;;
  esac
  unset __nvm_bin
fi

case ":$PATH:" in
  *"/anaconda3/condabin:"*) ;;
  *) [ -d "$HOME/anaconda3/condabin" ] && PATH="$PATH:$HOME/anaconda3/condabin" ;;
esac
export PATH
