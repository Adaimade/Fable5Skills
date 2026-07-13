---
name: fable-skill-authoring-and-frontier
description: "Load when you are authoring, editing, reviewing, or splitting a skill in THIS Fable Thinking library — creating a new SKILL.md, writing or fixing a trigger-rich description, deciding which skill owns a fact, running the ship/no-ship review, or filing a library bug because a real session hit a failure the library should have prevented. Also load when asked to work on the library's research frontier — how to prove a skill changes model behavior, whether descriptions fire when they should, drift detection, token compression, cross-model portability. Symptom phrases: 'add a skill', 'this description isn't triggering', 'where does this content belong', 'is this skill done', 'the library should have caught this'. Do NOT load to author project docs or READMEs (this governs only skills in .claude/skills/); for the general reporting/provenance house style see fable-reporting-and-writing; for the master operating loop and router see fable-operating-core."
---

## 繁中摘要

- 這是「元技能」：教你如何以與整個 Fable Thinking library 相同的標準來新增/修改/審查一個 skill，並描述這個 library 的研究前沿（尚未解決的開放問題）。
- Skill 格式規範（as of 2026-07-13）：`.claude/skills/<name>/SKILL.md`，緊接 `## 繁中摘要`，其餘英文。本 library 的「內規」是 frontmatter 只用 name + description 兩個鍵；但這是內規，不是平台限制——Claude Code / Agent Skills 官方格式其實允許許多選用鍵（如 allowed-tools、disable-model-invocation、model 等，見 code.claude.com/docs/en/skills），多加不算格式錯誤。需定期對照官方文件重新驗證（可能漂移）。
- Description 是寫給「檢索器」看的：列出應觸發載入的症狀、任務用語、情境，以及何時不要載入（指向正確的姊妹技能）。
- 所有權法則：一個事實只有一個家。動筆前先查哪個姊妹技能已擁有相鄰主題，用交叉引用而非複製。
- 品質門檻：只有當一個零背景的冷讀者不需作者在場就能照做，skill 才能出貨；提供三段式審查（事實 / 教義 / 可用性）與可攜式格式 lint 腳本。
- 前沿：五個明確標為「open」的開放問題，各附「現況為何不足、本 library 的資產、前三步、可證偽的完成標準」。維護協議：真實 session 撞到本該被擋下的失誤，就是 bug，記到擁有該主題的技能上。

---

This is the **meta-skill**: how to extend this library without lowering its bar, and what remains genuinely unsolved. Everything else in the library tells you how to think about code; this tells you how to think about the library itself. It defends the same four failure modes one level up: a skill shipped without a cold-reader test is P1 (unverified "done"); a hallucinated flag inside an anti-hallucination library is P2 and fatally ironic; duplicating a sibling's content instead of fixing the one home is P3 (shallow); rewriting a working sibling because you did not read it first is P4.

Jargon, defined once:
- **Skill**: one `SKILL.md` file (plus optional `scripts/`, `references/`) that a model loads mid-task to raise its standard on a specific class of work.
- **Frontmatter**: the YAML block fenced by `---` at the very top of `SKILL.md`.
- **Retriever**: the mechanism (a model or a matcher) that reads only skill *descriptions* and decides which to load. It never sees the body until it has already decided. You write the description FOR it.
- **Trigger**: a symptom, task phrase, or situation in the description that should cause the retriever to load the skill.
- **Owner**: the single sibling skill responsible for a given fact or topic. One home per fact.
- **Cold reader**: a zero-context mid-level engineer or Sonnet-class model that loads your skill mid-task with no knowledge of this library's history. Your only real audience.

---

## 1. The skill format spec (as of 2026-07-13)

> This format follows Claude Code **Agent Skills** conventions. It is the class of fact most likely to DRIFT. Re-verify the frontmatter contract against current Claude Code / Agent Skills docs before trusting this section blindly (see Provenance). If the docs and this section disagree, the docs win — then fix this section.

