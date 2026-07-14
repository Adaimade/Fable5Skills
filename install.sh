#!/bin/sh
# install.sh — install the Fable Thinking skill library into the CURRENT project.
#
# Usage (run from the target project's root):
#   sh /path/to/Fable5Skills/install.sh [install|status|off|on|remove]
#
#   install  (default) copy all fable-* skills into ./.claude/skills/
#   status   show what is installed here and whether it is enabled
#   off      disable: move fable-* skills to ./.claude/fable-skills.off/
#   on       re-enable: move them back into ./.claude/skills/
#   remove   delete the installed fable-* skills from this project
#
# Design guarantees:
#   - Project-scoped only: touches ONLY ./.claude/ of the current directory.
#   - Never touches the project's own non-fable skills.
#   - Managed installs are stamped (.fable-skills-version); unmanaged
#     fable-* dirs are never overwritten without --force.
set -eu

SRC_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$SRC_ROOT/.claude/skills"
DEST_ROOT="$PWD"
DEST="$DEST_ROOT/.claude/skills"
OFF_DIR="$DEST_ROOT/.claude/fable-skills.off"
STAMP="$DEST/.fable-skills-version"

cmd="${1:-install}"
force="${2:-}"

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

[ -d "$SRC" ] || die "source library not found at $SRC"
[ "$DEST_ROOT" != "$SRC_ROOT" ] || die "you are inside the skill library repo itself; cd to the target project first"

src_version() {
  if command -v git >/dev/null 2>&1 && git -C "$SRC_ROOT" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$SRC_ROOT" rev-parse --short HEAD
  else
    printf 'unknown'
  fi
}

count_fable() { # count fable-* dirs inside $1
  n=0
  for d in "$1"/fable-*/; do [ -d "$d" ] && n=$((n+1)); done
  printf '%s' "$n"
}

case "$cmd" in
  install)
    existing=$(count_fable "$DEST" 2>/dev/null || printf 0)
    if [ "$existing" -gt 0 ] && [ ! -f "$STAMP" ] && [ "$force" != "--force" ]; then
      die "found $existing existing fable-* skill dir(s) here WITHOUT an install stamp (possibly locally modified). Re-run with: install --force"
    fi
    mkdir -p "$DEST"
    n=0
    for d in "$SRC"/fable-*/; do
      name=$(basename "$d")
      rm -rf "$DEST/$name"
      cp -R "$d" "$DEST/$name"
      n=$((n+1))
    done
    [ "$n" -gt 0 ] || die "no fable-* skills found in source"
    # Library README: copy under a non-clashing name so a project's own
    # .claude/skills/README.md is never touched.
    [ -f "$SRC/README.md" ] && cp "$SRC/README.md" "$DEST/FABLE-SKILLS-README.md"
    src_version > "$STAMP"
    printf 'Installed %s fable-* skills into %s (version %s).\n' "$n" "$DEST" "$(cat "$STAMP")"
    printf 'Project-scoped only. Toggle for A/B testing: install.sh off | on\n'
    ;;
  status)
    on_n=$(count_fable "$DEST" 2>/dev/null || printf 0)
    off_n=$(count_fable "$OFF_DIR" 2>/dev/null || printf 0)
    ver='(no stamp)'
    [ -f "$STAMP" ] && ver=$(cat "$STAMP")
    printf 'Enabled here:  %s fable-* skills in %s\n' "$on_n" "$DEST"
    printf 'Disabled here: %s fable-* skills in %s\n' "$off_n" "$OFF_DIR"
    printf 'Installed version: %s   (library HEAD: %s)\n' "$ver" "$(src_version)"
    ;;
  off)
    [ "$(count_fable "$DEST" 2>/dev/null || printf 0)" -gt 0 ] || die "nothing to disable: no fable-* skills in $DEST"
    mkdir -p "$OFF_DIR"
    for d in "$DEST"/fable-*/; do
      name=$(basename "$d")
      rm -rf "$OFF_DIR/$name"
      mv "$d" "$OFF_DIR/$name"
    done
    [ -f "$STAMP" ] && mv "$STAMP" "$OFF_DIR/.fable-skills-version"
    [ -f "$DEST/FABLE-SKILLS-README.md" ] && mv "$DEST/FABLE-SKILLS-README.md" "$OFF_DIR/FABLE-SKILLS-README.md"
    printf 'Disabled: fable-* skills moved to %s (project skills untouched).\n' "$OFF_DIR"
    ;;
  on)
    [ "$(count_fable "$OFF_DIR" 2>/dev/null || printf 0)" -gt 0 ] || die "nothing to enable: no fable-* skills in $OFF_DIR"
    mkdir -p "$DEST"
    for d in "$OFF_DIR"/fable-*/; do
      name=$(basename "$d")
      rm -rf "$DEST/$name"
      mv "$d" "$DEST/$name"
    done
    [ -f "$OFF_DIR/.fable-skills-version" ] && mv "$OFF_DIR/.fable-skills-version" "$STAMP"
    [ -f "$OFF_DIR/FABLE-SKILLS-README.md" ] && mv "$OFF_DIR/FABLE-SKILLS-README.md" "$DEST/FABLE-SKILLS-README.md"
    rmdir "$OFF_DIR" 2>/dev/null || true
    printf 'Re-enabled: fable-* skills back in %s.\n' "$DEST"
    ;;
  remove)
    n=0
    for base in "$DEST" "$OFF_DIR"; do
      for d in "$base"/fable-*/; do
        [ -d "$d" ] || continue
        rm -rf "$d"; n=$((n+1))
      done
      rm -f "$base/.fable-skills-version" "$base/FABLE-SKILLS-README.md" 2>/dev/null || true
    done
    rmdir "$OFF_DIR" 2>/dev/null || true
    printf 'Removed %s fable-* skill dir(s) from this project. Project-own skills untouched.\n' "$n"
    ;;
  *)
    die "unknown command '$cmd' (use: install|status|off|on|remove)"
    ;;
esac
