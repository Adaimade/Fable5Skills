#!/bin/sh
# check-skill.sh — heuristic format linter for a Fable Thinking SKILL.md.
# Portable POSIX shell. Dependencies: awk, wc, grep, head (all POSIX-standard).
#
# It checks the LIBRARY'S OWN structural rules (as of 2026-07-13), NOT prose
# quality — a cold reader still has to do the factual/doctrine/usability passes.
# This is a fast pre-flight so obvious format breaks never reach review.
#
# Usage:
#   sh check-skill.sh path/to/SKILL.md          # lint one skill
#   sh check-skill.sh skills/*/SKILL.md         # lint many
#   sh check-skill.sh                           # lint ./SKILL.md if present
#
# Exit status: 0 if every file passed, 1 if any file had a FAIL.
# WARN lines never fail the run — they are judgement calls for a human.
#
# What it can and cannot see:
#   CAN   : frontmatter is fenced, has the required name+description keys (WARNs
#           on extra keys — they are valid Claude Code fields, off house style),
#           description is one line and < 1000 chars, and required sections exist.
#   CANNOT: whether the description actually TRIGGERS well, whether a command is
#           real, whether the content is true. Those need the review protocol.

status=0

check_one() {
  file=$1
  if [ ! -f "$file" ]; then
    printf '%s: FAIL cannot read file\n' "$file"
    status=1
    return
  fi

  fails=0
  warns=0
  report() { # level msg
    printf '%s: %s %s\n' "$file" "$1" "$2"
    case $1 in
      FAIL) fails=$((fails + 1)); status=1 ;;
      WARN) warns=$((warns + 1)) ;;
    esac
  }

  # --- Frontmatter must be fenced by --- on line 1 and a later --- line. ---
  first=$(head -n 1 "$file")
  if [ "$first" != "---" ]; then
    report FAIL "frontmatter must open with '---' on line 1"
  fi

  # Line number of the SECOND '---' (frontmatter close).
  close=$(awk 'NR==1{next} /^---[[:space:]]*$/{print NR; exit}' "$file")
  if [ -z "$close" ]; then
    report FAIL "frontmatter has no closing '---'"
    close=0
  fi

  # Keys at top level of frontmatter (lines before close, matching key:).
  # The pattern allows '-' so hyphenated keys (e.g. allowed-tools) are seen.
  # 'name' and 'description' are REQUIRED by this library's house convention
  # (missing => FAIL). Any OTHER key is a valid Claude Code field, just off the
  # house convention => WARN, never FAIL. (Docs: code.claude.com/docs/en/skills.)
  if [ "$close" -gt 1 ]; then
    keys=$(awk -v c="$close" 'NR>1 && NR<c' "$file" \
            | grep -E '^[A-Za-z_][A-Za-z0-9_-]*:' \
            | sed -E 's/^([A-Za-z_][A-Za-z0-9_-]*):.*/\1/')
    printf '%s\n' "$keys" | grep -qx 'name' \
      || report FAIL "frontmatter missing required key 'name'"
    printf '%s\n' "$keys" | grep -qx 'description' \
      || report FAIL "frontmatter missing required key 'description'"
    extra=$(printf '%s\n' "$keys" | grep -vxE 'name|description' \
            | sort -u | tr '\n' ',' | sed 's/,$//')
    if [ -n "$extra" ]; then
      report WARN "extra frontmatter key(s): ${extra} — valid Claude Code field(s), but this library's house convention is name+description only"
    fi
  fi

  # --- Description length + single-line check. ---
  # Extract the description value. Handles: description: "..."  on one line.
  desc_line=$(awk -v c="$close" 'NR>1 && NR<c && /^description:/{print; exit}' "$file")
  if [ -z "$desc_line" ]; then
    report FAIL "no 'description:' key in frontmatter"
  else
    desc_val=$(printf '%s' "$desc_line" | sed -E 's/^description:[[:space:]]*//')
    len=$(printf '%s' "$desc_val" | wc -c | tr -d ' ')
    if [ "$len" -ge 1000 ]; then
      report FAIL "description is ${len} chars (must be < 1000)"
    fi
    if [ "$len" -lt 120 ]; then
      report WARN "description is only ${len} chars — is it trigger-rich enough?"
    fi
  fi

  # --- Required sections (grep for the headings this library mandates). ---
  grep -q '## 繁中摘要' "$file" || report FAIL "missing '## 繁中摘要' section"
  grep -qi 'when not to use' "$file" || report WARN "no 'When NOT to use' section found"
  grep -qi 'provenance' "$file" || report FAIL "missing Provenance/maintenance section"

  # --- Length target 200–450 lines (WARN only — dense-short can be fine). ---
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 120 ]; then
    report WARN "only ${lines} lines — likely too thin for the 200–450 target"
  fi
  if [ "$lines" -gt 500 ]; then
    report WARN "${lines} lines — over the 450 target; consider tightening"
  fi

  if [ "$fails" -eq 0 ]; then
    printf '%s: PASS (%d warnings)\n' "$file" "$warns"
  fi
}

if [ "$#" -eq 0 ]; then
  set -- ./SKILL.md
fi

for f in "$@"; do
  check_one "$f"
done

exit "$status"
