# Fable Thinking — a project-agnostic skill library

**Purpose**: extract the working methodology of a distinguished-engineer-class model (Fable 5) into 15 portable skills, so junior/mid-level engineers and Sonnet-class models can debug, extend, validate, and research at the same standard — in ANY project.

**目的**：把 Fable 5 的工作思考方法萃取成 15 個不綁定專案的技能，讓任何工程師或較小的模型在任何專案中都能以相同紀律思考與行事。

- **Source of truth**: this repo (`Fable5Skills/.claude/skills/`).
- **Deployment**: copy the whole directory into `~/.claude/skills/` to load globally in every session.
- **Language**: English body (best model adherence) + a `繁中摘要` section atop each skill.
- **Founding pain points** (user-reported 2026-07-13, each skill defends where its topic touches them): P1 unverified completion claims · P2 hallucinated APIs/paths/flags · P3 shallow patching without root cause · P4 unrequested rewrites/destruction.

## Inventory

| Skill | One-liner | Defends |
|---|---|---|
| [fable-operating-core](fable-operating-core/SKILL.md) | The master loop (understand → ground truth → plan → act small → verify → report) + non-negotiables + router to all siblings. Start here. | all |
| [fable-ground-truth](fable-ground-truth/SKILL.md) | Never state an API/flag/path/version without verifying against reality; claim-type → cheapest-verification table; assumption ledger. | P2 |
| [fable-verification-standards](fable-verification-standards/SKILL.md) | Definition of done; evidence hierarchy; claim strength must never exceed evidence strength. | P1 |
| [fable-scope-and-change-control](fable-scope-and-change-control/SKILL.md) | Minimal-diff discipline; change classification and gates; reversibility drills; no unrequested rewrites. | P4 |
| [fable-debugging-playbook](fable-debugging-playbook/SKILL.md) | Root-cause method; symptom→triage table; fenced wrong paths (error-silencing, test-loosening, retry-masking). | P3 |
| [fable-failure-archaeology](fable-failure-archaeology/SKILL.md) | Incident catalog (symptom → root cause → evidence → countermeasure → status); protocol for adding new incidents. | all |
| [fable-codebase-archaeology](fable-codebase-archaeology/SKILL.md) | Reading an unfamiliar codebase before touching it; discovering invariants and the architecture contract. | P4 |
| [fable-environment-recon](fable-environment-recon/SKILL.md) | How any project builds/tests/runs, from manifests and CI — never guess; version-manager and env traps; `scripts/recon.sh`. | P2 |
| [fable-diagnostics-and-measurement](fable-diagnostics-and-measurement/SKILL.md) | Measure, don't eyeball: baselines before change, repeat runs, variance; interpretation guide; `scripts/repeat-bench.pl`. | P1 |
| [fable-hypothesis-and-experiment](fable-hypothesis-and-experiment/SKILL.md) | Hypotheses must predict numbers before running; one mechanism must explain ALL observations; adversarial refutation; idea lifecycle. | P3 |
| [fable-first-principles-analysis](fable-first-principles-analysis/SKILL.md) | Prove-it toolkit: estimation, invariants, complexity, boundary analysis, unit sanity — derivation first, measurement second. | P3 |
| [fable-hard-problem-campaign](fable-hard-problem-campaign/SKILL.md) | Decision-gated campaign template for problems that resist normal debugging: phases, gates with expected observations, ranked solution menu. | P3 |
| [fable-orchestration-and-delegation](fable-orchestration-and-delegation/SKILL.md) | When and how to fan out to subagents; self-contained prompts; adversarial verification panels; synthesis discipline. | P1/P2 |
| [fable-reporting-and-writing](fable-reporting-and-writing/SKILL.md) | Lead with the outcome; faithful failure reporting; calibration vocabulary; runbook house style; handoff templates. | P1 |
| [fable-skill-authoring-and-frontier](fable-skill-authoring-and-frontier/SKILL.md) | How to extend this library at standard; `scripts/check-skill.sh` linter; open frontier problems with falsifiable milestones. | — |

## Maintenance

- Lint everything: `sh fable-skill-authoring-and-frontier/scripts/check-skill.sh */SKILL.md` (run from this directory; all 15 PASS as of 2026-07-14).
- When a real session hits a failure this library should have prevented, that is a **bug** — file it against the owning skill (see fable-skill-authoring-and-frontier §6).
- One home per fact: before adding content, check which sibling owns the topic; cross-reference, never duplicate.
- Volatile facts are date-stamped in-skill; each skill ends with a Provenance section listing re-verification actions.

Built 2026-07-13/14 via multi-agent workflow: 15 parallel authors → 3 reviewers (factual / doctrine / usability) → 1 fixer. Review found 1 blocking + 7 important + 2 minor findings; all blocking/important applied.
