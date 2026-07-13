---
name: fable-diagnostics-and-measurement
description: "Load when you are about to claim something is faster/slower/smaller/more-accurate/fixed based on a performance, latency, memory, size, throughput, error-rate, or resource number — or when a task is to profile, benchmark, optimize, find a regression, or interpret metrics/logs/observability data. Use it to set up a metric, capture a baseline BEFORE changing code, control the run environment, repeat runs and read variance, and avoid noise/outlier/sampling-bias/averages-hiding-bimodality traps. Also load when tempted to eyeball a diff, a quiet log, or a UI and declare success. Do NOT load for root-cause debugging of a functional bug (see fable-debugging-playbook), for defining what counts as done end-to-end (see fable-verification-standards), for designing a hypothesis that predicts numbers (see fable-hypothesis-and-experiment), or for statistical estimation from first principles (see fable-first-principles-analysis)."
---

## 繁中摘要

- 這個技能的核心規則：任何「更快 / 更小 / 更準 / 修好了」的宣稱，都必須有一個「在改動前後、在同一條件下、用明確定義的量測方法」取得的數字，而不是憑肉眼判斷。
- 提供量測協定：先定義指標 → 改任何東西之前先建立基線（baseline）→ 控制環境 → 重複多次並回報變異度（variance）→ 與基線比較 → 連同條件一起陳述結果。
- 收錄可移植的儀器化（instrumentation）手法：計時、計數、結構化日誌標記、二分法定位，並附一個已實測的 Perl 計時腳本 `scripts/repeat-bench.pl`（是 Perl，不要用 `sh` 執行）。
- 提供「數字判讀指南」：單次執行不可信、變異與離群值、抽樣偏差、日誌倖存者偏差、相關不等於因果、平均值會掩蓋雙峰分布。
- 附「肉眼會騙人」對照表與回歸（regression）基線紀律：先把現況存成資料，之後才有辦法回答「我是不是弄壞了」。
- 何時不要用：功能性 bug 的根因除錯、端到端完成定義、假設設計、純理論估算，各有對應的姊妹技能。

# Fable Diagnostics and Measurement

**Measure, don't eyeball.** A number you can reproduce beats an impression you can't. This
skill is the discipline for turning "seems faster / looks fixed / feels better" into a
defensible, conditioned measurement — and for reading numbers without fooling yourself.

This directly attacks failure mode **P1** (claiming completion without verification): "it's
faster now" with no before/after number is the performance-flavored version of "fixed it"
without running it.

---

## 1. The core rule (non-negotiable)

> Any claim of **faster / slower / smaller / bigger / more accurate / less memory / fixed**
> requires a **number**, from a **defined measurement**, taken **before AND after** the
> change, under **stated conditions**.

If you have only an "after" number, you have a fact about the current state, not evidence of
improvement. If you have only one run, you have a sample, not a measurement. If you cannot
state the conditions, someone else cannot reproduce it — so it is an anecdote.

Minimum shippable claim shape:

> "Metric M went from **B ± v** (baseline) to **A ± v** (after), measured by **<method>**,
> N=**<runs>**, on **<machine/data/load>**, on **(as of 2026-07-13)**."

Anything less is an impression. Impressions are fine for forming a hypothesis (see
fable-hypothesis-and-experiment); they are not fine as a reported result (see
fable-reporting-and-writing for calibrated claim language).

---

## 2. The measurement protocol

Follow these steps **in order**. The order is the discipline: skipping "baseline before
change" is the single most common way measurement lies.

| # | Step | What it means | Failure if skipped |
|---|------|---------------|--------------------|
| 1 | **Define the metric** | State exactly what you measure and its unit (wall-clock ms? RSS bytes? p95 latency? error count per 1k requests?). | You measure something adjacent to what you care about (CPU time vs wall time). |
| 2 | **Baseline BEFORE changing anything** | Capture the metric on the *current* code/state and save it as data (a file, not memory). | No before number → improvement is unfalsifiable. |
| 3 | **Control the environment** | Same machine, same input data, same load, same config, same build flags. Close noisy neighbors. Note anything you can't control. | Your "speedup" is a quieter laptop. |
| 4 | **Repeat and report variance** | Run N times (start with N≥5–10). Report min / median / spread, never a single number. | One run catches an outlier and you ship a fantasy. |
| 5 | **Compare against baseline** | After the change, re-measure identically and compare distributions, not single points. | Point-vs-point comparison inside the noise band = fake win. |
| 6 | **State conditions with the result** | Ship the number *with* method, N, and environment. | Irreproducible → not a result. |

**Decision rule for "is this a real change?"** If the after-distribution overlaps the
before-distribution (e.g. after-median sits inside before's min–max, or the change is smaller
than one standard deviation), you have **not** demonstrated a difference. Either the effect is
small, or your noise is large — collect more runs or reduce noise before claiming anything.

