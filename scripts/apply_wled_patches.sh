#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WLED_DIR="${WLED_DIR:-WLED}"
SOURCE_DIR="$REPO_ROOT/$WLED_DIR"
PATCH_DIR="$REPO_ROOT/patches"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  echo "ERROR: WLED git checkout not found: $SOURCE_DIR"
  exit 2
fi

if [[ ! -d "$PATCH_DIR" ]]; then
  exit 0
fi

shopt -s nullglob
patches=("$PATCH_DIR"/*.patch)
if [[ "${#patches[@]}" -eq 0 ]]; then
  exit 0
fi

for patch in "${patches[@]}"; do
  rel_patch="${patch#$REPO_ROOT/}"
  if git -C "$SOURCE_DIR" apply --check "$patch" >/dev/null 2>&1; then
    echo "Applying WLED patch: $rel_patch"
    git -C "$SOURCE_DIR" apply "$patch"
  elif git -C "$SOURCE_DIR" apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "WLED patch already applied: $rel_patch"
  else
    echo "ERROR: WLED patch does not apply cleanly: $rel_patch"
    exit 1
  fi
done
