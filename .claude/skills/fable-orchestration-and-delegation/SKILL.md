---
name: fable-orchestration-and-delegation
description: "Load when deciding whether to split work across subagents and how to run them: a task big enough to fan out (audit every file, migrate N modules, review a large diff), an unfamiliar area for a scout to map in parallel, or a conclusion to stress-test with independent skeptics. Use it to choose solo vs one-scout vs many-agent HONESTLY (coordination cost is real), to write a subagent prompt that stands ALONE with ground-truth constraints, an output contract, scope fences, and defenses for the four failure modes (P1 unverified completion, P2 hallucinated APIs, P3 shallow patch, P4 unrequested rewrite), to build refuter/perspective/majority panels, and to synthesize conflicting outputs without laundering unverified claims. Do NOT load for the master loop/router (fable-operating-core), refutation science (fable-hypothesis-and-experiment), what counts as proof (fable-verification-standards), or when a task needs one continuous context. Core mechanic needs a subagent-capable environment."
---

## 繁中摘要

- 這個 skill 教「多代理協作」：何時該把工作拆給子代理（subagent）平行做、何時該獨自做、以及如何指揮與整合結果。
- 誠實成本表：獨自做 / 派一個偵察兵 / 大規模扇出（fan-out）各有協調成本；扇出不是免費的平行，多數情況該獨自做。
- 核心產物：一份「完全自足」的子代理提示（prompt）——子代理沒有你的對話脈絡，所以必須內含 ground-truth 限制、輸出合約、範圍圍欄，並在每一份委派提示裡明確防守 P1–P4（子代理更容易退化回這四種失敗）。
- 驗證拓撲：對抗式反駁小組（N 個獨立懷疑者被要求「推翻」）、多視角審查（不同鏡頭勝過相同冗餘）、多數決閘門。
- 整合紀律：orchestrator（指揮者）負責調解代理間的矛盾，絕不把互相衝突的結論直接拼接；每個發現都要保留「證據標籤 + 哪個代理產出」，防止 result laundering（把未驗證的宣稱當成已驗證回報）。
- 邊界與環境限制：需要單一連續脈絡的任務就別扇出；本 skill 核心機制只在支援子代理的環境成立（如 Claude Code 的 Agent/Workflow 工具，as of 2026-07-13）；無子代理時降級為「切換角色的循序自我審查」。

---

This skill governs **when and how to use more than one agent**, and — just as important — when not to. Delegation multiplies both throughput and risk: a subagent has none of your conversation context, so any fact you forgot to state, it will invent; any discipline you forgot to demand, it will skip. Smaller or context-free agents regress hardest to exactly the four library failure modes. So the orchestrator's job is not "spawn helpers" — it is to **manufacture context and discipline for agents that have neither, then reconcile what comes back without being fooled by it.**

Jargon, defined once:

| Term | Meaning |
|---|---|
| **Orchestrator** | The agent (you) that decides the split, writes the subagent prompts, and synthesizes results. Owns the final answer. |
| **Subagent** | A spawned agent that runs one task and returns output. Has **no** memory of this conversation — only the prompt you hand it. |
| **Fan-out** | Spawning many subagents to work in parallel on independent slices of one big task. |
| **Scout** | A single subagent sent to explore/map something (a codebase area, a question) and report back, so you spend your context on the answer, not the search. |
| **Output contract** | The exact shape, fields, and evidence labels you require a subagent to return — defined BEFORE you spawn it. |
| **Barrier** | A synchronization point where you wait for ALL parallel agents to finish before proceeding. |
| **Pipeline** | A chain where agent B consumes agent A's output; stages run in sequence, not in parallel. |
| **Result laundering** | Reporting a subagent's unverified claim as if it were verified, because the label got dropped in synthesis. The multi-agent form of P1. |

---

## 1. Solo vs one scout vs fan-out (decide honestly — parallelism is not free)

Delegation has a real, fixed overhead: writing a self-contained prompt, paying for the agent to re-derive context you already hold, and the synthesis burden of reconciling what returns. Fan-out wins only when the parallel work saved **exceeds** that overhead. Most tasks do not clear the bar.

