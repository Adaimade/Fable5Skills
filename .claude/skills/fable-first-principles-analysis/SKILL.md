---
name: fable-first-principles-analysis
description: "Load when you are about to accept a number, a scaling behavior, or a system's output as correct WITHOUT first deriving what it SHOULD be — before profiling, load-testing, sizing a buffer/cache/timeout, trusting a latency/memory/throughput figure, reviewing an algorithm's cost, or believing a dedupe/losslessness claim. Use it to compute the expected order of magnitude by hand (back-of-envelope), state and check invariants (conservation, monotonicity, idempotency), derive Big-O scaling before load-testing, reason about boundary/extreme cases (0, 1, max, empty, duplicate, negative, unicode), catch unit/dimension mismatches (ms vs s, bytes vs KB), and prove impossibility by counting/pigeonhole. Do NOT load for how to TAKE a measurement or read noisy numbers (use fable-diagnostics-and-measurement), for designing an experiment where a specific mechanism must predict a number (use fable-hypothesis-and-experiment), or for confirming an API/flag/path is real (use fable-ground-truth)."
---

## 繁中摘要

- 這個技能是「先推導、再量測」的手工推理工具箱：任何數字、擴展行為或系統輸出，在相信它之前，先用第一性原理算出「它應該是多少」。
- 鐵律：推導在前、量測在後。當推導與量測不合時，代表你某個假設是錯的——那個落差是最有價值的訊號（可能是程式錯，也可能是量測錯）。
- 六個配方，各附通用範例與失敗模式：(1) 數量級估算 (2) 不變量推理（守恆／單調／冪等）(3) 複雜度分析（Big-O）(4) 邊界／極端值 (5) 單位／量綱檢查 (6) 計數／鴿籠不可能性證明。
- 直接防守 P2（幻覺數值：獨立推導能抓出憑空捏造或算錯的值，100 倍落差＝程式或量測有 bug）與 P1（沒推導過期望值，就無法判斷觀察到的結果是否正確）。
- 量測機制（如何計時、變異、雜訊）交給 fable-diagnostics-and-measurement；針對特定機制預測數字交給 fable-hypothesis-and-experiment。
- 何時不要用：只是要「取得」一個數字、設計對照實驗、或確認 API/路徑是否存在，各有對應姊妹技能。

---

# Fable First-Principles Analysis

**Derive what the answer should be, then look. When derivation and observation disagree, one of your assumptions is wrong — and that gap is the most informative signal you have.** It tells you the bug is either in the code (the system is misbehaving) or in the measurement (you measured the wrong thing) — and either way you have learned something you could not have learned by staring at the number alone.

This is a thinking toolkit, not a tool to run. Its whole point is that a value you *computed independently* is worth more than a value you *installed a library to print*. It directly defends two library failure modes:

- **P2 (hallucinated/wrong specifics):** an independent derivation is the cheapest lie-detector you have. If the code says 40 ms and first principles say ~500 ms, one of them is fabricated — the guessed constant, the assumed batch size, or the measurement. A ~100× gap is never "close enough"; it is a bug in the code *or* in the derivation.
- **P1 (claiming completion without verification):** you cannot know an observed result is *correct* if you never worked out what correct would look like. "The test passed" and "the number came back" are not the same as "the number is what the physics of this system forces."

---

## The law (read first)

> **Derivation FIRST. Measurement SECOND.**
> Before you measure, load-test, or trust an output, compute the order of magnitude it *should* have. Then compare. A match is a weak confirmation; a mismatch is a strong, specific lead — go find which assumption broke.

Corollaries:

- A derivation is a **falsifiable prediction about your own system**, so it obeys the same honesty rules as any prediction: write it down *before* you look (see fable-hypothesis-and-experiment for the predict-before-run discipline applied to a specific mechanism; this skill owns the general derivation toolkit).
- You do not need a *precise* answer. You need the **right power of ten**. "Should be seconds, not milliseconds" catches more real bugs than a spreadsheet accurate to 3 significant figures.
- Every derivation rests on assumptions (constants, sizes, rates). When it disagrees with reality, **list the assumptions and find the wrong one** — do not discard the derivation. The disagreement *is* the discovery.

