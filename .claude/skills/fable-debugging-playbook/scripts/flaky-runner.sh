#!/bin/sh
# flaky-runner.sh — run a command N times, report pass/fail counts.
# Purpose: turn "it fails sometimes" into a number. A bug you cannot
# reproduce on demand you cannot fix on demand. Use this to measure a
# repro rate BEFORE you touch code, and to prove a fix took AFTER.
#
# Portable POSIX sh. No bashisms. Exit status: 0 if all runs passed,
# 1 if any run failed, 2 on usage error.
#
# Usage:   flaky-runner.sh N command [args...]
# Example: flaky-runner.sh 50 pytest -q tests/test_race.py
#          flaky-runner.sh 20 sh -c 'curl -sf localhost:8080/health'
#
# Notes:
#  - A run "passes" iff the command exits 0.
#  - stdout/stderr of each run are suppressed; only the tally is shown.
#    To see a failing run's output, re-run the command directly.
#  - Stops early on the first failure only if STOP_ON_FAIL=1 is set.

if [ "$#" -lt 2 ]; then
    echo "usage: $0 N command [args...]" >&2
    exit 2
fi

N="$1"
shift

# Validate N is a positive integer.
case "$N" in
    ''|*[!0-9]*) echo "error: N must be a positive integer, got '$N'" >&2; exit 2 ;;
esac
if [ "$N" -lt 1 ]; then
    echo "error: N must be >= 1" >&2
    exit 2
fi

pass=0
fail=0
i=1
while [ "$i" -le "$N" ]; do
    if "$@" >/dev/null 2>&1; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'run %d/%d: FAIL\n' "$i" "$N" >&2
        if [ "${STOP_ON_FAIL:-0}" = "1" ]; then
            break
        fi
    fi
    i=$((i + 1))
done

ran=$((pass + fail))
printf 'ran=%d pass=%d fail=%d rate=%d%%\n' \
    "$ran" "$pass" "$fail" "$((pass * 100 / ran))"

[ "$fail" -eq 0 ]
