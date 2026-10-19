#!/usr/bin/env bash
# Cloud Agent environment `install` hook.
# Syncs every GitHub skill pack listed in .cursor/skill-sources.txt into
# ~/.cursor/skills so Cloud Agents that boot from this environment snapshot
# see the same global skills as a local Cursor install.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
META_SRC="$ROOT/.cursor/skills/install-skills-from-github"

mkdir -p "$DEST"
if [[ -f "$META_SRC/SKILL.md" ]]; then
  if [[ -e "$DEST/install-skills-from-github" ]]; then
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$HOME/.cursor/skills-removed/$stamp"
    mv "$DEST/install-skills-from-github" \
      "$HOME/.cursor/skills-removed/$stamp/install-skills-from-github"
  fi
  cp -a "$META_SRC" "$DEST/install-skills-from-github"
  echo "seeded install-skills-from-github -> $DEST/install-skills-from-github"
fi

bash "$ROOT/scripts/install-cursor-skills-from-github.sh" sync
