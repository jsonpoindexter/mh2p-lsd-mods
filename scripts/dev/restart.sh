#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV_DIR="${ROOT_DIR}/dev"

source "${DEV_DIR}/dev.env"

echo "==> [RESTART] Running restart command on PCM"
ssh -p "${PCM_PORT}" -i "${PCM_SSH_KEY}" "${PCM_USER}@${PCM_HOST}" "
  sync
  ${PCM_RESTART_CMD}
"

echo "==> [RESTART] Done"