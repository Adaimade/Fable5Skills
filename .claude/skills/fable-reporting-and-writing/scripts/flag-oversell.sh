#!/bin/sh
# flag-oversell.sh — seed a review of a report/README/release-note draft by
# flagging vague-confidence and oversell phrases that hide missing evidence.
#
# It does NOT judge correctness and does NOT certify anything. It lists lines
# that CONTAIN a hedge/oversell phrase so YOU replace each with a calibrated
# claim (verified / probable / assumption / speculation) backed by observation.
# Deliberately over-inclusive: a false positive costs you one glance; a missed
# oversell ships a hallucinated completion claim. Grep-only; POSIX sh; no deps.
#
# Usage:   flag-oversell.sh FILE [FILE ...]
# Output:  matching lines grouped by file, with line numbers, to stdout.
#
# Exit codes: 0 = ran and found NOTHING to flag (clean);
#             1 = ran and flagged at least one phrase (review needed);
#             2 = usage error / unreadable file.

if [ "$#" -eq 0 ]; then
  echo "usage: flag-oversell.sh FILE [FILE ...]" >&2
  exit 2
fi

for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "cannot read: $f" >&2
    exit 2
  fi
done

# Case-insensitive, word-boundary-ish patterns. Each is a phrase that asserts
# confidence WITHOUT attaching an observation — the tell of an uncalibrated claim.
# Extended regex, alternation. Kept literal and conservative on purpose.
PATTERN='should[[:space:]]+(work|be[[:space:]]+fine|be[[:space:]]+ok|now[[:space:]]+work)'
PATTERN="$PATTERN"'|ought[[:space:]]+to[[:space:]]+work'
PATTERN="$PATTERN"'|(this[[:space:]]+)?should[[:space:]]+(fix|resolve|handle|do[[:space:]]+it)'
PATTERN="$PATTERN"'|probably[[:space:]]+(works|fine|fixed|ok)'
PATTERN="$PATTERN"'|seems[[:space:]]+to[[:space:]]+work'
PATTERN="$PATTERN"'|looks[[:space:]]+(good|fine|correct|right)[[:space:]]*[.!]?[[:space:]]*$'
PATTERN="$PATTERN"'|I[[:space:]]+think[[:space:]]+(it|this|that)'
PATTERN="$PATTERN"'|must[[:space:]]+be[[:space:]]+(fixed|working|correct)'
PATTERN="$PATTERN"'|(it|this)[[:space:]]+is[[:space:]]+(now[[:space:]]+)?(fully[[:space:]]+)?(working|fixed|done|complete)[[:space:]]*[.!]?[[:space:]]*$'
PATTERN="$PATTERN"'|all[[:space:]]+(good|set|done|working)'
PATTERN="$PATTERN"'|no[[:space:]]+(issues|problems)[[:space:]]*$'
PATTERN="$PATTERN"'|guaranteed|flawless|b?ullet-?proof|rock-?solid|production-?ready|just[[:space:]]+works'
PATTERN="$PATTERN"'|obviously|trivially[[:space:]]+correct|can'\''?t[[:space:]]+fail'

found=1  # default: nothing flagged -> will exit 0
for f in "$@"; do
  matches=$(grep -inE "$PATTERN" "$f")
  if [ -n "$matches" ]; then
    echo "== $f =="
    echo "$matches" | sed 's/^/  /'
    echo
    found=0  # something was flagged
  fi
done

if [ "$found" -eq 0 ]; then
  echo "# Each flagged line asserts confidence without attached evidence."
  echo "# Replace with a calibrated claim: VERIFIED (+observation) / PROBABLE"
  echo "# (+reason) / ASSUMPTION / SPECULATION. See SKILL.md calibration table."
  exit 1
else
  echo "# No hedge/oversell phrases matched. This is NOT proof the report is"
  echo "# calibrated — the linter only catches known phrasings. Re-read anyway."
  exit 0
fi
