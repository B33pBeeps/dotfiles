# ~/.zshenv — sourced by EVERY zsh (interactive, non-interactive, scripts).
# Keep tiny (<1ms): static exports and cached PATH only. No subprocesses.
# This is what keeps node/conda visible to agent-spawned shells, npm scripts,
# and tmux run-shell — fixes that live only in .zshrc don't exist there.

# Ubuntu's /etc/zsh/zshrc runs a redundant global compinit (~17-145ms);
# our .zshrc runs its own.
skip_global_compinit=1

export NVM_DIR="$HOME/.nvm"

# node — cached default-version bin dir (cache maintained by .zshrc / nvm()).
# Guard: if a parent shell already selected a node via nvm (e.g. `nvm use 25`),
# don't fight it — child shells must inherit the parent's choice.
if [[ $PATH != *"$NVM_DIR/versions/node/"* ]]; then
  () {
    local bin=""
    [[ -r "$HOME/.cache/zsh/nvm-default-bin" ]] && bin="$(<"$HOME/.cache/zsh/nvm-default-bin")"
    if [[ ! -d $bin ]]; then
      # degraded fallback if cache missing: newest installed version
      local -a vers=("$NVM_DIR"/versions/node/*(N/On))
      (( $#vers )) && bin="$vers[1]/bin"
    fi
    if [[ -d $bin ]]; then
      export NVM_BIN="$bin"
      export NVM_INC="${bin%/bin}/include/node"
      path=("$bin" $path)
    fi
  }
fi

# user bins + cargo ahead of node bin; condabin appended so the `conda` CLI
# exists in every zsh context (activation itself happens in .zshrc).
path=(
  "$HOME/bin"(N)
  "$HOME/.local/bin"(N)
  "$HOME/.cargo/bin"(N)
  $path
  "$HOME/anaconda3/condabin"(N)
)
typeset -U path PATH
export PATH