---

## 3. Universal instrumentation patterns

All portable (POSIX shell / git / common tools). Prefer the simplest that answers the
question. Patterns are marked **[core]** (assume present) or **[optional]** (nice if
installed; always keep a core fallback).

### Timing

| Tool | Pattern | Notes |
|------|---------|-------|
| `time` **[core]** | `time <cmd>` | Shell builtin. Output format varies by shell; fine for a rough single read, bad for parsing. |
| `repeat-bench.pl` **[needs Perl]** | `perl <skill-dir>/scripts/repeat-bench.pl -n 10 -- <cmd>` | Shipped here. It is **Perl, not sh** — run via `perl` (or `./…`), never `sh …`. `<skill-dir>` is where this skill is installed (see §7 for the full path). Runs N times, reports min/median/max/mean/stddev + noise indicator. Uses Perl `Time::HiRes` (Perl core) — present on macOS/BSD/most full Linux, but **absent in minimal containers** (Alpine, slim images). Fall back to the `time` builtin there. See §7. |
| `hyperfine` **[optional]** | `hyperfine -w 3 '<cmd>'` | Purpose-built benchmarker with warmup + stats. Use if installed; not assumed. |
| `date` | avoid `date +%N` for timing | **Trap:** `%N` (nanoseconds) is GNU-only; BSD/macOS `date` may print literal `N` or nothing. Use the bench script instead. |

### Counting

| Question | Pattern |
|----------|---------|
| How many matching lines? | `grep -c PATTERN file` (counts *lines*, not matches; a line with 2 hits counts once) |
| How many total occurrences? | `grep -o PATTERN file \| wc -l` |
| How many lines total? | `wc -l < file` (use `< file` so no filename is printed) |
| How many files match? | `grep -rl PATTERN . \| wc -l` |
| How many errors in a log? | `grep -c -iE 'error\|fatal\|panic' app.log` |
| Distribution of a field | `awk '{print $N}' file \| sort \| uniq -c \| sort -rn` |

### Structured log markers (for later extraction)

Emit machine-greppable markers so you can measure after the fact instead of eyeballing:

```
# In the code under test, print a stable prefix + key=value pairs:
#   METRIC phase=load ms=812 rows=10432
#   METRIC phase=index ms=94  rows=10432
# Then extract without re-running:
grep '^METRIC ' run.log | awk '{for(i=1;i<=NF;i++) print $i}'
# Or pull one field's numbers for stats:
grep '^METRIC ' run.log | sed -n 's/.* ms=\([0-9]*\).*/\1/p' | sort -n
```

Rules for markers: **stable prefix** (grep anchor), **key=value** (order-independent),
**one event per line** (line-oriented tools), **units in the key** (`ms=`, `bytes=`).

### Binary-search instrumentation (localization)

When something is slow/wrong somewhere in a long path and you don't know where: place a
timestamp/counter marker at the **midpoint**, run, and see which half owns the cost/defect.
Recurse into that half. Each step halves the search space — ~log₂(N) probes to localize.
(This is the measurement analogue of `git bisect`; for the *defect* version of bisection see
fable-debugging-playbook.)

```
log_marker() { printf 'MARK %s t=%s\n' "$1" "$(date +%s)" >&2; }   # whole-second granularity
# ...insert log_marker "A", log_marker "B" around the suspected span; diff the timestamps.
# For sub-second spans, emit from inside the program with a hi-res clock, not shell `date`.
```

---

## 4. Interpreting numbers (how measurement lies)

The number is real; your reading of it may not be. Watch for these:

| Trap | What happens | Countermeasure |
|------|--------------|----------------|
| **Single-run trust** | One run lands on a lucky/unlucky moment; you generalize from N=1. | Never trust one run. N≥5–10; report the spread. |
| **Noise vs signal** | The change is smaller than run-to-run variance. | Compare the *effect size* to the *stddev*. If effect < ~1σ, it's inside the noise. |
| **Outliers / cold start** | First run pays cache/JIT/connection warmup cost. | Use warmup runs (discard first). Report **median**, which resists outliers, alongside mean. |
| **Averages hide bimodality** | Mean of 10ms and 1000ms is 505ms — a value that never occurs. | Look at the distribution, not just the mean. Report min/median/max or percentiles; histogram if you can. |
| **Sampling bias** | You measured the easy inputs, or a non-representative time window. | Match the sample to production reality: input mix, size distribution, concurrency, time of day. |
| **Survivorship in logs** | The log looks clean because failures crashed/were dropped *before* logging, or a filter hides them. | Count what you expect to see, not just what's there. Reconcile: attempts vs successes vs logged lines. |
| **Correlation vs causation** | Two metrics move together in a dashboard; you infer one caused the other. | A dashboard shows association. Establish causation by *intervening* (change one thing, hold rest) — see fable-hypothesis-and-experiment. |
| **Aggregation window smearing** | A 5-min-averaged graph flattens a 10-second spike to invisibility. | Zoom the time resolution to match the event you're hunting; averages over the wrong window erase the signal. |
| **Unit / scale confusion** | ms vs µs, MiB vs MB, per-request vs total. | Put the unit in the metric name and in the marker key. Re-derive expected order of magnitude (see fable-first-principles-analysis). |