| Shape | Use when | True cost you are paying | Default |
|---|---|---|---|
| **Solo** (you, one context) | Single-file fact, a small localized fix, anything needing one continuous train of thought, tightly coupled edits | None extra. You keep full context and lose nothing to handoff. | **This is the default.** Delegate only to escape a real limit (breadth, context budget, or the need for independence). |
| **One scout** | The search would burn your context (large/unfamiliar area), or one bounded parallel question you can keep working around | One prompt to write + one result to read. Cheap. The scout re-derives context you can't hand it — brief it well. | Reach for this before fan-out. One extra agent, big context saving. |
| **Fan-out (many)** | Genuinely independent slices at scale: audit every file against a rule, migrate N modules the same way, review a large diff from several angles, gather M sources in parallel | N prompts to write, N context re-derivations, and the **synthesis cost grows with N** (you must reconcile N possibly-conflicting returns). Coordination can exceed the parallelism win. | Only when slices are **independent** (§2) and N is large enough that serial is clearly worse. |

**Honest anti-oversell:** fan-out is not "N× faster." You do the work serially anyway when you write N prompts and read N results, and reconciliation is superlinear when agents disagree. If a single agent (you) can hold the whole task in one context and finish before you could even brief the panel, **that is the correct choice** — say so and do it. "We could parallelize this" is not a reason to.

Litmus: if you cannot name the **independent** slices and the **output contract** each returns (§2), you are not ready to fan out. Scout or solo instead.

---

## 2. Decomposition principles

Fan-out is safe only over slices that do not interfere. Get this wrong and you get duplicated work, corrupted shared state, or agents that must have talked to each other but couldn't.

1. **Independent subtasks, no shared mutable state.** Two subagents must never write the same file, row, or resource. If slice A's correctness depends on slice B's in-progress result, they are **not** independent — sequence them (pipeline) or merge them into one agent. Read-only shared inputs are fine; shared *writes* are a race you cannot see.
2. **Define each output contract BEFORE spawning.** Decide the exact return shape first: fields, format, and an **evidence label** per finding (what was actually run/observed vs inferred). These `[RAN]/[READ]/[INFERRED]` report labels are defined by THIS skill (§3); they operationalize fable-ground-truth's observed-vs-inferred, cite-your-source discipline. If you cannot specify the contract, you do not yet understand the slice well enough to delegate it.
3. **Slices must partition cleanly.** Every unit of work belongs to exactly one agent. Overlap → duplicated effort (§6). Gaps → silent incompleteness (nobody audited module 7). State the partition explicitly in each prompt ("you own files A–F, and ONLY those").

**Pipeline vs barrier — define and choose both:**

| Topology | Definition | Use when | Cost / risk |
|---|---|---|---|
| **Barrier** | Spawn all slices in parallel; wait for **every** agent to finish, then synthesize. | Slices are independent and you need all results before deciding anything. | The whole batch is only as fast as its **slowest** agent (the straggler). One agent's failure can block synthesis. |
| **Pipeline** | Stage the work: agent B consumes agent A's output; run stages in sequence (each stage may itself fan out). | Later work genuinely depends on earlier results (scout → then targeted workers on what the scout found). | No parallelism *across* stages — latency adds up. A bad early stage poisons everything downstream, so verify stage outputs before feeding them on. |

Prefer a **pipeline** when there is a real dependency (map first, then act on the map) and a **barrier fan-out** only when slices are truly independent. Do not impose a barrier on dependent work — you will get agents guessing at inputs that don't exist yet (context starvation, §6).

---

## 3. The self-contained subagent prompt (the centerpiece)

A subagent starts with **zero** conversation context. It sees only the prompt string you pass. Therefore every prompt must carry, in its own body: the task, the ground-truth constraints, the exact output contract, hard scope fences, and an explicit defense of **each** of P1–P4 — because a context-free agent regresses to those four failure modes by default. Omitting a fact is not neutral; the agent fills the gap by inventing (P2) or by expanding scope (P4).

Use this template verbatim as a starting point. Every bracketed slot must be filled; **do not delete the P1–P4 fences** — they are the load-bearing part.

