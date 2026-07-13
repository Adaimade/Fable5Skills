---
name: fable-hard-problem-campaign
description: "Load when a bug or goal has RESISTED normal attempts and needs a staged, decision-gated assault — 2+ failed honest fix attempts, a multi-day or intermittent mystery, a cross-system failure nobody can localize, or a high-stakes change you cannot afford to get wrong. This is where fable-debugging-playbook's stop-digging rule hands off. It gives you an executable campaign template (stabilize → evidence ledger → hypothesis tree → discriminating experiments in cost order → mechanism confirmation → ranked fix menu → validation and promotion), each phase with a deliverable and a GATE that says what you must observe and which branch to take otherwise. Do NOT load for a first-pass bug hunt (use fable-debugging-playbook), a research question about behavior (fable-hypothesis-and-experiment), how to instrument or read numbers (fable-diagnostics-and-measurement), or deciding done-ness (fable-verification-standards) — this skill orchestrates those, it does not replace them."
---

## 繁中摘要

- 這是「久攻不下的難題」專用的階段化、決策閘門化作戰模板：當一般除錯（fable-debugging-playbook）已經 2 次以上誠實嘗試仍失敗、跨系統謎團、或高風險變更時啟用。
- 核心是 7 個編號階段（P0 穩定化 → P1 證據帳本 → P2 假設樹 → P3 依成本排序的鑑別實驗 → P4 機制確認 → P5 排序修正選單 → P6 驗證與晉升），每階段有明確交付物與「閘門」：列出應觀察到什麼，以及看到別的東西時該分支去哪。
- 本技能只負責「作戰編排與閘門」；每個階段內的方法交由對應姊妹技能：儀器量測看 fable-diagnostics-and-measurement、假設與鑑別實驗看 fable-hypothesis-and-experiment、可逆性與變更管控看 fable-scope-and-change-control、完成定義看 fable-verification-standards。
- 附「作戰帳本」Markdown 骨架（可直接複製）與選用的 scaffolder 腳本 scripts/new-campaign.sh，讓讀者 15 分鐘內把模板實例化到自己的問題。
- 明確圍籬四條錯誤捷徑：散彈式亂修、單次實驗改多個變數、相信記憶而非帳本、第一次安靜跑過就宣告勝利。
- 邊界：作戰帳本是「戰鬥進行中」的活文件，和 fable-failure-archaeology 的「已結案事後記錄」不同；久攻不下才用本技能，一般 bug 用 fable-debugging-playbook。

---

# fable-hard-problem-campaign

A **campaign** is what you run when a problem has beaten ordinary method. Not a
bigger debugging session — a *different mode*: scope is frozen, every observation
is written down, hypotheses are enumerated as a tree, and progress is forced
through numbered gates instead of hunches. The discipline exists because hard
problems punish improvisation: you lose track of what you already ruled out, you
re-test the same idea twice, and you declare victory on a fluke.

**This skill orchestrates the siblings; it does not replace them.** Each phase
below has a GATE — a checkpoint stating what you must observe to advance, and
which branch to take if you observe something else. The *method* inside a phase
(how to instrument, how to design an experiment, how to classify a change) is
owned by a sibling and cross-referenced, never re-taught here.

**Jargon, defined once:**
- **Campaign** — a staged, gated assault on a problem that resisted normal
  attempts; tracked in a single **ledger** file.
- **Ledger** — one living Markdown file that is the *single source of truth* for
  the campaign: repro, baseline, every observation (incl. negatives),
  hypothesis tree, experiment results, decisions. Memory is not the ledger.
- **Gate** — a phase exit condition: an expected observation plus branch rules
  ("if you see X instead → go to Y").
- **Branch** — a gate outcome that sends you to a different phase or sub-protocol
  rather than straight forward. Taking a branch is normal, not failure.
- **Discriminating experiment** — a test whose outcome *differs* between two
  live hypotheses, so its result kills at least one (owned by
  fable-hypothesis-and-experiment).
- **Blast radius** — everything a candidate fix could affect beyond its target.

---

## Entry criteria — when to escalate to a campaign

Do NOT run a campaign for an ordinary bug; it is heavier than most problems
need. Escalate from **fable-debugging-playbook** to a campaign when **any** of
these holds. This is the receiving end of that playbook's *stop-digging rule*
("2–3 hypotheses failed → switch to fable-hard-problem-campaign").

