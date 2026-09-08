#!/bin/sh
# Install the taste-unified skill somewhere else.
#
#   scripts/install.sh                    -> ~/.claude/skills/taste-unified
#   scripts/install.sh ../other-project   -> ../other-project/.claude/skills/taste-unified
#   scripts/install.sh /some/dir          -> /some/dir/taste-unified   (if /some/dir
#                                            is already a skills directory)
#
# Copies SKILL.md verbatim, alongside the line-map lock so the installed copy
# can still be verified. It is copied, never edited: the skill routes itself by
# absolute line number, so any rewrite on the way in would break it.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
src="$root/skills/taste-unified"
[ -f "$src/SKILL.md" ] || { echo "missing: $src/SKILL.md" >&2; exit 2; }

target=${1:-"$HOME"}

case "$target" in
  */skills|*/skills/) dest="${target%/}/taste-unified" ;;
  *)                  dest="${target%/}/.claude/skills/taste-unified" ;;
esac

if [ -e "$dest/SKILL.md" ]; then
  if cmp -s "$src/SKILL.md" "$dest/SKILL.md"; then
    echo "already current: $dest"
    exit 0
  fi
  printf 'overwrite existing skill at %s? [y/N] ' "$dest"
  read -r reply
  case "$reply" in [yY]*) ;; *) echo "aborted"; exit 1 ;; esac
fi

mkdir -p "$dest"
cp "$src/SKILL.md" "$src/line-map.lock" "$dest/"
cmp -s "$src/SKILL.md" "$dest/SKILL.md" || { echo "copy verification failed" >&2; exit 1; }
echo "installed -> $dest"
