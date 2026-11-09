#!/usr/bin/env bash
# Export smoke test: proves the presets in export_presets.cfg still produce working builds.
#   ./scripts/export_smoke.sh [--aab] [out_dir]     default out_dir: <repo>/build/export-smoke
#   GODOT=/path/to/godot      Godot binary (default: godot on PATH)
#   REQUIRE_ANDROID=1         fail, instead of skipping, when no JDK or Android SDK is found
# Exports, as debug builds:
#   - Linux: checks size and pack contents, then boots it headless to the main scene and
#     requires exit 0 and a clean log;
#   - Windows: checks size, pack contents and that the exe carries the product name
#     (application/modify_resources, no wine or rcedit needed);
#   - Android APK (no Gradle), when JAVA_HOME and ANDROID_HOME point at a JDK and an SDK;
#   - with --aab, the Android App Bundle through Gradle (installs the Android build template).
# Needs the export templates for the pinned Godot (tools/versions.env). Exit 0 = all passed.
set -uo pipefail

BUILD_AAB=0
if [ "${1:-}" = "--aab" ]; then
  BUILD_AAB=1
  shift
fi
OUT_DIR="${1:-}"
if [ -n "$OUT_DIR" ]; then
  mkdir -p "$OUT_DIR" && OUT_DIR="$(cd "$OUT_DIR" && pwd)" || exit 2
fi
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
ROOT="$(pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/build/export-smoke}"
LOG_DIR="$ROOT/build/check"
GODOT="${GODOT:-godot}"
EXPORT_TIMEOUT=600
GRADLE_TIMEOUT=1500
BOOT_TIMEOUT=60
BOOT_FRAMES=120
mkdir -p "$OUT_DIR" "$LOG_DIR"
: >"$ROOT/build/.gdignore"

# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
godot_log_init "$LOG_DIR"

# The line src/main/main.gd prints once the main scene is up.
READY_LINE="boot: main scene ready"
# Every pack must hold the main scene (exports keep a .remap next to the converted scene).
REQUIRED_RE='^src/main/main\.tscn(\.remap)?$'
# And the sounds: an import stub for each, and its data under .godot/imported.
AUDIO_STUB_RE='^assets/audio/.*\.wav\.import$'
AUDIO_DATA_RE='^\.godot/imported/.*\.wav-[0-9a-f]+\.sample$'
# The field experiment stays off and its baseline must not ship before the full new pool.
FIELD_RE='^content/fields/.*\.json(\.gz)?$'
LEVER_RE='^content/levers/[^/]+\.json$'
# Development-only directories no pack may ship.
FORBIDDEN_DIRS=(tests/ tools/ scripts/ docs/ addons/gut/ build/)

failed=0
fail() {
  echo "FAIL $*"
  failed=1
}

# project_setting <key>: the raw value of a key in project.godot (quotes stripped).
project_setting() {
  grep -E "^$1=" project.godot | head -n 1 | cut -d= -f2- | tr -d '"'
}

# preset_option <preset name> <key>: the raw value of an option of that preset.
preset_option() {
  python3 - "$1" "$2" <<'PY'
import configparser
import sys

cfg = configparser.RawConfigParser()
cfg.read("export_presets.cfg", encoding="utf-8")
for section in cfg.sections():
    if section.endswith(".options") or cfg.get(section, "name", fallback="").strip('"') != sys.argv[1]:
        continue
    print(cfg.get(section + ".options", sys.argv[2], fallback="").strip('"'))
PY
}

