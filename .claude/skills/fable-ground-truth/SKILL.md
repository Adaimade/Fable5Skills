---
name: fable-ground-truth
description: "Load this WHENEVER you are about to state or use a concrete fact you did not just read from reality — an API/function/method name, CLI flag or subcommand, file/dir path, library API, version number, config key, env var, URL/endpoint, or default value. Symptoms: writing a runbook or command someone will paste, being 'pretty sure' the flag is `--foo`, recalling an API from memory, writing plausible code for a library you have not opened, a command that failed with 'unknown option'/'no such file'/'has no attribute'. This is the anti-hallucination (P2) skill: verify-before-assert plus cite-your-source. Do NOT load it for: what counts as done / end-to-end proof (use fable-verification-standards); root-causing a known bug (use fable-debugging-playbook); learning how a project builds/runs (use fable-environment-recon); reading a codebase's architecture (use fable-codebase-archaeology)."
---

## 繁中摘要

- 本技能是「反幻覺」紀律 (對抗 P2)：任何 API、函式名、旗標、路徑、版本、設定鍵、環境變數、URL 或預設值，在說出或使用前必須先對照真實來源查證。
- 提供「宣稱類型 → 最便宜查證動作」對照表 (例如函式是否存在 → grep 原始碼；CLI 旗標 → `--help`；套件 API → 讀已安裝的原始碼與 lockfile 版本；路徑 → `ls`/`stat`)。
- 提供幻覺風險排名：模型最常在何處捏造 (似是而非的名稱、混用不同版本、從別的框架搬移慣用法)。
- 「標註來源」習慣：輸出中每個承載性宣稱都要能追溯到 file:line、指令輸出，或明確標記為假設 (ASSUMPTION)。
- 假設帳本 (assumption ledger)：無法查證的宣稱要單獨列出並標記，絕不悄悄混入事實。
- 附出貨前檢查清單與可攜式輔助腳本 `scripts/extract-claims.sh`，用來從草稿抽出待查證項目。

---

# fable-ground-truth

**Ground truth means: a fact you have observed from the system itself in this session** — read from a file, printed by a command, returned by an API you just called. Its opposite is a fact you recalled, inferred, or pattern-matched from another project. This skill exists because recalled facts *look identical* to observed ones on the page, and that is exactly how a runbook that "looks right" fails to run (failure mode P2: hallucinated APIs, paths, flags, or parameters).

## The one rule

> **Before you state or use a concrete fact, verify it against reality — or label it an assumption. No third option.**

A "concrete fact" is anything a machine could disagree with: an API / function / method name and its signature, a CLI flag or subcommand, a file or directory path, a library's public API, a package/tool version, a config key or its default, an environment variable name, a URL or endpoint, an error string you claim will appear.

The rule is not "be careful." It is a *gate*: for each concrete fact about to leave your fingers, either (a) point to where you just observed it, or (b) write the word ASSUMPTION next to it. If you can do neither, you are hallucinating — stop and verify.

Why a gate and not vibes: memory-recall and observation are indistinguishable from the inside. The only reliable discriminator is an external check. Skipping the check *feels* the same whether the fact is right or wrong; that symmetry is the trap.

## Claim type → cheapest verification action

Pick the **cheapest action that would fail loudly if the fact were wrong.** Commands below are patterns — adapt the tool to the project (see fable-environment-recon to learn its stack first).

