---
name: fable-failure-archaeology
description: "Load when you are about to start risky or unfamiliar work and want a pre-mortem, when a session just hit a costly failure and you want to record it so it never recurs, when you suspect you are repeating a known agent failure mode (declaring done without checking, hallucinating APIs, shallow patching, unrequested rewrites, repeating a rejected approach, silent fallbacks swallowing errors), or when you want the catalog of documented AI-agent failure modes with their countermeasures. This is the WHY-it-fails registry (incident format: symptom to root cause to evidence to countermeasure to status). Do NOT load for the step-by-step debugging method itself (use fable-debugging-playbook), for the definition of done and evidence rules (use fable-verification-standards), for anti-hallucination technique (use fable-ground-truth), or for change/scope gates (use fable-scope-and-change-control) — this skill catalogs the failures those siblings prevent and points at them."
---

## 繁中摘要

- 這是一份「AI 代理常見失敗模式」的事故檔案庫：每條以「症狀 → 根因 → 證據 → 對策 → 狀態」格式記錄，讓每個 session 不必重打已解決的仗。
- 收錄四個由使用者回報的創始事故 P1–P4（2026-07-13，標記為 user-reported），以及約 12 個業界公認的代理失敗模式（標記為 field-common pattern，非虛構特定事件）。
- 開工前做 pre-mortem：先掃這份清單，找出這次任務最可能踩的雷，再動手。
- 真的踩雷時，用本技能的協議把事故寫成專案內的紀錄（scripts/new-incident.sh 產生範本）；若是通用型，提議加進本清單。
- 本技能只負責「為什麼會失敗」的登記與對策指向；實際除錯方法、完成定義、防幻覺技巧、改動閘門各有專屬 sibling 技能，此處只交叉引用不重複。
- 誠實鐵律：P1–P4 標 user-reported 2026-07-13，其餘標 field-common pattern，絕不捏造具體事件。

---

# Failure Archaeology

A **failure archaeology** is a registry of failures that have already cost time,
written so a later session recognizes the pattern *before* repeating it. This
library's founding purpose is to stop four expensive AI-agent failure modes; this
skill is where those modes — and the broader field-known catalog — live as
**incidents**.

Each sibling skill teaches a *method*. This skill catalogs the *failures those
methods prevent*, and points at the sibling that owns the deeper fix. It answers
"what goes wrong, how do I recognize it, and what stops it" — not "how do I debug"
(that is `fable-debugging-playbook`).

## When to use this skill

| Situation | What to do here |
|---|---|
| About to start risky/unfamiliar work | Run the **pre-mortem** scan (bottom) before touching anything. |
| A session just burned time on a failure | Record it with the **adding-an-incident** protocol so it is settled. |
| You feel you may be repeating a mistake | Search the catalog by symptom; check "have I fenced this off?" |
| Reviewing another agent's work | Use the catalog as a checklist of things to look for. |

## When NOT to use this skill

| You want… | Load instead |
|---|---|
| The step-by-step method to find a root cause | `fable-debugging-playbook` |
| The definition of "done" and what counts as proof | `fable-verification-standards` |
| How to avoid stating unverified APIs/paths/flags | `fable-ground-truth` |
| Gates before deleting/refactoring/rewriting | `fable-scope-and-change-control` |
| The master operating loop and router | `fable-operating-core` |
| How research hypotheses must be structured | `fable-hypothesis-and-experiment` |

This skill *names and files* failures. The siblings *prevent* them. If you find
yourself writing a debugging procedure here, it belongs in a sibling — cross-
reference it instead.

## The incident format

Every entry uses exactly five fields. This structure forces honesty: a claim with
no **Evidence** field is a hunch, and a **Countermeasure** that is only "be more
careful" is not settled.

| Field | Meaning | Bad answer | Good answer |
|---|---|---|---|
| **Symptom** | The observable surface failure. | "It broke." | "`--dry-run` flag rejected: `unknown option`." |
| **Root cause** | The ONE mechanism explaining ALL observations. | "Flaky." | "Flag exists in v2 docs, project pins v1." |
| **Evidence** | What proves the root cause. | none | "`tool --help` in the repo lists no `--dry-run`." |
| **Countermeasure** | The check/discipline that prevents recurrence. Prefer a check that *fails loudly* over a reminder. | "Remember to verify." | "Grep `--help` output before citing any flag." |
| **Status** | `open` = prevention relies on in-the-moment discipline and still recurs in practice. `settled` = the countermeasure is a mechanical, automatable check that, once wired into a project, removes reliance on memory. | — | `settled` / `open` |

