#!/bin/sh
# extract-claims.sh — seed an assumption ledger from a runbook/instructions file.
#
# Scans a text/markdown file for tokens that are LIKELY to be load-bearing and
# hallucination-prone: CLI flags, file/dir paths, fenced shell commands, and
# dotted API calls. It does NOT verify them — it lists them so YOU verify each
# against reality before shipping. Grep-only; POSIX sh; no dependencies.
#
# Usage:   extract-claims.sh FILE [FILE ...]
# Output:  a checklist grouped by claim type, printed to stdout.
#
# Exit codes: 0 = ran (even if nothing found); 2 = usage error / unreadable file.

if [ "$#" -eq 0 ]; then
  echo "usage: extract-claims.sh FILE [FILE ...]" >&2
  exit 2
fi

for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "cannot read: $f" >&2
    exit 2
  fi
done

emit() {
  # emit LABEL  (reads matches on stdin, prints unique sorted, or "(none)")
  label="$1"
  out=$(sort -u | sed '/^$/d')
  echo "## $label"
  if [ -z "$out" ]; then
    echo "  (none found)"
  else
    printf '  [ ] %s\n' $out 2>/dev/null || echo "$out" | sed 's/^/  [ ] /'
  fi
  echo
}

echo "# Verification worklist (verify each before shipping)"
echo "# source: $*"
echo

# CLI long/short flags, e.g. --dry-run, -rf. Verify with: <cmd> --help
cat "$@" | grep -oE '(^|[[:space:]])-{1,2}[A-Za-z][A-Za-z0-9-]*' \
  | sed 's/^[[:space:]]*//' | emit "CLI flags -> verify with: <cmd> --help"

# Absolute / relative-with-slash paths. Verify with: ls / stat
cat "$@" | grep -oE '(/|\./|~/)[A-Za-z0-9._/-]+' | emit "Paths -> verify with: ls -la / stat"

# Dotted calls or attribute access, e.g. os.path.join, foo.bar(). Verify in source/docs.
cat "$@" | grep -oE '[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+' \
  | emit "Dotted API/attr refs -> verify in installed source or pinned docs"

# Fenced code blocks (commands). Printed with line numbers for context.
echo "## Fenced code blocks -> run/read each; confirm every command exists"
awk 'f{print FILENAME":"FNR": "$0} /^```/{f=!f}' "$@" | sed 's/^/  /'
echo
echo "# Reminder: an item listed here is UNVERIFIED. Mark it [x] only after you"
echo "# have file:line, command output, or an explicit ASSUMPTION label for it."
