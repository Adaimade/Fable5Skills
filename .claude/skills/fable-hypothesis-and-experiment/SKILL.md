---
name: fable-hypothesis-and-experiment
description: "Load when you are investigating WHY something behaves as it does and are about to run an experiment, benchmark, or test to decide between explanations — performance regressions, deciding which of several mechanisms causes an intermittent failure, 'is X faster than Y', 'is the cause A or B', tuning, or any research question where you might otherwise eyeball a result and declare victory. Use it to force a written hypothesis, a numeric prediction made BEFORE running, a discriminating experiment with pre-committed interpretation, adversarial self-refutation, and a hunch->adopted-or-retired lifecycle. Do NOT load for pure root-cause debugging of a known-broken behavior (use fable-debugging-playbook), for how to instrument or read numbers (fable-diagnostics-and-measurement), for establishing ground-truth facts about APIs/paths (fable-ground-truth), or for deciding done-ness of a shipped change (fable-verification-standards)."
---

## 繁中摘要
- 這個 skill 教你用「科學方法」做研究型調查：任何要靠實驗/基準測試/測試來判斷「為什麼」或「哪個假設對」的情況都適用。
- 鐵律：一個假設只有在「單一機制能解釋所有觀察（含負面結果與怪異離群值）」且「你真心嘗試推翻它卻失敗」後才被接受。
- 流程：寫下假設 → 先預測數字（跑之前）→ 設計能區分對立假設的實驗 → 預先承諾解讀（看到 A 就 H1、看到 B 就 H2）→ 執行 → 即使失望也如實記錄。
- 反向反駁：接受結論前切換角色，主動找替代機制、混淆變因、巧合；多代理時指派獨立 refuter（見 fable-orchestration-and-delegation）。
- 想法生命週期：hunch → 書面假設 → flag/branch 後的實驗 → 證據審查 → 採用（走 change control）或「寫明理由後退役」（避免殭屍想法復活）。
- 常見自我欺騙：只挑會支持的測試、看到第一個支持結果就停、反覆重跑到過關、事後編故事硬套。

---

This skill is the **research method**: how to move from "I have a theory about why this happens" to a conclusion you have earned the right to believe. It defends the four library failure modes at their research-shaped root: a hypothesis "confirmed" without a prediction is P1 (unverified completion); a mechanism asserted from memory is P2 (hallucination); the first supporting result accepted as proof is P3 (shallow); a rewrite justified by an untested theory is P4 (destructive).

Jargon, defined once:
- **Hypothesis**: a falsifiable claim that ONE named mechanism causes the observed behavior.
- **Mechanism**: the single specific cause-and-effect chain you claim is at work (not "something in the cache" — *which* thing, doing *what*).
- **Prediction**: what that mechanism forces you to observe, stated as a number/rate/ordering, written down BEFORE you run.
- **Discriminating experiment**: an experiment whose *possible* outcomes fall into different buckets for different hypotheses, so the result actually tells you which one is right (an experiment all your hypotheses predict the same result for teaches nothing).
- **Confound**: a second variable that changed at the same time and could explain the result instead of your mechanism.

---

## The evidence bar (stated as law)

> A hypothesis is accepted only when **ONE mechanism explains ALL observations — including the negative results and the weird outliers — and has survived a genuine attempt to refute it.**

Unpack every word, because each clause fences off a real failure:

| Clause | What it forbids |
|---|---|
| **ONE mechanism** | Two hand-wavy causes stitched together ("maybe caching AND the network"). If you need two, you have two hypotheses — test them separately or find the single deeper cause. |
| **explains ALL** | Cherry-picking the runs that fit. The one benchmark that went the "wrong" way is not noise until you have *shown* it is noise. |
| **including negatives & outliers** | Sweeping the disconfirming data point under the rug. A mechanism that cannot say why case C did *not* reproduce is incomplete. |
| **survived a genuine attempt to refute** | Stopping at the first result that agrees with you. You have not tested a theory until you have tried to kill it and failed. |

If any clause is unmet, the status is **open**, not "probably right". Say so plainly (see fable-reporting-and-writing for calibrated language).

---

## Weak vs strong: what a real hypothesis looks like

The single most common failure is calling a vague feeling a hypothesis. A strong hypothesis names ONE mechanism, is falsifiable, and forces a number you can check *before* running. Contrast:

| Weak (a mood — untestable) | Strong (one mechanism, falsifiable, numeric) |
|---|---|
| "the cache is slow" | "hit rate is <0.5 at 100 keys **because** eviction is FIFO not LRU, so re-requesting the 101st-oldest key always misses" |
| "it's probably a memory thing" | "RSS grows ~1 MB per request **because** each request appends to a list never cleared; predict linear growth, no plateau" |
| "X is faster than Y" | "X beats Y **because** it skips a per-item allocation; predict the gap grows with item count, ~constant per-item saving" |
| "the deploy broke it" | "commit abc123 added an N+1 query; predict query count scales 1:1 with result rows" |
| "the test is flaky" | "the test fails **when** task A finishes before task B; predict failure rate rises as A's work shrinks, ->0 when A is delayed" |

Litmus test: if you cannot state the observation that would prove it WRONG, and cannot attach a rough number to what you expect, it is not yet a hypothesis. Sharpen it before you spend a single run. Vague hypotheses are how P1 (unverified "fixed it") and P3 (shallow patch) get started.

---

## The protocol (run it in order — do not skip to "run")

Use `hypothesis-log.sh` to scaffold each record; append them to a running `HYPOTHESES.md` in your working notes. Invoke it by its installed path — skills deploy under `~/.claude/skills/` (personal) or a project's `.claude/skills/`; adjust to wherever this skill lives: `sh ~/.claude/skills/fable-hypothesis-and-experiment/scripts/hypothesis-log.sh`.

1. **Write the hypothesis down.** One sentence, one mechanism, falsifiable. If you cannot write what result would prove you *wrong*, it is not yet a hypothesis — it is a mood.
2. **Derive the prediction — BEFORE running anything.** What does this mechanism *force*? Put a number on it wherever you can: "if the N+1 query is the cause, request count scales with row count, so 10x rows -> ~10x queries and ~10x latency". A prediction written after seeing the result proves nothing (see "narrative overfitting" below). For deriving expected magnitudes from first principles, route to fable-first-principles-analysis.
3. **Design the discriminating experiment.** Pick the test whose outcomes *separate* your rivals. If H1 and H2 predict the same number, that experiment is wasted — find the input where they diverge. Change ONE variable; hold the rest fixed (a confound is a silent second change).
4. **Pre-commit to interpretation.** Write the outcome map before you run: *"if I see A -> H1; if I see B -> H2; if neither -> back to observation."* This is the single most important step — it stops you from bending whatever you see into a confirmation.
5. **Run.** Once. Then again to check it is stable (see fable-diagnostics-and-measurement for noise/variance and how many samples).
6. **Record even when disappointing.** The disappointing result is the valuable one — it eliminates a branch. Log the actual observed value next to the prediction. Do not quietly move on because it "didn't work".

### Worked example (portable, no domain assumed)
- **Observation**: endpoint p95 latency jumped from 40 ms to ~400 ms after yesterday's deploy.
- **Hypothesis**: the new code issues one DB query per result row (an N+1), instead of one batched query.
- **Prediction (before running)**: query count per request ~= result-row count; latency should scale linearly with rows. On a 100-row request expect ~100 queries and ~10x the 10-row latency.
- **Discriminating experiment**: hit the endpoint with 10-row and 100-row inputs; count queries via the DB/query log. Rival H2 = "slow external call" predicts latency *independent* of row count — that is the divergence.
- **Pre-commit**: queries scale with rows -> N+1 (H1). Latency flat vs rows but high -> external call (H2). Neither -> back to observation.
- **Run + record**: observed 12 and 103 queries; latency 45 ms vs 380 ms. Matches H1's prediction, contradicts H2.
- **Refute**: could a cold cache explain it? Re-run warm — still scales with rows. One mechanism (N+1) explains both data points and the negative (H2 ruled out). Accepted -> route to fable-scope-and-change-control to make the fix.

