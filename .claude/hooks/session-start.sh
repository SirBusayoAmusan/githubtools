#!/bin/bash
set -euo pipefail

# Cloud sessions only
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

command -v node >/dev/null || { echo "node is required for the Lantern skills installer" >&2; exit 1; }
command -v git >/dev/null || { echo "git is required for the Lantern skills installer" >&2; exit 1; }

# Hash file lives in the skills dir, so it disappears with the skills
hashes="$HOME/.claude/skills/.lantern-session-start.sha256"
mkdir -p "$HOME/.claude/skills"

files=(.claude/hooks/session-start.sh lantern/lantern-install.mjs lantern/skills-manifest.json)
while IFS= read -r f; do files+=("$f"); done < <(find lantern/own-skills -type f | sort)

if ! sha256sum --check --status "$hashes" 2>/dev/null; then
  rm -f "$hashes"
  node lantern/lantern-install.mjs --skills-only
  sha256sum "${files[@]}" > "$hashes" || rm -f "$hashes"
fi