# export_build <debug|release> <preset> <path> <log> [timeout]: fails on a non-zero exit, a
# logged problem or a missing artifact.
export_build() {
  local mode="$1" preset="$2" path="$3" log="$4" limit="${5:-$EXPORT_TIMEOUT}" status found
  # A fresh directory, so a stale build from an earlier run can never pass the checks.
  rm -rf "$(dirname "$path")"
  mkdir -p "$(dirname "$path")"
  timeout "$limit" "$GODOT" --headless "--export-${mode}" "$preset" "$path" >"$log" 2>&1
  status=$?
  found="$(godot_log_problems "$log")"
  if [ "$status" -ne 0 ] || [ -n "$found" ] || [ ! -f "$path" ]; then
    [ -n "$found" ] && head -n 20 <<<"$found"
    # Gradle's own failure lines carry no ERROR prefix; show the first few (HTTP 429s, say).
    grep -E -m 5 'Could not (GET|resolve|download)|Received status code|^FAILURE:' "$log"
    fail "export '$preset' (exit $status, log: $log)"
    return 1
  fi
  echo "exported '$preset' -> ${path#"$ROOT"/}"
}

# check_size <file> <min_kb> <max_kb>
check_size() {
  local file="$1" min=$(($2 * 1024)) max=$(($3 * 1024)) size
  if [ ! -f "$file" ]; then
    fail "missing artifact ${file#"$ROOT"/}"
    return 1
  fi
  size=$(stat -c %s "$file")
  if [ "$size" -lt "$min" ] || [ "$size" -gt "$max" ]; then
    fail "${file#"$ROOT"/} is $size bytes, expected $2..$3 KiB"
    return 1
  fi
  echo "size ok: ${file#"$ROOT"/} $((size / 1024)) KiB"
}

