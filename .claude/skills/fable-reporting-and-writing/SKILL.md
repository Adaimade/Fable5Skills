---
name: fable-reporting-and-writing
description: "Load when about to WRITE something a person or agent will read and act on — a completion/status report, a handoff to the next session, a PR/commit message, a README, release notes, a design doc, an incident writeup, or a bug summary. Also load when you catch yourself typing 'should work', 'probably fine', or 'looks good', or when a session is ending with work unfinished and you must hand off state. Governs HOW to phrase and structure the message: lead with the outcome, report failures faithfully with the actual output, calibrate every claim so claim strength never exceeds evidence, never oversell, write so a teammate who was not watching can act. Do NOT load it to decide whether a change is done or what evidence a claim needs (see fable-verification-standards), to verify a specific fact/API/path or run an assumption ledger (see fable-ground-truth), or for how to format a skill file itself (see fable-skill-authoring-and-frontier)."
---

## 繁中摘要

- 本技能是「溝通標準」：規範你寫給人或其他 agent 看的任何文字（完成報告、交接文件、PR 說明、README、事故報告）該怎麼措辭與編排。
- 核心契約：先講結果（發生了什麼／發現了什麼），細節放後面；設想讀者沒有在旁邊看你工作。
- 忠實回報：失敗要附上真實輸出，跳過的步驟要聲明，部分驗證要說成部分（「驗證了 X，因為 Z 無法驗證 Y」）；宣稱強度絕不超過證據強度。
- 提供「校準詞彙表」：verified / probable / assumption / speculation 各自的適用時機，並禁用「應該可以」這類空泛信心詞（附可攜式 `scripts/flag-oversell.sh` 輔助掃描）。
- 提供三個範本：完成報告、調查交接、事故報告；以及本 library 自身的 runbook 寫作風格規範。
- 界線：證據層級歸 fable-verification-standards；事實查證與假設帳本歸 fable-ground-truth；skill 檔案格式歸 fable-skill-authoring-and-frontier。本技能只管「措辭與結構」。

---

# Reporting and writing: say what happened, at the strength you can back

**Purpose.** A correct fix badly reported becomes a wrong belief in the reader's head. This skill governs the *communication envelope* around your work: the order you say things, the faithfulness of what you report, and the calibration of every claim. It defends the reader — a teammate or another agent who was **not watching you work** — from two failures: believing something is done when it is not (P1), and being unable to continue because you did not write down what you knew.

**What this skill owns vs. what it routes to.** This skill owns *phrasing and structure*. It does **not** own the truth machinery underneath:

| You need to know… | Owner |
|---|---|
| What observation licenses what claim (the evidence ladder, definition of done) | `fable-verification-standards` |
| Whether a specific API/flag/path/version is real; how to run an assumption ledger and cite sources | `fable-ground-truth` |
| How to format a skill *file* — frontmatter, trigger-rich description, the two-key rule | `fable-skill-authoring-and-frontier` |
| The catalog of past failure incidents (symptom→root cause→countermeasure→status) | `fable-failure-archaeology` |

This skill is where you land *after* those decide the truth: you know what you observed and what you may claim — now say it well.

---

## 1. The reporting contract

Three rules, in priority order. When they conflict, the earlier wins.

**1. Lead with the outcome.** The first sentence states what happened or what you found — the result, not the journey. The reader decides in one line whether to relax, act, or panic. Narrative, method, and detail come *after* and only if they help the reader act.

> Bad: "I started by reading the config, then noticed the parser, then after some digging…"
> Good: "The 500 is fixed — root cause was a null deref in the empty-orders branch. Details below."

**2. Write for someone who was not watching.** You have the whole session in your head; the reader has nothing. Every pronoun with no antecedent ("it works now"), every unnamed file ("the fix"), every implicit environment ("after the rebuild") is a hole the reader falls into. Name the thing, the file, the command, the environment.

**3. Claim strength ≤ evidence strength.** Never phrase a claim stronger than the evidence you actually gathered. This is the wording-side of the rule owned by `fable-verification-standards` — that skill decides *what rung* your evidence reaches; this skill makes sure your *sentence* does not climb higher than that rung. If you observed a unit test pass, you may write "the unit behaves as tested," not "the feature works."

**Structure that satisfies all three (BLUF — Bottom Line Up Front):**

```
<outcome in one line: what happened / what was found>
<evidence: the exact thing you observed, so the reader can trust the outcome>
<what's next / what's unverified / what the reader must do>
<supporting detail, method, narrative — last, skippable>
```

---

## 2. Faithful reporting rules

Faithful means: the report does not create a belief the work does not support. Optimism, omission, and smoothing all violate this even when no single sentence is a lie.