**Golden habit:** before comparing before/after, run the baseline **twice** and compare it to
itself. The gap between two baseline runs *is* your noise floor. Any "improvement" smaller than
that gap is unproven.

---

## 5. Eyeball-failure table (when visual inspection lies)

These are the specific cases where "I looked at it and it's fine" is wrong. Each has P-mode
relevance noted.

| You see | Why the eye is fooled | Measure instead | Defends |
|---------|----------------------|-----------------|---------|
| **A small diff** | Byte-small ≠ semantics-small: one flipped operator, boundary, or default changes behavior everywhere. | Run the affected behavior before/after; diff the *outputs/metrics*, not the source. | P3, P4 |
| **A quiet log** | Errors are swallowed (bare `except`, `catch {}`, `2>/dev/null`), or the log level hides them. | Count expected vs actual events; grep for swallow patterns; raise verbosity and re-run. | P1, P3 |
| **A green test suite** | Tests don't exercise the real path, were weakened to pass, or mock the thing that broke. | Observe the actual end-to-end behavior, not the test's verdict (see fable-verification-standards). | P1, P3 |
| **A correct-looking UI** | Rendered view ≠ underlying state: cached/optimistic render, stale store, not yet persisted. | Inspect the state/store/DB, not the pixels. Reload from source of truth. | P1 |
| **A "0 errors" dashboard** | The panel filters, samples, or lags; or errors are counted under a different name. | Query the raw event store for the window; confirm the panel's own definition. | P1 |
| **A fast local run** | Local has warm caches, small data, no network/contention. | Measure on representative data/load; state the conditions. | P1, P2 |
| **A plausible number** | It "looks about right" but you never sanity-checked the magnitude. | Derive the expected order of magnitude independently (see fable-first-principles-analysis); a 100× gap means a bug in code *or* in measurement. | P2 |

---

## 6. Baseline discipline for regressions

Goal: make **"did I break it?"** a question with a data answer instead of a vibe.

Before touching anything you might regress, **capture current behavior as data** and save it
to a file (not to memory, not to scrollback):

```
# Capture a behavioral/perf baseline into a timestamped, reproducible artifact.
# BENCH is the timing script (Perl). Set it once to wherever this skill is installed;
# it runs against your current working directory. Adjust the path as needed:
BENCH="perl $HOME/.claude/skills/fable-diagnostics-and-measurement/scripts/repeat-bench.pl"
mkdir -p .measure
$BENCH -n 10 -- <the-command> | tee .measure/baseline.txt   # perf baseline
<the-command> > .measure/baseline.out 2>&1                  # behavior baseline

# ...make your change...

<the-command> > .measure/after.out 2>&1
diff -u .measure/baseline.out .measure/after.out        # any behavioral drift is now visible
$BENCH -n 10 -- <the-command> | tee .measure/after.txt
```

Rules:

- **Capture before, not after.** Once you've changed the code, the true baseline is gone —
  you can only estimate it, and estimates are where regressions hide.
- **Save to files, keep them.** A baseline you have to re-derive from memory isn't a baseline.
  Put them under an ignored dir (e.g. `.measure/`); do not commit unless the repo wants
  fixtures.
- **Golden-output diffing** answers "did behavior change" for anything with deterministic
  output. If output is nondeterministic, normalize first (sort, strip timestamps/PIDs/paths)
  and record the normalization.
- **A regression is any unexplained delta** — slower, different output, more log lines, higher
  memory. Explain every delta or treat it as a bug. Do not wave away "it's probably noise"
  without checking it against your noise floor (§4).

This is the measurement counterpart to change control: keep the diff minimal *and* prove it
didn't move the numbers. Change classification and reversibility live in
fable-scope-and-change-control; this skill owns the *did-the-numbers-move* proof.

---

## 7. Shipped tool: `scripts/repeat-bench.pl`

An N-run timing harness. It is a **Perl program, not a shell script** — run it with `perl`
(or directly as `./repeat-bench.pl`); running `sh repeat-bench.pl` fails with
`use: command not found`. Uses Perl `Time::HiRes` (Perl core), so no external benchmarker is
required — **wherever Perl exists**. Perl ships on macOS/BSD and most full Linux distros, but
minimal containers (Alpine, slim Debian/Ubuntu images) often omit it: check `command -v perl`
first, and if it's missing, fall back to the `time` builtin plus the manual protocol in §2.

