---
name: fable-verification-standards
description: "Load when you are about to say done, fixed, working, passing, or complete — or when reviewing whether a change is actually finished. Enforces the definition of done and the evidence hierarchy: what counts as proof a change works, and the rule that claim strength must never exceed evidence strength. Use before every completion claim; when tests are green but you have not run the actual feature; when deciding whether integration or end-to-end observation is required; when defining acceptance criteria before implementing. Defends against claiming completion without verification (one of the costliest AI-agent failures, P1). Do NOT use for root-cause debugging technique (see fable-debugging-playbook), for how to phrase or calibrate a report once you know the claim (see fable-reporting-and-writing), or for how to instrument and measure numbers (see fable-diagnostics-and-measurement)."
---

## 繁中摘要

- 本技能定義「完成」的標準：宣稱強度絕不可超過證據強度（claim ≤ evidence）。這是防止「宣稱修好卻沒實際跑過」這個最昂貴失誤之一（P1）的核心。
- 提供「證據層級表」：從「看起來對」到「編譯通過、單元測試、整合測試、真實執行環境端到端觀察、對照原始症狀驗證」，每一級只允許你說出對應的話。
- 提供「完成前流程」與兩個範本：完成宣稱範本（跑它→觀察→對照原始需求）與降級宣稱範本（無法端到端驗證時，明確列出已驗證/未驗證項目並降低宣稱）。
- 提供「反向空間檢查」（這次改動弄壞了什麼）與「測試綠了但功能壞了」的失敗清單（症狀→為何測試說謊→鑑別檢查）。
- 界線：本技能決定證據容許哪種宣稱；措辭與語氣交給 fable-reporting-and-writing，量測方法交給 fable-diagnostics-and-measurement，根因除錯交給 fable-debugging-playbook。

---

# Verification Standards: the definition of done

**Purpose.** This skill stops one of the costliest AI-agent failures (P1): declaring a task complete without observing the actual behavior. "It should work" is not "it works." A green test suite is not a working feature. This skill gives you the one rule, the evidence ladder, and copy-paste templates that force the loop closed before you type "done".

**The one rule (memorize it):**

> **Claim strength must never exceed evidence strength.**

Every completion statement is a claim. Every claim sits at a rung on the evidence ladder below. You may only make the claim your *actual observed evidence* licenses — not the claim you *expect* to be true. If you have not run the thing, you have not verified the thing, and you may not say it is fixed.

This skill owns the **evidence → claim rule and the definition of done**. It does not own how to *word* the final claim once you know it (that is `fable-reporting-and-writing`), nor how to *measure* numbers (that is `fable-diagnostics-and-measurement`).

---

## 1. The evidence hierarchy

Read bottom-to-top: each rung is *strictly stronger* than the one below and licenses a *strictly stronger* claim. The right column is the ONLY sentence you are allowed to say at that rung. Saying anything from a higher rung than your evidence supports is a hallucinated completion claim.

| # | Evidence you actually have | What it proves | Claim you are LICENSED to make | What it does NOT prove |
|---|---|---|---|---|
| 0 | "The code looks right" — you read it | Nothing. You have a hypothesis. | "I *believe* this should work; unverified." | That it parses, runs, or is correct. |
| 1 | It compiles / builds / lints / typechecks | Syntax and types are consistent | "It builds." | That it does the right thing at runtime. |
| 2 | A unit test over the changed code passes | The unit behaves as the test asserts | "The unit behaves as tested." | That the test covers the change, or that the feature works. |
| 3 | Integration / higher-level tests pass | Components agree at their seams | "The tested paths integrate." | That the real end-user flow works. |
| 4 | You ran the actual feature in the real runtime and observed the intended behavior | The feature works in the environment you observed | "The feature works in runtime (observed: …)." | That it fixes the *original* reported problem. |
| 5 | You reproduced the ORIGINAL symptom/requirement, applied the change, and observed the symptom gone / requirement met | The reported problem is actually resolved | "The reported problem is gone (before: …, after: …)." | Nothing further — this is done. Still smoke adjacent behavior (§3). |

**How to use the table mid-task:** before writing any completion sentence, find the highest rung you have *observed evidence* for. Your sentence must come from that rung's "Licensed" column or weaker. If your intended sentence is higher, you are not done — climb the ladder or downgrade the claim (§5).

**Rung 5 is the most-missed rung.** A change can make the feature run cleanly (rung 4) and still not touch the actual reported symptom — you fixed *a* thing, not *the* thing. "Feature works" ≠ "the bug the user reported is fixed." Always close back to the original ask.

---

## 2. The completion protocol

Run this every time before you say "done", "fixed", "working", or "complete". No exceptions for "trivial" changes — trivial changes are where unobserved breakage hides.

**Checklist:**

