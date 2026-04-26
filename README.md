# dotfiles

Cross-platform terminal setup. Catppuccin Macchiato everywhere.

## What's inside

| Tool | What it does |
|------|--------------|
| **zsh** + zinit | Shell + plugin manager |
| **oh-my-posh** | Prompt theme (Catppuccin Macchiato, custom git + project-version segments) |
| **fzf-tab, autosuggestions, syntax-highlighting, completions** | zsh plugins |
| **tmux** | Terminal multiplexer with scratchpad popups, music controls, which-key menu |
| **alacritty** | GPU-accelerated terminal |
| **lazygit, bat, eza, fzf, zoxide, glow** | All themed to match |
| **nvim** | LazyVim config |

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
- Install tmux plugin manager (tpm)
- Symlink every config file from this repo
- Set zsh as your login shell

Then:

1. Open a new terminal — zinit downloads plugins (~30s on first run).
2. Prompt theme is `~/.config/oh-my-posh/zen.toml` — edit and reload.
3. Inside tmux, press `Ctrl+s I` to install tmux plugins (resurrect, continuum).

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
| `Ctrl+s g` | lazygit (popup) |
| `Ctrl+s t` | floating terminal |
| `Ctrl+s f` | fuzzy find file → nvim |
| `Ctrl+s n` | glow markdown browser |
| `Ctrl+s b` | btop |
| `Ctrl+s m` | music menu (play/pause, vol) |
| `Alt+p / Alt+. / Alt+,` | play-pause / next / previous (browser MPRIS) |
| `Ctrl+s \|` `Ctrl+s -` | vertical / horizontal split |
| `Alt+h/j/k/l` | move between panes (no prefix) |