| Rule | Requirement |
|---|---|
| **Path** | `.claude/skills/<skill-name>/SKILL.md`. Directory name = skill name = frontmatter `name`. |
| **Frontmatter keys** | **House convention:** use exactly `name` + `description` and nothing else, for consistency across the library. This is a *house rule, not a platform limit* — the Claude Code / Agent Skills format documents many valid OPTIONAL keys (`allowed-tools`, `disallowed-tools`, `disable-model-invocation`, `user-invocable`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `argument-hint`, `arguments`, `when_to_use`, `shell`; see code.claude.com/docs/en/skills). Adding one is **not a format break** — it just departs from this library's convention, so justify it. Do NOT invent keys like `version`/`tags`/`author` that the docs do not list (that would be P2). |
| **`name`** | Matches the directory. Kebab-case. In this library, prefixed `fable-`. |
| **`description`** | One single line, plain YAML-safe text, quote the whole value so a `: ` inside cannot break parsing. Under 1000 characters. Trigger-rich (see §2). |
| **繁中摘要** | Immediately after frontmatter: `## 繁中摘要`, 4–6 Traditional-Chinese bullets summarizing what/when. Everything else English. |
| **Voice** | Imperative runbook ("Do X. Then check Y."). Tables and checklists over prose walls. |
| **Commands** | Portable (POSIX shell, git, generic tools) or clearly marked "pattern — adapt". No machine-specific paths, usernames, or private project names in CONTENT. |
| **Volatile facts** | Date-stamp as "(as of 2026-07-13)". |
| **When-NOT section** | Name the sibling to load instead for each adjacent situation. |
| **Provenance section** | Ends the file: where each claim class comes from + a one-line re-verify action for anything that can drift. |
| **Length** | 200–450 lines. Dense and scannable beats long. |

Run `scripts/check-skill.sh <file>` for a fast pre-flight on the mechanical rules (fenced frontmatter, `name` + `description` present, description length, required sections present). It **FAILs** if `name` or `description` is missing and **WARNs** (does not fail) on any extra frontmatter key — extra keys are valid Claude Code fields, just off the house convention. It is a lint, not a review — it cannot see whether a trigger fires or a command is real. Green lint is necessary, never sufficient.

---

## 2. Description craft — write for the retriever, not the reader

The description is the ONLY text the retriever sees. If it does not name the situation the model is in, the skill never loads — and an unloaded skill is worth zero no matter how good the body is. This is the highest-leverage 1000 characters in the whole file.

Write it as an **inclusion list plus an exclusion list**:

| Put IN the description | Leave it OUT |
|---|---|
| Concrete **symptom phrases** a model would actually think ("this description isn't triggering", "where does this belong") | What the skill *is* philosophically ("a treatise on quality") |
| **Task types** ("authoring a skill", "reviewing whether a change is done") | Internal structure ("has three sections and a table") |
| **Situations / triggers** (the state the model is in when it needs you) | Praise or scope claims ("the definitive guide to…") |
| **When NOT to load**, naming the correct sibling | Anything the retriever cannot match a real task against |

Craft rules:
- **Lead with the trigger, not the topic.** "Load when you are about to say done/fixed/passing" beats "About verification standards."
- **Include the words the model will be thinking**, including symptom phrases and error-adjacent language. The retriever matches surface forms; give it surface forms.
- **State the boundary.** Every skill has a neighbor. Naming "do NOT load for X, use sibling Y" prevents both misfires and the retriever loading three overlapping skills.
- **One line, quoted, under 1000 chars.** Quote the whole value; a bare `: ` mid-description can break YAML parsing.
- **Do not oversell.** The description is a matcher, not marketing. "Defends against P1" is fine; "guarantees correct completion" is a false claim inside an anti-hallucination library.

Whether a description reliably fires is not something you can prove by reading it — that is frontier problem (b) in §5. Until you have a test matrix, treat trigger coverage as a best-effort craft, not a solved property.

---

## 3. Ownership law — one home per fact

**Every fact lives in exactly one skill. Adjacent skills cross-reference by name; they never duplicate.** Duplication is a latent bug: the two copies drift, and a reader who finds the stale one is misled by the very library meant to prevent that.

