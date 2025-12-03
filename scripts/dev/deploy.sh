#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_PROJECT_DIR="${ROOT_DIR}/patch-project"
DEV_DIR="${ROOT_DIR}/dev"

source "${DEV_DIR}/dev.env"

source "${ROOT_DIR}/patch-config.sh"

JAR_PATH="${PATCH_PROJECT_DIR}/build/libs/${PATCH_JAR_BASENAME}.jar"
REMOTE_TARGET="${PCM_JARS_DIR}/${PCM_JAR_NAME}"

if [[ ! -f "${JAR_PATH}" ]]; then
  echo "ERROR: ${PATCH_JAR_BASENAME}.jar not found at ${JAR_PATH}. Run ./dev/build-jar.sh first."
  exit 1
fi

echo "==> [DEPLOY] Copying ${JAR_PATH} -> ${PCM_HOST}:${REMOTE_TARGET}"
scp -P "${PCM_PORT}" -i "${PCM_SSH_KEY}" \
    "${JAR_PATH}" \
    "${PCM_USER}@${PCM_HOST}:${REMOTE_TARGET}"

echo "==> [DEPLOY] Done (no restart yet)"