| Claim type | Cheapest verification | Fails loudly when wrong? |
|---|---|---|
| Function / method / class exists | `grep -rn "name" src/` (for several names use `-E` with pipe-alternation) or read the defining file | Yes — no match |
| Function signature / params | Read the definition (grep to the file, open it) | Yes — args differ |
| CLI flag / subcommand | `the-cmd --help` or `the-cmd help sub` | Yes — flag absent |
| Tool/CLI actually installed | `command -v the-cmd` | Yes — empty output |
| Library / package API | Read the *installed* source: `python3 -c "import PKG, os; print(os.path.dirname(PKG.__file__))"`, `node -e "console.log(require.resolve('pkg'))"`, then open it | Yes — attribute missing |
| Installed version | `pkg --version`; or read the lockfile (`package-lock.json`, `poetry.lock`, `Cargo.lock`, `go.mod`, pinned `requirements.txt`) — NOT the loose range in the manifest | Yes — mismatch |
| File / directory path | `ls -la PATH` or `stat PATH` | Yes — "No such file" |
| Config key / default | Read the config file AND the code that parses it (grep the key name); defaults live in the parser, not your memory | Yes — key/parse absent |
| Environment variable | `grep -rn "VARNAME" .` (find where it is read); `printenv VARNAME` for current value | Yes — never read |
| Endpoint / route / URL | Grep the route table / server code; for external URLs, only after user OK, fetch and check status | Partly — 404/no route |
| Error string you predict | Grep the codebase for the literal string, or trigger it | Yes — no such string |
| "It defaults to X" / "usually Y" | Treat as ASSUMPTION until you read the default in source | n/a — label it |

Rule of thumb: **the verification should touch the same artifact the user will touch.** Checking a doc site when the user runs a locally-installed binary is not verification — versions drift. Read what is installed.

## Where models actually hallucinate (risk ranking)

Spend verification effort here first — highest to lowest expected error rate:

| Rank | Pattern | Why it happens | Tell-tale |
|---|---|---|---|
| 1 | **Plausible-but-wrong names** — `--recursive` when it's `-r`, `readFileSync` when it's `read_file`, `df.append` when it was removed | Name-shaped gap filled by the most *frequent* token in training, not this project's token | You'd bet money but never grepped it |
| 2 | **Version-mixed APIs** — combining calls from v1 and v3 of a library that never coexisted | Training blends versions; the blend compiles in your head | Signature "feels" right but you don't know the pinned version |
| 3 | **Transplanted idioms** — React patterns in Vue, pytest fixtures in unittest, npm flags on yarn | Adjacent-framework muscle memory | You learned it "somewhere like this" |
| 4 | **Invented paths / layout** — `src/utils/helpers.js` because projects "usually" have one | Convention-completion | You typed a path you never `ls`'d |
| 5 | **Confident defaults** — "timeout defaults to 30s", "it retries 3×" | Defaults vary per version/config | A number with no source |
| 6 | **Stale/renamed** — deprecated flag, renamed method, moved config | The world moved since training cutoff | "This used to work" energy |

The unifying cause: **fluency is not knowledge.** The more natural a name feels, the more it deserves a grep — high fluency is *correlated with* high training frequency, which is exactly what generic-but-wrong tokens have.

### Phrases that should trigger a grep

These come out of your own mouth right before a P2 mistake. Treat each as a hard stop — verify before the sentence ends:

- "pretty sure it's `--…`" / "I think the flag is…"
- "usually" / "by default" / "typically it's…" (defaults vary — read it)
- "should be at `path/…`" / "it's probably in `src/…`"
- "the API is roughly…" / "something like `foo.bar()`"
- "like in \<other framework\>" / "same as \<other project\>" (transplant risk)
- "IIRC" / "from memory" / "last I checked" (stale risk)
- "let me just add a try/except so it doesn't error" (that's a shallow patch — see fable-debugging-playbook, not a verification)

## Cite your source

Every load-bearing claim in your output should be traceable to one of exactly three things:

1. **`file:line`** — "the flag is `--strict` (`src/cli.rs:212`)"
2. **command output** — "3 tests exist (`ls test/ | wc -l` → 3)"
3. **an explicit `ASSUMPTION:` label** — "ASSUMPTION: the service listens on 8080 (README says so; not verified against running process)"

If a claim fits none of these, it is unsourced and must not be stated as fact. Citations do not need to bloat prose — a trailing `(path:line)` or a footnote is enough. The discipline is that *you looked*, and the reader can re-look. This is the same evidence habit fable-verification-standards applies to "is it done"; here it applies to "is it true."

Cheap citation habits:
- When you grep/read to verify, keep the `path:line` from the result and paste it inline. Don't re-derive it later.
- Quote the *exact* token you verified, not a paraphrase (`--no-verify`, not "the skip-verification flag").
- If you verified a fact 40 messages ago and are now unsure it still holds (file edited since?), re-verify — a citation to a stale read is not ground truth.

## Assumption ledger

When you cannot verify something right now (no access, would take too long, external system), do **not** silently promote it to fact and do **not** silently drop it. Label it and collect it.

**Inline:** prefix with `ASSUMPTION:` at the point of use.

**Collected:** keep a short ledger the reader sees, e.g. at the end of a runbook:

```
## Assumptions (unverified — confirm before relying)
- ASSUMPTION: prod uses the same config schema as staging (checked staging only).
- ASSUMPTION: `deploy.sh` is idempotent (README implies it; not tested).
- ASSUMPTION: node ≥ 18 present on target (local is 20; target unchecked).
```

Rules for the ledger:
- One line each: the claim, and *why* it's unverified / what would verify it.
- Assumptions are liabilities, not decoration — the shorter the ledger, the more you actually verified.
- Never blend an assumption into a factual sentence. "The server runs on 8080" and "ASSUMPTION: the server runs on 8080" are different claims; collapsing them is how P2 spreads.
- Promote or kill: when you later verify one, either restate it as a cited fact or, if wrong, fix everything that depended on it.

## Before you ship any runbook / instructions / code — checklist

Run every box. A single unchecked concrete fact is enough to make the whole thing untrustworthy.

- [ ] Every **command** — the binary exists (`command -v`) and every **flag** is in its `--help`.
- [ ] Every **path** — `ls`/`stat` confirms it, or it's clearly a placeholder (`<your-path>`).
- [ ] Every **API/function/method** used — grepped or read in the *installed* source, not recalled.
- [ ] Every **version-sensitive** call matches the **pinned** version (lockfile), not a remembered one.
- [ ] Every **config key / env var** — traced to where it is read/parsed.
- [ ] Every **default value / "usually"** claim — either sourced or labeled `ASSUMPTION`.
- [ ] Every **URL/endpoint** — grepped from routes/source; external fetches only with user OK.
- [ ] **Citations present** for load-bearing claims (`file:line` / command output).
- [ ] **Assumption ledger** written for everything you couldn't verify (empty is best).
- [ ] You did **not** invent a name to fill a gap — if you were "pretty sure", you grepped it.
- [ ] Nothing verified long ago and possibly stale (file edited since your read?).

Optional helper: `scripts/extract-claims.sh FILE` scans a draft and prints a worklist of flags, paths, dotted API refs, and fenced commands to verify. It is deliberately **over-inclusive** (false positives are cheap; a missed claim is the real danger) and it does **not** verify anything — it only seeds the ledger. Example:

```
# Invoke by its installed path — skills deploy under ~/.claude/skills/ (personal) or a
# project's .claude/skills/; adjust to wherever this skill lives. Reads the file you pass.
sh ~/.claude/skills/fable-ground-truth/scripts/extract-claims.sh my-runbook.md
```

## Worked micro-example

Task: "add a `--verbose` flag to the deploy script and document it."

Wrong (P2): write "Run `./deploy.sh --verbose` for detailed logs" because that's what such scripts usually take.

Ground-truth flow:
1. `grep -rnE "verbose|getopts|argparse|ArgumentParser" deploy.sh` → find the arg parser (or find there is none).
2. If none exists, the flag doesn't exist yet — say so, implement it, then cite the new line.
3. Verify the runtime: `sh deploy.sh --verbose` actually runs and changes output (this is where fable-verification-standards takes over — observe the behavior, don't assume it).
4. Document: "Run `./deploy.sh --verbose` for detailed logs (`deploy.sh:14`, added this change)."

The whole difference is step 1 — three seconds of grep between a guess and a fact.

## Worked micro-example 2 — library API (risk ranks 1–2)

Task: "serialize this object to a YAML string using the project's yaml library."

Wrong (P2): write `yaml.dump(obj, default_flow_style=False)` — the name and kwarg *feel* right, but they belong to PyYAML; the project might use `ruamel.yaml` (different API), or a version where the default already changed. This is a plausible-but-wrong name (rank 1) possibly version-mixed (rank 2).

Ground-truth flow:
1. Find what is actually imported: `grep -rnE "import yaml|from ruamel" src/` (adapt patterns to the language) → learn which library.
2. Find the installed source and version: `python3 -c "import yaml, os; print(yaml.__version__, os.path.dirname(yaml.__file__))"` (adapt to the language/package manager).
3. Confirm the function and its real signature by reading that source, or `python3 -c "import yaml, inspect; print(inspect.signature(yaml.dump))"` — now `inspect` is actually used, to read the true signature.
4. Only then write the call, cited: "`yaml.dump(obj, default_flow_style=False)` (PyYAML `<version from step 2>`, `dump` signature confirmed via inspect)."

If step 1 shows there is no yaml dependency at all, the honest output is "no YAML library is present; options: add one (scope change — see fable-scope-and-change-control) or hand-format." Inventing the import is the failure.

## Anti-patterns — fake ground truth

Citations and verification can themselves be faked. Watch for these; they defeat the whole discipline while looking rigorous:

| Anti-pattern | What it looks like | Fix |
|---|---|---|
| **Fabricated citation** | Writing `(config.py:42)` for a line you never opened | A citation is a promise you read it — only write `path:line` you actually saw in a tool result this session |
| **Wrong-artifact check** | Verifying against a doc site / blog while the user runs a different installed version | Verify against the *installed* artifact (see the rule of thumb above) |
| **Verified-adjacent** | Confirming `foo()` exists, then assuming `foo(timeout=…)` accepts that kwarg | Verify the *specific* signature/kwarg, not just the name |
| **Stale-read-as-fresh** | Citing a read from many steps ago after the file was edited | Re-read if the file could have changed since |
| **Silent assumption** | Blending "probably 8080" into a factual sentence | Label `ASSUMPTION:` and put it in the ledger |
| **`--help` says X, so runtime does X** | Trusting help text over behavior for a version-skewed binary | For load-bearing behavior, also observe it run (hand-off to fable-verification-standards) |

The meta-rule: **a check only counts if a wrong answer would have made it fail.** If your "verification" would pass whether or not the fact is true, it verified nothing.

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| "Is the change actually done / proven end-to-end?" | fable-verification-standards |
| Chasing the root cause of a specific bug | fable-debugging-playbook |
| Figuring out how the project builds / tests / runs | fable-environment-recon |
| Understanding an unfamiliar codebase's architecture and invariants | fable-codebase-archaeology |
| Deciding scope / avoiding an unrequested rewrite | fable-scope-and-change-control |
| Measuring performance / comparing before-after numbers | fable-diagnostics-and-measurement |
| The master loop that routes to all of these | fable-operating-core |

This skill is upstream of all of them: it governs the *truth of individual facts* you state while doing any of that work. When another skill says "run X" or "read Y", the correctness of the specific X and Y is this skill's job.

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|---|---|---|
| The core gate, risk ranking, ledger, cite-your-source discipline | First-principles reasoning about how LLMs generate plausible-but-unobserved tokens | Stable; re-examine if a concrete counter-example shows the discipline missing a common failure |
| Reason the library exists (P1–P4, esp. P2 hallucinated APIs/paths/flags) | User-reported pain points (as of 2026-07-13) | Confirm with user that hallucinated APIs/paths/flags remain a top time-sink |
| Verification-action commands (`--help`, `ls`, `stat`, `command -v`, lockfile reads, `require.resolve`, `inspect`) | Standard POSIX / git / common-tool usage; `scripts/extract-claims.sh` tested in a scratch dir before shipping | Re-run `scripts/extract-claims.sh` on a sample file; spot-check that listed idioms still match current tool syntax |
| Frontmatter format (two keys: name, description) and skill file layout | Convention of this library (see fable-skill-authoring-and-frontier) | Re-check skill frontmatter format against current Claude Code skills docs if the loader changes |
| Sibling skill names and ownership boundaries | This library's inventory (as of 2026-07-13) | Re-check against the current skills directory; update names if any skill is renamed |

Note on portability: every command here is a *pattern*. This skill ships to every project regardless of language or stack, so adapt the tool (the grep target, the package manager, the lockfile name) to the project in front of you — learn its stack via fable-environment-recon before assuming which of these applies.
