---
name: fable-codebase-archaeology
description: "Load BEFORE editing code you did not write and do not already understand — any unfamiliar repo, module, or subsystem you are about to debug, extend, or refactor. Triggers: first task in a new codebase, 'I must change X but do not know how it works', a file everything imports, a bug with no obvious owner, or the urge to refactor something that looks odd. How to READ a codebase and recover its architecture contract, invariants, and conventions from code plus git history before touching anything — the primary defense against P4 (unrequested rewrites that destroy working functionality) and P3 (shallow patching without understanding). Do NOT load for greenfield code you write fresh, or code you already know. For how to build/test/RUN the project use fable-environment-recon; for the change rule itself use fable-scope-and-change-control; for proof it works use fable-verification-standards; for the catalog of AI-agent failure modes use fable-failure-archaeology."
---

## 繁中摘要

- 本技能教你在「動手改動之前」如何讀懂一個陌生的程式庫：從程式碼、文件與 git 歷史中還原它的架構契約、承重決策、隱性不變式與慣例。
- 提供一條可照做的偵查流程（進入點與清單檔 → 目錄拓撲 → 文件 → 依賴骨幹 → git 歷史考古 → TODO 熱點 → 以測試當作可執行文件）。
- 核心產出是「不變式帳本」：動手前先把發現的不變式寫下來，並用 Chesterton 圍籬原則，把「一致但無說明的模式」預設為刻意設計，直到有證據反駁。
- 內附可攜、已實測的 `scripts/archaeology.sh`：唯讀掃描 git 變動熱點、還原紀錄、警語註解與拓撲，只給線索、不下結論。
- 附校準表：一行修正 vs 子系統改動各要做多少考古；以及何時「不要」用本技能。
- 這是主要對抗 P4（未經要求的重寫破壞既有功能）與 P3（未理解就淺層打補丁）的技能。建置/測試/執行深度請轉 fable-environment-recon。

# Codebase archaeology: read before you touch

You are about to change code you did not write. The failure this skill prevents:
you edit something that looks wrong or redundant, and it turns out to have been
load-bearing — you have caused P4 (an unrequested change that destroyed working
functionality). The countermeasure is not caution-as-vibe; it is a short,
disciplined reconnaissance that recovers the **architecture contract** before the
first edit.

**Architecture contract** = the set of decisions, invariants, and conventions the
code depends on to keep working, most of which nobody wrote down. Your job is to
reconstruct enough of it that your change respects it.

Two rules frame everything below:

1. **Undocumented but consistent = intentional until proven otherwise.** A pattern
   repeated across the codebase is a decision, not an accident, even when no
   comment explains it. (This is Chesterton's Fence — see §3.)
2. **Every signal is a lead, never a verdict.** Churn counts, import counts, and
   test density tell you *where to look*, not *what is true*. Confirm by reading.

---

## §1. The recon sequence (runbook)

Do these in order. Stop early when the task is small (see the calibration table in
§5). Commands are portable POSIX shell / git; adapt filenames to the ecosystem.

You can run steps 2, 5, 6 and part of 1/7 at once with the shipped read-only
scanner — it writes nothing and executes no project code:

```sh
# Invoke by its installed path — skills deploy under ~/.claude/skills/ (personal) or a
# project's .claude/skills/; adjust the path to wherever this skill lives. Read-only.
sh ~/.claude/skills/fable-codebase-archaeology/scripts/archaeology.sh <path-to-repo>
# prints signals; read the files it names
```

Then work the sequence deliberately:

| # | Step | Portable command / action | What you are looking for |
|---|------|---------------------------|--------------------------|
| 1 | **Entry points & manifests** | `ls`; find `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `Makefile`, `Dockerfile`, `main.*`, `index.*` | Where execution starts; declared dependencies; declared scripts |
| 2 | **Directory topology** | `find . -maxdepth 2 -type d` (prune `node_modules`, `.git`, `vendor`, `dist`) | The rough module map; where the code mass lives |
| 3 | **README / docs** | read `README*`, `ARCHITECTURE*`, `CONTRIBUTING*`, `docs/` | The authors' own mental model and stated rules |
| 4 | **How it builds/tests/runs** | → route to **fable-environment-recon** | (Owned there. Do not re-derive here.) |
| 5 | **Dependency spine** | see §1a below | The few modules everything imports — the load-bearing core |
| 6 | **Git history archaeology** | see §1b below | What changes often, what was reverted, why decisions were made |
| 7 | **TODO/FIXME + warning comments** | `git grep -nIE 'TODO|FIXME|HACK|XXX|WARNING|DO NOT'` | Known-fragile spots; invariants people bothered to write |
| 8 | **Tests as executable documentation** | read the tests around your target | Intended behavior, edge cases, and the real contract |

Step 8 is about *understanding* behavior from tests, not proving your change works
— that is **fable-verification-standards**' job.

### §1a. The dependency spine

The **dependency spine** is the small set of modules that most other modules
import. Touching a spine module has blast radius across the whole codebase; touching
a leaf does not. Find it by counting inbound references. Portable, language-agnostic
first pass (greps import/include/require lines and ranks the named targets):

```sh
# Rank the most-imported local module names (heuristic — tune the pattern per language).
git grep -hE '^\s*(import|from|require|include|use )' -- '*.*' \
  | grep -oE '[A-Za-z0-9_./]+' | sort | uniq -c | sort -rn | head -30
```

Treat the ranking as a lead: open the top few and confirm they are genuinely
central (a config or logging module tops these lists without being architecturally
load-bearing — read to tell the difference).

### §1b. Git history archaeology

Git history is the only record of decisions that were tried, kept, or undone. All
read-only:

```sh
git log --oneline -20                       # recent narrative of the project
git log --format= --name-only | sort | uniq -c | sort -rn | head   # most-churned files
git log --grep=revert -i --oneline          # things that were undone — read the pain
git log -p -- path/to/file                  # why THIS file looks the way it does
git log -S 'someSymbol' --oneline           # when a symbol was introduced/removed
git blame path/to/file                      # who/what/when for a specific line
```

**Most-churned** files are either load-bearing (everyone must edit them) OR fragile
(they keep breaking). You cannot tell which from the count — open the file and its
recent diffs to decide.

**Reverts** are gold: a revert means someone made exactly the change that looked
reasonable to you, and it broke something. Read the reverted commit and the revert's
message before repeating it.

> If the repo has no git history (shallow clone, exported tarball), steps 5/7 still
> work via `grep -r`; step 6 is unavailable — say so in your notes and lean harder
> on tests and comments.

---

## §2. Discovering the architecture contract

The invariants that matter are usually the ones nobody documented. Recover them
from these five signals — each is corroborating evidence, none is proof alone:

| Signal | How to read it | What it implies |
|--------|----------------|-----------------|
| **What everything imports** (§1a spine) | high inbound reference count | changing its interface breaks many callers — a contract, not an implementation detail |
| **What has the most tests around it** | count test files/cases touching a module | the authors considered this behavior load-bearing and worth pinning |
| **What comments warn about** | `WARNING`/`DO NOT`/`HACK`/`must`/`invariant` near code | an explicit invariant — the cheapest kind to find; obey it |
| **What git shows was reverted** (§1b) | `git log --grep=revert`, then read the diff | a change of this shape has already failed once |
| **What is consistent without explanation** | the same pattern repeated across files | an intentional convention (Chesterton's Fence, §3) |

Cross-check them. When four signals point at the same module — heavily imported,
heavily tested, warning-commented, and churny — you have found a load-bearing
decision. Do not "clean it up" as a side effect of your task.

---

## §3. The invariant ledger (write it down before editing)

Before you edit, write down the invariants you have discovered. An **invariant** is
a property the code assumes always holds (e.g. "this list is always sorted", "IDs
are never reused", "this function is only ever called on the main thread"). Break one
silently and you get a bug far from your diff.

**Chesterton's Fence** (the principle behind rule 1 up top): before removing or
changing something whose purpose you do not understand, first find out *why it is
there*. If you cannot explain why the fence was built, you are not yet qualified to
tear it down. Applied to code: an odd-looking line, a redundant-seeming check, or an
unusual pattern is presumed intentional until git history, tests, or an author tell
you otherwise. (The rule against acting on that presumption to rewrite/delete is
owned by **fable-scope-and-change-control** — this skill only tells you to *discover
the fence first*.)

Keep a ledger for the current task. Copy-paste this table and fill it in:

| Invariant (what must stay true) | Evidence (where you saw it) | Confidence | What breaks if violated |
|--------------------------------|-----------------------------|------------|-------------------------|
| e.g. `cache keys are lowercased before lookup` | 3 call sites + `test_cache_lower` | high | silent cache misses |
| e.g. `db handle is opened once, reused` | `db.py:init` comment "DO NOT reopen" | high | connection-pool exhaustion |
| e.g. `events processed in arrival order` | consistent pattern, no test | medium | out-of-order state corruption |

Confidence rubric: **high** = explicit comment/test or multiple corroborating
signals; **medium** = consistent pattern, no explicit statement; **low** = single
occurrence, could be incidental. Low-confidence entries are the ones to confirm (ask,
or write a discriminating test) before your change relies on them either way.

Your change must not violate any high/medium invariant without a deliberate,
stated decision to change the contract on purpose.

---

## §4. Convention matching

Code that respects local conventions is reviewable and reversible; code that imports
your personal style is noise that hides the real diff. Before writing, infer and
match. Fill this quickly by reading 2–3 neighbouring files:

- [ ] **Naming** — case style (`snake_case` / `camelCase` / `PascalCase`), noun/verb
      patterns, abbreviations the project uses. Match the file you are editing.
- [ ] **File & module layout** — where does a new function/type/test belong? Follow
      the existing placement, not what you would pick fresh.
- [ ] **Error handling idiom** — exceptions vs result/error returns vs error codes?
      Does the project wrap errors, log-and-continue, or fail fast? Match it exactly;
      do not introduce a second idiom.
- [ ] **Test structure** — framework, file naming (`test_*` / `*.test.*` /
      `*_test.go`), arrange/act/assert style, fixture conventions. New tests must
      look like existing ones.
- [ ] **Imports/formatting** — ordering, grouping, quote style. If a formatter/linter
      config exists (`.editorconfig`, `.prettierrc`, `ruff`, etc.), it is the
      authority — defer to it over your preference.

When two conventions conflict in the codebase, match the *nearest* one (same file >
same directory > same package) and note the inconsistency rather than "fixing" it.

---

## §5. Calibration: how much archaeology per task size

Archaeology has a cost. Match the depth to the blast radius of your change, not to
how interesting the code is.

| Task | Minimum recon before editing | Skip |
|------|------------------------------|------|
| **One-line fix in a leaf file** | read the file + its direct tests; `git log -p` on that file | full topology, spine analysis |
| **Change to one function's behavior** | above + callers of that function (`git grep`), its tests, any warning comments | history of unrelated modules |
| **New feature in an existing module** | §1 steps 1–3, 5, 8 on that module; §3 ledger for the module's invariants | repo-wide churn ranking |
| **Subsystem change / refactor across files** | full §1 sequence; §2 contract discovery; §3 ledger; §4 conventions | nothing — do it all |
| **Touching a spine module** (high inbound count) | everything, plus enumerate callers and their tests; expect wide blast radius | nothing |

When unsure, do one level more than feels necessary — the cost of extra reading is
minutes; the cost of an unnoticed broken invariant is a P4 incident.

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| Writing new/greenfield code with no existing contract to respect | just write it (apply §4 conventions once files exist) |
| You already know this codebase well | proceed; skim §3 only if the change is risky |
| You need to know how to build/test/**run** the project | **fable-environment-recon** |
| You are deciding whether a change is in-scope / reversible | **fable-scope-and-change-control** |
| You need to prove your change actually works | **fable-verification-standards** |
| You are avoiding hallucinated APIs/paths/flags in what you write | **fable-ground-truth** (reading real code here is *how* you comply) |
| You want the catalog of AI-agent failure incidents | **fable-failure-archaeology** (different "archaeology" — failure modes, not code) |
| You are attacking a genuinely hard problem end-to-end | **fable-hard-problem-campaign** (do the recon here first, then run the campaign) |

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|-------------|--------|--------------|
| Recon sequence, contract-discovery signals, invariant ledger, Chesterton's Fence, calibration | First-principles reasoning about how codebases encode undocumented decisions | Review against your own recent "I broke a hidden invariant" incidents; adjust the signal table |
| Git commands (`log`, `blame`, `grep`, `log -S`, `--grep=revert`) | Standard git usage; all read-only; tested on a scratch fixture (as of 2026-07-13) | `git help log`; re-run `scripts/archaeology.sh` on any repo |
| `scripts/archaeology.sh` behavior | Written and tested on git and non-git fixtures in `/private/tmp` (as of 2026-07-13) | Run it against a known repo; confirm sections populate and it writes nothing |
| Failure modes P3/P4 this defends | User-reported pain points (2026-07-13) | Confirm with maintainer these remain the costly modes |
| Ownership boundaries (siblings named) | Fable Thinking library inventory (as of 2026-07-13) | Re-check sibling skill names exist and still own the cited topics |

**Drift watch:** the import-ranking grep in §1a is a heuristic and will over- or
under-match per language — it is labeled as a lead, not a fact, on purpose. If a
future ecosystem uses a syntax it misses, tune the pattern; do not treat its output
as ground truth.