---

## The toolkit at a glance

| # | Technique | Reach for it when… | One-line question it answers |
|---|-----------|--------------------|------------------------------|
| 1 | **Back-of-envelope estimation** | About to trust or measure a latency / memory / size / throughput figure | "What order of magnitude *should* this be?" |
| 2 | **Invariant reasoning** | A bug is hard to localize, or you're validating data/state | "What must ALWAYS hold here — and does it?" |
| 3 | **Complexity analysis** | About to load-test, or reviewing a loop/query | "How does cost grow as input grows?" |
| 4 | **Boundary / extreme-case** | Writing or reviewing anything that takes input | "What does the spec force at 0, 1, max, empty, dup, negative?" |
| 5 | **Dimensional / unit sanity** | Any formula, config value, or converted quantity | "Do the units and magnitudes line up?" |
| 6 | **Counting / pigeonhole** | A claim of losslessness, uniqueness, or fit-in-space | "Is this even *possible*, by counting?" |

Each recipe below: **when to use → steps → worked example (derive expected → contrast wrong observation → gap localizes) → failure modes.**

---

## Recipe 1 — Back-of-envelope estimation

Estimate the order of magnitude a quantity *should* have from a handful of known constants, before you measure it.

**When to use:** before profiling; before sizing a buffer, cache, timeout, or instance; whenever a reported latency / memory / throughput / cost figure is about to be believed.

**Steps:**
1. Name the dominant cost. Most systems are dominated by one term (the sequential round-trips, the bytes moved, the per-item allocation). Ignore the rest at first.
2. Pull the constants you're sure of — and only those. Round-trip ~0.1–10 ms depending on locality; a record is tens–hundreds of bytes; a modern core does ~10⁸–10⁹ simple ops/sec. Mark each as an assumption.
3. Multiply through, keeping units explicit (see Recipe 5).
4. Round to the nearest power of ten. That is your expected magnitude.
5. Compare to the observed/claimed value. Same order → weak pass. Off by ≥10× → a lead: which assumption or which layer is lying?

**Worked example (latency from sequential IO):**
- Derive: a request makes **50 sequential** dependent DB calls, each ~10 ms round-trip. Expected ≈ 50 × 10 ms = **500 ms**. If the calls could be batched/parallel, expected drops toward one round-trip (~10 ms).
- Contrast: the dashboard shows p50 = **40 ms**. That is ~12× *below* the "50 sequential" derivation.
- Gap localizes: 40 ms cannot come from 50 sequential 10 ms hops — so either the calls are **not** sequential (already batched — good, update the model), or the 10 ms constant is wrong (calls hit a warm local cache, not the DB), or the dashboard is sampling only cache hits (a P1 measurement trap). Each is a concrete next probe. The number stopped being a mystery.

**Worked example (memory from records × size):**
- Derive: load **10⁷ records** at ~**200 bytes** each → 10⁷ × 200 = 2×10⁹ bytes = **~2 GB** resident, minimum, before per-object overhead.
- Contrast: the box has 1 GB and the job is expected to "fit in memory."
- Gap localizes: it *cannot* fit — the derivation proves an OOM or heavy swapping is structural, not a tuning issue. You now know to stream/paginate, not to bump a heap flag. (This is also a counting argument; see Recipe 6.)

**Failure modes:**
- **Estimating the wrong dominant term** (counting CPU when the system is IO-bound). Sanity-check *which* resource dominates before multiplying.
- **False precision** — chasing 3 significant figures hides that you're off by a power of ten. Round early.
- **Serial vs parallel confusion** — N calls cost N round-trips only if dependent; independent calls collapse toward one. State which.
- **Forgetting overhead** at the extreme: per-object/allocator/serialization overhead can be 2–10×; your estimate is a *floor* unless you add it.

