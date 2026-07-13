---
name: fable-debugging-playbook
description: "Load when hunting the cause of a bug, defect, crash, wrong output, or failing test — symptoms like works-locally-fails-elsewhere, intermittent or flaky, worked-yesterday, off-by-one, wrong-data-vs-wrong-code, config or env mismatch, cache or staleness, concurrency or race. Use it whenever you are tempted to add a try/except to silence an error, loosen a test until it passes, or sprinkle retries/sleeps to mask a race — this skill fences those traps and drives you to the root cause via reproduce, minimize, localize, discriminating experiment, and one-mechanism confirmation. Do NOT use it for general research hypotheses about a system's behavior (use fable-hypothesis-and-experiment), for a bug that has resisted several honest attempts and needs a staged assault (use fable-hard-problem-campaign), or for deciding what counts as proof a fix works (use fable-verification-standards)."
---

## 繁中摘要

- 這是「找出 bug 根本原因」的方法論技能，專門防守 P3（用淺層補丁掩蓋問題，而非修正根因）。
- 核心是一個編號迴圈：可靠重現 → 縮小重現 → 定位（依層級／時間／輸入二分）→ 提出能「預測觀察結果」的假設 → 執行有鑑別力的實驗 → 確認單一機制能解釋「所有」現象 → 修正根因 → 驗證原症狀消失且無回歸。
- 附有「症狀 → 分診表」，涵蓋常見失敗類別（本地正常他處失敗、間歇性、昨天還好、邊界、資料錯 vs 程式錯、環境不符、快取過期、並行競態）。
- 明確「圍籬封鎖」四條錯誤捷徑：try/except 吞錯、放寬測試、加 retry/sleep 掩蓋競態、只修症狀點不修污染源。每條說明為何誘人、為何後患更大、正確做法。
- 「停止繼續挖」規則：連續 2–3 個假設失敗後，回頭用 fable-ground-truth 重新驗證你對系統的假設，並擴大搜尋範圍。
- 邊界：一般假設方法論看 fable-hypothesis-and-experiment；驗證標準看 fable-verification-standards；久攻不下看 fable-hard-problem-campaign。

---

# fable-debugging-playbook

Root-cause debugging. A bug is a contradiction between what the system does and
what its rules say it should do. Your job is not to make the symptom disappear —
it is to find the single mechanism that produces it, and remove that mechanism.

**This skill exists to defend against P3: shallow patching instead of root
cause.** Silencing an error, weakening a test, or masking a race makes the
symptom vanish while the defect stays live and resurfaces later, usually
somewhere harder to trace. This playbook is the discipline that stops that.

**Jargon, defined once:**
- **Repro** — a procedure that makes the bug appear on demand.
- **Repro rate** — fraction of runs of the repro that actually fail (100% =
  deterministic; anything less = intermittent/flaky).
- **Localize** — narrow *where* the defect lives (which layer, commit, input,
  or moment in time) before deciding *what* it is.
- **Discriminating experiment** — a test whose outcome is *different* under two
  competing hypotheses, so its result eliminates at least one. A test both
  hypotheses predict the same way tells you nothing.
- **Root cause** — the earliest point in the causal chain where, if you change
  it, the symptom cannot occur. Symptom site ≠ root cause.

---

## The debugging loop (the method you own)

Run these in order. Do not skip forward — most wasted debugging time is a fix
attempted before the bug was localized.

| # | Step | Done when |
|---|------|-----------|
| 1 | **Reproduce reliably** | You can trigger the bug on demand and state its repro rate. |
| 2 | **Minimize the repro** | You have the *smallest* input / config / code path that still fails. |
| 3 | **Localize** | You know which layer, commit, or input boundary the defect lives behind. |
| 4 | **Hypothesize (predict)** | Each candidate cause makes a concrete, checkable prediction about what you'll observe. |
| 5 | **Run the discriminating experiment** | One observation has eliminated at least one hypothesis. |
| 6 | **Confirm one mechanism explains ALL observations** | Including the weird, "unrelated", and negative ones. No leftovers. |
| 7 | **Fix the cause** | The change removes the mechanism, not the symptom's visibility. |
| 8 | **Verify** | Original symptom gone AND no regression introduced (see fable-verification-standards). |

### Step 1 — Reproduce reliably

You cannot fix on demand a bug you cannot trigger on demand. First priority is a
repro, not a fix.

