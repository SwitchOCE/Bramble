#!/usr/bin/env bash
# Claude Code cloud environment setup script for Bramble.
# Paste the whole file into: claude.ai/code > environment settings > Setup script.
# See docs/CLOUD_SETUP.md. It runs as root on Ubuntu 24.04 x86_64 before Claude starts. When it
# finishes in about 5 minutes the filesystem is snapshotted and reused; changing the pasted
# script invalidates that cache.
# Only the Godot editor is fatal. Every other part logs a WARNING and carries on, so one flaky
# download never blocks a session; scripts/session-start.sh then reports what is missing.
# By pasting this script the owner accepts the Android SDK licences (sdkmanager --licenses).
# The pins below are a verbatim copy and this script doesn't use them all, hence, for the whole
# file:
# shellcheck disable=SC2034
set -uo pipefail

# >>> tools/versions.env (verbatim copy; tools/checks/versions.py fails if it drifts)
# The one place toolchain versions and checksums are pinned.
# Read by scripts/check.sh, scripts/session-start.sh, scripts/export_smoke.sh and
# .github/workflows/ci.yml. scripts/cloud-setup.sh carries a verbatim copy, because it is pasted
# into the cloud environment UI and runs before the repo exists; tools/checks/versions.py fails
# when that copy, project.godot or the vendored GUT disagree with this file.
# Upgrade steps: docs/CLOUD_SETUP.md, "Upgrading the toolchain".

# Godot editor and export templates. SHA-512s are the release's SHA512-SUMS.txt lines.
GODOT_VERSION=4.7.2
GODOT_LINUX_SHA512=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65
GODOT_TEMPLATES_SHA512=ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079

# Test framework, vendored in addons/gut (the release matching Godot 4.7).
GUT_VERSION=9.7.1

# Python tools: GDScript format and lint, Python lint.
GDTOOLKIT_VERSION=4.5.0
RUFF_VERSION=0.16.8

# Android. The SDK levels come from config.gradle inside the export templates'
# android_source.zip for the Godot version above; re-read them on every Godot upgrade.
JDK_MAJOR=17
ANDROID_CMDLINE_TOOLS_BUILD=11076708
ANDROID_CMDLINE_TOOLS_SHA256=2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258
ANDROID_PLATFORM=36
ANDROID_BUILD_TOOLS=36.1.0
# <<< tools/versions.env

GODOT_TAG="${GODOT_VERSION}-stable"
GH_RELEASES="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}"
GODOT_DATA=/opt/godot-data     # XDG_DATA_HOME: export templates, debug keystore, user://
GODOT_CONFIG=/opt/godot-config # XDG_CONFIG_HOME: editor settings
ANDROID_SDK=/opt/android-sdk
JAVA_HOME="/usr/lib/jvm/java-${JDK_MAJOR}-openjdk-amd64"
STAMP_DIR=/opt/bramble

# Keep a copy of the output: the cloud does not show the setup script's log to the session, so
# this is the only place to read section times or see why a part of the setup failed.
mkdir -p "$STAMP_DIR"
exec > >(tee "$STAMP_DIR/setup.log") 2>&1

SECONDS=0
section_name=""
section_start=0
log() { echo "[cloud-setup] $*"; }
# section <name>: logs how long the previous section took, then starts the next one.
section() {
  if [ -n "$section_name" ]; then
    log "  ${section_name}: $((SECONDS - section_start))s"
  fi
  section_name="$1"
  section_start=$SECONDS
  log "$1"
}
# fetch <url> <file> <sha algorithm> <expected hash>: download and verify, or return 1.
fetch() {
  curl -fsSL --retry 3 -o "$2" "$1" || { log "WARNING: download failed: $1"; return 1; }
  echo "$4  $2" | "${3}sum" -c --quiet - || { log "WARNING: checksum mismatch: $1"; return 1; }
}

# ---------------------------------------------------------------- apt packages
section "apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null || log "WARNING: apt-get update failed"
apt-get install -y --no-install-recommends \
  unzip zip curl ca-certificates git python3 python3-pip \
  xvfb xauth libgl1 libgl1-mesa-dri libegl1 libglu1-mesa \
  libxcursor1 libxinerama1 libxrandr2 libxi6 libxkbcommon0 libxkbcommon-x11-0 \
  libasound2t64 libpulse0 libfontconfig1 libfreetype6 libudev1 \
  fonts-dejavu-core fonts-noto-core \
  "openjdk-${JDK_MAJOR}-jdk-headless" \
  shellcheck \
  >/dev/null || log "WARNING: some apt packages failed"