---

## Recipe 2 — Invariant reasoning

An **invariant** is a property that must hold at every valid state — before and after every operation. Checking an invariant localizes a bug faster than stepping through code, because a violation points at *where* reality diverged from the rules, not just *that* it did.

Define the three you will use most:
- **Conservation:** a total is neither created nor destroyed by an operation. `sum(balances)` is unchanged by a transfer; `items_in + items_created == items_out + items_remaining`.
- **Monotonicity:** a quantity only ever moves one direction. A version counter never decreases; a cache's insert count never drops; a timestamp sequence never goes backward.
- **Idempotency:** applying an operation twice equals applying it once. `f(f(x)) == f(x)`. Retries, sync, and "apply config" steps are supposed to be idempotent.

**When to use:** a bug you can't localize by reading; validating incoming/stored data; reviewing a state machine, ledger, cache, queue, or sync path; deciding whether a retry is safe.

**Steps:**
1. Write the invariant as an equation or inequality over observable state — one line.
2. Decide where it must hold (loop boundary, after each transaction, at API entry/exit).
3. Instrument a **cheap assertion / check** at those points (an `assert`, a logged `CHECK total=… expected=…`, a validation query). See fable-diagnostics-and-measurement for emitting greppable markers.
4. Run. The **first** point where the invariant is false is adjacent to the mechanism. Everything before it is exonerated; the defect is between the last good check and the first bad one.

**Worked example (conservation localizes a lost-update bug):**
- Invariant: for a money transfer, `sum(all balances)` is **conserved** — it must be identical before and after.
- Derive expected: before = after, always. The delta must be exactly 0.
- Contrast: after a batch of concurrent transfers, `sum` dropped by the amount of ~1 transfer.
- Gap localizes: a non-zero delta means value was destroyed — the classic signature of a lost update (two transactions read-modify-write the same row without a lock/atomic op). You didn't need to trace every transfer; the conservation check said "value leaked here," and the *size* of the leak (~1 transfer) says how many collisions happened. Now go to fable-debugging-playbook to reproduce and fix the race — do **not** paper it with a retry (that masks P3).

**Failure modes:**
- **Asserting a non-invariant:** "the list is always sorted" may be false by design between steps. Confirm it truly must always hold, or scope it to the exact points where it must.
- **Floating-point equality:** conservation of floats needs a tolerance (`abs(delta) < ε`), not `==`.
- **Checking too coarsely:** an end-only check tells you *that* it broke, not *where*. Add interior checks to bisect (measurement-side bisection lives in fable-diagnostics-and-measurement).
- **Silencing the assertion** when it fires because it's "annoying" — that is P3 (masking the symptom). A firing invariant is a gift; follow it.

---

## Recipe 3 — Complexity analysis

**Big-O** names how cost grows as input size *n* grows, ignoring constants: O(n) = linear (double n, double cost), O(n²) = quadratic (double n, 4× cost), O(log n) = grows very slowly, O(1) = flat. Derive it by reading the code, before you ever load-test.

**When to use:** before load/scale testing; reviewing any loop, recursion, or query that runs over a collection; explaining why something is fine at n=100 and dies at n=10⁶.

**Steps:**
1. Find the loops/recursion over the input. Multiply nested depths: a loop of n containing a loop of n is n×n = O(n²).
2. Watch for **hidden inner loops**: an `x in list` membership test is O(n); a substring search, a `.index()`, a per-item DB/API call, a re-sort inside a loop — each hides a factor of n (or more).
3. Write the total as a function of n; keep only the fastest-growing term (n² dominates n).
4. Predict the shape: plot expected cost at n, 10n, 100n. O(n) → 10× per step; O(n²) → 100× per step.
5. Load-test only to *confirm the shape*, not to discover it (measurement mechanics: fable-diagnostics-and-measurement).