- Capture the exact command, input, environment, and expected-vs-actual result.
- If it is intermittent, **measure the repro rate** before touching anything.
  Ship this with the skill: `flaky-runner.sh` runs a command N times and tallies
  pass/fail. Invoke it by its installed path — skills deploy under `~/.claude/skills/`
  (personal) or a project's `.claude/skills/`; adjust to wherever this skill lives, and
  run it from where your test command runs:
  `sh ~/.claude/skills/fable-debugging-playbook/scripts/flaky-runner.sh 50 <your test command>`
  turns "it fails sometimes" into "fails 18/50 = 36%". That number is your baseline; a
  real fix drives it to 0/50, not "I ran it once and it passed".
- If you genuinely cannot reproduce, that IS the finding — the bug depends on a
  variable you have not identified (data, timing, environment). Localize *that*.

### Step 2 — Minimize the repro

Shrink until nothing more can be removed without the bug disappearing.

- Delete inputs, config, steps, and code paths one at a time.
- Each deletion is itself a discriminating experiment: if the bug survives, what
  you removed was irrelevant; if it vanishes, you just found something load-
  bearing. Either outcome is progress.
- A one-line repro is worth more than a paragraph of description.

### Step 3 — Localize before you theorize

Narrow *where* before deciding *what*. Three portable bisection axes:

| Bisect by | Technique | Portable command pattern |
|-----------|-----------|--------------------------|
| **Time (history)** | Binary-search the commit that introduced it | `git bisect start; git bisect bad; git bisect good <known-good-rev>` — then mark each checkout, or automate with `git bisect run <cmd-exit-0-if-good>` |
| **Layer** | Confirm the value at each boundary (input → parse → compute → store → output); the defect is between the last correct boundary and the first wrong one | Log/print the value at each layer; compare to the value you *derived* it should be |
| **Input** | Binary-search the failing input: does half of it still fail? | Halve the dataset/string/config repeatedly |

Localizing by instrumentation and measurement (adding counters, timing, taps) is
its own discipline — see **fable-diagnostics-and-measurement** for how to
instrument without perturbing what you measure.

### Step 4 — Hypothesize by predicting

A hypothesis you cannot check against an observation is a guess. State each
candidate cause as: *"If cause C is true, then when I do X I will observe Y."*

The general discipline of predicting-before-observing and one-mechanism-explains-
all is owned by **fable-hypothesis-and-experiment**; here you apply it narrowly
to a single defect. Write down 2–3 competing hypotheses, not one — a single
hypothesis you can only confirm is how confirmation bias hides the real cause.

### Step 5 — Run the discriminating experiment

Pick the experiment whose outcome *differs* between your live hypotheses, and run
it. If two hypotheses predict the same result, that experiment cannot separate
them — design a different one.

Example shape: hypothesis A says "the cache returns stale data"; hypothesis B
says "the writer never wrote". Discriminating experiment: read the underlying
store directly, bypassing the cache. Stale data present → A is dead, B lives.
Store empty → B is dead, A lives.

### Step 6 — One mechanism must explain ALL observations

Before you fix, force yourself to account for **every** observation with a
*single* mechanism — including the ones that seem unrelated, and the negative
results (the things that did NOT happen).

- If your explanation covers the main symptom but leaves a "weird" log line, an
  off timestamp, or an intermittent second failure unexplained — you are not
  done. Unexplained residue is where the real cause hides.
- Two mechanisms invoked to explain two observations is a smell. Prefer the one
  cause that produces both.

### Step 7 — Fix the cause

Change the earliest point in the causal chain that removes the mechanism. Keep
the diff minimal and targeted — do not rewrite surrounding code you were not
asked to touch (that is P4; see **fable-scope-and-change-control**). A root-cause
fix is usually *smaller* than a symptom patch, not larger.

### Step 8 — Verify

- Re-run the original repro; the symptom must be gone. For an intermittent bug,
  re-run `flaky-runner.sh` and require 0 failures over at least as many runs as
  your baseline used.
- Run the surrounding tests to catch regressions.
- **What counts as sufficient proof — the evidence hierarchy and definition of
  done — is owned by fable-verification-standards.** Claiming "fixed" without
  observing the actual behavior end-to-end is P1, the failure this library was
  built to stop.

---

## Symptom → triage table

Start here when you have a symptom but no theory. Each row: the first
discriminating question, and the usual culprit families.