| Rule | Do this | Not this |
|---|---|---|
| **Failures get the real output** | Paste the actual error/stack/exit code you saw | "It didn't work" / silently omit the failure |
| **Skipped steps are declared** | "Did NOT run the integration suite (no staging access)" | Imply the full checklist ran by staying silent |
| **Partial is stated as partial** | "Verified X; could NOT verify Y because Z" | Report X and let the reader assume Y too |
| **Negative results are reported** | "Tried approach A, it did not help — here's the evidence" | Quietly drop the dead branch and show only the win |
| **Uncertainty is surfaced, not hidden** | Label the shaky claim (§3) | Round confidence up to make the report cleaner |
| **The original ask is answered** | Close back to what was actually requested | Answer a nearby easier question and imply it was the ask |

**The silence rule.** A report that omits the failure *reads as* a report where nothing failed. Silence is not neutral — the reader fills it with success. If a step was skipped, a check failed, or a part is unverified, you must *say so out loud*; it is not enough to merely not-claim it.

**Never smooth a failure into a success.** "The tests are mostly passing" hides which ones fail and whether they matter. Report: "138/142 pass; the 4 failures are all in the payments module I did not touch — likely pre-existing, not confirmed." Now the reader can act.

---

## 3. Calibration vocabulary

Every load-bearing claim carries exactly one confidence label. Pick the *weakest* label the evidence forces you to — overclaiming is the failure this library exists to kill. Use these four words with these exact meanings:

| Label | Means | Use when | Example |
|---|---|---|---|
| **VERIFIED** | I observed this directly, this session | You ran it and saw the result with your own tools | "VERIFIED: `curl /report` returns `200 []` for a no-order user." |
| **PROBABLE** | Strong indirect evidence, not directly observed | Same code path as something verified; sound reasoning; one step removed | "PROBABLE: the no-profile case is also fixed — same null-guard, not exercised." |
| **ASSUMPTION** | Taken as true to proceed, not checked | You needed it to move and did not verify it | "ASSUMPTION: prod config matches staging (checked staging only)." |
| **SPECULATION** | A hypothesis / guess | Plausible but unsupported; a lead, not a finding | "SPECULATION: the intermittent timeout may be GC pauses — untested." |

The mechanics of *running* an assumption ledger and *citing* each fact to `file:line` or command output belong to `fable-ground-truth`; this skill governs which of these four words to attach and how to phrase it. The evidence *ladder* that decides whether you have earned VERIFIED belongs to `fable-verification-standards`.

**Banned in any completion or status claim.** These phrases assert confidence while attaching *no observation* — they are the linguistic signature of P1 (claiming done without verifying). Replace each with a calibrated claim:

| Banned phrase | Why it's poison | Say instead |
|---|---|---|
| "should work" / "ought to work" | Predicts the future; hides that you never ran it | "VERIFIED: ran X, observed Y" — or "PROBABLE: … (not run because Z)" |
| "should be fixed" | Same, for bugs | "VERIFIED: reproduced the original symptom, it is gone" — or downgrade |
| "probably fine" / "looks good" | Confidence with no evidence attached | State the evidence, or label SPECULATION |
| "it works now" (no observation) | Unfalsifiable to the reader | "It returns `200` now (observed: …)" |
| "production-ready" / "bulletproof" / "just works" | Marketing, not measurement | State exactly what was tested and what was not |
| "obviously" / "trivially correct" | Substitutes vibe for proof | Show the one-line reason it's correct, or drop the adjective |

Optional helper: `scripts/flag-oversell.sh FILE` greps a draft for these phrasings and prints the offending lines so you can recalibrate before shipping. It is deliberately **over-inclusive** (a false positive costs one glance) and it **certifies nothing** — a clean run means "no known phrasing matched," not "the report is calibrated." Exit `1` = flagged something, `0` = clean, `2` = usage error.

```
# Invoke by its installed path — skills deploy under ~/.claude/skills/ (personal) or a
# project's .claude/skills/; adjust to wherever this skill lives. Reads the file you pass.
sh ~/.claude/skills/fable-reporting-and-writing/scripts/flag-oversell.sh my-report.md
```

---

## 4. No-oversell discipline for external-facing writing

Docs, READMEs, release notes, PR descriptions, and papers are read by strangers who cannot see your session and will *act on your words as fact*. The bar is higher than an internal report: a claim in a README is a promise.

**The reproducibility standard.** A stranger with only your document — not your machine, not your memory — must be able to reproduce every claim it makes. If they can't rerun it from the doc alone, the doc is overselling.

**Prove-before-claim gate.** Before a capability/performance/correctness claim may appear in external writing:

- [ ] The claim is **VERIFIED** (§3), not PROBABLE or weaker — external writing has no room for "should."
- [ ] The **exact steps to reproduce** it are in the doc (commands, inputs, environment, versions) — see `fable-ground-truth` for verifying those commands are real.
- [ ] **Numbers carry their method.** "40% faster" is meaningless without baseline, workload, sample size, and variance — route to `fable-diagnostics-and-measurement` for how to produce and interpret those numbers; do not print a number you cannot defend.
- [ ] **Scope bounds are stated.** What it does NOT do, where it breaks, known limitations — omitting these is overselling by silence (§2).

**Label unproven ideas as unproven.** A design you have not built, a benchmark you have not run, an approach you suspect will help — mark it **open** or **candidate**, never present it as an established result. "Candidate: a bloom filter could cut the lookups — not yet measured" is honest; "We use a bloom filter to cut lookups" (when you haven't) is fabrication. Methodology claims are discipline and heuristics, not guarantees — phrase them as such.

---

## 5. Runbook house style (the style THIS library uses)

This is the writing standard for the Fable Thinking skills and any operational runbook/instructions you produce. (The rules for a skill *file's* structure — frontmatter, the two-key description, the 繁中摘要 block, the one-home-per-fact ownership rule — are owned by `fable-skill-authoring-and-frontier`; this section is the *prose* style that applies to all operational writing, skill or not.)

| Principle | Rule |
|---|---|
| **Imperative voice** | "Run X. Then check Y." Not "one could run X." The reader is executing, not admiring. |
| **Copy-pasteable commands** | Every command must run as written, or be an obvious `<placeholder>`. Portable POSIX/git/common tools; mark anything project-specific as a pattern to adapt. Verify commands are real via `fable-ground-truth`. |
| **Define jargon at first use** | The first time a term appears, define it in one clause. The reader may have zero context. |
| **Tables and checklists over prose** | A decision belongs in a table (condition → action); a procedure belongs in a checklist. Prose walls hide the actionable bit. |
| **Date-stamp volatile facts** | Anything that can drift — versions, tool behavior, external facts — carries "(as of YYYY-MM-DD)". |
| **When-NOT-to section** | Every runbook says where it does *not* apply and names the sibling/alternative for the adjacent case. Boundaries prevent misapplication. |
| **Provenance section** | End with where each class of claim came from and a one-line re-verification action for anything that can drift (see §8 for why this is a *writing* practice). |
| **No oversell** | §3 and §4 apply to the runbook's own claims about itself. |

---

## 6. Handoff documents: let the next session continue without re-discovery

When a session ends with work unfinished — you are out of context, out of time, or handing to another model — write a handoff so the successor does not re-derive everything you already learned. The cost this prevents: the next session re-runs your dead ends because it does not know they are dead.

A handoff must carry **four things**, and dead ends are the one most often dropped and most valuable:

| Section | What goes here | Why it matters |
|---|---|---|
| **State** | Where things stand right now: what's done, what's in progress, what's untouched. The current diff / branch / files changed. | The successor knows the starting position without reconstructing it |
| **Evidence so far** | What you VERIFIED, with the observations (§3). The reproduction, if any. | The successor trusts what's solid and doesn't re-verify it |
| **Open hypotheses** | Live leads, each with its current confidence label and the next experiment that would confirm/kill it | The successor picks up the thread; the *method* for these is `fable-hypothesis-and-experiment` |
| **Dead ends WITH reasons** | Approaches tried that did NOT work — **and the evidence for why** | Without the reason, the successor cannot tell "ruled out" from "not yet tried" and wastes the same hours |

**A dead end without its reason is worthless** — worse than absent, because it reads as untried. "Tried bumping the timeout — no effect, the hang is before the timeout fires (stack showed it blocked in `connect`)" saves the next session the whole experiment. "Tried bumping the timeout" alone invites them to try it again.

---

## 7. Templates

Fill every field with something concrete. A field you cannot fill is a signal — usually that you are not as done as you thought (route back to `fable-verification-standards`).

### 7a. Completion report

This is the *communication envelope*. The evidence fields (`Verification` / `Before` / `After` / `Adjacent checks`) are defined by `fable-verification-standards` — do not re-derive them; fill them at the rung your evidence supports. This template adds the wrapper: outcome first, then those fields, then what's next.

```
OUTCOME: <one line — done / partial / blocked, and the headline result>
Original ask: <verbatim requirement or symptom>
Change: <one line: what you changed, which files>
Verification: I ran <exact command / flow>. Observed: <concrete output>.
  Before: <symptom present>   After: <symptom gone>
  (fields per fable-verification-standards; claim only at the rung you reached)
Adjacent checks: <suite result + neighbor behavior smoked, or "NOT run because …">
Confidence: <VERIFIED / PROBABLE / …>  — unverified gaps: <list, or "none">
Next / for you: <what the reader must do, or "nothing — complete">
```

If you cannot fill `Observed` / `After` with something you actually saw, do not send this as a completion — send it as a handoff (§6) or a partial, and say so in the OUTCOME line.

### 7b. Investigation handoff

```
OUTCOME/STATUS: <blocked / in-progress / paused — one line on where it stands>
Goal: <what we're trying to achieve or find out, verbatim if from the user>
STATE:
  - Done: <…>   In progress: <…>   Untouched: <…>
  - Working tree: <branch / files changed / how to see the diff>
EVIDENCE SO FAR (VERIFIED):
  - <observation> (how observed: <command/tool>)
OPEN HYPOTHESES:
  - <hypothesis> — <confidence label> — next test: <the experiment that would settle it>
DEAD ENDS (do not re-try):
  - <approach> — ruled out because <evidence>
KEY FILES / COMMANDS: <the paths and commands the successor needs, verified real>
```

### 7c. Incident writeup

This is how to *write up* one incident. The living *catalog* of failure incidents — and the schema they're stored in — belongs to `fable-failure-archaeology`; add the incident there, phrased with this template.

```
TITLE: <one line: the symptom as first observed>
Impact: <who/what was affected, and how badly>
Symptom: <the observable — error, wrong output, exit code — with the actual text>
Root cause: <the single mechanism that explains ALL the symptoms>
  (finding it is fable-debugging-playbook; here you only report it)
Evidence: <what proved the root cause — the discriminating observation>
Fix / countermeasure: <what changed, and how it prevents recurrence>
Verification: <how you confirmed the fix — observed, per fable-verification-standards>
Status: <resolved / mitigated / monitoring — and any residual risk, labeled>
```

---

## 8. Why provenance is a writing discipline

The "Provenance and maintenance" section that ends every skill here is not bureaucracy — it is faithful reporting applied to the document itself. It answers, for the reader who inherits the doc: *which claims are solid, which will rot, and how do I re-check them?* A claim with no stated source is unaccountable; a volatile fact with no re-verification action silently goes stale and becomes a P2 hallucination the day after it drifts. Writing provenance is how a document stays honest after you're gone. Every runbook, doc, and report of consequence should carry it in proportion to its lifespan.

---

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| Deciding whether the change is actually done / what evidence a claim needs | `fable-verification-standards` |
| Verifying a specific fact/API/flag/path is real; running an assumption ledger; citing sources | `fable-ground-truth` |
| Formatting a skill *file* — frontmatter, trigger-rich description, two-key rule | `fable-skill-authoring-and-frontier` |
| Producing/interpreting the numbers a claim rests on (baselines, variance, noise) | `fable-diagnostics-and-measurement` |
| The method for forming/testing the open hypotheses you're writing down | `fable-hypothesis-and-experiment` |
| Finding the root cause you're about to report in an incident | `fable-debugging-playbook` |
| The living catalog where incident writeups are stored | `fable-failure-archaeology` |
| The master loop that routes to all of these | `fable-operating-core` |

This skill answers exactly one question: **"I know what I did and what I may claim — how do I say it so the reader can trust and act on it?"**

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| Reporting contract (lead with outcome, write for a non-watcher, claim ≤ evidence) | First-principles reasoning about reader-facing communication; distilled from Fable-5 working methodology | Stable reasoning; revisit if reports keep failing the reader in a way not covered here |
| Faithful reporting rules and the silence rule | First-principles; directly targets P1 (claiming done without verifying) | Confirm with user that optimistic/omitting reports remain a top time-sink (as of 2026-07-13) |
| Calibration vocabulary (verified/probable/assumption/speculation) and banned-phrase table | First-principles design of a fixed confidence lexicon; banned phrases are the observed signature of P1 | Add rows as new oversell phrasings surface in practice |
| No-oversell / reproducibility standard for external writing | First-principles; "a stranger can rerun it from the doc alone" | Stable; tighten if a shipped doc is found to overclaim |
| Runbook house style | This library's own conventions (as of 2026-07-13); skill-*file* format delegated to `fable-skill-authoring-and-frontier` | Re-check the boundary if that sibling's scope shifts |
| Handoff + template structures | First-principles design to eliminate successor re-discovery | Adjust fields if handoffs show a field consistently left blank or a missing field |
| `scripts/flag-oversell.sh` | POSIX sh, grep-only; tested in a scratch dir against dirty+clean fixtures before shipping (all banned phrases flagged, calibrated prose passed, exit codes 0/1/2 correct) | Re-run on a sample report; add patterns as new oversell phrasings appear; confirm no new false positives on calibrated prose |
| Sibling skill names and ownership boundaries | This library's inventory (as of 2026-07-13) | Re-check against the current skills directory; update names and cross-refs if any skill is renamed |

**Scope note:** the linter is an optional aid, not the discipline. It catches known *phrasings*; it cannot tell whether a claim is calibrated to its evidence — that judgment is yours, guided by §3 and the sibling skills above.