**Worked example (accidental O(n²) from a membership scan):**
- Code: for each of n incoming ids, check `if id in seen_list` (a list), then append. Membership on a list is O(n); doing it n times is **O(n²)**.
- Derive expected: at n = 10⁴, that's ~10⁸ comparisons — ~0.1–1 s. At n = 10⁵ it's ~10¹⁰ — tens of seconds to minutes. The prediction: **100× slower for every 10× more input.**
- Contrast: it's instant on the 200-row test fixture, so it shipped.
- Gap localizes: the fixture (n=200 → ~4×10⁴ ops, trivial) never exercised the quadratic term. Production n=10⁵ hangs exactly as the O(n²) derivation predicts. Fix: replace the list with a **set/hash** — membership becomes O(1), total O(n), and 10⁵ ids finish in milliseconds. The derivation both explained the hang and named the fix (change the data structure, not the hardware).

**Failure modes:**
- **Constants can dominate at your real n.** O(n²) with a tiny constant can beat O(n log n) for small n. Big-O is about *growth*, not about which is faster at n=50 — pair it with Recipe 1 to check the actual regime you run in.
- **Amortized vs worst case:** hash lookup is O(1) *amortized* but O(n) on a pathological collision/resize. Note which you're claiming.
- **Hidden costs in library calls:** a one-line `sorted()`, `in`, or ORM access can carry the loop. Don't count only the loops you wrote.
- **Ignoring the other input dimension:** cost may be O(n·m) (rows × columns, items × retries). One variable can hide the blow-up.

---

## Recipe 4 — Boundary / extreme-case analysis

Push each parameter to its extreme and **derive the correct behavior from the spec**, then test that the code does it. Bugs cluster at edges because that's where off-by-ones, empty branches, and overflow live.

**The extremes to sweep (checklist):**

| Push it to… | Classic bug it exposes |
|-------------|------------------------|
| **0 / empty** | division by zero, average of nothing, `first()` on empty, loop that never runs |
| **1 / singleton** | pluralization, "join with comma" degenerating, off-by-one at the single element |
| **max / overflow** | integer/counter overflow, buffer/window limit, timeout at the ceiling |
| **negative / signed** | unsigned assumptions, `abs`, backwards ranges, epoch/before-epoch dates |
| **duplicate / repeated** | dedup logic, unique-key assumptions, set-vs-list confusion |
| **unicode / non-ASCII / empty string** | byte-vs-char length, encoding, normalization, injection |
| **huge / streaming** | load-it-all-in-memory assumptions (ties to Recipe 1) |

**Steps:** for each relevant extreme, (1) read the **spec/contract** for what *should* happen, (2) predict the code's output, (3) run that exact input, (4) any mismatch is a boundary bug.

**Worked example:** a function returns the average of a list. Boundary = empty list. Spec says "return 0 for no data" (or "raise EmptyInput"). Derive: with 0 elements the code computes `sum/len = 0/0`. Contrast: the code has no empty guard. Gap localizes: it will divide-by-zero / return NaN on the empty case — a crash that the happy-path tests (which always pass ≥1 element) never reach. The extreme *is* the bug's home.

**Failure modes:** testing only "typical" inputs (the happy path is where bugs hide *least*); treating a boundary crash as an edge case to ignore rather than a spec violation to fix; forgetting that "max" for one field interacts with "empty" for another (combine extremes).

---

## Recipe 5 — Dimensional / unit sanity

Check that units and magnitudes are consistent across a formula, a config value, or a converted quantity. A silent unit mismatch is one of the most common invisible bugs — nothing errors; the number is just wrong by a fixed factor.

**Steps:** (1) attach a unit to every quantity (ms, s, bytes, KB, req/s); (2) carry units through the arithmetic — they must cancel to the unit you expect (bytes ÷ s = B/s; ms × count = ms); (3) check the resulting magnitude is plausible (Recipe 1); (4) a wrong unit shows up as a suspiciously round factor: **1000× (s↔ms, KB↔bytes), 60× (s↔min), 1024 vs 1000, 8× (bits↔bytes)**.

