# Custom Powerlevel10k additions — loaded after ~/.p10k.zsh
# Project version segment — shows version from package.json / pyproject.toml /
# Cargo.toml / VERSION / master-branch version-bump commits.

typeset -gA _prj_ver_cache

_project_version() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  if [[ -n ${_prj_ver_cache[$root]+x} ]]; then
    echo ${_prj_ver_cache[$root]}
    return
  fi

  local ver=""

  if [[ -f $root/package.json ]]; then
    ver=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' $root/package.json | head -1)
  elif [[ -f $root/pyproject.toml ]]; then
    ver=$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' $root/pyproject.toml | head -1)
  elif [[ -f $root/Cargo.toml ]]; then
    ver=$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' $root/Cargo.toml | head -1)
  elif [[ -f $root/VERSION ]]; then
    ver=$(head -1 $root/VERSION)
  fi

  if [[ -z $ver ]] && git -C $root rev-parse --verify master >/dev/null 2>&1; then
    ver=$(git -C $root log master --pretty=%s 2>/dev/null | grep -m1 -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$')
  fi

  if [[ -z $ver ]]; then
    local f
    f=$(fd -t f -d 4 -E node_modules --glob "package.json" $root 2>/dev/null | head -1)
    [[ -n $f ]] && ver=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' $f | head -1)
  fi

  _prj_ver_cache[$root]=$ver
  echo $ver
}

# p10k segment: shown in mauve with a tag icon
function prompt_project_version() {
  local ver=$(_project_version)
  [[ -n $ver ]] && p10k segment -f 183 -i '' -t "$ver"
}

# Register the segment; insert right after vcs if present, else append
() {
  local -a elements=(${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS})
  local -a new_elements=()
  local inserted=0
  for el in $elements; do
    new_elements+=("$el")
    if [[ $el == vcs && $inserted == 0 ]]; then
      new_elements+=(project_version)
      inserted=1
    fi
  done
  [[ $inserted == 0 ]] && new_elements+=(project_version)
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=($new_elements)
}