**Provenance labels** (never fabricate a specific event):
- `user-reported 2026-07-13` — the four founding incidents, reported by the library owner.
- `field-common pattern` — widely documented AI-agent/engineering failure modes. These describe *classes*, not a specific dated incident.
- `project-local` — an incident recorded in a real session via the protocol below.

---

## Founding incidents (user-reported 2026-07-13)

These four cost the most time and are the reason this library exists. All are
`user-reported 2026-07-13`. All are `open`: each is prevented only by discipline,
not by an automatic check, so all still recur when the discipline lapses — which
is why the user reported them as top active time-sinks. A named sibling owns the
discipline that reduces each. (Statuses as of 2026-07-13.)

### P1 — Completion claimed without verification
- **Symptom:** Agent reports "fixed"/"done"; tests are green, yet the feature is broken end-to-end. Or the fix was never actually executed.
- **Root cause:** Success was *inferred* from a proxy (code compiles, unit test passes, "looks right") instead of *observed* in the real behavior the user cares about.
- **Evidence:** The failure reappears the first time the actual flow is exercised; no log/output/screenshot of the real behavior exists in the session.
- **Countermeasure:** Never claim done without end-to-end observation of the actual behavior. A green test is a proxy, not proof. Owned by `fable-verification-standards` (evidence hierarchy).
- **Status:** `open` — the discipline is defined but not mechanically enforced; still recurs when skipped.

### P2 — Hallucinated API / path / flag / parameter
- **Symptom:** A runbook or patch looks correct but does not run: unknown flag, missing file, wrong function signature, non-existent config key.
- **Root cause:** A plausible-from-training detail was stated as fact without checking it against the actual installed version/repo.
- **Evidence:** `--help`, the source, or the package version contradicts the cited detail.
- **Countermeasure:** Verify every API/flag/path/version against reality *before* stating it. Owned by `fable-ground-truth`.
- **Status:** `open` — technique defined but not mechanically enforced; still recurs when verification is skipped.

### P3 — Shallow patch instead of root cause
- **Symptom:** Error "goes away" via try/except, a retry loop, a bumped timeout, or an edited test — but the underlying defect remains.
- **Root cause:** The symptom was silenced instead of explained; no single mechanism was ever shown to account for all observations.
- **Evidence:** The masked failure resurfaces elsewhere, intermittently, or under load; the "fix" touches error-handling/tests, not the mechanism.
- **Countermeasure:** Require one mechanism that explains all observations before fixing. Fence off symptom-silencing patches. Owned by `fable-debugging-playbook`.
- **Status:** `open` — method defined but not mechanically enforced; still recurs when discipline is skipped.

### P4 — Unrequested rewrite / refactor / deletion
- **Symptom:** Working functionality disappears or changes because the agent "cleaned up," reformatted, or rewrote code that was not in scope.
- **Root cause:** No change-classification or scope gate; the agent treated "improve" as license to touch anything.
- **Evidence:** The diff is far larger than the request; behavior changed in areas the user never mentioned.
- **Countermeasure:** Minimal-diff discipline; gate destructive/irreversible actions; do only what was asked. Owned by `fable-scope-and-change-control`.
- **Status:** `open` — gates defined but not mechanically enforced; still recurs when gates are skipped.

---

## Field-common agent failure modes (field-common pattern)

Widely documented patterns (catalog and statuses as of 2026-07-13). Each is a
**class**, labelled `field-common pattern` — not a fabricated specific event.
**Countermeasure owner** names the sibling with the deeper fix; that sibling is
the source of truth for the "how."