| Symptom | First question to split it | Usual culprits |
|---------|---------------------------|----------------|
| **Works locally, fails elsewhere** | What differs between the two environments? Diff env vars, versions, paths, data, permissions. | Env/config mismatch; absolute paths; missing dependency; version skew. See fable-environment-recon. |
| **Intermittent / flaky** | What is the repro rate? What is *not* controlled between runs? | Ordering/timing, shared mutable state, uninitialized value, network, clock, random seed, concurrency. |
| **Worked yesterday** | What changed since? `git log`/`git bisect` your code AND check external drift (deps, data, upstream API, clock, expiring token/cert). | New commit; dependency auto-update; data change; expired credential; date-dependent logic. |
| **Off-by-one / boundary** | Does it fail only at the first/last/empty element? | Inclusive-vs-exclusive bounds; length vs index; empty-collection edge; fencepost. |
| **Wrong data vs wrong code** | Is the *input* to the failing step already wrong, or is correct input mishandled? Inspect the value at the boundary. | If input already wrong → localize upstream. If input right, output wrong → the fault is *here*. |
| **Config / env mismatch** | Which config is *actually* loaded at runtime (not which you think)? Print the effective value. | Wrong file precedence; env var shadowing; default silently used; profile not applied. |
| **Cache / staleness** | Does bypassing the cache / clearing it change the result? | Stale cache, memoization, build artifact, CDN, stale lockfile, browser/DNS cache. |
| **Concurrency / race** | Does it disappear under a single thread / added delay / forced ordering? (Confirms a race; a delay is a *diagnostic*, never the fix.) | Unsynchronized shared state; check-then-act; missing await; resource contention; ordering assumption. |

---

## Fenced wrong paths (do NOT take these)

These are the shortcuts that make P3 costly. Each is *tempting* because it makes
the symptom vanish immediately — and expensive because the defect stays live and
resurfaces later, detached from its cause. The stories below are **archetypal
illustrations of the pattern, not records of specific real events.** The master
catalog of real, documented AI-agent failure incidents is
**fable-failure-archaeology**.

### 🚫 Silencing the error with try/except (or equivalent swallow)

- **Tempting because:** the stack trace disappears and the run goes green.
- **The pattern:** you wrap the failing call, swallow the exception, return a
  default. The corrupted or missing value flows downstream; days later it
  surfaces as a wrong result in a report nobody connects back to the swallowed
  error. You now have two bugs and no stack trace.
- **Do instead:** let it fail loudly at the source; read the trace; fix why the
  call failed. If a failure is genuinely expected and recoverable, handle *that
  specific* case explicitly and narrowly — never blanket-catch to make red go
  away.

### 🚫 Loosening a test until it passes

- **Tempting because:** the suite goes green and you can "move on".
- **The pattern:** the test asserted `== 42`; it now returns 41; you change the
  assertion to `41`, or widen it to `>= 0`, or delete it. You have not fixed the
  bug — you have destroyed the one instrument that detects it and encoded the
  bug as the new "correct" behavior.
- **Do instead:** treat the failing test as a *true report*. Either the code is
  wrong (fix the code) or the test's expectation is genuinely outdated for a
  *deliberate, requested* reason (then update it consciously and say so). Editing
  a test to pass without either is P3.

### 🚫 Adding retries / sleeps to mask a race

- **Tempting because:** a `sleep(1)` or a retry loop makes the flaky failure go
  away *most* of the time.
- **The pattern:** the real defect is an ordering assumption. The sleep makes the
  bad ordering *less likely*, not impossible. It comes back under load, on slower
  hardware, or in CI — now intermittently and rarely, which is far harder to
  debug than the original reliable-ish failure.
- **Do instead:** a delay is a *diagnostic* — if a sleep fixes it, you have
  confirmed a race. Then fix the race: synchronize the shared state, await the
  real signal, or enforce the ordering. Remove the sleep.

### 🚫 Fixing the symptom site instead of the corrupting source

- **Tempting because:** the crash is on line 200, so line 200 looks like the bug.
- **The pattern:** a value went bad at line 40 and only *manifests* at line 200.
  You clamp/patch line 200. The bad value still flows everywhere else it is used;
  you fixed one of its many symptoms.
- **Do instead:** trace the bad value *backward* to where it was first wrong
  (Step 3, localize by layer). Fix it there.

### 🚫 "It's probably the framework / library / OS" — before checking your own code

- **Tempting because:** it externalizes the bug and excuses you from reading your
  own diff.
