#!/bin/sh
# recon.sh — READ-ONLY environment reconnaissance.
# Prints what a project declares about how it builds/tests/runs, WITHOUT
# guessing and WITHOUT running any build/test/install command.
#
# It only reads files. It never writes, installs, deletes, or executes
# project code. Safe to run in an unfamiliar repo.
#
# Usage:  sh recon.sh [ROOT_DIR]     (default ROOT_DIR = current directory)
#
# Portable POSIX sh. Invokes: find, grep, sed (with -E), sort, head, tr, cat,
# basename, printf, and the [ ] (test) builtin. No jq/yaml parser assumed, so
# output is best-effort text scraping; always open the real files before
# trusting a command. See fable-environment-recon/SKILL.md.
#
# Known limitations (tested on macOS/BSD find as of 2026-07-13; not on Linux):
#  - On GNU find, -maxdepth after -name emits a warning (functionally OK);
#    stderr is suppressed with 2>/dev/null, which also hides permission errors.
#  - Uses $(find ...) word-splitting, so paths containing spaces are not handled.
#  - sed -E is near-universal but not guaranteed on very old / busybox sed.
#  - CI detection matches base filenames (e.g. config.yml), so it can list an
#    unrelated file of the same name — confirm by opening it.

set -u

ROOT="${1:-.}"
if [ ! -d "$ROOT" ]; then
  echo "recon.sh: not a directory: $ROOT" >&2
  exit 1
fi

# Depth limit keeps output readable and avoids descending node_modules etc.
MAXDEPTH=3

section() { printf '\n== %s ==\n' "$1"; }

# find files named $1 up to MAXDEPTH, skipping common vendor/build dirs.
find_named() {
  find "$ROOT" \
    \( -name node_modules -o -name .git -o -name vendor -o -name target \
       -o -name dist -o -name build -o -name .venv -o -name venv \) -prune \
    -o -maxdepth "$MAXDEPTH" -type f -name "$1" -print 2>/dev/null | sort
}

report_manifest() {
  # $1 = glob/name, $2 = ecosystem label
  hits=$(find_named "$1")
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits" | while IFS= read -r f; do
      printf '  [%s] %s\n' "$2" "$f"
    done
  fi
}

section "Detected manifests (manifest -> ecosystem)"
report_manifest "package.json"      "node"
report_manifest "pnpm-lock.yaml"    "node/pnpm"
report_manifest "yarn.lock"         "node/yarn"
report_manifest "package-lock.json" "node/npm"
report_manifest "bun.lockb"         "node/bun"
report_manifest "Cargo.toml"        "rust"
report_manifest "pyproject.toml"    "python"
report_manifest "requirements.txt"  "python"
report_manifest "setup.py"          "python"
report_manifest "Pipfile"           "python/pipenv"
report_manifest "poetry.lock"       "python/poetry"
report_manifest "go.mod"            "go"
report_manifest "pom.xml"           "jvm/maven"
report_manifest "build.gradle"      "jvm/gradle"
report_manifest "build.gradle.kts"  "jvm/gradle"
report_manifest "Gemfile"           "ruby"
report_manifest "composer.json"     "php"
report_manifest "CMakeLists.txt"    "c/c++/cmake"
report_manifest "Makefile"          "make"
report_manifest "makefile"          "make"
report_manifest "Dockerfile"        "docker"
report_manifest "docker-compose.yml" "docker-compose"
report_manifest "docker-compose.yaml" "docker-compose"
report_manifest "Taskfile.yml"      "task"
report_manifest "justfile"          "just"

section "Declared package.json scripts (best-effort scrape)"
# Extract the "scripts" block heuristically: lines between "scripts" and the
# next closing brace. This is a scrape, not a JSON parse — verify by reading.
for pj in $(find_named "package.json"); do
  printf '  %s:\n' "$pj"
  sed -n '/"scripts"[[:space:]]*:[[:space:]]*{/,/}/p' "$pj" \
    | grep -E '^[[:space:]]*"[^"]+"[[:space:]]*:' \
    | grep -vE '"scripts"' \
    | sed -E 's/^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*"(.*)".*/    - \1: \2/' \
    || true
done
[ -z "$(find_named 'package.json')" ] && printf '  (none)\n'

section "Declared Makefile targets (best-effort scrape)"
# Target lines look like  name:  ... (excludes variables and pattern rules).
for mf in $(find_named "Makefile") $(find_named "makefile"); do
  printf '  %s:\n' "$mf"
  grep -E '^[a-zA-Z0-9][a-zA-Z0-9_.-]*:' "$mf" \
    | grep -vE '=' \
    | sed -E 's/^([a-zA-Z0-9_.-]+):.*/    - \1/' \
    | sort -u || true
done

section "Version-manager / toolchain pin files"
for vf in .nvmrc .node-version .python-version .ruby-version .tool-versions \
          rust-toolchain rust-toolchain.toml .sdkmanrc .java-version .terraform-version; do
  for hit in $(find_named "$vf"); do
    val=$(head -5 "$hit" 2>/dev/null | tr '\n' ' ')
    printf '  %s  ->  %s\n' "$hit" "$val"
  done
done

section "CI workflow files"
if [ -d "$ROOT/.github/workflows" ]; then
  for wf in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
    [ -f "$wf" ] || continue
    name=$(grep -E '^name:' "$wf" | head -1 | sed -E 's/^name:[[:space:]]*//')
    printf '  %s  (name: %s)\n' "$wf" "${name:-<unnamed>}"
  done
fi
for ci in .gitlab-ci.yml .circleci/config.yml Jenkinsfile azure-pipelines.yml \
          .travis.yml bitbucket-pipelines.yml; do
  for hit in $(find_named "$(basename "$ci")"); do
    printf '  %s\n' "$hit"
  done
done

section "Env templates (NEVER contain real secrets — copy & fill locally)"
for et in .env.example .env.sample .env.template env.example .env.dist; do
  for hit in $(find_named "$et"); do
    keys=$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$hit" 2>/dev/null \
             | sed -E 's/=.*//' | sort -u | tr '\n' ' ')
    printf '  %s  keys: %s\n' "$hit" "${keys:-<none>}"
  done
done

section "Reminder"
cat <<'EOF'
  This report is a SCRAPE, not a parse. Before running any command:
   1. Open the real manifest / Makefile / CI yaml and confirm the target.
   2. The project's own scripts + CI steps are ground truth — prefer them
      over "canonical" ecosystem commands.
   3. Check pin files above before diagnosing any "wrong version" error.
   4. Never invent env values; copy the template and fill locally.
EOF
