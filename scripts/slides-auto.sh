#!/usr/bin/env bash
# Wrapper for slides that auto-splits overflowing slides.
# Usage: slides-auto.sh <file.md>

set -e

file="$1"
[[ -z "$file" || ! -f "$file" ]] && { echo "Usage: slides-auto.sh <file.md>"; exit 1; }

# Terminal height minus padding for slides chrome (border, footer)
max_lines=$(( $(tput lines) - 4 ))
(( max_lines < 5 )) && max_lines=20

tmp=$(mktemp /tmp/slides-XXXXXX.md)
trap 'rm -f "$tmp"' EXIT

awk -v max="$max_lines" '
BEGIN { count = 0; slide = "" }

/^---[[:space:]]*$/ {
    # Flush current slide (possibly split)
    if (slide != "") {
        n = split(slide, lines, "\n")
        chunk = 0
        for (i = 1; i <= n; i++) {
            if (chunk >= max) {
                printf "\n---\n\n"
                chunk = 0
            }
            print lines[i]
            chunk++
        }
    }
    print "---"
    slide = ""
    next
}

{
    if (slide == "")
        slide = $0
    else
        slide = slide "\n" $0
}

END {
    # Flush last slide
    if (slide != "") {
        n = split(slide, lines, "\n")
        chunk = 0
        for (i = 1; i <= n; i++) {
            if (chunk >= max) {
                printf "\n---\n\n"
                chunk = 0
            }
            print lines[i]
            chunk++
        }
    }
}
' "$file" > "$tmp"

slides "$tmp"
