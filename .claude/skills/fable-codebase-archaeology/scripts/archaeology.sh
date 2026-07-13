#!/bin/sh
# archaeology.sh — read-only reconnaissance of an unfamiliar codebase.
# Portable POSIX sh. Reads nothing but prints signals to guide manual reading.
# Usage: sh archaeology.sh [path]   (defaults to current directory)
# It NEVER writes, installs, or executes project code. Safe to run anywhere.

set -u
ROOT=${1:-.}
cd "$ROOT" 2>/dev/null || { echo "cannot cd into $ROOT" >&2; exit 1; }

hr() { printf '\n==== %s ====\n' "$1"; }

hr "MANIFESTS & ENTRY POINTS (dependency/build declarations)"
# Common manifest filenames across ecosystems. Adapt list as needed.
find . -maxdepth 3 \
  \( -name node_modules -o -name .git -o -name vendor -o -name target \
     -o -name dist -o -name build \) -prune -o -type f \
  \( -name 'package.json' -o -name 'requirements*.txt' -o -name 'pyproject.toml' \
     -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'pom.xml' \
     -o -name 'build.gradle*' -o -name 'Gemfile' -o -name 'composer.json' \
     -o -name 'Makefile' -o -name 'CMakeLists.txt' -o -name '*.csproj' \
     -o -name 'Dockerfile' -o -name 'main.*' -o -name 'index.*' \) -print 2>/dev/null \
  | sed 's|^\./||' | sort | head -40

hr "DIRECTORY TOPOLOGY (top-level file counts, code dirs only)"
for d in */ ; do
  [ -d "$d" ] || continue
  case "$d" in .git/|node_modules/|vendor/|target/|dist/|build/) continue ;; esac
  n=$(find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')
  printf '%6s  %s\n' "$n" "$d"
done | sort -rn | head -30

hr "DOCS (read these first)"
find . -maxdepth 2 -type f \( -iname 'README*' -o -iname 'CONTRIBUTING*' \
  -o -iname 'ARCHITECTURE*' -o -iname 'docs' -o -iname '*.md' \) 2>/dev/null \
  | grep -viE '/(node_modules|vendor|\.git)/' | sed 's|^\./||' | sort | head -25

if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
  hr "GIT: recent history (newest 15)"
  git log --oneline -15 2>/dev/null

  hr "GIT: most-churned files (edit frequency = load-bearing or fragile)"
  git log --format= --name-only 2>/dev/null | grep -v '^$' | sort | uniq -c | sort -rn | head -15

  hr "GIT: reverts (past decisions that were undone — read the pain)"
  git log --grep=revert -i --oneline 2>/dev/null | head -15
  echo "(empty = no revert commits found)"
else
  hr "GIT: no repository detected — history archaeology unavailable"
fi

hr "WARNING COMMENTS (invariants people bothered to write down)"
# Prefer git grep (respects .gitignore, fast); fall back to grep -r.
PAT='TODO|FIXME|HACK|XXX|WARNING|CAUTION|DO NOT|DANGER|IMPORTANT|NOTE:'
if git rev-parse --git-dir >/dev/null 2>&1; then
  git grep -nIE "$PAT" 2>/dev/null | head -40
else
  grep -rnIE "$PAT" . 2>/dev/null \
    | grep -viE '/(node_modules|vendor|\.git|dist|build)/' | head -40
fi

hr "DONE — this is a map, not the territory. Now read the files it pointed at."
