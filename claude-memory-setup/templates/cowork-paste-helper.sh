#!/bin/bash
# cowork-paste-claude-md — copy ~/.claude/CLAUDE.md to clipboard
#
# Usage:
#   bash cowork-paste-helper.sh
#
# What it does:
#   Reads ~/.claude/CLAUDE.md and pipes it to the system clipboard (macOS: pbcopy,
#   Linux: xclip/wl-copy). Then prints instructions for pasting into Claude Desktop's
#   Cowork Global Instructions field.
#
# Why this exists:
#   Cowork Global Instructions live server-side. There's no local file that syncs
#   automatically. When you edit ~/.claude/CLAUDE.md, you need to manually paste
#   the new content into Cowork to keep CoWork sessions aligned with Claude Code.

set -euo pipefail

FILE="${CLAUDE_MD_PATH:-$HOME/.claude/CLAUDE.md}"

if [ ! -f "$FILE" ]; then
  echo "ERROR: $FILE not found" >&2
  exit 1
fi

# Pick a clipboard tool based on platform
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$FILE"
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$FILE"
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$FILE"
elif command -v xsel >/dev/null 2>&1; then
  xsel --clipboard --input < "$FILE"
else
  echo "ERROR: no clipboard utility found (tried pbcopy, wl-copy, xclip, xsel)" >&2
  exit 1
fi

lines=$(wc -l < "$FILE" | tr -d ' ')
bytes=$(wc -c < "$FILE" | tr -d ' ')

echo "✓ CLAUDE.md copied to clipboard ($lines lines / $bytes bytes)"
echo ""
echo "Next steps:"
echo "  1. Open Claude Desktop"
echo "  2. Settings → Cowork → Global Instructions"
echo "  3. Clear existing content → ⌘V (or Ctrl+V) to paste → Save"
echo ""
echo "Do this any time you edit ~/.claude/CLAUDE.md to keep Cowork in sync."
