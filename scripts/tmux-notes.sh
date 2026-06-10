#!/usr/bin/env bash
# Per-project notes — nvim on ~/notes/<session>.md in a popup (prefix N).
# Lowercase n reads markdown (glow); uppercase N writes it.
set -e
session=$(tmux display-message -p '#S')
mkdir -p "$HOME/notes"
exec nvim "$HOME/notes/${session}.md"
