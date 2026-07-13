#!/bin/sh
# new-campaign.sh — scaffold a project-local hard-problem campaign ledger.
#
# Purpose: when a bug or goal has resisted normal attempts (see the entry
# criteria in ../SKILL.md), start a campaign by capturing everything in ONE
# living ledger file: repro, baseline, evidence (incl. negatives), hypothesis
# tree, experiments, confirmed mechanism, ranked fix menu, validation.
#
# This ledger is a LIVE working doc during the fight. It is NOT the settled
# post-mortem — that is a fable-failure-archaeology incident record.
#
# Portable POSIX sh. No dependencies beyond: sh, date, mkdir, printf, tr, sed.
# Writes into the CURRENT project only (./.campaign/), never global.
#
# Usage:
#   scripts/new-campaign.sh "short-slug"    # writes ./.campaign/<date>-<slug>.md, prints path
#   scripts/new-campaign.sh "flaky-ci"      # example
#
# The generated file is a fill-in-the-blanks skeleton. Edit it as the campaign
# progresses. Its content is kept byte-identical to the ledger template in
# ../SKILL.md — if you change one, change both.

set -eu

slug="${1:-unnamed-campaign}"

# Sanitize slug: lowercase, keep [a-z0-9-], collapse runs of '-', trim ends.
safe_slug=$(printf '%s' "$slug" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//')
[ -n "$safe_slug" ] || safe_slug="unnamed-campaign"

stamp=$(date +%Y-%m-%d)
dir=".campaign"
file="$dir/${stamp}-${safe_slug}.md"

mkdir -p "$dir"

# Do not clobber an existing ledger for the same day+slug.
if [ -e "$file" ]; then
  printf 'refusing to overwrite existing ledger: %s\n' "$file" >&2
  exit 1
fi

cat > "$file" <<EOF
# Campaign: ${safe_slug}

- Started: ${stamp}
- Entry trigger: <2+ failed attempts | multi-day | cross-system | intermittent+stakes | high-stakes change>
- Current phase: 0
- Status: open   # open | closed

## Scope freeze (Phase 0)
- WILL touch: <files / systems in bounds>
- WON'T touch: <explicitly out of bounds>

## Repro & baseline (Phase 0)
- Repro command/input/env: <exact>
- Expected vs actual: <...>
- Repro rate (baseline): <e.g. 14/50 = 28%>   # deterministic if 100%

## Evidence ledger (Phase 1)  — date + source EVERY line, incl. negatives
- [YYYY-MM-DD] <observation> — source: <cmd/log/file/run>
- [YYYY-MM-DD] NEGATIVE: <what did NOT happen / null result> — source: <...>

## Hypothesis tree (Phase 2)
- H1 <mechanism> — predicts: <distinct observation> — discriminating exp: <E1>
  - H1a <sub-mechanism> — predicts: <...> — exp: <...>
- H2 <mechanism> — predicts: <...> — exp: <E2>
### Parked (untestable now)
- HP <mechanism> — untestable because: <...> — testable if: <...>

## Experiments (Phase 3)  — pre-commit interpretation BEFORE running
- E1: <experiment>
  - Pre-committed: result A → H1 dead; result B → H1 promoted
  - [YYYY-MM-DD] Result: <A|B|neither> → <branch taken>

## Confirmed mechanism (Phase 4)
- Mechanism: <the ONE cause that explains ALL observations>
- Explains: <list every observation incl. negatives — no residue>
- Adversarial refutation: <not-yet-checked prediction tested; outcome>

## Fix menu (Phase 5)  — ranked
| Candidate | Theory obligation | Blast radius | Reversibility | Rank |
|-----------|-------------------|--------------|---------------|------|
| A | <why mechanism makes this work> | <...> | <class> | 1 |
| B | <...> | <...> | <class> | 2 |
- Chosen: <A> because <...>

## Validation & promotion (Phase 6)
- Original symptom re-check vs baseline: <0/50 over N>=baseline runs>
- Regression sweep: <what was run; result>
- Routed through change control: <yes/link>
- Outcome: <closed | branched back to Phase _>
EOF

printf '%s\n' "$file"