| # | Pattern | Symptom | Root cause | Countermeasure (owner) | Status |
|---|---|---|---|---|---|
| F1 | Context amnesia | Re-proposes an approach already tried and rejected earlier in the session/thread. | Earlier rejection fell out of working context; no durable record kept. | Keep a running "tried & rejected" note; scan it before proposing. Record as project-local incident. (this skill) | open |
| F2 | Sycophantic agreement | Abandons a correct, evidence-backed position because the user pushed back. | Optimizing for agreement over truth; treating pushback as disproof. | Weigh evidence, not social pressure — pushback with no new evidence is not disproof (`fable-operating-core` N8); surface the conflict explicitly (`fable-reporting-and-writing`, faithful-reporting / the silence rule). | open |
| F3 | Premature success declaration | "Should work now" without running it. | Same proxy-vs-proof error as P1, milder. | Observe the real behavior before declaring. (`fable-verification-standards`) | open |
| F4 | Partial-read wrong edit | Edits based on the first N lines; breaks a guard/branch further down the file. | Read a slice, assumed the rest; edited against an incomplete mental model. | Read the whole function/region (and callers) before editing. (`fable-codebase-archaeology`) | open |
| F5 | Environment assumption transplant | Runs `npm`/`pip` in a `cargo`/`go` project; assumes a build tool that is not there. | Pattern-matched to the most common stack instead of detecting the actual one. | Detect the toolchain from the repo before running anything. (`fable-environment-recon`) | settled |
| F6 | Unpinned-version drift | Docs/behavior cited for a version different from the one installed. | Assumed "latest"; the project pins an older/forked version. | Read the lockfile/manifest; cite the installed version. (`fable-ground-truth`, `fable-environment-recon`) | settled |
| F7 | Silent fallback swallows error | A broad `except`/`catch` or default value hides the real failure; wrong result flows on. | Defensive code turned a loud failure into a silent wrong answer. | Let failures surface; never catch-and-continue without re-raising or logging the cause. (`fable-debugging-playbook`) | open |
| F8 | Deleting "unused" load-bearing code | Removes code that "looks dead"; something breaks that had no obvious caller. | Static "looks unused" ignored dynamic/reflective/config-driven use. | Prove non-use (grep all forms, run the suite, check dynamic dispatch) before deleting; treat deletion as irreversible. (`fable-scope-and-change-control`) | open |
| F9 | Mock/test data leaks to prod path | A stub, fixture, hard-coded sample, or `TODO` value reaches a real code path. | Test scaffolding was never removed; no boundary between fixture and product. | Grep for fixture markers before done; assert no test doubles on prod paths. (`fable-verification-standards`) | settled |
| F10 | Summary drift across a long session | Late-session "summary" contradicts what was actually done earlier. | Compounding paraphrase; summarizing the summary, not the record. | Anchor summaries to concrete artifacts (diffs, outputs), not prior prose. (`fable-reporting-and-writing`) | open |
| F11 | Retry-masking a race | Adding retries/sleeps makes an intermittent failure "pass." | A real ordering/concurrency bug was hidden by timing, not fixed. | Treat intermittent green as unproven; find the race. (`fable-debugging-playbook`) | open |
| F12 | Confirmation-biased debugging | Only gathers evidence that fits the first guess; ignores contradicting signals. | Stopped at the first plausible cause; no discriminating experiment. | One mechanism must explain ALL observations, including negatives. (`fable-debugging-playbook`, `fable-hypothesis-and-experiment`) | open |
| F13 | Eyeballed "improvement" | Claims something is faster/smaller/better with no measurement. | Judged by feel; no baseline, no before/after. | Measure against a baseline; report numbers with variance. (`fable-diagnostics-and-measurement`) | open |
| F14 | Fix-verified-in-wrong-place | Verifies against a cached build, stale process, or different environment than the change. | The observed "pass" came from an artifact that predates the edit. | Confirm the change is loaded (rebuild/restart) before verifying. (`fable-verification-standards`, `fable-environment-recon`) | open |

Status uses the same criterion as the format table (statuses as of 2026-07-13):
`open` = prevention needs in-the-moment judgment/discipline and still recurs — a
standing hazard to scan for. `settled` (F5, F6, F9) = the countermeasure is a
purely mechanical check (detect the toolchain from repo files; read the version
from the lockfile; grep for fixture markers) that, once wired into a project,
prevents recurrence without relying on memory. Note the settled sub-cases sit
under `open` parents: F6 is the mechanizable slice of P2, and F7/F11 are the
non-mechanizable slices of P3 — a narrow dumb check can be `settled` while the
broad discipline it lives under stays `open`.

---

## Adding an incident (how the archaeology grows)

When a real session burns meaningful time on a failure, capture it so no future
session re-fights it. Two homes:

