# Derive patch jar base name from current git branch.
# Expected branch naming: patch/<mod-name>

# Determine current branch name
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown-branch")"

# Strip the 'patch/' prefix if present to get the mod name
if [[ "${BRANCH_NAME}" == patch/* ]]; then
  MOD_NAME="${BRANCH_NAME#patch/}"
else
  echo "WARNING: patch-config.sh: expected branch 'patch/<mod-name>', got '${BRANCH_NAME}'" >&2
  MOD_NAME="${BRANCH_NAME}"
fi

# Base name (without .jar) for this mod’s jar
PATCH_JAR_BASENAME="${MOD_NAME}"

# Where it will live on the PCM
PCM_JARS_DIR="/mnt/app/eso/hmi/lsd/jars"
PCM_JAR_NAME="${PATCH_JAR_BASENAME}.jar"