Invoke it by its installed path — skills deploy under `~/.claude/skills/` (personal) or a
project's `.claude/skills/` (project-local); adjust the path to wherever this skill lives. It
runs against your current working directory:

```
perl ~/.claude/skills/fable-diagnostics-and-measurement/scripts/repeat-bench.pl \
     [-n RUNS] [-w WARMUPS] -- CMD [ARGS...]
  -n RUNS      timed runs        (default 10)
  -w WARMUPS   discarded warmups (default 1)
```

- Sends the command's stdout/stderr to `/dev/null`; reports only timing.
- Prints **min / median / max / mean / stddev** in ms, plus **CV** (coefficient of variation =
  stddev/mean); CV > ~10% flags a noisy measurement — trust the median and quiet the machine.
- Counts non-zero exits and warns if any run failed (a failed run's timing is meaningless).

Example (verified as of 2026-07-13):

```
$ perl scripts/repeat-bench.pl -n 6 -- sleep 0.05
runs=6 warmups=1 failures=0  (times in ms)
  min        55.78
  median     58.54
  max        60.83
  mean       58.52
  stddev      2.00  (CV 3.4%)
  NOTE: CV > ~10% means high noise; trust median over mean, and
        rerun on a quiet machine before comparing to a baseline.
```

**Limits (read before trusting it):** (1) It measures **wall-clock** time of the whole process
including shell/fork startup (~a few ms) — for very fast commands that overhead dominates;
benchmark a batch, not a single trivial call. (2) The command is run via `sh -c`, so arguments
containing spaces or shell metacharacters are re-parsed by the shell — wrap
complex commands in a quoted string or a small script. (3) It times, it does not measure CPU,
memory, or I/O — use `/usr/bin/time -l` (BSD) or `/usr/bin/time -v` (GNU) for those, noting the
flags differ by platform. (4) Warmup defaults to 1; increase `-w` for JIT/cache-heavy workloads.

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| A functional bug: wrong output, crash, hang — you need the root cause, not a number. | fable-debugging-playbook |
| Deciding what counts as "done" / evidence a change works end-to-end. | fable-verification-standards |
| Designing an experiment where a hypothesis must predict numbers before you run. | fable-hypothesis-and-experiment |
| Estimating an expected value from first principles (before you have any measurement). | fable-first-principles-analysis |
| Establishing how the project builds/tests/runs at all (no metric yet). | fable-environment-recon |
| Writing up the measured result with calibrated, no-oversell language. | fable-reporting-and-writing |
| Keeping the change minimal / gating destructive edits. | fable-scope-and-change-control |

Boundary note: this skill owns **how to obtain and read a number** (metric, baseline,
variance, noise). fable-hypothesis-and-experiment owns **the reasoning around the number**
(predict-before-run, one mechanism explains all observations, adversarial refutation). If you
are *taking* the measurement, you are here; if you are *deciding what it means for a theory*,
go there.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|-------------|--------|--------------|
| Core rule, measurement protocol, interpretation traps, baseline discipline | First-principles reasoning about experimental method and common statistics errors. | Sanity-check against any standard benchmarking/statistics reference; these are stable. |
| Anti-eyeball / P1–P4 framing | User-reported AI-agent pain points dated 2026-07-13 (P1 unverified completion, P2 hallucinated specifics, P3 shallow patch, P4 unrequested rewrite). | Confirm the four failure modes still match with the maintainer. |
| `repeat-bench.pl` behavior + example output | Written and executed in this session (macOS, Perl 5, 2026-07-13); the §7 output block is real (the tool always prints the CV NOTE lines). It is Perl, not sh. | Run `perl scripts/repeat-bench.pl -n 6 -- sleep 0.05` and confirm it prints a min/median/max/mean/stddev block. |
| `date +%N` is GNU-only; `grep -c` counts lines; `/usr/bin/time` flags differ (`-l` BSD / `-v` GNU) | Documented POSIX/GNU/BSD tool behavior; verified `date +%N` and `perl -MTime::HiRes` on the authoring machine. | On a target box: `date +%N` (literal `N` ⇒ BSD), `man time`, `grep --version`. |
| `hyperfine` as optional | Real third-party tool; deliberately not assumed present. | `command -v hyperfine`. |
| Sibling skill names / boundaries | Fable Thinking library inventory (as of 2026-07-13). | Re-check names if the library is reorganized. |

Re-verification cadence: the tool/flag row is the only volatile part — re-check when moving to
an unfamiliar platform. The methodology rows are first-principles and should not drift.
