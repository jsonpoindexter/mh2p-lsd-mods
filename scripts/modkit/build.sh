#!/bin/bash
set -euo pipefail

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build modkit package from the current patch branch.

OPTIONS:
    --failsafe    Generate a failsafe.sh script in the modkit directory
                  (derived from uninstall.sh template)
    -h, --help    Show this help message

DESCRIPTION:
    Creates a modkit package in the modkit/<mod-name> directory based on the
    current git branch. The package includes the patched JAR, install/uninstall
    scripts, and a README.

    With --failsafe flag, an additional failsafe.sh script is created at the
    root of the modkit directory for emergency recovery.

EXAMPLES:
    $(basename "$0")              # Build modkit package
    $(basename "$0") --failsafe   # Build with failsafe script
EOF
    exit 0
}

# Parse command line arguments
BUILD_FAILSAFE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --failsafe)
            BUILD_FAILSAFE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

# Generate failsafe.sh if requested
if [[ "${BUILD_FAILSAFE}" == "true" ]]; then
    FAILSAFE_PATH="${MODKIT_DIR}/failsafe.sh"
    echo "==> Creating failsafe.sh..."
    render_template "${TEMPLATE_DIR}/uninstall.sh.template" "${FAILSAFE_PATH}"
    echo "==> Failsafe script created at ${FAILSAFE_PATH}"
fi

echo "==> Modkit package created"