- [ ] **Re-read the original ask.** What exact symptom/requirement started this? Write it down verbatim.
- [ ] **Run the actual thing** in the real runtime — the command, the endpoint, the UI flow, the CLI invocation the user would use. Not a test that stands in for it; the thing itself.
- [ ] **Observe the behavior** with your own eyes/tools. Capture the concrete output (log line, HTTP status + body, exit code, screenshot text, printed value).
- [ ] **Compare observation against the original ask.** Does the observed behavior satisfy the *specific* thing that was requested — not a nearby thing?
- [ ] **Run the negative-space checks** (§3): what might this have broken?
- [ ] **State the claim at the rung your evidence supports** (§1), and **put the observation in the report.** A completion claim with no observation attached is unverified by definition.

**Completion claim template (rung 4–5):**

```
Done. Original ask: <verbatim requirement/symptom>.
Change: <one line of what you changed>.
Verification: I ran <exact command / flow>. Observed: <concrete output>.
Before: <symptom present, e.g. "returned 500 / value was 3">.
After:  <symptom gone,   e.g. "returns 200 with {..} / value is 5">.
Adjacent checks: <suite run + result, smoke of neighbor behavior>.
```

If you cannot fill the `Observed` / `After` lines with something you actually saw, you are not at rung 4–5. Go to §5.

---

## 3. Negative-space checks: what did the change break?

A change is not "the diff you intended" — it is "the diff you intended PLUS every behavior that depended on the old code." Verifying the happy path proves you added the feature; it says nothing about what you subtracted.

Before claiming done, spend proportional effort on the negative space:

| Check | How | Why it catches breakage |
|---|---|---|
| Run the existing test suite | The project's full/relevant test command | Regressions in code you did not think you touched |
| Smoke the adjacent behavior | Exercise the feature *next to* your change, not just your change | Shared helpers, shared state, shared config broken as a side effect |
| Re-run the exact old happy path | The flow that worked before your change | You fixed case B but broke case A |
| Check the error/edge paths | Empty input, missing file, unauthorized, timeout | Happy-path fix that removed a guard |
| Diff review for scope creep | `git diff --stat` then read the diff | Accidental edits, debug prints, commented-out code left in |

