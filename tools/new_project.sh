#!/usr/bin/env bash
# Scaffold a new game project from this starter kit (run from the kit repo, any working directory).
# Usage: tools/new_project.sh [--no-git] <dest_dir> "<Project Name>"
# Copies the kit into dest_dir (created if missing, must be empty), leaves out the kit-only files (.git, kit/,
# docs/lessons/, this script), puts kit/project_README.md in place as README.md, replaces __PROJECT_NAME__
# (display name), __PROJECT_SLUG__ (file-safe name) and __PROJECT_PKG__ (Android package segment) in the text
# files, runs git init (unless --no-git), and prints next steps.
set -euo pipefail
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT=1
[[ "${1:-}" == "--no-git" ]] && { GIT=0; shift; }
[[ $# -eq 2 ]] || { echo "usage: tools/new_project.sh [--no-git] <dest_dir> \"<Project Name>\"" >&2; exit 2; }
DEST="$1"; NAME="$2"
[[ -f "$KIT/project.godot" && -f "$KIT/kit/project_README.md" ]] || { echo "new_project: $KIT is not the starter kit" >&2; exit 1; }
[[ -n "${NAME// }" ]] || { echo "new_project: project name is empty" >&2; exit 2; }
if [[ -d "$DEST" && -n "$(ls -A "$DEST")" ]]; then echo "new_project: $DEST exists and is not empty" >&2; exit 1; fi
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"
case "$DEST/" in "$KIT"/*) echo "new_project: $DEST is inside the kit" >&2; exit 1 ;; esac

tar -C "$KIT" -cf - \
  --exclude=./.git --exclude=./.godot --exclude=./build --exclude=./out --exclude=./config \
  --exclude=./kit --exclude=./docs/lessons --exclude=./tools/new_project.sh --exclude='__pycache__' . \
  | tar -C "$DEST" -xf -
cp "$KIT/kit/project_README.md" "$DEST/README.md"
# CLAUDE.md lines marked KIT-ONLY explain the template to whoever opens the kit itself; projects do not need them.
sed -i '/KIT-ONLY/d' "$DEST/CLAUDE.md"

SLUG="$(printf '%s' "$NAME" | tr -c 'A-Za-z0-9\n' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
[[ -n "$SLUG" ]] || SLUG="game"
PKG="$(printf '%s' "$SLUG" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9')"
[[ "$PKG" =~ ^[a-z] ]] || PKG="g$PKG"
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }
N="$(esc "$NAME")"; S="$(esc "$SLUG")"
grep -rlI --exclude-dir=.git -e '__PROJECT_' "$DEST" | while IFS= read -r f; do
  sed -i "s|__PROJECT_NAME__|$N|g; s|__PROJECT_SLUG__|$S|g; s|__PROJECT_PKG__|$PKG|g" "$f"
done

if (( GIT )); then (cd "$DEST" && { git init -q -b main 2>/dev/null || git init -q; }); fi
echo "new_project: created '$NAME' in $DEST (file name: $SLUG, package: com.example.$PKG)"
cat <<EOT
Next steps:
  1. cd $DEST && tools/check_all.sh          # should be all green on minute one
  2. Fill in CLAUDE.md and docs/agent_brief.md; follow docs/new_project_checklist.md and docs/playbook.md
  3. Create the GitHub repo:  gh repo create <owner>/$SLUG --public --source=. --remote=origin
  4. git add -A && git commit -m "Start from starter kit" && git push -u origin main
  5. CI (.github/workflows/checks.yml) runs unit, lint and sims on the push; confirm it is green
  6. Set package/unique_name in export_presets.cfg (now com.example.$PKG) before any store build
EOT