### Worked example 2 — "is X faster than Y?" (comparison, not debugging)
This is the second common research shape: no defect, just a claim to settle. The trap is running one casual timing and declaring a winner.
- **Hypothesis**: approach X is faster than Y for this workload *because* it avoids a per-item allocation.
- **Prediction (before running)**: if the mechanism is allocation, X's advantage should GROW with item count and SHRINK toward zero for tiny inputs; expect roughly constant per-item savings. If X is uniformly ~2x faster regardless of size, the cause is something else (my stated mechanism is wrong even if X wins).
- **Discriminating experiment**: time both across a size sweep (e.g. 1, 10, 1k, 100k items), fixed machine, warm caches, multiple trials each; report medians and spread.
- **Pre-commit**: gap grows with size -> allocation mechanism holds. Gap flat across sizes -> X may still win but for a different reason; do NOT credit allocation. Y wins anywhere it matters -> hypothesis refuted.
- **Refute before believing**: is the "winner" inside the noise? Compare the gap to run-to-run variance (fable-diagnostics-and-measurement). A 3% median win with 8% variance is not a win. Did I compare optimized-vs-debug builds, or warm-vs-cold? Those are confounds, not results.
- **Disposition**: mechanism confirmed -> adopt only if the size regime you actually run in shows the win; otherwise RETIRE with a written why ("X wins only above ~10k items; our inputs are <100 — not worth the complexity, as of 2026-07-13").

---

## Adversarial refutation (do this BEFORE you believe yourself)

Confirmation is cheap; refutation is where truth is made. Before accepting any conclusion, switch roles and genuinely attack it:

- **Alternative mechanism**: name at least one *other* cause that fits the same data. Can your experiment distinguish them? If not, you have not earned the conclusion.
- **Confound hunt**: what else changed between the "before" and "after" you compared? Version, cache state, data volume, machine load, time of day, warm vs cold. List them; rule each out or admit it is uncontrolled.
- **Coincidence check**: how many runs? A 1-in-3 flake "fixed" after one green run is not fixed (see p-hacking below).
- **The ALL test**: point at every observation you have — especially the outlier and the case that did *not* reproduce — and ask "does my one mechanism explain this too?" If one data point needs a second story, your model is wrong or incomplete.

In multi-agent settings, do not self-grade. Assign a **separate refuter** agent whose only job is to break the conclusion, given the same data and blind to your preferred answer. Route to fable-orchestration-and-delegation for how to write that adversarial-panel prompt. A conclusion that survives an independent refuter is far stronger than one you only argued for yourself.

---

## The idea lifecycle

Every investigation moves an idea through fixed stages. Name the current stage out loud; never let an idea skip straight from hunch to merged.

```
hunch  ->  written hypothesis  ->  experiment behind a flag/branch  ->  evidence review
                                                                            |        |
                                                              adopted <-----+        +-----> RETIRED
                                                        (via change control)              (with written why)
```

| Stage | Entry gate | Artifact produced |
|---|---|---|
| **hunch** | a feeling, a smell | a note ("worth checking: ...") |
| **written hypothesis** | one mechanism, falsifiable | a record from `hypothesis-log.sh` |
| **experiment** | prediction written first; change isolated behind a flag/branch so nothing ships yet | outcome vs prediction, logged |
| **evidence review** | refutation attempted; ALL/ONE test passed | supported / refuted verdict |
| **adopted** | verdict = supported AND survived refutation | change made via fable-scope-and-change-control |
| **RETIRED** | verdict = refuted, OR not worth the cost | a written **why** in your notes |

**Retirement is a first-class outcome, not a failure.** A retired idea with a written reason ("tried X; predicted 2x, measured 1.02x; not the bottleneck — do not revisit without new data") prevents **zombie ideas**: the same dead theory getting re-proposed and re-tested every few sessions because nobody recorded that it already lost. Write the why. Date it "(as of 2026-07-13)" style so a future reader knows how stale it is. A settled, catalogued failure belongs in fable-failure-archaeology; a still-open research dead-end belongs in your project notes.

---

## Common self-deceptions (recognize and kill on sight)

| Trap | What it looks like | Countermeasure |
|---|---|---|
| **Confirmation bias in test selection** | You pick the input/benchmark most likely to agree with you. | Choose the *discriminating* input, ideally the one your hypothesis is most likely to FAIL on. |
| **Stopping at first support** | One green run and you declare it solved. | The evidence bar requires surviving refutation, not one agreement. Ask "what would I see if I were wrong?" and go check that. |
| **P-hacking equivalent** | Re-running until it passes, then reporting the pass. Silently discarding "bad" runs. | Pre-commit sample count and pass criterion. Report the full distribution incl. failures. For flaky tests this is fatal — a race masked by reruns is P3. |
| **Narrative overfitting** | Writing the explanation *after* seeing the data so it fits perfectly. | The prediction must be written and timestamped BEFORE the run. A story that only ever fits in hindsight predicts nothing. |
| **Moving the goalposts** | Result disappoints, so you quietly redefine what "success" meant. | The pre-committed interpretation is frozen. If it fails, the hypothesis is refuted — record it, do not re-narrate it. |
| **Single-run stability illusion** | Treating one measurement as the truth. | Repeat; check variance (fable-diagnostics-and-measurement). Noise can dwarf your effect. |