If you cannot run the suite (no suite, can't build it), say so explicitly in the report — do not silently skip it and imply it passed. See `fable-scope-and-change-control` for the discipline of keeping the diff minimal so the negative space stays small in the first place.

---

## 4. "Tests green but broken" failure catalog

Green tests are rung 2–3 evidence, not rung 4–5. These are the recurring reasons a passing suite coexists with a broken feature. When tests pass but you have not observed the feature, run the discriminating check before trusting the green.

| Symptom | Why the tests lie | Discriminating check |
|---|---|---|
| Tests pass, feature still broken when run for real | The test does not exercise the changed code path | Add/point a test at the exact change, OR run the real flow (rung 4). Coverage of the *line*, not the *file*. |
| Passes locally, fails in reality | Mocks/stubs replace the thing that actually fails (network, DB, clock, filesystem) | Run once against the real dependency, or in an integration environment. Ask: "what did this mock assume?" |
| Passes but you changed something else since | Stale build / stale cache — tests ran against old artifacts | Clean build (`git clean -n` to preview; remove build/ caches), rebuild, re-run. Confirm the binary/bundle timestamp is post-edit. |
| Passes here, breaks there | Wrong environment — different OS, version, env vars, config, feature flags | Verify in the target runtime. Print the actual versions/flags in play (route to `fable-environment-recon`). |
| Passes because the test was weakened | Assertion loosened, case deleted, or `skip`/`xfail` added to make it green | Diff the test files too. A test edit that makes a failing test pass is a red flag — see `fable-debugging-playbook` (test-weakening trap). |
| Passes but asserts the wrong thing | Test checks a proxy (status 200) not the requirement (correct body) | Assert the actual requirement, then observe it at rung 4–5. |

This catalog is a **pre-completion checklist**, not an incident log. The full narrated incidents (symptom → root cause → evidence → countermeasure → status) live in `fable-failure-archaeology`; cross-ref there when you want the war stories.

---

## 5. When end-to-end verification is impossible

Sometimes you genuinely cannot reach rung 4–5: no runtime access, no test environment, a hardware dependency, a destructive side effect you must not trigger, credentials you must not use. That is a legitimate state. What is NOT legitimate is *claiming* rung 4–5 anyway.

**Protocol when you cannot fully verify:**

1. **Say so explicitly.** Do not imply verification you did not do. Silence reads as "verified" — break the silence.
2. **Downgrade the claim** to the highest rung you actually reached.
3. **List exactly what was and was not verified**, and why the gap exists.
4. **State what would close the gap** so the next person (or the user) can finish it.

**Downgrade template:**

```
Partial. Original ask: <verbatim>.
Change: <one line>.
VERIFIED: <rung + evidence, e.g. "rung 3 — integration tests pass, output: …">.
NOT VERIFIED: <the specific gap, e.g. "real production runtime behavior against live data">.
Reason gap remains: <no staging access / would send real email / no GPU here>.
Claim downgraded to: <the weaker sentence you are actually licensed to say>.
To close the gap: <exact step someone with access must run and what they should observe>.
```

An honest downgrade is a *success* of this skill, not a failure of the task. `fable-reporting-and-writing` governs the surrounding tone; this skill governs the truth content of the claim.

---

## 6. Acceptance-threshold discipline: define done BEFORE you build

You cannot verify against a target you never set. The most common way a completion claim goes wrong is that "done" was never defined, so any plausible-looking result gets rationalized as success.

**Before implementing, write the acceptance criteria:**

- [ ] **Observable and specific.** "The endpoint returns 200 with the user's name" — not "it works better."
- [ ] **Tied to the original ask**, not to a proxy you find convenient to hit.
- [ ] **Measurable where numbers matter.** If success is "faster" / "less memory" / "fewer errors", pin the number and the method *now* — how you will measure, baseline, and the threshold that counts as pass. The *how* of measuring (baselines, variance, noise, sampling) is owned by `fable-diagnostics-and-measurement` — route there; do not re-derive it here.
- [ ] **Includes the negative bound.** "…and the existing X flow still works." Success that breaks a neighbor is not success.

Writing these down before you code turns verification from a vague vibe-check into a checklist you either pass or fail. It also stops post-hoc goalpost-moving, where "done" quietly drifts to match whatever you happened to produce.

---

## 7. Worked example: the same fix at every rung

A user reports: *"The `/report` endpoint returns 500 for users with no orders."* You change the code so the empty-orders case returns an empty list instead of dereferencing null.

Watch the claim you are licensed to make climb with the evidence:

| What you did | Rung | Claim you may make | Claim you may NOT make |
|---|---|---|---|
| Read your patch, it looks correct | 0 | "I believe this handles the empty case; unverified." | "Fixed." |
| Project builds, types check | 1 | "It builds." | "The 500 is fixed." |
| Unit test for empty-orders passes | 2 | "The empty-orders branch behaves as tested." | "The endpoint works." |
| API integration test on `/report` passes | 3 | "The `/report` tested paths integrate." | "The reported 500 is gone." |
| You `curl`ed `/report` as a no-order user, saw `200 []` | 4 | "The endpoint works in runtime — observed `200 []`." | "The user's problem is solved" *(you tested a synthetic no-order user, not their actual case)*. |
| You reproduced the ORIGINAL 500 with the user's actual reported input, applied the fix, saw `200` with correct body | 5 | "The reported 500 is gone — before: 500 on user X's input, after: 200 with `[…]`." | — (done) |

The trap most agents fall into: they reach rung 2 (unit test green) and write "Fixed the 500." That is a rung-5 claim backed by rung-2 evidence — a hallucinated completion. The unit test proves the *branch* works; it says nothing about whether the *endpoint* still 500s for some other reason (auth middleware, serialization, a second null two lines down). Only rung 4–5 — actually hitting the endpoint — can retire the claim.

**Also note rung 4 vs 5:** hitting `/report` with *a* no-order user (rung 4) is not the same as reproducing the *user's specific reported case* (rung 5). If their 500 came from a different empty-state (no orders AND no profile), your rung-4 test misses it. Close back to the original input whenever you can obtain it.

---

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| You need to find *why* something is broken (reproduce, localize, root cause) | `fable-debugging-playbook` |
| You know the claim but need to *phrase* the report / calibrate tone / lead with outcome | `fable-reporting-and-writing` |
| You need to *measure* numbers — instrument, baseline, handle variance/noise | `fable-diagnostics-and-measurement` |
| You are worried the change itself is too large / destructive / out of scope | `fable-scope-and-change-control` |
| You need to establish how the project builds/tests/runs before you can verify anything | `fable-environment-recon` |
| You want the narrated catalog of past failure incidents | `fable-failure-archaeology` |
| You need the master loop that decides which skill to load when | `fable-operating-core` |

This skill answers exactly one question: **"Given what I actually observed, what am I allowed to claim, and is that enough to say done?"**

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| The one rule (claim ≤ evidence) and the evidence hierarchy | First-principles reasoning about proof strength; distilled from Fable-5 working methodology | Stable reasoning; revisit if the rung ordering is ever contested in review. |
| Completion / downgrade templates | First-principles design to force observation into the claim | Adjust wording if reports show fields being left blank in practice. |
| "Tests green but broken" catalog | User-reported pain points (dated 2026-07-13): P1 (completion without verification), P2 (hallucinated runbooks), P3 (shallow patches) | Add rows as new green-but-broken modes are observed; keep it a checklist, not incidents. |
| Negative-space checks | First-principles reasoning about diffs as add + subtract | Stable. |
| Acceptance-threshold discipline | First-principles; measurement how-to delegated | Re-check the boundary with `fable-diagnostics-and-measurement` if that skill's scope shifts. |
| Sibling skill names and boundaries | Fixed library inventory (as of 2026-07-13) | Re-check sibling names if any skill is renamed; update the "When NOT to use" and cross-refs. |
| Shell hints (`git diff --stat`, `git clean -n`) | Standard git usage | Portable; `git clean -n` is dry-run (preview only) and safe. Re-verify only if git CLI conventions change. |

**Scope note:** No scripts ship with this skill by design. A portable "verify your change" script would be theater — real verification is inherently project-specific (the command, flow, and runtime differ every time). This skill teaches the discipline; the sibling `fable-environment-recon` provides the portable recon script for discovering *how* a given project builds and runs.
