#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): runs on every cloud session start and resume.
# Heavy installs belong in scripts/cloud-setup.sh (snapshotted); this does per-session work only:
#   1. exports the toolchain variables through $CLAUDE_ENV_FILE (env set in settings.json does
#      not reach the Bash tool's shell), with JDK 17 first on PATH;
#   2. warns when the environment differs from tools/versions.env, which usually means the
#      setup script pasted into the environment UI is older than the repo copy;
#   3. imports the project once per fresh clone (.godot/ is not committed).
# Never fails the session: problems print as WARNING lines, which the agent sees at start.
# Does nothing outside cloud sessions.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

warn() { echo "WARNING: $*" >&2; }

# shellcheck source=tools/versions.env
. tools/versions.env || { warn "cannot read tools/versions.env"; exit 0; }

JAVA_HOME="/usr/lib/jvm/java-${JDK_MAJOR}-openjdk-amd64"
ANDROID_SDK=/opt/android-sdk
# Where the setup script's pip install put gdtoolkit and ruff (/usr/local/bin). It goes first:
# the cloud base image ships its own unpinned ruff and others in ~/.local/bin, earlier on PATH.
PIP_BIN="$(python3 -c 'import sysconfig; print(sysconfig.get_path("scripts"))' 2>/dev/null)"
PIP_BIN="${PIP_BIN:-/usr/local/bin}"
TOOL_PATH="${PIP_BIN}:${JAVA_HOME}/bin:${ANDROID_SDK}/platform-tools:${ANDROID_SDK}/cmdline-tools/latest/bin"
PATH="${TOOL_PATH}:${PATH}"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export XDG_DATA_HOME=/opt/godot-data"
    echo "export XDG_CONFIG_HOME=/opt/godot-config"
    echo "export JAVA_HOME=${JAVA_HOME}"
    echo "export ANDROID_HOME=${ANDROID_SDK}"
    echo "export ANDROID_SDK_ROOT=${ANDROID_SDK}"
    echo "export PATH=\"${TOOL_PATH}:\$PATH\""
  } >>"$CLAUDE_ENV_FILE"
else
  warn "CLAUDE_ENV_FILE is not set; toolchain variables will not reach later commands"
fi
export XDG_DATA_HOME=/opt/godot-data XDG_CONFIG_HOME=/opt/godot-config JAVA_HOME

# The setup script's stamp against the repo's pins.
stamp=/opt/bramble/setup.env
if [ -f "$stamp" ]; then
  for key in GODOT_VERSION GUT_VERSION GDTOOLKIT_VERSION RUFF_VERSION JDK_MAJOR \
    ANDROID_PLATFORM ANDROID_BUILD_TOOLS ANDROID_NDK; do
    got="$(grep -E "^${key}=" "$stamp" | cut -d= -f2-)"
    if [ "$got" != "${!key}" ]; then
      warn "environment has ${key}=${got:-<none>}, tools/versions.env has ${!key}: re-paste scripts/cloud-setup.sh into the environment (docs/CLOUD_SETUP.md)"
    fi
  done
else
  warn "no $stamp: the environment's setup script is missing, failed, or predates the stamp (docs/CLOUD_SETUP.md)"
fi

if ! command -v godot >/dev/null 2>&1; then
  warn "godot is not on PATH; the environment's setup script did not run or failed (docs/CLOUD_SETUP.md)"
  exit 0
fi
version="$(godot --headless --version 2>/dev/null | head -n1)"
echo "Godot: ${version}"
case "$version" in
  "${GODOT_VERSION}.stable"*) ;;
  *) warn "godot is ${version}, tools/versions.env pins ${GODOT_VERSION}" ;;
esac
[ -f "$XDG_DATA_HOME/godot/export_templates/${GODOT_VERSION}.stable/version.txt" ] \
  || warn "no export templates for ${GODOT_VERSION} under $XDG_DATA_HOME"
# Skip "Picked up JAVA_TOOL_OPTIONS" (the cloud sets it for its proxy): it prints first.
java_version="$("$JAVA_HOME/bin/java" -version 2>&1 | grep -m1 ' version ')"
case "$java_version" in
  *"\"${JDK_MAJOR}."*) ;;
  *) warn "JDK ${JDK_MAJOR} not found at ${JAVA_HOME} (got: ${java_version:-nothing})" ;;
esac
[ -d "$ANDROID_SDK/build-tools/${ANDROID_BUILD_TOOLS}" ] \
  || warn "Android build-tools ${ANDROID_BUILD_TOOLS} missing under $ANDROID_SDK"
for tool in gdformat gdlint ruff shellcheck xvfb-run; do
  command -v "$tool" >/dev/null 2>&1 || warn "$tool is not installed"
done
got="$(ruff --version 2>/dev/null)"
[ "$got" = "ruff ${RUFF_VERSION}" ] \
  || warn "ruff on PATH ($(command -v ruff)) is '${got}', tools/versions.env pins ${RUFF_VERSION}"
got="$(gdlint --version 2>/dev/null | head -n1 | tr -s ' ')"
[ "$got" = "gdlint ${GDTOOLKIT_VERSION}" ] \
  || warn "gdlint on PATH is '${got}', tools/versions.env pins gdtoolkit ${GDTOOLKIT_VERSION}"

# .godot/ is gitignored, so build the import cache once per fresh clone.
if [ -f project.godot ] && [ ! -d .godot/imported ]; then
  echo "Importing the project (first run in this VM)..."
  timeout 500 godot --headless --import >/tmp/godot-import.log 2>&1 \
    || warn "godot --import exited non-zero; see /tmp/godot-import.log"
fi
exit 0