---

## Where good hypotheses come from

You cannot test your way to insight if the hypothesis is bad. The richest sources, in rough order of yield:

| Source | Why it is fertile | Concrete move |
|---|---|---|
| **Recent changes** | Most regressions are caused by what just changed. | Diff the last commits/deploys; the delta is a suspect list. `git log`, `git diff`, bisect. |
| **Working vs broken cases** | The *difference* between a case that works and one that fails localizes the mechanism. | Minimize both to the smallest inputs that still differ; whatever varies between them is your lead. |
| **Boundaries** | Bugs cluster at edges: 0/1/empty/max, first/last, type transitions, timeouts, buffer limits. | Push the input to each boundary and watch where behavior flips. |
| **Invariant violations** | Something that must always hold is not holding; *why* it broke is the hypothesis. | State the invariant, then ask what could make it false (see fable-first-principles-analysis for invariant reasoning). |

For actually *reading* the code/history to mine these leads, see fable-codebase-archaeology; for reproducing and localizing a known break, see fable-debugging-playbook. This skill picks up once you have a lead worth turning into a testable hypothesis.

---

## Fast checklist (before you claim you know why)

- [ ] Hypothesis written as ONE falsifiable mechanism.
- [ ] Prediction written with a number/rate/ordering, BEFORE running.
- [ ] Experiment discriminates — its outcomes separate my rivals.
- [ ] Interpretation pre-committed (A->H1, B->H2, else->neither).
- [ ] Ran enough times to see variance, not one lucky run.
- [ ] Recorded the result even though it was disappointing / partial.
- [ ] Genuinely tried to refute: alternative mechanism, confound, coincidence.
- [ ] ONE mechanism explains ALL observations incl. negatives/outliers.
- [ ] Disposition set: adopted (-> change control) or RETIRED with written why.

If any box is unchecked, the honest status is **open** — say that, do not round up to "done".

---

## When NOT to use this skill (load the sibling instead)

| Situation | Load instead |
|---|---|
| Behavior is known-broken; you need to reproduce and root-cause it | fable-debugging-playbook |
| You need to instrument, benchmark, or interpret noisy numbers | fable-diagnostics-and-measurement |
| You must confirm an API/flag/path/version is real | fable-ground-truth |
| You are deciding whether a shipped change is truly done | fable-verification-standards |
| You need expected magnitudes / complexity from first principles | fable-first-principles-analysis |
| You are running an adversarial multi-agent refutation panel | fable-orchestration-and-delegation |
| You are actually making the adopted change | fable-scope-and-change-control |
| You are cataloguing a settled, recurring failure so it is never re-fought | fable-failure-archaeology |
| You are attacking a large hard problem needing phased, gated campaign | fable-hard-problem-campaign |

Boundary with fable-debugging-playbook: debugging localizes a *known defect* to its cause; this skill governs *research questions* where the answer itself is uncertain ("is A or B the cause", "is X faster than Y"). They share the discriminating-experiment idea; debugging owns the triage/reproduce/localize front end, this skill owns the predict-first / refute / lifecycle discipline.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| Evidence bar (one mechanism, all observations, survived refutation) | First-principles reasoning about inference; standard hypothetico-deductive method | Stable philosophy of science — no drift expected. |
| Predict-before-run, discriminating experiment, pre-committed interpretation | First-principles; adapted from experimental-design practice | Stable. |
| The four library failure modes (P1–P4) and their research-shaped roots | User-reported pain points (dated 2026-07-13) | Re-confirm with maintainer if the library's stated failure modes change. |
| Idea lifecycle stages and retirement-with-why | First-principles reasoning + user pain point that dead ideas get re-fought | Stable; adjust stage names if sibling skills rename gates. |
| Self-deception table (confirmation bias, p-hacking, narrative overfitting, etc.) | Well-documented cognitive/statistical biases; first-principles | Stable. |
| `scripts/hypothesis-log.sh` behavior | Tested on 2026-07-13 (POSIX `sh`, default + arg + append + `sh -n`) on darwin | Re-run `sh -n scripts/hypothesis-log.sh` and a sample invocation if edited. |
| Sibling skill names in cross-references and When-NOT table | Library inventory (as of 2026-07-13) | Re-check names against the current skills/ directory; fix any renamed sibling. |