Before authoring or adding a paragraph:
1. **Scan the library inventory** (the sibling list in fable-operating-core's router, or `ls .claude/skills/`). Ask: does a sibling already own this topic?
2. **If a sibling owns it** — cross-reference it ("see fable-ground-truth"). Do not restate its content, even "briefly". A one-line pointer is correct; a paraphrase is duplication.
3. **If two skills both seem to own it** — the boundary is unclear. Decide the split explicitly, state it in BOTH skills' When-NOT sections, and put the fact in exactly one. Ambiguous ownership is how duplication starts.
4. **If nobody owns it** — either it belongs inside an existing skill's charter (add it there) or it is a genuinely new topic (new skill). Do not wedge an unrelated topic into a skill because it is nearby.

Boundary-writing pattern (use in the When-NOT table): name the sibling, then say in one clause what it owns versus what you own. Example: "fable-reporting-and-writing owns the general provenance/house-style; this skill owns provenance *as applied to authoring skills*."

---

## 4. The authoring checklist and the ship/no-ship review

### 4a. Authoring checklist (before you consider a draft done)

- [ ] **Audience is a cold reader.** Zero library history assumed. Every jargon term defined at first use.
- [ ] **Ground truth for every command.** No invented flags, paths, file formats, or behaviors. If you are not certain a flag exists, verify it (see fable-ground-truth) or delete it. A hallucinated command here is fatal irony.
- [ ] **Shipped scripts are TESTED by running them.** Build fixtures in a scratch dir (e.g. `/private/tmp`), never in the repo. If a script cannot be made portable and tested, do NOT ship it — describe the technique in prose and record the gap.
- [ ] **Volatile facts date-stamped** "(as of 2026-07-13)".
- [ ] **Provenance section present** (the provenance-section discipline; see fable-reporting-and-writing), with a re-verify line for anything that can drift.
- [ ] **No oversell** (the calibrated-claims discipline; see fable-reporting-and-writing). Methodology framed as discipline/heuristics, not guarantees. Unproven ideas labeled "open" or "candidate".
- [ ] **No private paths / usernames / project names** in content. Portable only.
- [ ] **Ownership checked** (§3): no sibling's content duplicated; boundaries stated.
- [ ] **When-NOT section** names the right sibling for each adjacent situation.
- [ ] **Format lint passes:** `sh ~/.claude/skills/fable-skill-authoring-and-frontier/scripts/check-skill.sh path/to/SKILL.md` (adjust to wherever this skill is installed; or `cd` into the skills dir and run `sh fable-skill-authoring-and-frontier/scripts/check-skill.sh */SKILL.md`).

### 4b. The review protocol (three passes, each defined)

A skill ships only if a cold reader could act on it without the author present. Run three passes; each has a distinct question and a distinct failure it catches. Do NOT collapse them — they find different defects.

| Pass | Question it answers | Method | Catches |
|---|---|---|---|
| **Factual** | Is every concrete claim TRUE? | Check each command/flag/path/format against reality; run every shipped script; verify cross-referenced sibling names exist. | P2 (hallucination) — the fatal-irony class. |
| **Doctrine** | Does it agree with the rest of the library? | Check it against the library non-negotiables and each cited sibling's charter; confirm it does not contradict or duplicate a sibling. | Drift, contradiction, one-home-per-fact violations. |
| **Usability** | Can a cold reader ACT on it alone? | Read as a zero-context model mid-task: is every trigger in the description matchable? Is every step executable without hidden knowledge? Is anything undefined-on-first-use? | P1-shaped "looks right, can't run it" and dead-on-arrival skills the retriever never loads. |

Rule: **claim strength never exceeds evidence strength** (the discipline fable-verification-standards owns). A skill that says "verify the flag" but ships an unverified flag fails the factual pass regardless of how good its prose is.

---

## 5. THE FRONTIER — open problems (ALL open, none solved)

These are the unsolved problems in making smaller models think at this standard. None is claimed solved. Each states why current practice falls short, the specific asset this library brings, the first three concrete steps, and a **falsifiable "you have a result when…"** milestone — so progress is checkable, not vibes.

### (a) Does a skill actually change model behavior? — OPEN
- **Why current practice falls short:** skills are written and shipped on the author's faith that they help. There is no measurement that loading the skill changes what the model does. "Feels better" is P1 at the library level.
- **This library's asset:** each skill already names the specific failure modes (P1–P4) it targets — pre-declared, scorable behaviors to measure against.
- **First three steps:** (1) pick one skill and 5–10 tasks it claims to improve; (2) run each task twice — skill loaded vs not — holding model and prompt fixed; (3) score both with a fixed rubric derived from the skill's own claims, ideally graded blind by a separate model.
- **You have a result when:** on a held-out task set, the skill-loaded runs score higher on the pre-registered rubric than the no-skill runs by a margin larger than run-to-run variance (see fable-diagnostics-and-measurement for variance), and the effect replicates on a second task set.

### (b) Trigger reliability — do descriptions fire when they should? — OPEN
- **Why current practice falls short:** descriptions are hand-tuned by intuition. Nobody knows the false-negative rate (should-have-loaded, did not) or false-positive rate (loaded, irrelevant).
- **This library's asset:** each description already enumerates intended triggers and explicit when-NOT boundaries — a ready-made spec of what SHOULD and should NOT fire.
- **First three steps:** (1) for one skill, write 15–20 paraphrased task prompts that SHOULD trigger it plus 15–20 near-miss prompts that should NOT (the sibling's territory); (2) present each to the retriever with the full description set; (3) record load / no-load into a confusion matrix.
- **You have a result when:** you can report a precision/recall number per skill on the paraphrase matrix, and can show a description edit moving a specific previously-misclassified paraphrase to the correct side without regressing the others.

### (c) Skill drift detection — OPEN
- **Why current practice falls short:** provenance sections list re-verify actions, but nothing RUNS them. A flag that changed upstream stays wrong until a human happens to notice.
- **This library's asset:** every skill ends with an explicit, itemized provenance/re-verify table — a machine-readable-ish checklist already exists.
- **First three steps:** (1) standardize provenance rows so each drift-prone claim has a checkable assertion; (2) write a harness that extracts those rows; (3) for the subset that is mechanically checkable (a file exists, a command's `--help` still lists a flag), run them and diff against last-known-good.
- **You have a result when:** an automated run flags at least one genuinely stale claim before a human does, with a false-alarm rate low enough that maintainers act on its output instead of ignoring it.

### (d) Compression — minimum tokens per behavioral gain — OPEN
- **Why current practice falls short:** skills cost context every time they load. Nobody knows which sentences carry the behavioral change and which are ballast. Longer is assumed better; it may be worse (dilution).
- **This library's asset:** frontier (a)'s behavior-measurement harness makes "gain" measurable, so "gain per token" becomes computable.
- **First three steps:** (1) get a behavior score for the full skill (needs (a)); (2) ablate — remove one section at a time and re-score; (3) rank sections by score-drop per token removed.
- **You have a result when:** you can exhibit a shortened variant that holds the behavioral score within variance at materially fewer tokens — or prove the opposite, that below some length the gain collapses (a real floor).

### (e) Cross-model portability — does the library hold for non-Claude models? — OPEN
- **Why current practice falls short:** the library was distilled from one model's methodology (Fable 5) and is tuned on Claude-family behavior. Whether it transfers to other model families is untested.
- **This library's asset:** the skills are written as explicit externalized discipline (checklists, gates, rubrics) rather than relying on implicit model habits — externalized rules are the most portable form.
- **First three steps:** (1) take the (a) behavior harness; (2) run the same skill-vs-no-skill comparison on a non-Claude model of similar tier; (3) compare the effect size and sign to the Claude-family result.
- **You have a result when:** you can state, per skill, whether the behavioral gain replicates on another model family — and identify which specific constructs (checklists vs prose doctrine vs cross-references) survive the transfer and which do not.

> All five depend on frontier (a): without a way to measure behavior change, the others cannot be scored. Attack (a) first. Treat every result above as a *candidate* until it replicates — this library does not get to exempt its own research from its own evidence bar (see fable-hypothesis-and-experiment).

---

## 6. Library maintenance protocol

**When a real session hits a failure this library should have prevented, that is a BUG — file it against the owning skill.** The library's whole value is that no session re-fights a settled battle; a repeat means a skill has a gap.

Triage a library bug:

| Step | Action |
|---|---|
| 1. Classify the failure | Which of P1–P4 (or new class) did the session hit? |
| 2. Find the owner | Which skill's charter *should* have covered it? Use the §3 inventory scan. If genuinely no owner exists, it may be a missing skill — route to the author. |
| 3. Decide gap type | Missing content, weak trigger (skill existed but did not load — a frontier-(b) symptom), or wrong content (drift — frontier (c))? |
| 4. Fix at the one home | Patch the owning skill only. Do not scatter the fix across siblings (that reintroduces duplication). |
| 5. Consider the incident catalog | If it is a recurring, settled failure mode, it also belongs as an incident in fable-failure-archaeology (which owns the catalog; this protocol owns only the *filing* decision). |

A useful library bug report names: the task, what the model did, which skill should have caught it, and why it did not (not loaded / loaded-but-silent-on-this / said-the-wrong-thing).

---

## When NOT to use this skill (load the sibling instead)

| Situation | Load instead |
|---|---|
| Authoring project docs, READMEs, or code comments (not a skill in `.claude/skills/`) | (general writing — this skill governs skills only) |
| The general reporting / provenance / no-oversell house style for any deliverable | fable-reporting-and-writing |
| The master operating loop and which sibling to load for a situation | fable-operating-core |
| Defining "done" / evidence hierarchy for a code change | fable-verification-standards |
| Verifying a specific API/flag/path is real (the technique, not the authoring rule) | fable-ground-truth |
| Measuring behavior change, variance, before/after numbers (for frontier (a)/(d)) | fable-diagnostics-and-measurement |
| Running the frontier problems as actual research with predictions | fable-hypothesis-and-experiment |
| Cataloguing a settled recurring failure as an incident | fable-failure-archaeology |

Boundary with fable-reporting-and-writing: it owns the general house style (lead-with-outcome, calibrated claims, the provenance-section discipline) for ANY output; this skill owns those rules *as applied to authoring a library skill*, plus the format spec, ownership law, review protocol, and the research frontier. When in doubt about phrasing, that sibling is the home; about skill structure and the frontier, this one is.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| Skill format spec (path, frontmatter keys, sections, length) | Claude Code Agent Skills conventions + this library's stated format rules (as of 2026-07-13) | **Re-check the frontmatter contract against current Claude Code / Agent Skills docs — this is the most drift-prone section.** If docs disagree, docs win, then fix §1. |
| Description-for-the-retriever craft (§2) | First-principles reasoning about how retrieval works + library format rules | Stable in principle; adjust if the retrieval mechanism's matching behavior is documented to change. |
| Ownership law / one-home-per-fact (§3) | Library cross-referencing rules (as of 2026-07-13) + first-principles on duplication drift | Re-check sibling names/charters against the current `skills/` directory; fix any rename. |
| Authoring checklist + review protocol (§4) | Library write/truth rules + the four failure modes (P1–P4), user-reported (dated 2026-07-13) | Re-confirm with maintainer if the library's stated failure modes or write rules change. |
| The four failure modes P1–P4 | User-reported pain points (dated 2026-07-13) | Re-confirm with maintainer. |
| Frontier problems (a)–(e) — all labeled OPEN | First-principles reasoning about evaluating skills; none claimed solved | If any is attacked and a result obtained, update its status from OPEN and record the evidence; until then it stays open. |
| Maintenance protocol (§6) | Library maintenance rule (a prevented-but-recurred failure is a bug), user-stated (dated 2026-07-13) | Stable; adjust step 5 if the incident-catalog owner changes. |
| `scripts/check-skill.sh` behavior | Tested on darwin (POSIX `sh`): `sh -n` clean; runs green across all 15 `SKILL.md` files (as of 2026-07-13). It **FAILs** only on a missing `name`/`description`, missing required sections, or an over-length/absent description; extra frontmatter keys (including hyphenated ones like `allowed-tools`, now correctly detected) produce a **WARN**, not a FAIL, because they are valid Claude Code fields — see §1. It counts the raw description value INCLUDING wrapping quotes, so its length check is ~2 chars stricter than the value alone — treat borderline results as advisory. Fixtures exercised: extra/hyphenated keys (WARN), missing name (FAIL), no-closing-fence, no-opening-fence, missing-file paths. | From the skills root (`.claude/skills/`) re-run `sh fable-skill-authoring-and-frontier/scripts/check-skill.sh */SKILL.md` after any edit; it is a format lint only, never a substitute for the §4b review. |
| Sibling skill names in cross-references and When-NOT table | Library inventory (as of 2026-07-13) | Re-check names against the current `skills/` directory; fix any renamed sibling. |