1. **Project-local record** (default). The failure may be project-specific, so
   file it *in the project*, not in this global skill. The **manual template
   below works everywhere** and needs no script — reach for it first.

   As a convenience, this skill ships `scripts/new-incident.sh`, which generates
   the fill-in stub for you. It lives inside the skill directory, not in your
   project, so invoke it by its full path (skills deploy under
   `~/.claude/skills/` when installed globally). Run it *from your project root*
   — it writes to the current working directory:

   ```sh
   # Writes ./.failure-archaeology/<date>-<slug>.md as a five-field stub.
   # Portable POSIX sh; adjust the path to wherever this skill is installed.
   ~/.claude/skills/fable-failure-archaeology/scripts/new-incident.sh "retry-masked-race"
   ```

   Then fill every field. The record is not done until **Evidence** points at a
   concrete artifact (a failing repro, a log line, a diff, a measurement) and
   **Countermeasure** is a check that fails loudly rather than a reminder. Flip
   **Status** to `settled` only after the countermeasure is verified end-to-end
   (see `fable-verification-standards`).

2. **Propose a catalog entry** (only if generic). If the pattern is *not*
   project-specific — it would bite any project — add it to the field-common
   table above as a new `F#`, labelled `field-common pattern`, with the sibling
   that owns its countermeasure. Do **not** invent a dated specific incident; the
   catalog holds classes, and only `user-reported`/`project-local` entries name a
   dated event.

**Honesty gate for every new entry:** if you cannot name real Evidence, you do
not have an incident yet — you have a hunch. Mark it `open` and say so.

### Manual template (if you cannot run the script)

```
# Incident: <slug>
- Date observed: <YYYY-MM-DD>
- Provenance: project-local (observed this session)
## Symptom        <observable surface failure, exact text>
## Root cause     <one mechanism explaining ALL observations; "unknown" is allowed>
## Evidence       <repro / log / diff / measurement — no claim without this>
## Countermeasure <a check that fails loudly, not "be careful">
## Status         open | settled
## Generic?       <if not project-specific, propose an F# catalog entry>
```

---

## Pre-mortem: scan before risky work

Before starting anything with real blast radius (a refactor, a deploy path, an
unfamiliar module, a "quick fix" under pressure), spend two minutes asking which
catalogued failures this task most invites. A **pre-mortem** imagines the task has
already failed and asks *how*.

Checklist — for THIS task, which apply?

- [ ] Will I be tempted to declare done without running the real flow? → P1 / F3 / F14
- [ ] Am I about to cite a flag/path/API/version I have not verified here? → P2 / F6
- [ ] Am I reaching for a try/except, retry, or sleep to make an error go away? → P3 / F7 / F11
- [ ] Is my diff about to grow beyond what was asked (cleanup, rename, delete)? → P4 / F8
- [ ] Have I already tried and rejected something like this earlier? → F1
- [ ] Am I changing course only because of pushback, against the evidence? → F2
- [ ] Did I read the whole region and its callers, or just a slice? → F4
- [ ] Am I assuming a build/test tool without detecting the real one? → F5
- [ ] Could a fixture/stub/TODO value be reaching a real path? → F9
- [ ] Am I claiming better/faster without a measured baseline? → F13
- [ ] Does my leading guess explain ALL observations, including the ones that don't fit? → F12

Any box you cannot clear names the sibling skill to load *before* proceeding, per
the table in "When NOT to use this skill" and the countermeasure owners above.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| Incident format (5 fields) | First-principles: a failure record needs symptom, cause, proof, fix, and a settled/open flag to be actionable. | Reasoning; stable. Revisit only if a field proves unused across many real entries. |
| P1–P4 founding incidents | User-reported pain points, dated 2026-07-13. | Ask the library owner whether these four still capture the top time-sinks; update wording if their experience shifts. |
| F1–F14 field-common patterns | First-principles reasoning about well-known AI-agent/engineering failure modes; labelled as classes, not specific events. | Sanity-check each against current agent behavior; add/retire entries as new patterns become common or old ones become mechanically prevented. |
| Countermeasure owners (sibling names) | This library's fixed inventory (see `fable-operating-core` router). | If a sibling is renamed/split, update the owner column and cross-references. |
| `scripts/new-incident.sh` | Written and tested for this skill (POSIX sh; slug sanitize, no-clobber, dated path). Verified by running in a scratch dir on 2026-07-13. | Re-run in a scratch dir on any `date`/`sed`/`tr` environment change; confirm it still produces the five-field stub and refuses to clobber. |

**Boundary reminder:** this skill is the *registry* of failures. The *methods*
that prevent them live in the named siblings — keep the "how" there and the
"what/why/recognize" here. When in doubt about where a fact lives, `fable-
operating-core` holds the router.
