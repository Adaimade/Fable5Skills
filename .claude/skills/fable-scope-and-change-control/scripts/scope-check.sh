#!/bin/sh
# scope-check.sh — report the size and shape of the current uncommitted change
# so you can spot scope drift (P4) before you commit or hand off.
#
# It DOES NOT block anything and makes NO changes. It reads `git diff` and prints:
#   - every file touched, with lines added/removed
#   - the total line churn
#   - a WARN for any touched file that does not match your declared scope patterns
#
# Usage (run inside a git work tree):
#   scope-check.sh                       # summarize working-tree + staged changes
#   scope-check.sh 'src/auth/*' 'test/*' # additionally flag files outside these globs
#
# Args: zero or more shell glob patterns describing the files you INTENDED to touch.
#   Patterns are matched against repo-relative paths with the shell `case` operator,
#   so `*` matches across directory separators (e.g. 'src/*' matches src/a/b.c).
# Exit status: 0 if all touched files are in scope (or no patterns given);
#              1 if at least one touched file is out of scope; 2 on usage error.
#
# Portable: POSIX sh + git only. No bashisms, no GNU-only flags.

set -eu

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "scope-check: not inside a git work tree" >&2
  exit 2
fi

# Compare against HEAD so both staged and unstaged edits are included.
# --numstat prints: <added>\t<removed>\t<path>  (binary files show '-').
diff_output=$(git diff --numstat HEAD 2>/dev/null || true)

if [ -z "$diff_output" ]; then
  echo "No uncommitted changes vs HEAD. Nothing to review."
  exit 0
fi

total_add=0
total_del=0
files=0
out_of_scope=0

echo "Touched files (added/removed):"
# Read numstat line by line. Fields are tab-separated.
printf '%s\n' "$diff_output" | while IFS='	' read -r added removed path; do
  [ -z "${path:-}" ] && continue
  printf '  +%-6s -%-6s %s' "$added" "$removed" "$path"

  if [ "$#" -gt 0 ]; then
    in_scope=0
    for pat in "$@"; do
      # shellcheck disable=SC2254
      case "$path" in
        $pat) in_scope=1; break ;;
      esac
    done
    if [ "$in_scope" -eq 0 ]; then
      printf '   <-- OUT OF SCOPE'
    fi
  fi
  printf '\n'
done

# The while-subshell can't export counters (piped subshell), so recompute totals
# in the parent shell from the same data.
total_add=$(printf '%s\n' "$diff_output" | awk -F'\t' '$1 ~ /^[0-9]+$/ {s+=$1} END {print s+0}')
total_del=$(printf '%s\n' "$diff_output" | awk -F'\t' '$2 ~ /^[0-9]+$/ {s+=$2} END {print s+0}')
files=$(printf '%s\n' "$diff_output" | grep -c .)

echo "----"
echo "Files touched: $files   Lines added: $total_add   Lines removed: $total_del"

if [ "$#" -gt 0 ]; then
  for line in $(printf '%s\n' "$diff_output" | awk -F'\t' '{print $3}'); do
    hit=0
    for pat in "$@"; do
      # shellcheck disable=SC2254
      case "$line" in
        $pat) hit=1; break ;;
      esac
    done
    [ "$hit" -eq 0 ] && out_of_scope=$((out_of_scope + 1))
  done
  if [ "$out_of_scope" -gt 0 ]; then
    echo "WARN: $out_of_scope file(s) touched outside declared scope. Justify or revert them."
    exit 1
  fi
  echo "OK: all touched files are within declared scope."
fi

exit 0
