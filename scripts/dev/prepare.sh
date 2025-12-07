#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

LSD_SRC_DIR="${ROOT_DIR}/lsd-src"
PATCH_PROJECT_DIR="${ROOT_DIR}/patch-project"
PATCH_SRC_DIR="${PATCH_PROJECT_DIR}/src/main/java"

PATCH_LIST_FILE="${ROOT_DIR}/patch-files.txt"
CHANGED_FILES=""

# 1) Prefer explicit list from patch-files.txt if present
if [[ -f "${PATCH_LIST_FILE}" ]]; then
  echo "==> [PREPARE] Using patch-files.txt"
  # Filter out blank lines and comments
  CHANGED_FILES="$(grep -Ev '^\s*($|#)' "${PATCH_LIST_FILE}" || true)"
fi

# 2) Fallback: use git diff vs baseline if no explicit files were listed
if [[ -z "${CHANGED_FILES}" ]]; then
  # Ensure lsd-src is a local git repo with a 'baseline' tag
  if [[ ! -d "${LSD_SRC_DIR}/.git" ]]; then
    echo "ERROR: ${LSD_SRC_DIR} is not a git repository."
    echo "Initialize it and create a 'baseline' tag after your initial decompile, e.g.:"
    echo "  cd lsd-src && git init && git add . && git commit -m 'baseline' && git tag baseline"
    exit 1
  fi

  if ! git -C "${LSD_SRC_DIR}" rev-parse baseline >/dev/null 2>&1; then
    echo "ERROR: 'baseline' tag not found in ${LSD_SRC_DIR}."
    echo "Create it after your initial clean decompile, e.g.:"
    echo "  cd lsd-src && git add . && git commit -m 'baseline' && git tag baseline"
    exit 1
  fi

  # Collect changed files vs baseline (added/copied/modified/renamed/type-changed)
  CHANGED_FILES="$(git -C "${LSD_SRC_DIR}" diff --name-only --diff-filter=ACMRT baseline --)"
fi

# 3) If still nothing, bail out
if [[ -z "${CHANGED_FILES}" ]]; then
  echo "==> [PREPARE] No files listed in patch-files.txt and no changes detected vs baseline; nothing to copy."
  exit 0
fi

echo "==> [PREPARE] Rebuilding patch sources"

rm -rf "${PATCH_SRC_DIR}"
mkdir -p "${PATCH_SRC_DIR}"

for relpath in ${CHANGED_FILES}; do
  src="${LSD_SRC_DIR}/${relpath}"
  dest="${PATCH_SRC_DIR}/${relpath}"

  if [[ ! -f "${src}" ]]; then
    echo "  [SKIP] ${relpath} (not a regular file)"
    continue
  fi

  mkdir -p "$(dirname "${dest}")"
  echo "  [PREPARE] ${relpath}"
  cp "${src}" "${dest}"
done

echo "==> [PREPARE] Done"