# ---------------------------------------------------------------- Godot editor (fatal)
section "Godot ${GODOT_VERSION}"
mkdir -p /opt/godot "$GODOT_DATA" "$GODOT_CONFIG"
if ! /opt/godot/godot --headless --version 2>/dev/null | grep -qF "${GODOT_VERSION}.stable"; then
  tmp=$(mktemp -d)
  zip="Godot_v${GODOT_TAG}_linux.x86_64.zip"
  fetch "${GH_RELEASES}/${zip}" "$tmp/$zip" sha512 "$GODOT_LINUX_SHA512" \
    || { log "FATAL: Godot download or checksum failed"; exit 1; }
  unzip -q "$tmp/$zip" -d "$tmp"
  mv "$tmp/Godot_v${GODOT_TAG}_linux.x86_64" /opt/godot/godot
  chmod +x /opt/godot/godot
  rm -rf "$tmp"
fi
ln -sf /opt/godot/godot /usr/local/bin/godot
godot --headless --version || { log "FATAL: the godot binary does not run"; exit 1; }

# ---------------------------------------------------------------- export templates (about 1.3 GB)
section "Godot export templates"
TPL_DIR="$GODOT_DATA/godot/export_templates/${GODOT_VERSION}.stable"
if [ ! -f "$TPL_DIR/version.txt" ]; then
  (
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    tpz="Godot_v${GODOT_TAG}_export_templates.tpz"
    fetch "${GH_RELEASES}/${tpz}" "$tmp/$tpz" sha512 "$GODOT_TEMPLATES_SHA512" || exit 1
    unzip -q "$tmp/$tpz" -d "$tmp" || exit 1
    mkdir -p "$TPL_DIR" && mv "$tmp/templates/"* "$TPL_DIR/"
  ) || log "WARNING: export templates not installed"
fi
# Root's default path too, for any command run without the XDG variables.
mkdir -p /root/.local/share/godot
ln -sfn "$GODOT_DATA/godot/export_templates" /root/.local/share/godot/export_templates || true

# ---------------------------------------------------------------- Python tools
section "gdtoolkit ${GDTOOLKIT_VERSION}, ruff ${RUFF_VERSION}"
pip install --quiet --break-system-packages "gdtoolkit==${GDTOOLKIT_VERSION}" "ruff==${RUFF_VERSION}" \
  || pip install --quiet "gdtoolkit==${GDTOOLKIT_VERSION}" "ruff==${RUFF_VERSION}" \
  || log "WARNING: gdtoolkit/ruff not installed"

# ---------------------------------------------------------------- Android SDK (needs dl.google.com)
section "Android SDK (platform ${ANDROID_PLATFORM}, build-tools ${ANDROID_BUILD_TOOLS})"
# Every step checks its own result: set -e has no effect in a subshell guarded by ||, and a
# failed checksum must stop the install.
(
  export JAVA_HOME
  sdkm="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"
  if [ ! -x "$sdkm" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    zip="commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_BUILD}_latest.zip"
    fetch "https://dl.google.com/android/repository/${zip}" "$tmp/$zip" sha256 "$ANDROID_CMDLINE_TOOLS_SHA256" || exit 1
    unzip -q "$tmp/$zip" -d "$tmp" || exit 1
    mkdir -p "$ANDROID_SDK/cmdline-tools" || exit 1
    rm -rf "$ANDROID_SDK/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest" || exit 1
  fi
  # yes ends on SIGPIPE once sdkmanager stops reading; under pipefail that would fail the block.
  (yes || true) | "$sdkm" --sdk_root="$ANDROID_SDK" --licenses >/dev/null || exit 1
  "$sdkm" --sdk_root="$ANDROID_SDK" "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS}" \
    "platforms;android-${ANDROID_PLATFORM}" >/dev/null || exit 1
) || log "WARNING: Android SDK not fully installed (is dl.google.com in Allowed domains?)"

# ---------------------------------------------------------------- Godot editor settings
# Android export reads the JDK and SDK paths from editor settings; a fresh config has none.
section "Godot editor settings"
settings="$GODOT_CONFIG/godot/editor_settings-${GODOT_VERSION%.*}.tres"
if [ ! -f "$settings" ]; then
  mkdir -p "$(dirname "$settings")"
  cat >"$settings" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "${JAVA_HOME}"
export/android/android_sdk_path = "${ANDROID_SDK}"
EOF
fi

# ---------------------------------------------------------------- stamp and permissions
section "stamp"
{
  echo "# Written by the pasted scripts/cloud-setup.sh; scripts/session-start.sh checks its hash."
  if [ -f "$0" ]; then
    echo "SETUP_SCRIPT_SHA256=$(sha256sum "$0" | cut -d' ' -f1)"
  fi
  echo "SETUP_SECONDS=${SECONDS}"
} >"$STAMP_DIR/setup.env"
chmod -R a+rwX "$GODOT_DATA" "$GODOT_CONFIG" "$ANDROID_SDK" "$STAMP_DIR" 2>/dev/null || true
cat "$STAMP_DIR/setup.env"

section "done in ${SECONDS}s (under about 300s keeps the snapshot cached)"
exit 0
