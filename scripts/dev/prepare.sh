#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

LSD_SRC_DIR="${ROOT_DIR}/lsd-src"
PATCH_PROJECT_DIR="${ROOT_DIR}/patch-project"
PATCH_SRC_DIR="${PATCH_PROJECT_DIR}/src/main/java"
PATCH_MANIFEST="${ROOT_DIR}/patch-files.txt"

if [[ ! -f "${PATCH_MANIFEST}" ]]; then
  echo "ERROR: patch manifest not found at ${PATCH_MANIFEST}"
  exit 1
fi

echo "==> [PREPARE] Rebuilding patch sources"

rm -rf "${PATCH_SRC_DIR}"
mkdir -p "${PATCH_SRC_DIR}"

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="${relpath%$'\r'}"  # Remove trailing \r if present
  # Skip empty lines and comments
  [[ -z "${relpath}" ]] && continue
  [[ "${relpath}" =~ ^# ]] && continue

  src="${LSD_SRC_DIR}/${relpath}"
  dest="${PATCH_SRC_DIR}/${relpath}"

  if [[ ! -f "${src}" ]]; then
    echo "ERROR: Missing source file: ${src}"
    exit 1
  fi

  mkdir -p "$(dirname "${dest}")"
  echo "  [PREPARE] ${relpath}"
  cp "${src}" "${dest}"
done < "${PATCH_MANIFEST}"

echo "==> [PREPARE] Done"