**Worked example:** a config sets `timeout: 30`. The library treats the field as **seconds**; the caller assumed **milliseconds**. Derive: intended 30 ms, actual 30 s — a **1000×** gap. Contrast: requests that should time out fast now hang for 30 seconds. Gap localizes: the round 1000× factor is the fingerprint of an s/ms unit mismatch — check the field's documented unit, don't tune the value. (This is why fable-diagnostics-and-measurement insists on putting the unit *in* the metric name: `ms=`, `bytes=`.)

**Failure modes:** dropping the unit and comparing bare numbers; mixing SI (1000) and binary (1024) for "KB/MB"; assuming an API's unit instead of reading it (that's a fable-ground-truth check — verify, don't guess the unit).

---

## Recipe 6 — Counting / pigeonhole (impossibility proofs)

The **pigeonhole principle:** if you put N items into M containers and N > M, at least one container holds ≥2 items. Use it to prove something *cannot* work before you try to build or trust it — the cheapest possible refutation.

**When to use:** any claim of losslessness, uniqueness, perfect dedup, or "it fits," involving a fixed-size space (hash width, id space, cache slots, bits).

**Steps:** (1) count the things you must distinguish (N); (2) count the distinct labels/slots available (M); (3) if N > M, collisions/loss are **forced** — the claim is impossible as stated; (4) report the impossibility and the minimum viable space.

**Worked example:** "we dedupe 10 billion events losslessly by their **32-bit** hash." Count: distinct 32-bit values M = 2³² ≈ **4.3×10⁹**. Items N = 10¹⁰ = **10×10⁹**. Since N (10 billion) > M (4.3 billion), by pigeonhole **at least** two distinct events *must* share a hash. Therefore dedup-by-32-bit-hash **cannot** be lossless — it will silently drop real events on collision. No experiment needed; the counting settles it. Fix: widen the key (64/128-bit) so M ≫ N, or dedup on the full identity. This same argument proves "10⁷ × 200 B won't fit in 1 GB" (Recipe 1) — counting is the backbone of both.

**Failure modes:** counting the *typical* load instead of the *maximum* (pigeonhole is about the worst case); ignoring that even N ≪ M gives collisions with meaningful probability (the birthday effect — pigeonhole gives the hard *impossibility* bound, not the *safe* threshold); forgetting a fixed-width int/hash is a bounded space at all.

---

## The meta-rule, expanded — mind the gap

When your careful derivation and your careful measurement disagree, resist the two easy exits: "the derivation is just theory" and "the measurement must be noise." Instead, treat the gap as the highest-value clue in the investigation:

| The gap says | Because | Your next move |
|--------------|---------|----------------|
| **The code is wrong** | Reality violates what the design forces (invariant broken, O(n²) where O(n) intended). | Localize the mechanism → fable-debugging-playbook. |
| **The measurement is wrong** | You measured the wrong thing, wrong units, wrong sample, warm cache. | Re-instrument → fable-diagnostics-and-measurement; recheck units (Recipe 5). |
| **The derivation's assumption is wrong** | A constant/size/rate you assumed doesn't hold (calls are batched; records are 2 KB not 200 B). | Update the model; the corrected model is now a better tool. |

Exactly one of these is true, and finding *which* is the whole payoff. A ~100× disagreement is never rounding error — it is a bug in one of the three places, and the gap has already narrowed your search to those three. This is why derivation comes first: without an expected value, an observed value can be arbitrarily wrong and you would never know (that is P1 at its root, and P2 when the wrong value was fabricated by memory or a hallucinated constant).

---

## Fast checklist (before trusting a number or a design)