| Trigger | Why a campaign |
|---------|----------------|
| **2+ honest fix attempts have failed** | Your mental model is probably wrong; you need a ledger to stop re-testing it. |
| **Multi-day / recurring** problem | Cost of re-deriving what you already know now exceeds the cost of writing it down. |
| **Cross-system mystery** — no one can even localize it | Requires coordinated evidence from multiple layers/teams in one place. |
| **Intermittent with real stakes** — flaky but consequential | Needs measured repro rate and pre-committed experiment interpretation, not eyeballing. |
| **High-stakes / hard-to-reverse change** | The gates and the ranked fix menu force you to weigh blast radius and reversibility *before* acting. |

If none hold, go back to **fable-debugging-playbook** — a campaign's overhead
will slow you down.

---

## The campaign structure (numbered phases, each with a GATE)

Run in order. A gate that branches is doing its job — obey it. Record every gate
outcome in the ledger with a date.

### Phase 0 — Stabilize

**Deliverable:** scope frozen (write down exactly what you will and won't touch);
a captured repro; baseline data (repro rate, key measurements) in the ledger.

- Freeze scope first. A hard problem tempts sprawling edits; name the boundary
  now so Phase 5 can respect it (change-classification is owned by
  **fable-scope-and-change-control**).
- Capture the repro exactly (command, input, env, expected-vs-actual).
- If intermittent, **measure the repro rate** — turn "sometimes" into a number
  (e.g. fable-debugging-playbook ships `flaky-runner.sh` for this).

> **GATE 0:** Repro rate is quantified (e.g. "fails 14/50 = 28%").
> - Deterministic or measured intermittent rate in hand → **advance to Phase 1**.
> - **Cannot reproduce at all** → **branch to the instrumentation sub-protocol**
>   (below) to find the hidden variable, THEN return here. Do not proceed on an
>   unreproducible problem — you will have no way to know if a fix worked.

**Instrumentation sub-protocol (branch target).** The goal is to surface the
uncontrolled variable that decides pass vs fail. The *how* — adding taps,
counters, and timing without perturbing what you measure — is owned by
**fable-diagnostics-and-measurement**; log every added instrument in the ledger,
run until you catch at least one failure with instrumentation live, then return
to GATE 0 with a now-measurable repro.

### Phase 1 — Evidence assembly

**Deliverable:** every observation in one ledger section — including the
*negatives* (things that did NOT happen, experiments that came back null).

- One place, not scattered across your memory and three terminals.
- Negatives are evidence: "changing the timeout did nothing" rules out a family
  of causes and must be recorded, or you will re-test it next week.

> **GATE 1:** Every observation in the ledger is **dated and sourced** (which
> command / log / file / run produced it).
> - All observations dated and sourced → **advance to Phase 2**.
> - An observation you "remember" but cannot source → **re-capture it** before
>   trusting it. Memory is not the ledger (see fenced wrong path below).

### Phase 2 — Hypothesis tree

**Deliverable:** an enumerated tree of candidate mechanisms; each leaf makes a
*distinct* prediction (predict-before-run and one-mechanism discipline are owned
by **fable-hypothesis-and-experiment** — apply them here at campaign scale).

- Enumerate broadly, then split: "wrong data" vs "wrong code"; "our code" vs
  "dependency" vs "environment"; each into concrete sub-mechanisms.
- Two hypotheses that predict the *same* observation are not yet separable —
  either refine one until they diverge, or note they need the same experiment.

> **GATE 2:** For **each branch**, at least one **discriminating experiment**
> exists (a test whose result would kill or promote that branch).
> - Every branch has a discriminating experiment → **advance to Phase 3**.
> - A branch is **untestable** with current tools/access → **park it
>   explicitly** in a "Parked" ledger section with the reason and what would make
>   it testable. Do not silently drop it, and do not let an untestable favorite
>   block progress on testable branches.

### Phase 3 — Discriminating experiments, in cost order

**Deliverable:** experiments run cheapest-first, each with its interpretation
**pre-committed in the ledger before you run it**.

- Order by cost (time, risk, setup), cheapest first — a $0 experiment that kills
  half the tree beats an expensive one that resolves a leaf.
- **Pre-commit interpretation:** write "result A → hypothesis H1 dead; result B →
  H1 promoted" *before* running. This blocks the post-hoc rationalization that
  keeps a dead hypothesis alive.
- **Change exactly one variable per experiment** (see fenced wrong path).

> **GATE 3 (per experiment):** The result **kills or promotes** at least one
> branch, per your pre-committed interpretation.
> - Result resolved a branch → update the tree, run the next cheapest experiment.
> - Result matches **neither** pre-committed outcome → your model missed a
>   mechanism. **Branch back to Phase 2** and add the branch that would produce
>   what you actually saw. This is the campaign catching a wrong model — the
>   whole point of gating.
> - Tree exhausted with nothing promoted → **branch back to Phase 1**: your
>   evidence set is incomplete or your repro is not the reported bug.

### Phase 4 — Mechanism confirmation

**Deliverable:** ONE mechanism that explains **every** observation in the
ledger — including the weird ones and the negatives — that has survived an
adversarial refutation pass.

- The one-mechanism rule: if your explanation leaves any observation unaccounted
  for, you are not done. Unexplained residue is where the real cause hides.
- **Adversarial refutation:** actively try to *break* your own explanation. Find
  the observation it predicts that you have NOT yet checked, and check it. Look
  for a second mechanism you are quietly invoking. (For multi-agent adversarial
  verification — a fresh agent trying to refute — see
  **fable-orchestration-and-delegation**.)

> **GATE 4:** The refuter **fails to break** the mechanism — no observation
> contradicts it, no second mechanism is smuggled in, the not-yet-checked
> prediction held.
> - Refuter fails → mechanism confirmed → **advance to Phase 5**.
> - Refuter succeeds (found a contradicting or unexplained observation) →
>   **branch back to Phase 2** with that observation as a new constraint.

### Phase 5 — Fix design from a ranked solution menu

**Deliverable:** a *ranked menu* of candidate fixes (not one fix), each scored on
three axes, with a chosen candidate and the reason.

| Candidate | Theory obligation | Blast radius | Reversibility |
|-----------|-------------------|--------------|---------------|
| Fix A | What must be true about the mechanism for this to work | What else it can affect beyond target | How cleanly it can be undone |
| Fix B | … | … | … |

- **Theory obligation:** the fix must follow from the confirmed mechanism, not
  from "this might help". If you cannot state why the mechanism makes this fix
  work, it is a shotgun fix (fenced below).
- **Blast radius** and **reversibility classes** are owned by
  **fable-scope-and-change-control** — use its classification; prefer the
  minimal, most-reversible fix that discharges the theory obligation.
- Rank, pick, and record the runners-up in the ledger (if the top choice fails
  validation, you return here, not to Phase 0).

> **GATE 5:** The chosen fix has a stated theory obligation tied to the confirmed
> mechanism, and its blast radius/reversibility are acceptable for the stakes.
> - Yes → **advance to Phase 6**.
> - The only candidates are large/irreversible → **STOP and route through
>   fable-scope-and-change-control's gates** before touching anything
>   destructive; consider a reversible mitigation first.

### Phase 6 — Validation and promotion

**Deliverable:** measured proof the original symptom is gone, a regression sweep,
and the change routed through change control — then the campaign is closed.

- **Verify the original symptom** against the Phase 0 baseline: re-run the repro;
  for an intermittent bug require 0 failures over **at least as many runs as the
  baseline** (one quiet run is not proof — fenced below).
- **Regression sweep:** run the surrounding tests / adjacent flows; a hard-problem
  fix touches load-bearing code and can break neighbors.
- **Success is measured, never judged by eye.** What counts as sufficient proof —
  the evidence hierarchy and definition of done — is owned by
  **fable-verification-standards**. Route the change through
  **fable-scope-and-change-control** for the actual commit/merge discipline.

> **GATE 6:** Original symptom measurably gone (against baseline) AND regression
> sweep clean AND change routed through change control.
> - All three → **close the campaign**; if the failure is a reusable lesson,
>   distill it into a settled incident via **fable-failure-archaeology** (see
>   boundary below).
> - Symptom persists or regression appears → **branch back to Phase 5** and try
>   the next-ranked candidate; if none remain, back to Phase 2 — the mechanism
>   was wrong.

---

## Ledger vs incident record — a boundary, not duplication

| Artifact | This skill's **campaign ledger** | fable-failure-archaeology **incident record** |
|----------|----------------------------------|-----------------------------------------------|
| When | *During* the fight — a live working doc | *After* — a settled post-mortem |
| Purpose | Track repro, tree, experiments, decisions | So no future session re-fights a solved battle |
| State | Evolving; full of dead branches and negatives | Distilled; symptom → root cause → countermeasure → status |

They are not the same file. A closed campaign may *produce* an incident record
(GATE 6), but the ledger is the messy source and the incident record is the clean
summary.

---

## Fenced wrong paths (do NOT take these)

Archetypal patterns that make a campaign fail. **Illustrations of the pattern,
not records of specific real events** — the catalog of real, documented
AI-agent incidents is **fable-failure-archaeology**.

### 🚫 Shotgun fixes — changing code hoping something sticks

- **Tempting because:** the problem is painful and *doing something* feels like
  progress.
- **The pattern:** you apply a fix with no theory obligation (Phase 5). If it
  "works", you do not know *why*, so you cannot tell a real fix from a fluke, and
  the symptom returns. If it does not, you have muddied the repro.
- **Do instead:** every fix must follow from the confirmed mechanism (Phase 4).
  No mechanism → you are not in Phase 5 yet.

### 🚫 Changing multiple variables in one experiment

- **Tempting because:** it seems faster to try three things at once.
- **The pattern:** the result changes and you cannot attribute it — you have
  destroyed the experiment's discriminating power (Phase 3). Now you must redo it.
- **Do instead:** one variable per experiment. Slower per step, far faster to a
  confirmed cause.

### 🚫 Trusting memory over the ledger

- **Tempting because:** "I already checked that" feels certain.
- **The pattern:** you skip re-recording an observation, mis-remember a negative
  as a positive, and re-test a branch you already killed — or worse, build on a
  false memory. Over a multi-day campaign, memory decays and misleads.
- **Do instead:** if it is not dated and sourced in the ledger (GATE 1), it did
  not happen. Write first, reason from the writing.

### 🚫 Declaring victory on the first quiet run

- **Tempting because:** the error did not appear once and you want to be done —
  this is P1, the core failure this library exists to stop.
- **The pattern:** an intermittent bug at 28% "passes" a single run 72% of the
  time by pure chance. You ship; it recurs; trust erodes.
- **Do instead:** measure against the Phase 0 baseline (GATE 6). Require zero
  failures over at least the baseline's run count, and route through
  fable-verification-standards for what counts as proof.

---

## Campaign ledger template (copy this into your project)

Copy the skeleton below into a file such as `./.campaign/<date>-<slug>.md` (the
optional `new-campaign.sh` scaffolds exactly this — invoke it by its installed path,
e.g. `sh ~/.claude/skills/fable-hard-problem-campaign/scripts/new-campaign.sh <slug>`,
adjusting to wherever this skill is installed; it writes to your current directory). It is
project-agnostic — no tool or language is assumed.

```markdown
# Campaign: <slug>

- Started: <YYYY-MM-DD>
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
```

---

## Worked mini-example — intermittent CI failure (generic)

Shows three gates firing, **including a branch that does not pass on first try.**
Illustrative, not a real incident.

**Problem:** a test suite fails on CI "randomly", ~3 attempts to fix it (add
retries, bump a timeout, pin a dep) all failed → entry criteria met (2+ failed
attempts + intermittent+stakes). Start a campaign.

- **Phase 0 → GATE 0 BRANCHES.** Locally the suite passes every time — cannot
  reproduce. GATE 0 is not satisfied (no measured rate), so **branch to the
  instrumentation sub-protocol**: per fable-diagnostics-and-measurement, add a
  tap that logs test execution order and the value of a shared temp path per run,
  and run in CI's container image locally in a loop. After 40 runs it fails 11
  times = **28%**. Return to GATE 0 — now satisfied. Advance.

- **Phase 1 → GATE 1 passes.** Ledger records, dated and sourced: failures only
  when test_A runs before test_B (from the order tap); NEGATIVE — timeout bump
  from the earlier failed attempt changed nothing (source: prior CI run). Every
  line sourced. Advance.

- **Phase 2 → GATE 2 passes.** Tree: H1 "test ordering — shared temp file not
  isolated" (predicts: forcing B-before-A never fails); H2 "wall-clock race"
  (predicts: adding delay changes rate). Both have a discriminating experiment.
  Advance.

- **Phase 3 → GATE 3 BRANCHES once, then resolves.** Cheapest first: E1 force
  order B-before-A. Pre-committed: never fails → H1 promoted; still fails → H1
  dead. Result: never fails in 40 runs → **H1 promoted, H2 not yet dead.** Run E2
  (add 200ms delay). Pre-committed: rate drops → H2 lives; unchanged → H2 dead.
  Result: **unchanged** → H2 dead. Tree resolved to H1.

- **Phase 4 → GATE 4 passes.** Mechanism: test_A writes a fixed-name temp file
  test_B reads; when A precedes B, B reads A's leftovers. Explains the order
  dependency AND the negative (timeout irrelevant). Refutation: predicts that
  isolating the temp path makes failures vanish even in A-before-B order — not
  yet checked; check it in Phase 6's spirit as the final experiment → holds.

- **Phase 5.** Fix menu: (A) give each test a unique temp path — theory
  obligation: removes the shared resource the mechanism needs; blast radius:
  two test files; reversibility: trivial. (B) add teardown to delete the file —
  smaller change but leaves the shared name (weaker theory obligation). Rank A #1.

- **Phase 6 → GATE 6.** Apply A; re-run the instrumented loop: **0/50** (baseline
  was 11/40). Regression sweep: full suite green. Route through
  fable-scope-and-change-control. Symptom measurably gone → **close**; distill a
  one-line lesson ("shared fixed-name temp files cause order-dependent flakes")
  into a fable-failure-archaeology incident.

The two branches (GATE 0 → instrumentation; GATE 3's E1 leaving H2 alive) are the
campaign earning its overhead: a shotgun session would have shipped the retry and
called it done.

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| First-pass hunt for a bug's cause (not yet resisted attempts) | fable-debugging-playbook |
| A research question about how a system behaves | fable-hypothesis-and-experiment |
| How to instrument / measure to get a repro rate | fable-diagnostics-and-measurement |
| Root cause is a false belief about an API/flag/path/version | fable-ground-truth |
| What evidence proves the fix works (done-ness) | fable-verification-standards |
| Classifying a change / reversibility / commit discipline | fable-scope-and-change-control |
| Splitting the campaign across multiple agents / adversarial panels | fable-orchestration-and-delegation |
| Recording a *settled* lesson so no one re-fights it | fable-failure-archaeology |

---

## Provenance and maintenance

| Claim class | Source |
|-------------|--------|
| Campaign structure, the seven phases, the gate/branch mechanism | First-principles reasoning about staged inference under uncertainty; not tool-specific. |
| Entry criteria and the debugging-playbook handoff | Designed to dovetail with fable-debugging-playbook's stop-digging rule (library inventory, as of 2026-07-13). |
| Per-phase method ownership (instrument, experiment, reversibility, done-ness) | Library ownership rules — each cross-referenced sibling owns its method (as of 2026-07-13). |
| Fenced wrong paths | Archetypal patterns illustrating campaign-scale mistakes; stories are illustrative, NOT logged real events. Real incidents live in fable-failure-archaeology. |
| P1 ("first quiet run") framing | User-reported pain points (as of 2026-07-13) motivating this library. |
| Ledger skeleton; `scripts/new-campaign.sh` behavior | First-principles template; script tested under `sh` with fresh-scaffold, no-clobber, slug-sanitization, and empty-slug-fallback cases before shipping (as of 2026-07-13). |

**Re-verification actions (do these if things drift):**
- Re-check every sibling skill name referenced here still exists in the library
  index; a renamed skill becomes a dead cross-reference.
- Keep the ledger skeleton in this file byte-identical to the one
  `scripts/new-campaign.sh` emits; if you edit one, edit both.
- Re-run the script's edge cases if the shell environment changes:
  `sh new-campaign.sh demo` (expect a file written, path printed),
  run it twice with the same slug/date (expect the second to refuse, exit 1),
  `sh new-campaign.sh 'Weird Name!!'` (expect slug sanitized to `weird-name`),
  `sh new-campaign.sh ''` (expect fallback slug `unnamed-campaign`).
- Re-check the skill frontmatter format (exactly two keys: name, description)
  against current Claude Code skill docs if the loader changes.