```
ROLE: You are a subagent with NO prior context. Everything you need is in this message.
Do not assume anything not stated here. If a required fact is missing, STOP and report
"MISSING: <what>" rather than guessing.

TASK (exact, bounded):
  <one concrete task. e.g. "In files listed under SCOPE, find every call to `foo()` that
   omits the `timeout=` argument and report file:line and the surrounding 3 lines.">

CONTEXT YOU NEED (ground truth — do not rely on memory):
  - Repo/area: <path>. Build/test/run: <exact commands, or "do not build">.
  - Facts that are true here: <versions, the real API signature, the real config keys>.
  - Verify anything not listed above against the actual files before you rely on it.

OUTPUT CONTRACT (return EXACTLY this, nothing else):
  - Format: <e.g. a list of {file, line, snippet, verdict}>.
  - EVIDENCE LABEL on every item: mark each as
      [RAN]     = I executed it and observed this output (paste the command + result), or
      [READ]    = I read this directly in a file (cite file:line), or
      [INFERRED]= I reasoned this but did NOT observe it (say so plainly).
    Never present [INFERRED] as [RAN] or [READ].
  - If you found nothing, say "NONE FOUND" — do not pad.

SCOPE FENCE (P4 — do not exceed):
  - Touch ONLY: <explicit files/paths>. Do NOT edit, delete, reformat, rename, or "improve"
    anything else. If a fix seems needed outside this list, PROPOSE it in your report —
    do not perform it.
  - Make the MINIMAL change that satisfies the task. A large diff is a failure, not thoroughness.

DISCIPLINE (defend every one — you will be checked on these):
  - P1 (no unverified "done"): Report only what you actually ran and observed. If you did not
    execute it end to end, say "NOT VERIFIED" — do not claim it works. Paste the evidence.
  - P2 (no hallucination): Do NOT invent file paths, flags, function names, or config keys.
    Cite the file:line or command output for every concrete claim. "I believe" = go check first.
  - P3 (root cause, not silence): Do NOT paper over an error with try/except, a retry, a
    weakened test, or a deleted assertion. If you cannot fix the real cause within scope,
    report the cause and stop.
  - P4 (no unrequested rewrite): Stay inside the SCOPE FENCE. Match existing style. Do not
    refactor, restructure, or delete working code you were not asked to change.

RETURN: only the OUTPUT CONTRACT above, plus a one-line "CONFIDENCE + what I could NOT verify."
```

Why each block exists:
- **ROLE + "STOP if missing"** converts a silent guess into a visible gap — the single best defense against context starvation (§6).
- **CONTEXT** is where P2 dies: an agent handed the real API signature won't invent one.
- **OUTPUT CONTRACT with evidence labels** is what makes synthesis honest (§5) and prevents result laundering.
- **SCOPE FENCE + DISCIPLINE** re-install the P1–P4 guardrails the agent lacks. You are exporting the library's non-negotiables into a mind that never read them.

Rule: **no delegated prompt ships without all four P1–P4 lines.** If you are tempted to trim them "to keep it short," you are removing the exact discipline the agent is most likely to drop.

---

## 4. Verification topologies

