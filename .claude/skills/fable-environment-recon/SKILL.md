---
name: fable-environment-recon
description: "Load when you must establish how an unfamiliar project builds, tests, installs, or runs and you do not already KNOW the exact commands — before running a build/test/run command you guessed, when an install or build fails, or when you hit wrong-version / missing-dependency / command-not-found / works-on-my-machine errors. Symptom phrases: 'how do I run this', 'which package manager', 'wrong node/python version', 'npm ERR / ModuleNotFoundError / command not found', 'it built for me but not in CI', 'stale lockfile', 'missing env var'. Do NOT load to understand what the code MEANS or its architecture (use fable-codebase-archaeology), to verify a change actually works end-to-end (use fable-verification-standards), or to root-cause a runtime bug once the project already builds and runs (use fable-debugging-playbook)."
---

## 繁中摘要
- 用途：在**不猜測**的前提下，從零建立「這個專案如何安裝／建置／測試／執行」的事實。
- 核心規則：專案**自己的** scripts 與 CI 步驟就是 ground truth，先讀 `package.json` scripts、`Makefile` targets、CI yaml，再談所謂「標準」指令。
- 偵測：用 manifest 檔（`package.json`、`Cargo.toml`、`pyproject.toml`、`go.mod`、`pom.xml`、`Makefile`、`Dockerfile` 等）判斷技術棧與對應指令。
- 版本陷阱：先看 `.nvmrc`、`.python-version`、`.tool-versions`、`rust-toolchain` 等釘選檔，再診斷「版本錯誤」。
- 祕密與環境變數：從 `.env.example` 等範本探索必要變數；**永不杜撰值、永不提交真祕密**。
- 附 `scripts/recon.sh`：**唯讀**掃描腳本，列出 manifests／scripts／版本釘選／CI／env 範本；不執行任何建置。

# Environment recon: know how it builds, don't guess

You have just landed in a project and need to install, build, test, or run it.
The failure this skill prevents is **P2 (hallucinated commands)**: confidently
typing `npm run build` when the project uses `pnpm` and the script is called
`compile`, then reporting a fake runbook that does not run. The cure is to read
what the project *declares* about itself before typing anything.

Jargon, defined once:
- **manifest** — the file that declares a project's dependencies/metadata for an
  ecosystem (e.g. `package.json`, `Cargo.toml`, `go.mod`).
- **lockfile** — the machine-generated file pinning exact resolved dependency
  versions (e.g. `package-lock.json`, `Cargo.lock`, `poetry.lock`).
- **version-manager pin file** — a small file naming the required toolchain
  version (e.g. `.nvmrc` → Node version).
- **ground truth** — reality you have observed, not inferred. Here: the commands
  the project's own scripts and CI actually run.

---

## The one rule that overrides ecosystem defaults

> **The project's own scripts and CI are ground truth for how to build, test,
> and run it. Read them BEFORE reaching for any "canonical" command.**

A repo may look like a standard Node app but wrap everything in a `Makefile`, or
use `pnpm` not `npm`, or rename `test` to `check`, or require a `docker compose`
stack before tests pass. The "canonical" command is a *hypothesis*; the
project's declared script/CI step is *evidence*. When they disagree, the project
wins. Order of authority (highest first):

| Rank | Source | Why it wins |
|------|--------|-------------|
| 1 | CI workflow steps (`.github/workflows/*.yml`, `.gitlab-ci.yml`, etc.) | The exact commands that must pass for the project to ship — verified continuously. |
| 2 | `Makefile` / `Taskfile` / `justfile` targets, `package.json` scripts | The maintainers' chosen entry points. |
| 3 | README / CONTRIBUTING "getting started" | Human intent, but can go stale — cross-check against 1–2. |
| 4 | Ecosystem-canonical command (table below) | A fallback hypothesis only when 1–3 are silent. Still verify it runs. |

Read top-down. Only drop to rank 4 when higher ranks say nothing about the task.

---

## Step 1 — Detect the stack from manifests

