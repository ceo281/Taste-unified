#!/bin/sh
# Verify that the GATE 0 line-number map inside SKILL.md still points at the
# sections it names.
#
# taste-unified/SKILL.md routes the reader by absolute line number ("Part 2,
# universal invariants: line 136"). Any edit that adds or removes a line above a
# target silently re-points that coordinate at the wrong section, and the skill
# keeps working just badly enough that nobody notices. This script catches that.
#
#   scripts/verify-line-map.sh            check the map (exit 1 on drift)
#   scripts/verify-line-map.sh --update   re-record the anchors after an
#                                         intentional edit to SKILL.md + its map
#
# How it works: the lock file records a hash of the *content* each map entry
# points at, keyed by the entry's label. So the check is "does 'line 382' still
# land on the A1 profile header", not "is 382 still 382" — renumbering the file
# is fine as long as the map is renumbered with it.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
skill="$root/skills/taste-unified/SKILL.md"
lock="$root/skills/taste-unified/line-map.lock"
mode=${1:-check}

[ -f "$skill" ] || { echo "missing: $skill" >&2; exit 2; }

# Pull "<label>: line <N>" pairs out of the GATE 0 map region only.
entries=$(awk '
  /^### THE MAP/       { in_map = 1; next }
  /^### ROUTE, THEN/   { in_map = 0 }
  !in_map              { next }
  {
    line = $0
    while (match(line, /line [0-9]+/)) {
      n = substr(line, RSTART + 5, RLENGTH - 5)
      label = substr(line, 1, RSTART - 1)
      sub(/^[-\t ]+/, "", label)          # strip list bullet
      sub(/^.*\. /, "", label)            # keep only the last sentence-ish chunk
      sub(/:[ \t]*$/, "", label)
      gsub(/\t/, " ", label)
      if (label != "") print n "\t" label
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$skill")

[ -n "$entries" ] || { echo "no map entries found in $skill" >&2; exit 2; }

hash_of_line() {
  sed -n "$1p" "$skill" | sha256sum | cut -c1-16
}

if [ "$mode" = "--update" ]; then
  {
    echo "# anchors for the GATE 0 map in SKILL.md -- regenerate with scripts/verify-line-map.sh --update"
    printf '%s\n' "$entries" | while IFS="$(printf '\t')" read -r n label; do
      printf '%s\t%s\n' "$(hash_of_line "$n")" "$label"
    done
  } > "$lock"
  echo "recorded $(printf '%s\n' "$entries" | wc -l | tr -d ' ') anchors -> ${lock#"$root"/}"
  exit 0
fi

[ -f "$lock" ] || { echo "missing: $lock (run: scripts/verify-line-map.sh --update)" >&2; exit 2; }

fail=0
printf '%s\n' "$entries" | while IFS="$(printf '\t')" read -r n label; do
  want=$(awk -F"\t" -v l="$label" '$2 == l { print $1 }' "$lock")
  got=$(hash_of_line "$n")
  if [ -z "$want" ]; then
    echo "NEW    $label -> line $n (not in lock; run --update if intended)"
  elif [ "$want" != "$got" ]; then
    echo "DRIFT  $label -> line $n"
    echo "       now reads: $(sed -n "${n}p" "$skill" | cut -c1-72)"
    echo "$n" >> "$root/.verify-failed"
  fi
done

if [ -f "$root/.verify-failed" ]; then
  rm -f "$root/.verify-failed"
  echo
  echo "The GATE 0 map no longer matches the file. Fix the line numbers in the map," >&2
  echo "then re-run with --update to re-record the anchors." >&2
  fail=1
fi

[ "$fail" -eq 0 ] && echo "line map OK ($(printf '%s\n' "$entries" | wc -l | tr -d ' ') entries)"
exit "$fail"
