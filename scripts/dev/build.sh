#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_PROJECT_DIR="${ROOT_DIR}/patch-project"
DEV_DIR="${ROOT_DIR}/scripts/dev"

# Per-mod config
source "${ROOT_DIR}/patch-config.sh"

# 1) Prepare patch sources
"${DEV_DIR}/prepare.sh"

echo "==> [BUILD] Building ${PATCH_JAR_BASENAME}.jar"
cd "${PATCH_PROJECT_DIR}"
./gradlew -q clean jar -PjarBaseName="${PATCH_JAR_BASENAME}"

JAR_PATH="${PATCH_PROJECT_DIR}/build/libs/${PATCH_JAR_BASENAME}.jar"

if [[ ! -f "${JAR_PATH}" ]]; then
  echo "ERROR: Jar not found at ${JAR_PATH}"
  exit 1
fi

echo "==> [BUILD] Jar ready at ${JAR_PATH}"