# check_listing <label> <listing file>: one res-relative path per line.
check_listing() {
  local label="$1" listing="$2" dir card ok=1
  grep -qE "$REQUIRED_RE" "$listing" || { fail "$label: pack lacks the main scene"; ok=0; }
  if grep -qE "$FIELD_RE" "$listing"; then
    fail "$label: player pack ships an experimental field library"
    ok=0
  fi
  grep -qE "$LEVER_RE" "$listing" || { fail "$label: pack lacks gameplay levers"; ok=0; }
  for card in content/levers/*.json; do
    grep -qxF "$card" "$listing" || { fail "$label: pack lacks $card"; ok=0; }
  done
  local stubs samples
  stubs=$(grep -cE "$AUDIO_STUB_RE" "$listing")
  samples=$(grep -cE "$AUDIO_DATA_RE" "$listing")
  if [ "$stubs" -eq 0 ] || [ "$stubs" -ne "$samples" ]; then
    fail "$label: pack has $stubs sound stubs and $samples sound samples"
    ok=0
  fi
  for dir in "${FORBIDDEN_DIRS[@]}"; do
    if grep -qE "^${dir}" "$listing"; then
      fail "$label: pack ships files under $dir"
      ok=0
    fi
  done
  [ "$ok" -eq 1 ] && echo "contents ok: $label ($(wc -l <"$listing") files)"
}

# list_pck <pck> <listing>: lists the pack from an empty project, so only its files show.
list_pck() {
  local pck="$1" listing="$2" project status
  project="$(mktemp -d)"
  touch "$project/project.godot"
  timeout "$BOOT_TIMEOUT" "$GODOT" --headless --path "$project" \
    -s "$ROOT/tools/checks/pck_files.gd" -- "$pck" 2>"$listing.err" \
    | sed -n 's|^res://||p' >"$listing"
  status=${PIPESTATUS[0]}
  rm -rf "$project"
  if [ "$status" -ne 0 ]; then
    cat "$listing.err"
    fail "cannot list ${pck#"$ROOT"/} (exit $status)"
    return 1
  fi
}

# list_zip <archive> <prefix> <listing>: entries under prefix, with the prefix removed.
list_zip() {
  python3 - "$1" "$2" >"$3" <<'PY' || { fail "cannot list ${1#"$ROOT"/}"; return 1; }
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in archive.namelist():
        if name.startswith(sys.argv[2]):
            print(name[len(sys.argv[2]) :])
PY
}

# Preset values that must agree with project.godot. Windows has no "use the project name" default.
check_presets() {
  local name version ok=1 got
  name="$(project_setting 'config/name')"
  version="$(project_setting 'config/version')"
  got="$(preset_option Windows application/product_name)"
  [ "$got" = "$name" ] || { fail "Windows product_name '$got' != project name '$name'"; ok=0; }
  got="$(preset_option Windows application/product_version)"
  [ "$got" = "${version}.0" ] || { fail "Windows product_version '$got' != '${version}.0'"; ok=0; }
  for preset in "Android APK" "Android AAB"; do
    got="$(preset_option "$preset" version/name)"
    [ "$got" = "$version" ] || { fail "$preset version/name '$got' != project version '$version'"; ok=0; }
  done
  [ "$ok" -eq 1 ] && echo "presets ok (name '$name', version $version)"
  echo "note: Android package name is '$(preset_option "Android APK" package/unique_name)', a placeholder until the owner picks the app ID"
}

# boot_linux <binary>: runs headless to the main scene and exits 0 with a clean log.
boot_linux() {
  local bin="$1" log="$LOG_DIR/export_boot_linux.log" status found
  timeout "$BOOT_TIMEOUT" "$bin" --headless --audio-driver Dummy --quit-after "$BOOT_FRAMES" >"$log" 2>&1
  status=$?
  if [ "$status" -ne 0 ]; then
    tail -n 20 "$log"
    fail "linux boot exited $status (log: $log)"
    return 1
  fi
  found="$(godot_log_problems "$log")"
  if [ -n "$found" ]; then
    head -n 20 <<<"$found"
    fail "linux boot logged problems (log: $log)"
    return 1
  fi
  if ! grep -qxF "$READY_LINE" "$log"; then
    fail "linux boot never printed '$READY_LINE' within $BOOT_FRAMES frames (log: $log)"
    return 1
  fi
  echo "boot ok: linux reached the main scene and exited 0"
}

# Use the real PCK to verify feature-off UI/defaults and reject the CLI escape route.
# The probe is external and is not shipped in player builds.
boot_linux_field() {
  local bin="$1" log status found expected
  log="$LOG_DIR/export_boot_linux_field_settings.log"
  expected="export-field-smoke: feature off; Strong field choice absent; saved preference uses Bots"
  # Stock templates disable --script. Run the external probe with the editor against the
  # exported PCK; all res:// classes and content then come from that pack, not the checkout.
  timeout "$BOOT_TIMEOUT" "$GODOT" --headless --audio-driver Dummy \
    --main-pack "${bin%.*}.pck" -s "$ROOT/tools/checks/field_export_smoke.gd" >"$log" 2>&1
  status=$?
  found="$(godot_log_problems "$log")"
  if [ "$status" -ne 0 ] || [ -n "$found" ]; then
    tail -n 25 "$log"
    fail "packed field feature-off settings smoke exited $status (log: $log)"
    return 1
  fi
  if ! grep -qxF "$expected" "$log"; then
    fail "packed field feature-off settings smoke did not finish its checks (log: $log)"
    return 1
  fi
  echo "feature gate ok: packed UI hides Strong field and saved preference defaults to Bots"
}

# check_product_name <exe> <name>: the version resource carries the name (UTF-16LE).
check_product_name() {
  if python3 - "$1" "$2" <<'PY'; then
import re
import sys

data = open(sys.argv[1], "rb").read()
# A VS_VERSIONINFO String: the key, its terminator and padding (UTF-16 NULs), then the value.
key, value = "ProductName".encode("utf-16-le"), (sys.argv[2] + "\0").encode("utf-16-le")
sys.exit(0 if re.search(re.escape(key) + b"(?:\0\0)+" + re.escape(value), data) else 1)
PY
    echo "resources ok: ${1#"$ROOT"/} has ProductName '$2'"
  else
    fail "${1#"$ROOT"/} lacks ProductName '$2' in its version resource"
  fi
}

# android_ready: a JDK and an SDK are available for Android exports.
android_ready() {
  [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ] \
    && [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/platform-tools" ]
}

# The pack and the class cache come from the import cache; build it on a fresh clone.
if [ ! -f .godot/global_script_class_cache.cfg ] && [ ! -d .godot/imported ]; then
  echo "no import cache yet; running godot --headless --import"
  timeout 600 "$GODOT" --headless --import >"$LOG_DIR/export_import.log" 2>&1 \
    || { echo "FAIL import (log: $LOG_DIR/export_import.log)"; exit 1; }
fi

check_presets
name="$(project_setting 'config/name')"

linux="$OUT_DIR/linux/bramble.x86_64"
if export_build debug "Linux" "$linux" "$LOG_DIR/export_linux.log"; then
  check_size "$linux" 10240 512000
  check_size "${linux%.*}.pck" 1 204800
  list_pck "${linux%.*}.pck" "$OUT_DIR/linux.files" && check_listing linux "$OUT_DIR/linux.files"
  boot_linux "$linux"
  boot_linux_field "$linux"
fi

windows="$OUT_DIR/windows/bramble.exe"
if export_build debug "Windows" "$windows" "$LOG_DIR/export_windows.log"; then
  check_size "$windows" 10240 512000
  check_size "${windows%.*}.pck" 1 204800
  list_pck "${windows%.*}.pck" "$OUT_DIR/windows.files" && check_listing windows "$OUT_DIR/windows.files"
  check_product_name "$windows" "$name"
fi

if android_ready; then
  apk="$OUT_DIR/android/bramble.apk"
  if export_build debug "Android APK" "$apk" "$LOG_DIR/export_android_apk.log"; then
    check_size "$apk" 10240 307200
    list_zip "$apk" "assets/" "$OUT_DIR/android_apk.files" && check_listing android-apk "$OUT_DIR/android_apk.files"
  fi
  if [ "$BUILD_AAB" -eq 1 ]; then
    # Gradle builds need the Android build template in res://android/ (gitignored). The install
    # flag only works together with an export (on its own, Godot just runs the game), and that
    # first export logs engine warnings about the fresh template ("Scan thread aborted", one
    # leaked instance). So a missing template gets an install pass judged on its exit code and
    # the template alone; the export after it is judged strictly.
    if [ ! -d android/build ]; then
      mkdir -p "$OUT_DIR/android-template"
      timeout "$GRADLE_TIMEOUT" "$GODOT" --headless --install-android-build-template \
        --export-debug "Android AAB" "$OUT_DIR/android-template/bramble.aab" \
        >"$LOG_DIR/android_template.log" 2>&1
      status=$?
      rm -rf "$OUT_DIR/android-template"
      # Its export runs Gradle too, so a non-zero exit with the template in place is a Gradle
      # failure: say so, and let the strict export below report it.
      if [ ! -d android/build ]; then
        fail "could not install the Android build template (exit $status, log: $LOG_DIR/android_template.log)"
      elif [ "$status" -ne 0 ]; then
        echo "note: build template installed, but its export exited $status; the AAB export below shows why"
      fi
    fi
    aab="$OUT_DIR/android-aab/bramble.aab"
    if [ -d android/build ] \
      && export_build debug "Android AAB" "$aab" "$LOG_DIR/export_android_aab.log" "$GRADLE_TIMEOUT"; then
      check_size "$aab" 10240 307200
      # Godot puts the project's files in an install-time asset pack inside the bundle.
      list_zip "$aab" "assetPackInstallTime/assets/" "$OUT_DIR/android_aab.files" \
        && check_listing android-aab "$OUT_DIR/android_aab.files"
    fi
  fi
elif [ "${REQUIRE_ANDROID:-0}" = "1" ]; then
  fail "Android exports need JAVA_HOME (JDK) and ANDROID_HOME (SDK); REQUIRE_ANDROID=1"
else
  echo "SKIP Android: no JDK at JAVA_HOME or no SDK at ANDROID_HOME (set REQUIRE_ANDROID=1 to fail instead)"
fi

if [ "$failed" -ne 0 ]; then
  echo "export_smoke: FAILED"
  exit 1
fi
echo "export_smoke: all checks passed"
