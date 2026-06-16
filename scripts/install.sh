#!/usr/bin/env bash
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
NAME="optimizing-skills"
MODE="copy"; [ "${1:-}" = "--dev" ] && MODE="link"
installed=0
for base in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
  parent="$(dirname "$base")"
  [ -d "$parent" ] || { echo "skip: $parent 不存在(对应工具未安装)"; continue; }
  mkdir -p "$base"
  dest="$base/$NAME"
  rm -rf "$dest"
  if [ "$MODE" = "link" ]; then
    ln -s "$SRC" "$dest"; echo "linked -> $dest"
  else
    cp -r "$SRC" "$dest"; rm -rf "$dest/.git"; echo "copied -> $dest"
  fi
  installed=$((installed+1))
done
[ "$installed" -gt 0 ] && echo "✅ installed to $installed target(s)" || echo "⚠️ 未发现 Claude/Codex skills 目录"
