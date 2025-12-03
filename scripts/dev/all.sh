#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV_DIR="${ROOT_DIR}/dev"

"${DEV_DIR}/build.sh"
"${DEV_DIR}/validate.sh"
"${DEV_DIR}/deploy.sh"
"${DEV_DIR}/restart.sh"