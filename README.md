# dotfiles

Cross-platform terminal setup. Dual-theme system — `set-theme catppuccin|gruvbox` re-skins zsh / tmux / alacritty / kitty / foot / bat / lazygit / nvim in one shot, plus a 170+-theme alacritty live picker.

## What's inside

| Tool | What it does |
|------|--------------|
| **zsh** + zinit | Shell + plugin manager (~70ms startup — node/conda PATH cached in `~/.zshenv` so it works in every shell, not just interactive ones) |
| **oh-my-posh** | Prompt theme (custom git + project-version segments) |
| **fzf-tab, autosuggestions, syntax-highlighting, completions** | zsh plugins |
| **tmux** | Terminal multiplexer with scratchpad popups, project sessionizer, music controls, which-key menu |
| **alacritty** | GPU-accelerated terminal |
| **lazygit, bat, eza, fzf, zoxide, glow** | All themed to match |
| **nvim** | LazyVim config (colorscheme follows `set-theme`, hot-reloads on focus) |

## Install on a new machine

```bash
git clone https://github.com/B33pBeeps/dotfiles.git ~/code/personal/dotfiles
cd ~/code/personal/dotfiles
./install.sh
```

`install.sh` will:

- Install Homebrew if missing (Linux/macOS)
- `brew install` all the CLI tools
- On Linux: `apt install playerctl` for media controls
- Install zinit (zsh plugin manager)
- Install tmux plugin manager (tpm) **and the plugins themselves** (resurrect, continuum)
- Clone (or fast-forward) the alacritty-theme collection (`~/.config/alacritty/themes`)
- Symlink every config file from this repo
- Symlink user-facing scripts into `~/.local/bin`: `set-theme`, `alacritty-theme`, `nock`, `dotfiles-doctor`, `tmux-sessionizer`
- Set zsh as your login shell

Then:

1. Open a new terminal — zinit downloads plugins (~30s on first run).
2. Prompt theme is `~/.config/oh-my-posh/zen.toml` — edit and reload.
3. Run `dotfiles-doctor` any time to verify the whole setup.

## Platform support

| Platform | Status |
|----------|--------|
| Linux (Debian/Ubuntu) | Full support |
| macOS (Apple Silicon + Intel) | Full support |
| WSL | Full support (Ubuntu under Windows) |
| Native Windows | Not supported (use WSL) |

## Customizing

Everything is symlinked, so editing `~/.zshrc` edits the repo copy. Commit and push from `~/code/personal/dotfiles`:

```bash
cd ~/code/personal/dotfiles
git add -A && git commit -m "tweak prompt" && git push
```

## Tmux keybindings

Prefix is `Ctrl+s`. Press `Ctrl+s ?` for an in-terminal cheat sheet.

| Keys | Action |
|------|--------|
| `Ctrl+s o` | **project sessionizer** — fzf over `~/code` (+ zoxide frecency), create-or-switch session |
| `Ctrl+s s` | session picker (1-9 jump, `ctrl-n`: new session named after your query) |
| `Ctrl+s w` | session + window tree picker |
| `Ctrl+s g` | lazygit (popup) |
| `Ctrl+s t` | floating terminal |
| `Ctrl+s f` | fuzzy find file → nvim |
| `Ctrl+s /` | live grep → nvim at the matched line |
| `Ctrl+s .` | scrollback **path** picker — fzf every `file:line` in pane history, open in nvim at that line |
| `Ctrl+s y` | scrollback **URL** picker — Enter opens in browser, `ctrl-y` copies |
| `Ctrl+s n` | glow markdown browser |
| `Ctrl+s N` | per-project notes — nvim on `~/notes/<session>.md` |
| `Ctrl+s b` | btop |
| `Ctrl+s e` | redthread (sticky-note pegboard) |
| `Ctrl+s F` | elio (file manager) |
| `Ctrl+s q` | Claude/Codex quota |
| `Ctrl+s S` | songfetch (Spotify) |
| `Ctrl+s P` | pick markdown → slides |
| `Ctrl+s T` | **theme switcher** (global, both palettes) |
| `Ctrl+s m` | music menu (play/pause, vol) |
| `Alt+p / Alt+. / Alt+,` | play-pause / next / previous (browser MPRIS) |
| `Ctrl+s \|` `Ctrl+s -` | vertical / horizontal split |
| `Alt+h/j/k/l` | move between panes (no prefix) |

## Themes

Two layers:

- **`set-theme [catppuccin|gruvbox]`** (or `Ctrl+s T` in tmux, or no arg for a picker) — the global switcher. Rewrites the palette across zsh/fzf, tmux, oh-my-posh, foot, kitty, elio, lazygit, alacritty import, and bat; state lives in `~/.config/dotfiles-theme`. tmux repaints immediately; **nvim re-themes itself the next time it gains focus** — no restart.
- **`theme`** (alias for `alacritty-theme`) — fzf live-preview through 170+ alacritty themes, alacritty only. Personal `catppuccin-macchiato` pinned to the top with a ★. ENTER keeps, ESC reverts.

## Doctor

`dotfiles-doctor` verifies the whole setup: every symlink (parsed straight from `install.sh`), required tools, theme consistency across files, leftover `*.bak` files, **non-interactive shell health** (node/npm visible to `zsh -c` and `/bin/sh` — the thing that breaks agents and npm scripts when shell init goes wrong), and a zsh startup benchmark against a budget (`DOTFILES_ZSH_BUDGET_MS`, default 150ms).

```bash
dotfiles-doctor         # full check
dotfiles-doctor bench   # benchmark only
zbench                  # hyperfine startup measurement (alias)
```

## Sessionizer

`Ctrl+s o` scans `~/code` (depth 2) plus your zoxide frecency hits under it, fzf-picks a project, and creates-or-switches to a tmux session named after the dir (existing sessions marked ▸). Also on PATH as `tmux-sessionizer`.

## nock — pinned command palette

"Harpoon for shell commands." Pin frequently-used commands and fire them into the pane you came from, in two scopes: **global** (everywhere) and **session** (per tmux session / project).

| Keys | Action |
|------|--------|
| `prefix a` | Open palette — global + session commands, numbered |
| `prefix A` | Pin command(s) — fzf multi-select over shell history or free-type, then pick scope |

Inside the palette:

| Keys | Action |
|------|--------|
| `Enter` / `1-9` | Run the command in the original pane |
| `Ctrl-y` | Paste to the prompt without running (review/edit first) |
| `Ctrl-d` | Delete highlighted command |
| `Ctrl-e` / `Ctrl-g` | Edit session / global list in nvim (reorder, edit by hand) |

Storage: `~/.config/nock/global.list` + `~/.config/nock/sessions/<session>.list` (plain text, one command per line).

## zsh startup architecture

Startup is ~70ms (was ~600ms) without lazy-wrapper landmines:

- **`~/.zshenv`** — read by *every* zsh: cached nvm-default node bin + user bins + conda's `condabin`. Agent-spawned shells, `npm run`, and tmux `run-shell` all see node/conda.
- **`~/.zshrc`** — interactive only: conda activates base from a cached script (no python at startup); `nvm` is a lazy function that loads the real nvm.sh on first call and keeps the cache fresh after `nvm use/install/alias`.
- **`shell/profile-path.sh`** (sourced from `~/.profile`) — same PATH for bash/sh login contexts.

Caches live in `~/.cache/zsh/` and are pure derivatives — `rm -rf ~/.cache/zsh` is always safe (next interactive shell rebuilds them).
