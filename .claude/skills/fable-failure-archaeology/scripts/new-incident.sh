#!/bin/sh
# new-incident.sh — scaffold a project-local failure-archaeology incident record.
#
# Purpose: when a costly failure occurs in a real session, capture it in the
# incident format (symptom -> root cause -> evidence -> countermeasure -> status)
# so no future session re-fights the same battle.
#
# Portable POSIX sh. No dependencies beyond: sh, date, mkdir, printf.
# Writes into the CURRENT project only (./.failure-archaeology/), never global.
#
# Usage:
#   scripts/new-incident.sh "short-slug" > /dev/null   # writes a stub file, prints its path to stderr
#   scripts/new-incident.sh "retry-masked-race"        # same, path printed to stdout
#
# The generated file is a fill-in-the-blanks stub. Edit it to complete the record.

set -eu

slug="${1:-unnamed-incident}"

# Sanitize slug: keep [a-z0-9-], collapse everything else to '-'.
safe_slug=$(printf '%s' "$slug" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//')
[ -n "$safe_slug" ] || safe_slug="unnamed-incident"

stamp=$(date +%Y-%m-%d)
dir=".failure-archaeology"
file="$dir/${stamp}-${safe_slug}.md"

mkdir -p "$dir"

# Do not clobber an existing record for the same day+slug.
if [ -e "$file" ]; then
  printf 'refusing to overwrite existing record: %s\n' "$file" >&2
  exit 1
fi

cat > "$file" <<EOF
# Incident: ${safe_slug}

- Date observed: ${stamp}
- Provenance: project-local (observed this session)
- Status: open   # open | settled

## Symptom
<what was observed — the surface failure, exact error text or wrong behavior>

## Root cause
<the ONE mechanism that explains ALL observations. If unknown, say so and mark open.>

## Evidence
<what proves the root cause: a failing repro, a log line, a diff, a measurement.
 Link commits/files/line ranges. No claim without evidence.>

## Countermeasure
<the change or discipline that prevents recurrence. Prefer a check that FAILS loudly
 over a note that asks humans to remember.>

## Status
open   # flip to "settled" only once the countermeasure is verified end-to-end

## Generic?
<If this pattern is not project-specific, propose adding it to the
 fable-failure-archaeology catalog as a "field-common pattern" entry.>
EOF

printf '%s\n' "$file"