To *check* work (yours or an agent's), spawn agents whose structure makes agreement meaningful. Redundancy is only informative when the copies are **independent**; N identical agents given identical prompts mostly repeat the same blind spot.

| Topology | How to build it | Best for | Watch out for |
|---|---|---|---|
| **Adversarial refuter panel** | N subagents, each told their ONLY job is to **break** the conclusion — find the counterexample, the missed case, the confound. Blind to your preferred answer. | Deciding whether to trust a conclusion / a "fix" / a research verdict before acting on it. | If any refuter is told the answer you want, it will rationalize it. Keep them adversarial and independent. |
| **Perspective-diverse review** | N subagents, each a **different lens** on the same artifact: e.g. security, performance, correctness/edge-cases, readability, API-contract stability. | Reviewing a diff, design, or plan where different failure classes need different eyes. | Diversity of *lens* beats N clones. Two "correctness" reviewers < one correctness + one security + one perf. |
| **Majority gate** | Spawn N independent solvers of the same well-posed question; take the answer the majority reach; **investigate disagreement rather than just outvoting it.** | A question with a checkable answer where a lone agent might slip (a count, a classification, a yes/no). | A tie or a split is a signal the question is ambiguous or hard — dig in, don't just tally. Majority ≠ truth; it's a smoke alarm. |

**Concrete refuter-panel prompt** (this is the artifact fable-hypothesis-and-experiment routes here for — the *science* of refutation is owned there; this is *how to write the multi-agent version*):

```
ROLE: You are an independent skeptic with NO prior context. Your ONLY job is to REFUTE the
claim below. You get no credit for agreeing. Find the case where it is FALSE.

THE CLAIM UNDER TEST:
  <state the conclusion exactly, e.g. "The intermittent test failure is caused by cache
   eviction being FIFO not LRU.">

THE EVIDENCE OFFERED FOR IT (given to you neutrally, not as proof):
  <paste the data/observations the claim rests on — no spin, no "and this proves...">.

YOUR JOB:
  1. Name at least one ALTERNATIVE mechanism that fits the SAME evidence.
  2. Point to any observation the claim does NOT explain (an outlier, a negative case).
  3. Identify a CONFOUND: something else that changed and could be the real cause.
  4. Design one discriminating check that would DISTINGUISH the claim from your alternative.

OUTPUT CONTRACT:
  - Verdict: SURVIVES (I could not break it and here is why) | REFUTED (here is the
    counterexample/alternative that fits better).
  - Label each point [RAN]/[READ]/[INFERRED] as in the standard contract.
  - Do NOT hedge into agreement. If it truly survives your best attack, say so — that is a
    strong result precisely because you tried to kill it.
```

A conclusion that survives several **independent** refuters is far stronger than one you argued for yourself. Do not self-grade a conclusion you are attached to.

---

## 5. Synthesis discipline (the orchestrator owns reconciliation)

Collecting outputs is not synthesizing them. The orchestrator's hardest, non-delegable job is to **reconcile**, and the cardinal sin is concatenation.

1. **Never concatenate contradictory findings.** If agent A says "no timeouts missing" and agent B flags three, the report is NOT "A found none; B found three." That is an unresolved contradiction dressed as a finding. Exactly one of them is right (or they scoped different files) — **find out which**, then report the reconciled truth.
2. **Trace every disagreement to evidence.** Pull the [RAN]/[READ] evidence each agent gave. A [RAN] with pasted output beats an [INFERRED] assertion. If both claim [RAN] and still disagree, they ran different things — re-run the discriminating check yourself. Disagreement is a lead, not noise to average away.
3. **Preserve evidence labels end to end (anti-laundering).** When you lift a finding from a subagent into your report, carry its label. A subagent's `[INFERRED]` must not silently become your confident assertion. If the agent did not verify it, your report says "reported but not verified" — see fable-reporting-and-writing for calibrated language, and fable-ground-truth for what re-verification would upgrade an `[INFERRED]` label to `[RAN]`/`[READ]` (re-run it, or read the file — its cite-your-source triad). **Downgrading is safe; upgrading requires new evidence you gathered.**
4. **Resolve, then compress.** The final answer is a single reconciled account, not a transcript of who said what. Attribute only where the source matters (e.g. "the security lens flagged X"); otherwise deliver one coherent conclusion at a calibrated confidence.
5. **The orchestrator re-verifies the load-bearing claim.** For anything the final decision hinges on, do not take an agent's word — reproduce the key observation yourself before you commit. This is the multi-agent version of the P1 rule.

---

## 6. Failure modes (recognize and prevent)

| Failure | What it looks like | Root cause | Prevention |
|---|---|---|---|
| **Duplicated work** | Two agents independently do the same audit / edit the same file. | Slices overlapped; partition not stated. | Explicit, disjoint scope per prompt ("you own ONLY A–F"). §2. |
| **Context starvation** | Agent's output is wrong or full of guesses because a critical fact was never in its prompt. | Orchestrator assumed the agent "knows" something only in this conversation. | Self-contained prompt (§3) + the "STOP and report MISSING" instruction so gaps surface loudly. |
| **Result laundering** | An agent's unverified guess is reported up as established fact. | Evidence label dropped during synthesis (§5). | Mandatory evidence labels in the output contract; carry them into the report; downgrade-only rule. |
| **Coordination cost > win** | You spent longer briefing and reconciling N agents than solving it solo. | Fan-out chosen by reflex, not by the §1 cost test. | Run the §1 litmus first. Default solo. Fan out only when independent slices at real scale clear the overhead. |
| **Straggler stall** | The whole barrier waits on one slow/hung agent. | Barrier topology on uneven slices. | Balance slice sizes; set a bound; consider a pipeline so partial results flow. §2. |
| **Groupthink panel** | N "reviewers" all miss the same bug. | Identical prompts / same lens = correlated blind spots. | Perspective-diverse or adversarial panels, not clones (§4). |
| **Poisoned pipeline** | A wrong early-stage output silently corrupts all downstream agents. | No verification between pipeline stages. | Verify each stage's output before feeding it on (§2, §5). |

---

## 7. When NOT to orchestrate

Delegation is a tool with a cost, not a virtue. Prefer **solo** when any of these hold:

- **The task needs one coherent context.** Tightly coupled reasoning, a design that must stay consistent across every part, or edits where each depends on the last — splitting it fractures the very context that makes it correct.
- **The slices aren't independent.** If they share mutable state or each needs the others' results, you don't have a fan-out; you have a sequence (or one task).
- **Briefing costs more than doing.** If writing self-contained prompts and reconciling returns takes longer than just solving it, solve it. (§1 litmus.)
- **The answer is a single small fact or fix.** Scouting or fanning out a one-liner is pure overhead.

> **Environment note (as of 2026-07-13).** This skill's core mechanic — spawning subagents — requires a host environment that provides it (for example, Claude Code's Agent / Workflow / Task tools). **Verify the actual tool exists in your environment before relying on any of this; do not assume a `Task`/`Agent` tool by name — that would be P2.** When no subagent capability is available, this skill **degrades gracefully to sequential self-review with role-switching**: you play each panelist in turn (write the conclusion, then explicitly switch to "now I am the refuter, blind to my preferred answer," attack it, then reconcile). You lose true independence — the same mind is less independent from itself than a separate agent is — so weight a self-review conclusion less than one that survived a genuinely separate refuter, and say so when you report.