Run the shipped recon script (read-only, see below) or scan by hand. Map each
manifest to its ecosystem and the *canonical fallback* commands (rank 4 above —
use only after checking the project's own scripts/CI):

| Manifest file | Ecosystem | Install (fallback) | Build (fallback) | Test (fallback) | Run (fallback) |
|---------------|-----------|--------------------|--------------------|-------------------|------------------|
| `package.json` (+ `package-lock.json`) | Node / npm | `npm ci` (or `npm install`) | `npm run build` | `npm test` | `npm start` |
| `package.json` + `pnpm-lock.yaml` | Node / pnpm | `pnpm install` | `pnpm build` | `pnpm test` | `pnpm start` |
| `package.json` + `yarn.lock` | Node / yarn | `yarn install` | `yarn build` | `yarn test` | `yarn start` |
| `package.json` + `bun.lockb` | Node / bun | `bun install` | `bun run build` | `bun test` | `bun run start` |
| `Cargo.toml` | Rust / cargo | `cargo fetch` | `cargo build` | `cargo test` | `cargo run` |
| `pyproject.toml` | Python (PEP 621 / poetry / hatch / uv) | depends on tool — see note | per tool | `pytest` | per tool |
| `requirements.txt` | Python / pip | `pip install -r requirements.txt` | (usually none) | `pytest` | `python <entry>` |
| `Pipfile` | Python / pipenv | `pipenv install` | — | `pipenv run pytest` | `pipenv run <cmd>` |
| `go.mod` | Go | `go mod download` | `go build ./...` | `go test ./...` | `go run .` |
| `pom.xml` | JVM / Maven | `mvn install` | `mvn package` | `mvn test` | `mvn exec:java` / run jar |
| `build.gradle[.kts]` | JVM / Gradle | `./gradlew build` | `./gradlew assemble` | `./gradlew test` | `./gradlew run` |
| `Gemfile` | Ruby / bundler | `bundle install` | — | `bundle exec rake test` | `bundle exec <cmd>` |
| `composer.json` | PHP / composer | `composer install` | — | `composer test` / `phpunit` | per script |
| `CMakeLists.txt` | C/C++ / CMake | `cmake -B build` | `cmake --build build` | `ctest --test-dir build` | run built binary |
| `Makefile` | make (any language) | — | `make` / `make build` | `make test` | `make run` |
| `Dockerfile` | container image | — | `docker build -t app .` | (per image) | `docker run app` |
| `docker-compose.yml` | multi-container stack | `docker compose pull` | `docker compose build` | (per service) | `docker compose up` |
| `Taskfile.yml` | Task runner | — | `task build` | `task test` | `task run` |
| `justfile` | just runner | — | `just build` | `just test` | `just run` |

Notes:
- **`pyproject.toml` is ambiguous** — it is used by poetry, hatch, pdm, uv, and
  plain setuptools, each with different commands. Look for the disambiguator:
  `[tool.poetry]` → poetry; `[tool.hatch]` → hatch; a `uv.lock` → uv; a
  `poetry.lock` → poetry; else treat as PEP 517 build (`pip install .`). Do not
  guess — read the `[build-system]` / `[tool.*]` tables.
- **`npm ci` vs `npm install`**: `npm ci` requires a `package-lock.json` and
  installs exactly it (clean, reproducible); `npm install` may mutate the lock.
  Prefer `ci` in CI-like/reproduction work; you need the lockfile present.
- **Multiple manifests = monorepo or polyglot.** A top-level manifest plus
  per-package manifests (workspaces) means the build is orchestrated at the
  root. Find the workspace config (`pnpm-workspace.yaml`, `workspaces` in
  `package.json`, Cargo `[workspace]`, Go `go.work`) before running per-package.

---

## Step 2 — Read the project's declared commands (rank 1–2)

Before running anything, extract the real entry points:

- **`package.json` scripts** — open the file and read the `"scripts"` object.
  Every `npm run <name>` maps to a line there. Do not assume `build`/`test`
  exist; they may be `compile`, `check`, `ci:test`, etc.
- **`Makefile` targets** — read target names (lines like `build:` at column 0).
  `make help` sometimes exists; if not, the file is short — read it.
- **CI steps** — open `.github/workflows/*.yml` (or `.gitlab-ci.yml`,
  `.circleci/config.yml`, `Jenkinsfile`, `azure-pipelines.yml`) and read the
  `run:`/`script:` lines in order. This is the authoritative "what must pass"
  sequence, including setup steps you would otherwise miss (service containers,
  env exports, codegen).

The recon script scrapes these for you as a *starting index* — but a scrape is
not a parse. Always open the real file before committing to a command
(anti-hallucination discipline: see **fable-ground-truth**).

---

## Step 3 — Check version-manager pins BEFORE diagnosing "wrong version"

A huge share of "it won't build" is a toolchain-version mismatch. Check for pin
files first; do not "fix" code for what is a version problem.

| Pin file | Tool it configures | How to honor it |
|----------|--------------------|------------------|
| `.nvmrc`, `.node-version` | Node version | `nvm use` / `fnm use` (reads the file), or install that exact version. |
| `.python-version` | pyenv Python version | `pyenv install <v>` + `pyenv local`, or match your interpreter. |
| `.ruby-version` | Ruby version | `rbenv`/`rvm` selects it. |
| `.tool-versions` | asdf / mise — **multiple** tools at once | `asdf install` / `mise install` reads all pinned tools. |
| `rust-toolchain` / `rust-toolchain.toml` | rustup channel | rustup auto-selects when you `cargo` in the dir. |
| `.sdkmanrc` | SDKMAN (Java/Kotlin/etc.) | `sdk env` applies it. |
| `Volta` config in `package.json` (`"volta"` key) | Volta pins Node/npm/yarn | Volta auto-switches; check this key too. |
| `engines` in `package.json` | npm-declared Node/npm range | Advisory; some setups enforce with `engine-strict`. |
| `.terraform-version` | tfenv | selects Terraform version. |

Traps:
- The pin file names a version you do not have installed → the error is
  "install that version", not "the project is broken".
- A **version manager is installed but not activated** in the current shell →
  `node --version` shows a global version, not the pinned one. Confirm which
  binary is active: `command -v node` / `command -v python`, then compare to the
  pin. (See "global vs local" trap below.)
- `.tool-versions` pins several tools — a mismatch in any one can break the
  build; check them all, not just the obvious one.

---

## Step 4 — Discover required env vars & secrets (never invent values)

Projects fail at runtime, not build time, when a required env var is missing.
Discover what is required; never fabricate values; never commit real secrets.

- Look for templates: `.env.example`, `.env.sample`, `.env.template`,
  `env.example`, `.env.dist`. Each key present there is (usually) required.
  Copy to `.env` locally and fill values you legitimately have.
- Read config loaders for `getenv`/`process.env.X`/`os.environ["X"]` references
  to find variables not documented in a template.
- A runtime error like `KeyError: 'DATABASE_URL'` /
  `Missing required environment variable X` **names the variable for you** —
  that is ground truth about what is required.
- **Never** invent a secret value, API key, or connection string to make an
  error go away — that is a P3 shallow patch that hides a real config gap. If a
  value is genuinely unknown, stop and ask the human who owns the project.
- **Never** write a real secret into a committed file, an example template, or a
  URL query string. Templates hold placeholders/blanks only.

Entering credentials is a prohibited action for you regardless of framing: if a
step needs a password, token, or card number typed into a field, direct the
human to do it themselves.

---

## Step 5 — Known traps (symptom → cause → move)

| Symptom you observe | Likely cause | Read-only next move |
|---------------------|--------------|---------------------|
| Install errors, lockfile "out of sync" / "frozen lockfile" failure | **Stale lockfile vs manifest** — manifest edited without regenerating lock | Diff manifest vs lock dates; use the ecosystem's frozen-install (`npm ci`, `pnpm i --frozen-lockfile`, `cargo build --locked`) to see the mismatch, don't blindly delete the lock. |
| `command not found` for a tool you "know" is installed | **Global vs local** — project expects a project-local binary (`./node_modules/.bin`, venv, `./gradlew`) | Prefer the project runner (`npm run`, `npx`, `poetry run`, `./gradlew`); check `command -v <tool>` to see what resolves. |
| Version mismatch errors despite "correct" install | **Version manager not activated** in this shell | `command -v node/python`; compare to pin file (Step 3). |
| Build passes locally, fails in CI (or vice versa) | **Hidden env var** or a CI setup step you skipped | Read the CI job top-to-bottom; replicate its env exports and service containers, not just its build line. |
| Rebuild uses stale artifacts / "phantom" old behavior | **Dirty build cache** | Use the ecosystem's clean target (`make clean`, `cargo clean`, `gradle clean`, delete `dist`/`build`) — a documented, reversible clean, not a `rm -rf` guess. |
| `fatal error: X.h`, linker errors, `gyp` failures | **Missing system dependency** (compiler, headers, libssl, etc.) | Read README prerequisites + CI's OS setup steps for the package list; do not silence with flags. |
| `sed -i` / `date -d` / `readlink -f` behaves differently than expected | **OS difference** — BSD (macOS) vs GNU (Linux) tools differ | macOS `sed -i` needs an arg (`sed -i '' …`); GNU does not. `date -d` is GNU-only (`date -v` on BSD). Prefer portable forms or detect the OS. |
| Nothing resolves / relative paths wrong | **Running from the wrong directory** | Confirm repo root (dir with the top-level manifest / `.git`); many scripts assume cwd = root. |
| `EACCES` / permission denied writing during install | **sudo-installed global tool or root-owned cache** | Use a per-user version manager; do not `sudo npm install` to paper over it. |

---

## The recon script (read-only)

`scripts/recon.sh` — a portable POSIX `sh` script that **only reads files** and
prints a starting index: detected manifests, scraped `package.json` scripts and
`Makefile` targets, version-manager pin files, CI workflow names, and `.env`
templates. It **never** installs, builds, executes project code, writes, or
deletes. Safe to run in an unfamiliar repo.

```sh
# From the repo root (or pass a path):
sh /path/to/fable-environment-recon/scripts/recon.sh
sh /path/to/fable-environment-recon/scripts/recon.sh /path/to/project
```

It descends at most 3 levels and prunes `node_modules`, `.git`, `vendor`,
`target`, `dist`, `build`, `venv`/`.venv`. Output is a **scrape, not a parse** —
treat it as an index that tells you *which files to open*, then open them and
confirm before running any command. Tested (as of 2026-07-13) on a synthetic
polyglot fixture (Node + Rust + Go + Make + CI + env template) and on
empty/nonexistent-dir edge cases.

---

## Recon checklist (do all before you type a build/test/run command)

- [ ] Listed manifests and identified the ecosystem(s) — and whether it is a
      monorepo/workspace.
- [ ] Read the project's **own** scripts / Makefile / CI steps for the task.
- [ ] Chose the command from the highest-authority source available (CI > script
      > README > ecosystem default), not from memory.
- [ ] Checked version-manager pin files and confirmed the active toolchain
      matches.
- [ ] Found required env vars from templates/config; did not invent any value.
- [ ] Confirmed I am in the repo root (or the intended working dir).
- [ ] When I finally run the command, I will **watch it actually succeed** — a
      command that "should work" is not a verified command (see
      **fable-verification-standards**).

---

## When NOT to use this skill

| Situation | Use instead |
|-----------|-------------|
| You need to understand what the code *means* / its architecture and invariants | **fable-codebase-archaeology** |
| The project already builds and runs; you are chasing a *runtime bug* | **fable-debugging-playbook** |
| You need to prove a change actually works end-to-end | **fable-verification-standards** |
| You are about to assert a specific flag/API/path is correct | **fable-ground-truth** |
| You are deciding scope / worried about an unrequested rewrite | **fable-scope-and-change-control** |
| You want the overall operating loop and which skill to load next | **fable-operating-core** |

Boundary with **fable-codebase-archaeology**: that skill answers *"what does
this code do and why"*; this skill answers *"how do I make it build/test/run"*.
Recon establishes the mechanical environment; archaeology reads the meaning.

---

## Provenance and maintenance

| Claim class | Source | Re-verify by |
|-------------|--------|--------------|
| Manifest → ecosystem mapping, canonical commands | First-principles + widely-documented ecosystem conventions (npm/cargo/go/maven/gradle/pip docs) | Spot-check one command per ecosystem against its official docs when a tool releases a major version. |
| "Project's own scripts/CI are ground truth" rule | First-principles (CI is the definition of passing) + user-reported pain, dated 2026-07-13 | Stable principle; no drift expected. |
| Version-manager pin files list | Documented behavior of nvm/fnm/pyenv/asdf/mise/rustup/Volta/SDKMAN (as of 2026-07-13) | Re-check for new managers; confirm `.tool-versions` still shared by asdf + mise. |
| OS-difference traps (BSD vs GNU `sed`/`date`) | First-principles + long-standing documented POSIX/GNU divergence | Stable; verify `sed -i ''` still required on macOS after major OS updates. |
| P1–P4 failure modes this defends against | User-reported pain points, dated 2026-07-13 | — |
| `recon.sh` behavior (read-only, prune list, scrape accuracy) | Tested by the author on a synthetic fixture under /private/tmp, 2026-07-13 | Re-run on a fresh fixture if the script changes; confirm it still executes nothing. |

Drift watch: ecosystem default commands change slowly but do change (e.g. new
package managers, `npm` command renames). The **method** — read the project's
declarations first — is the durable part; the fallback table is the perishable
part. When in doubt, trust the repo over this table.
