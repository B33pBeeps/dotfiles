#!/usr/bin/env bash
# Show Claude + Codex quota

echo ""
printf '\033[1;34m━━━ Claude ━━━\033[0m\n'
sidekick quota --provider claude 2>/dev/null
echo ""
printf '\033[1;35m━━━ Codex ━━━\033[0m\n'
sidekick quota --provider codex 2>/dev/null
echo ""
read -n 1 -s