---

## When NOT to use this skill (load the sibling instead)

| Situation | Load instead |
|---|---|
| The master operate loop and which sibling to load when | fable-operating-core |
| The *science* of refutation / hypothesis lifecycle (this skill only writes the multi-agent prompt for it) | fable-hypothesis-and-experiment |
| What counts as proof a change is done; the done-ness evidence ladder (rungs 0–5) | fable-verification-standards |
| The observed-vs-inferred / cite-your-source discipline the `[RAN]/[READ]/[INFERRED]` labels operationalize | fable-ground-truth |
| Verifying a specific API/flag/path/version is real | fable-ground-truth |
| Keeping a change minimal, in-scope, reversible (the P4 discipline itself) | fable-scope-and-change-control |
| Root-cause debugging method | fable-debugging-playbook |
| Calibrated language / how to report findings without overselling | fable-reporting-and-writing |
| Attacking one large hard problem with a phased, gated campaign (may *use* this skill for panels) | fable-hard-problem-campaign |

Boundary statements: adversarial refutation as a *method* is owned by fable-hypothesis-and-experiment; this skill owns only **how to write and run the multi-agent version** of it. The subagent-report evidence labels `[RAN]/[READ]/[INFERRED]` are defined by THIS skill (§3); they operationalize fable-ground-truth's observed-vs-inferred, cite-your-source discipline (`[RAN]`=command output, `[READ]`=file:line, `[INFERRED]`=ASSUMPTION). Note these are a *different axis* from fable-verification-standards' done-ness rung ladder (rungs 0–5) — the labels do not duplicate or defer to it. Calibration of the final claim is owned by fable-reporting-and-writing.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| Solo/scout/fan-out decision table and honest cost accounting | First-principles reasoning about overhead vs parallelism win | Stable reasoning; revisit if delegation cost model changes. |
| Decomposition (independence, output-contract-first, pipeline vs barrier) | First-principles reasoning about shared mutable state and dependencies | Stable. |
| Self-contained subagent prompt template + P1–P4 fences | First-principles + the library's four user-reported failure modes (dated 2026-07-13); context-free agents regress to P1–P4 | Re-confirm P1–P4 definitions with maintainer if the library's stated failure modes change. |
| Verification topologies (refuter panel, perspective-diverse, majority gate) | First-principles about independence of redundant checks; honors incoming contract from fable-hypothesis-and-experiment | Stable; keep the refuter-panel prompt in sync with that sibling's routing text. |
| Synthesis / anti-laundering (preserve & downgrade-only evidence labels) | First-principles; the `[RAN]/[READ]/[INFERRED]` labels are defined here and operationalize fable-ground-truth's cite-your-source triad | Re-check that fable-ground-truth still defines the observed-vs-inferred triad (command output / file:line / ASSUMPTION) these labels map to. |
| Failure-mode table | First-principles about the listed topologies | Stable. |
| Subagent capability is environment-specific; Claude Code Agent/Workflow/Task tools as example (as of 2026-07-13) | Documented Claude Code behavior at the date; **must be verified per environment** | Re-check that a subagent/Task tool actually exists in the current environment and by what name before relying on it; update the example if tool names change. |
| Sibling skill names in cross-references and When-NOT table | Library inventory (as of 2026-07-13) | Re-check names against the current skills/ directory; fix any renamed sibling. |

No scripts ship with this skill: the subagent prompt is pasted into a delegation tool call, not fetched via shell, so it lives inline as a fenced template above. A shell script would only redundantly emit it.
