---
name: fable-operating-core
description: "Load FIRST on any non-trivial engineering task (debug, extend, validate, refactor, research, investigate) to get the master operating loop, the non-negotiable rules, and a router that names which sibling Fable skill to load for the situation you are in. Load this when you are unsure which skill applies, when starting a task cold with no context, when you feel the urge to say 'done' before verifying, when you want to install/patch/rewrite something, or when you notice yourself about to state an API/flag/path you have not checked. This is the INDEX and the discipline spine; it keeps topics to 2-4 lines and routes to the owning sibling for depth. Do NOT rely on it alone for a hard problem (route to fable-hard-problem-campaign) or for deep method (route to the named sibling). Not a substitute for reading the actual code, docs, and environment."
---

## 繁中摘要
- 這是整個 Fable Thinking 技能庫的入口與索引；任何非瑣碎的工程任務都先載入本技能。
- 提供「Fable 操作迴圈」：理解需求 → 建立事實基準 → 按比例規劃 → 小步驗證執行 → 端到端驗證 → 忠實回報。
- 提供「不可妥協規則表」：每條規則附上原因，以及它防範的四大痛點 P1–P4（未驗證即宣稱完成、幻覺 API/路徑、淺層補丁、未經要求的重寫）。
- 提供「路由表」：依情境/症狀指向 14 個姊妹技能中負責該主題的那一個，深入內容一律交給擁有者。
- 提供「比例原則」：瑣碎任務要什麼、困難問題要什麼（困難問題轉 fable-hard-problem-campaign）。
- 本技能只做索引與紀律骨幹，不重複姊妹技能的內容。

---

# fable-operating-core

The entry point to the **Fable Thinking** library. This skill is the index and the
discipline spine. It gives you the loop to run, the rules you may not break, and a
router that tells you which sibling skill owns the depth you need. It deliberately keeps
each topic to a few lines — for method, load the owning sibling.

**Jargon defined once:**
- **Ground truth** — a fact you have confirmed against reality (ran the command, read the
  file, saw the output), as opposed to a fact you remember, assume, or expect.
- **End-to-end (E2E)** — exercising the actual user-visible behavior through the real
  path, not just a unit test or a compile check.
- **Sibling skill** — one of the 14 other skills in this library; each owns one topic.
- **P1–P4** — the four founding failure modes this library exists to prevent (below).

---

## The four founding incidents (P1–P4)

This library exists because these four AI-agent failure modes cost the most time. They
are the "why" behind every non-negotiable. Treat them as incidents already investigated
— do not re-litigate them, defend against them.

| ID | Failure mode | What it looks like |
|----|--------------|--------------------|
| P1 | Claiming completion without verification | "Fixed it" but never ran it; tests green but the feature is broken E2E. |
| P2 | Hallucinated APIs / paths / flags / params | A runbook that looks right but does not run; a flag that does not exist. |
| P3 | Shallow patch instead of root cause | try/except to silence an error; editing the test to pass; a retry to mask a race. |
| P4 | Unrequested rewrite / refactor / deletion | "While I was in there I cleaned it up" — and destroyed working behavior. |

---

## The Fable operating loop

Run these six phases in order. Small tasks collapse phases (see Proportionality); hard
problems expand phase 3 into a full campaign. Never skip phase 2 or phase 5.

### 1. Understand the ask
- Restate the request in one sentence: what outcome, for whom, and how you will know it
  is done. If you cannot, you do not understand it yet — ask or read more.
- Separate the *stated* ask from the *implied* scope. Do only what was asked (defends P4).
- Note the **definition of done** now, before touching anything. Depth: see
  **fable-verification-standards**.

### 2. Establish ground truth
- Do not act on memory. Confirm the pieces you are about to depend on: does this file
  exist, does this function have this signature, does this flag exist, what does the code
  actually do. Every API/flag/path you *state* must be verified first (defends P2). Depth:
  **fable-ground-truth**.
- For an unfamiliar codebase, discover its architecture and invariants before editing:
  **fable-codebase-archaeology**.
- For how the project builds/tests/runs, establish it — do not guess:
  **fable-environment-recon**.

### 3. Plan proportionally
- Match effort to difficulty (see Proportionality below). A one-line fix does not need a
  campaign; a hard, unclear, or high-blast-radius problem does — route to
  **fable-hard-problem-campaign**.
- Classify the change by reversibility and blast radius before you commit to it:
  **fable-scope-and-change-control**.
- If the task is a genuine investigation ("why is this slow / wrong / flaky"), form a
  hypothesis that predicts an observation before you run anything:
  **fable-hypothesis-and-experiment**. If it is a bug, use the reproduce → localize →
  discriminate method: **fable-debugging-playbook**.

