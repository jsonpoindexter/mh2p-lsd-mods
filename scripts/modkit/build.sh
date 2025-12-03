#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODKIT_DIR="${ROOT_DIR}/modkit"
TEMPLATE_DIR="${MODKIT_DIR}/templates"

# Load patch settings:
source "${ROOT_DIR}/patch-config.sh"

: "${PATCH_JAR_BASENAME:?PATCH_JAR_BASENAME must be set in patch-config.sh}"

JAR_NAME="${PATCH_JAR_BASENAME}.jar"
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"

# Remove "patch/" prefix if present
MOD_NAME="${BRANCH_NAME#patch/}"

MOD_OUT_DIR="${MODKIT_DIR}/${MOD_NAME}"
UPDATE_OUT_DIR="${MOD_OUT_DIR}/Update"

JAR_PATH="${ROOT_DIR}/patch-project/build/libs/${JAR_NAME}"

if [[ ! -f "${JAR_PATH}" ]]; then
    echo "ERROR: ${JAR_NAME} not found. Build first: ./dev/build-jar.sh"
    exit 1
fi

echo "==> Creating mod output for '${MOD_NAME}'"

rm -rf "${MOD_OUT_DIR}"
mkdir -p "${UPDATE_OUT_DIR}"

# Copy the jar
echo "==> Copying jar..."
cp -vf "${JAR_PATH}" "${UPDATE_OUT_DIR}/${JAR_NAME}"

# Render templates
render_template() {
    local template_file="$1"
    local output_file="$2"
    sed \
        -e "s/{JAR_NAME}/${JAR_NAME}/g" \
        -e "s/{MOD_NAME}/${MOD_NAME}/g" \
        "${template_file}" > "${output_file}"
    chmod +x "${output_file}"
}

echo "==> Creating install/uninstall scripts..."
render_template "${TEMPLATE_DIR}/install.sh.template" "${UPDATE_OUT_DIR}/install.sh"
render_template "${TEMPLATE_DIR}/uninstall.sh.template" "${UPDATE_OUT_DIR}/uninstall.sh"

echo "==> Creating README..."
render_template "${TEMPLATE_DIR}/README.md.template" "${MOD_OUT_DIR}/README.md"

# Optional: Initialize git repo
if [[ ! -d "${MOD_OUT_DIR}/.git" ]]; then
    echo "==> Initializing git repo inside mod directory..."
    (
        cd "${MOD_OUT_DIR}"
        git init -q
        git add .
        git commit -q -m "Initial modkit export for ${MOD_NAME}"
    )
fi

echo "==> Modkit package created"