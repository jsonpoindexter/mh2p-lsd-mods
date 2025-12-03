#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_PROJECT_DIR="${ROOT_DIR}/patch-project"

source "${ROOT_DIR}/patch-config.sh"

JAR_PATH="${PATCH_PROJECT_DIR}/build/libs/${PATCH_JAR_BASENAME}.jar"

if [[ ! -f "${JAR_PATH}" ]]; then
  echo "ERROR: ${PATCH_JAR_BASENAME}.jar not found at ${JAR_PATH}. Run ./scripts/dev/build.sh first and make sure you are on a patch/<mod-name> branch."
  exit 1
fi

echo "==> [VALIDATE] Inspecting ${JAR_PATH}"
jar tf "${JAR_PATH}"