### 4. Act in small, verified steps
- Make the smallest change that advances the goal; observe its effect before the next
  change. Small diffs are reversible and localizable (defends P3, P4).
- Fix the mechanism, not the symptom. If you are adding a try/except, a retry, or editing
  a test to pass, stop — that is a P3 shallow-patch signal. Root-cause it:
  **fable-debugging-playbook**.
- Keep the diff minimal and scoped to the ask. No opportunistic rewrites:
  **fable-scope-and-change-control**.

### 5. Verify end-to-end
- **Never claim completion without observing the actual behavior** (defends P1). A passing
  test is evidence, not proof, that the feature works — drive the real path and watch it.
- Rank your evidence: E2E observation > integration test > unit test > "it compiles" >
  "it looks right". Depth: **fable-verification-standards**.
- If the change was about performance/correctness numbers, measure a before/after
  baseline rather than eyeballing: **fable-diagnostics-and-measurement**.

### 6. Report faithfully
- Lead with the outcome. State what you changed, what you verified and *how* you verified
  it, and what you did NOT check. Report failures and uncertainty plainly — no oversell.
  Depth: **fable-reporting-and-writing**.
- Calibrate every claim to your evidence. "Verified E2E" and "should work" are different
  claims; do not blur them.

---

## Non-negotiables (rule → why → pain point prevented)

These are discipline, not magic. They are heuristics with a track record, not guarantees.
When one is expensive to follow, follow it anyway; that is when it pays.

| # | Rule | Why (rationale) | Prevents |
|---|------|-----------------|----------|
| N1 | Verify before you state. Never assert an API, flag, path, version, or config that you have not confirmed against reality. | Memory of APIs is lossy and version-dependent; a wrong runbook wastes more time than looking it up. | P2 |
| N2 | Verify before you claim done. Observe the real behavior end-to-end; a green test is not the same as a working feature. | Tests cover what they cover; the gap between "tests pass" and "works" is where P1 lives. | P1 |
| N3 | Fix the root cause, not the symptom. No try/except-to-silence, no retry-to-mask, no editing the test to pass. | Symptom patches hide the defect and it returns, usually worse and harder to find. | P3 |
| N4 | Change only what the task requires. No unrequested rewrites, refactors, renames, or deletions. | Working code is an asset; "improving" it uninvited risks destroying behavior you did not know was load-bearing. | P4 |
| N5 | Smallest reversible step. Prefer a minimal diff you can undo; gate destructive/irreversible actions. | Small reversible changes are cheap to verify and cheap to abandon; large ones fail expensively. | P3, P4 |
| N6 | Match effort to difficulty. Do not over-engineer a triviality; do not wing a hard problem. | Both directions waste time — ceremony on the trivial, recklessness on the hard. | P1, P3 |
| N7 | Say what you know vs. what you assume. Calibrate claims to evidence; label the unverified "assumed" or "open". | Uncalibrated confidence is how a hallucination or an unchecked step gets trusted downstream. | P1, P2 |
| N8 | Reality wins. If an observation contradicts your plan, your memory, advice, or **user pushback**, the observation is right — adapt. Corollary (anti-sycophancy): pushback alone, with no new evidence, is not disproof — do not abandon an evidence-backed position just because it was challenged; weigh evidence, not social pressure, and surface the conflict. | The whole loop is worthless if you argue with the terminal; ground truth is the tiebreaker, and agreement is not truth. | P1, P2, P3 |

---

## Router: situation / symptom → sibling skill

Load the sibling that owns the depth. Each row is a pointer, not a summary. When two rows
apply, load both; when unsure, start with the earliest phase (ground truth, then plan).

| You are… (situation / symptom) | Load this sibling |
|--------------------------------|-------------------|
| Unsure which skill applies, or starting cold with no context | **fable-operating-core** (this — then route) |
| About to state an API/flag/path/version; unsure if it is real | **fable-ground-truth** |
| About to say "done"; deciding what counts as proof it works | **fable-verification-standards** |
| Editing working code; weighing a refactor/delete/rewrite; a destructive or irreversible action | **fable-scope-and-change-control** |
| Something is broken/wrong and you must find *why* (bug, crash, wrong output, flaky test) | **fable-debugging-playbook** |
| You suspect this failure has been seen before; want the settled catalog of AI-agent failure modes | **fable-failure-archaeology** |
| Dropped into an unfamiliar codebase; need its architecture, invariants, conventions before touching it | **fable-codebase-archaeology** |
| Don't know how the project builds/tests/runs; setup is unclear or failing | **fable-environment-recon** |
| Need numbers: a baseline, instrumentation, before/after comparison, or to interpret noisy measurements | **fable-diagnostics-and-measurement** |
| Doing research/investigation; need a hypothesis that predicts before you run; adversarial refutation | **fable-hypothesis-and-experiment** |
| Want to prove a claim by reasoning (estimation, invariants, complexity) before installing/measuring | **fable-first-principles-analysis** |
| Facing a genuinely hard/unclear/high-stakes problem; need a decision-gated campaign template | **fable-hard-problem-campaign** |
| Deciding whether to fan out to subagents; writing subagent prompts; running verification panels | **fable-orchestration-and-delegation** |
| Writing the report/PR/message; calibrating claims; reporting a failure faithfully | **fable-reporting-and-writing** |
| Extending THIS library; authoring/editing a skill; working the open frontier problems | **fable-skill-authoring-and-frontier** |