- [ ] I derived the **expected order of magnitude** before looking at the measured one.
- [ ] I wrote the derivation's **assumptions** down (constants, sizes, rates, serial-vs-parallel).
- [ ] For anything that scales, I have a **Big-O** and a predicted shape (10× input → ? cost).
- [ ] I stated the **invariants** and checked them at the points they must hold.
- [ ] I swept the **boundaries** (0, 1, max, empty, dup, negative, unicode) against the spec.
- [ ] **Units** carry through and the magnitude is plausible; no stray 1000×/1024×/8×.
- [ ] Any "lossless/unique/fits" claim survived a **counting/pigeonhole** check.
- [ ] Derivation and measurement **agree**; if not, I found which of code/measurement/assumption is wrong — I did **not** wave the gap away.

---

## When NOT to use this skill (load the sibling instead)

| Situation | Load instead |
|-----------|--------------|
| You need to actually *take* a measurement, control the run, read variance/noise | fable-diagnostics-and-measurement |
| A specific *mechanism* must predict a number and you'll run a discriminating experiment | fable-hypothesis-and-experiment |
| You must confirm an API / flag / path / unit / version is *real* | fable-ground-truth |
| You have a known-broken behavior to reproduce and root-cause | fable-debugging-playbook |
| You're deciding whether a shipped change is truly done end-to-end | fable-verification-standards |
| You're establishing how the project builds/tests/runs at all | fable-environment-recon |
| You're attacking a large hard problem needing phased, gated campaign | fable-hard-problem-campaign |

**Boundaries with the closest siblings:**
- **fable-diagnostics-and-measurement** owns *obtaining and reading* a number (metric, baseline, variance). This skill owns *deriving what the number should be* before you obtain it. You use this one, then it, then compare.
- **fable-hypothesis-and-experiment** owns predicting a number *for a specific causal mechanism under test* and the predict-before-run/refute lifecycle. This skill is the general **derivation toolkit** it calls on to produce those predictions ("expected magnitude / complexity from first principles").
- **fable-debugging-playbook** *uses* invariant reasoning (Recipe 2) as one localization technique; it owns the full reproduce→localize→fix loop for a known defect. Come here for the derivation methods themselves.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|-------------|--------|--------------|
| The law (derivation-first, the gap is the signal) and the meta-rule table | First-principles reasoning about inference and modeling | Stable; no drift expected. |
| The six recipes (estimation, invariant, complexity, boundary, dimensional, counting) | Standard engineering/CS first-principles technique (order-of-magnitude estimation, loop invariants, Big-O, boundary testing, dimensional analysis, pigeonhole) | Stable, textbook-level; sanity-check against any algorithms/estimation reference. |
| Worked-example arithmetic: 50×10 ms=500 ms; 10⁷×200 B=2 GB; list-membership loop=O(n²), ~10⁸ ops at n=10⁴; 30 s vs 30 ms=1000×; 2³²≈4.3×10⁹ < 10¹⁰ | Computed and checked in this session (2026-07-13) with a calculator, not from memory | Recompute the products; they are pure arithmetic and must hold exactly. |
| Rule-of-thumb constants (round-trip 0.1–10 ms; ~10⁸–10⁹ simple ops/sec/core; record tens–hundreds of bytes) | First-principles orders of magnitude, deliberately given as *ranges* to adapt per system | These are starting anchors to replace with the target system's real constants — never ship them as the answer. |
| P1 / P2 framing (unverified completion, hallucinated specifics) | User-reported AI-agent pain points (dated 2026-07-13) | Confirm the four library failure modes still match with the maintainer. |
| Sibling skill names / boundaries | Fable Thinking library inventory (as of 2026-07-13) | Re-check names against the current skills/ directory if the library is reorganized. |

No scripts are shipped with this skill **by design**: its subject is deriving values *by hand*, and a bundled calculator would undercut the message. The techniques are prose recipes to be applied with a scratch calculation, not a command to run. (Measurement automation lives in fable-diagnostics-and-measurement's `repeat-bench.pl`.)
