#!/usr/bin/env bash
set -euo pipefail
src="$(cd "$(dirname "$0")" && pwd)/commands"
dest="${CLAUDE_COMMANDS_DIR:-$HOME/.claude/commands}"
mkdir -p "$dest"
cp "$src"/*.md "$dest/"
echo "installed /sonnet /s /haiku /h /opus /o /fable /f -> $dest"