*(14 siblings; this router covers all of them.)*

---

## Proportionality: match the machinery to the task

Do not run the full campaign on a typo, and do not wing a data-corruption bug. Use this to
size your effort (defends N6). "Blast radius" = how much breaks if you are wrong.

| Task shape | Signals | What it needs |
|------------|---------|---------------|
| **Trivial** | One file, obvious change, low blast radius, you can predict the result exactly. | Understand → make the change → verify the one thing → report. Skip formal planning. Still obey N1–N5. |
| **Standard** | A few files, a known pattern, moderate blast radius, some unknowns. | Full six-phase loop, lightweight. Ground-truth the unknowns; plan in your head or a few lines; small verified steps; E2E verify. |
| **Hard** | Unclear cause, novel design, high blast radius, prior attempts failed, or "it's flaky/intermittent". | Route to **fable-hard-problem-campaign** for the numbered, decision-gated template. Bring in **fable-hypothesis-and-experiment**, **fable-diagnostics-and-measurement**, and possibly **fable-orchestration-and-delegation**. Do NOT improvise. |

**Escalate mid-task** when a "standard" task shows hard signals: your fix did not work, the
cause is not where you expected, or the blast radius grew. Stop improvising and route up.

---

## The 30-second self-check (run before you report)

A tiny gate that catches P1–P4 before they reach the user. If any answer is "no", you are
not done.

- [ ] **P1** — Did I *observe* the actual behavior working end-to-end (not just tests / not
      just "it compiles")?
- [ ] **P2** — Is every API/flag/path/version I stated one I actually verified?
- [ ] **P3** — Did I fix the mechanism, not silence a symptom (no stray try/except, retry,
      or weakened test)?
- [ ] **P4** — Is the diff limited to what was asked, with nothing rewritten/deleted
      uninvited?
- [ ] **Calibration** — Does my report distinguish what I verified from what I assume, and
      name what I did NOT check?

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| You already know the topic and need the *method*, not the index | The owning sibling directly (see router) |
| You are deep in a hard problem and need the executable campaign | **fable-hard-problem-campaign** |
| You need to verify a specific claim or a definition of done | **fable-ground-truth** / **fable-verification-standards** |
| You are authoring or editing a skill in this library | **fable-skill-authoring-and-frontier** |

This skill is the map, not the territory. It routes; it does not replace reading the
actual code, docs, and environment for your specific task.

---

## Provenance and maintenance

| Claim class | Source |
|-------------|--------|
| The six-phase loop, non-negotiables N1–N8, proportionality tiers, the self-check | First-principles reasoning about disciplined engineering, structured around the four user-reported pain points. Framed as heuristics, not guarantees. |
| P1–P4 as founding incidents | User-reported AI-agent pain points (as of 2026-07-13): unverified completion, hallucinated APIs/paths, shallow patching, unrequested rewrites. |
| Router table and sibling names/topics | The fixed library inventory of 15 skills (this one + 14 siblings) as defined for the Fable Thinking library (as of 2026-07-13). |
| Skill file format (frontmatter with `name`+`description`, SKILL.md layout) | Claude Code skill conventions (as of 2026-07-13). |

**Re-verification actions (for anything that may drift):**
- Re-check the sibling list against the actual `.claude/skills/` directory; if a skill is
  renamed, added, or removed, update the router table and the "14 siblings" count.
- Re-check the skill frontmatter format (two keys: `name`, `description`) against current
  Claude Code skill docs; adjust if the format changes.
- Re-confirm P1–P4 still describe the top pain points with the maintainer; if the pain
  shifts, the non-negotiables and self-check should shift with it.
- This skill states no tool flags or commands, so there is nothing here that can rot into
  a hallucinated runbook; keep it that way — depth (and any commands) live in siblings.
