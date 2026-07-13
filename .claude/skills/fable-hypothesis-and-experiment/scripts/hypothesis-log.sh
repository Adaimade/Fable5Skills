#!/bin/sh
# hypothesis-log.sh — print a blank hypothesis record to stdout.
# Portable POSIX shell. No dependencies beyond `date` and `cat`.
# Usage:
#   sh hypothesis-log.sh                 # print template to stdout
#   sh hypothesis-log.sh >> HYPOTHESES.md  # append to a running log
#   sh hypothesis-log.sh "cache key collides on user id"   # seed the title
#
# The record forces you to write a PREDICTION before you run anything,
# and to name a DISCRIMINATING outcome map before you look at results.
# Fill it in top to bottom. Do not delete sections; mark them N/A instead.

title=${1:-"<one-line claim, falsifiable>"}
today=$(date +%Y-%m-%d)

cat <<EOF
### H: ${title}
- date: ${today}
- status: open        # open | supported | refuted | retired
- source: ???         # boundary | recent-change | working-vs-broken diff | invariant violation

**Mechanism (one sentence, the single cause I claim):**
> ...

**Prediction (BEFORE running — numeric where possible):**
> If this mechanism is real I expect to observe: ...
> (value / count / rate / ordering, with rough magnitude)

**Discriminating experiment (outcomes must separate rival hypotheses):**
> Setup: ...
> Pre-committed interpretation:
>   - if I see A  -> this hypothesis holds
>   - if I see B  -> rival hypothesis R holds
>   - if I see C  -> neither; go back to observation

**Result (record even when disappointing):**
> observed: ...
> matches prediction? yes / no / partial

**Refutation attempt (genuinely try to break the conclusion):**
> alternative mechanism that also fits: ...
> confound / coincidence ruled out by: ...
> does ONE mechanism explain ALL observations incl. negatives/outliers? yes / no

**Disposition:**
> adopted (route to change control) | retired — reason: ...
EOF