- **The pattern:** you assume a mature, widely-used dependency is broken. The
  overwhelming prior is that the bug is in the new, unique code — yours.
- **Do instead:** exhaust your own code first. Only suspect the dependency after
  you have a *minimal repro that isolates the dependency's behavior* from your
  code — at which point you can also report it upstream credibly.

---

## The stop-digging rule

When you have run **2–3 hypotheses and each discriminating experiment came back
negative**, stop generating new hypotheses inside your current mental model. The
model itself is probably wrong. This is a heuristic threshold, not a guarantee —
adjust for the size of the problem, but do not ignore it.

Do this instead:

1. **Re-verify your assumptions about the system.** You are likely holding a
   false belief about an API, a default, a path, a version, or what a config key
   actually does. Verify each against reality — do not trust memory. This is
   exactly what **fable-ground-truth** is for. A wrong assumption here makes
   *every* downstream hypothesis untestable.
2. **Widen the search.** You may have localized to the wrong layer. Re-open Step
   3: instrument one boundary further out, or bisect on a different axis.
3. **Question the repro.** Are you sure the thing you are reproducing is the same
   bug the report describes? Re-read the original symptom.
4. **If it still resists** after honest re-verification and widening, this is no
   longer routine debugging — it is a hard problem. Switch to the staged,
   decision-gated assault in **fable-hard-problem-campaign**.

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| General research question about how a system behaves (not a defect) | fable-hypothesis-and-experiment |
| Bug has resisted several honest debugging passes; needs a staged campaign | fable-hard-problem-campaign |
| Deciding what evidence proves a fix actually works | fable-verification-standards |
| Root cause is a false belief about an API/flag/path/version | fable-ground-truth (then return here) |
| You need to instrument/measure to localize | fable-diagnostics-and-measurement |
| "Fails only in this environment" and you must map the build/run setup | fable-environment-recon |
| The fix is turning into an unrequested rewrite | fable-scope-and-change-control |
| Cataloguing a *settled* failure so no session re-fights it | fable-failure-archaeology |

---

## Quick checklist (paste into your working notes)

- [ ] I can reproduce on demand; repro rate = ____
- [ ] Repro is minimized (nothing else removable)
- [ ] Localized to a layer / commit / input boundary
- [ ] 2–3 competing hypotheses, each with a prediction
- [ ] Ran the experiment whose outcome *differs* between them
- [ ] ONE mechanism explains every observation, including the weird/negative ones
- [ ] Fixed the cause (earliest point in the chain), minimal diff
- [ ] Original symptom gone (re-ran repro); no regressions
- [ ] Did NOT: swallow the error, loosen a test, add a masking sleep/retry, patch the symptom site, or blame the framework unchecked

---

## Provenance and maintenance

| Claim class | Source |
|-------------|--------|
| The debugging loop, minimize/localize/discriminate ordering, one-mechanism rule | First-principles reasoning about causal inference; standard debugging method, not tool-specific. |
| Symptom → triage table | First-principles enumeration of universal failure classes; culprit families are common-knowledge categories, not measured statistics. |
| Fenced wrong paths | Archetypal patterns illustrating P3 (shallow patching); stories are illustrative, NOT logged real events. Real documented incidents live in fable-failure-archaeology. |
| P1–P4 failure modes; the "defends P3" framing | User-reported pain points (as of 2026-07-13) that motivated this library. |
| `git bisect` usage, POSIX `sh` in flaky-runner.sh | Standard, verified tool behavior. Script tested against `sh` and `dash` with deterministic-pass, deterministic-fail, ~50% coin-flip, bad-N, N=0, and STOP_ON_FAIL cases before shipping (as of 2026-07-13). |
| Sibling skill names / boundaries | Library inventory (as of 2026-07-13). |

**Re-verification actions (do these if things drift):**
- Re-check that every sibling skill name referenced here still exists in the
  library index; a renamed skill becomes a dead cross-reference.
- Re-run `scripts/flaky-runner.sh` edge cases if the shell environment changes:
  `sh flaky-runner.sh 5 true` (expect all pass, exit 0),
  `sh flaky-runner.sh 3 false` (expect all fail, exit 1),
  `sh flaky-runner.sh 0 true` (expect usage error, exit 2).
- Re-check `git bisect` invocation against current git docs if git's CLI changes
  (stable for years as of 2026-07-13).
- Re-check the skill frontmatter format (exactly two keys: name, description)
  against current Claude Code skill docs if the loader changes.
