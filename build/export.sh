#!/usr/bin/env bash
# build/export.sh [--dry-run] <N> "<one-line summary>"
# A dry run may inject a throwaway library with FIELD_LIBRARY=/absolute/path.json.gz.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
dry=0
if [ "${1:-}" = --dry-run ]; then dry=1; shift; fi
[ "$#" = 2 ] || { echo 'usage: build/export.sh [--dry-run] <N> "<one-line summary>"' >&2; exit 2; }
number="$1" summary="$2"
[[ "$number" =~ ^[1-9][0-9]*$ ]] || { echo 'build number must be a positive integer' >&2; exit 2; }
# Keep the required README first line unambiguous.
[[ -n "$summary" && "$summary" != *$'\n'* && "$summary" != *$'\r'* && "$summary" != *'('* && "$summary" != *')'* ]] \
  || { echo 'summary must be one line without parentheses' >&2; exit 2; }
[ -z "$(git status --porcelain)" ] || { echo 'refusing a dirty source tree; commit changes first' >&2; exit 2; }
commit="$(git rev-parse HEAD)"
tag="ideation-build-$number"
library="${FIELD_LIBRARY:-$ROOT/content/fields/baseline.json.gz}"
if [ "$dry" = 0 ] && [ "$library" != "$ROOT/content/fields/baseline.json.gz" ]; then
  echo 'throwaway library injection is only allowed with --dry-run' >&2; exit 2
fi
[ -s "$library" ] || { echo "missing strong-field library: $library" >&2; exit 2; }
library="$(realpath "$library")"
library_sha="$(sha256sum "$library" | cut -d' ' -f1)"
if [ "$dry" = 1 ]; then
  out="$(mktemp -d "$ROOT/build/export-dry-run-$number-$(date +%m%d-%H%M).XXXXXX")"
else
  ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || { echo "tag already exists: $tag" >&2; exit 2; }
  out="/data/bramble-builds/$(date +%m%d-%H%M)-ideation$number"
  mkdir "$out"
fi
mkdir -p "$out/project" "$out/logs" "$out/data/godot/keystores" "$out/data/godot/export_templates" "$out/config" "$out/cache" "$out/tmp"
git archive "$commit" | tar -x -C "$out/project"
# Bake the archived source revision into every platform's pack. Runtime environment and
# Git are not available on the owner's machine; the checkout itself stays untouched.
sed -i "/^\[application\]$/a config/build_commit=\"$commit\"" "$out/project/project.godot"
if [ "$dry" = 1 ]; then
  mkdir -p "$out/project/content/fields"
  cp "$library" "$out/project/content/fields/baseline.json.gz"
  # Exercise opt-in field starts in this throwaway snapshot; do not change the shipped default.
  sed -i 's/^custom_features=""/custom_features="strong_field"/' "$out/project/export_presets.cfg"
fi
# shellcheck source=/opt/bramble/env.sh
source /opt/bramble/env.sh
source tools/versions.env
export XDG_DATA_HOME="$out/data" XDG_CONFIG_HOME="$out/config" XDG_CACHE_HOME="$out/cache" LP_NUM_THREADS=6
cp /opt/godot-data/godot/keystores/debug.keystore "$out/data/godot/keystores/debug.keystore"
ln -s "/opt/godot-data/godot/export_templates/$GODOT_VERSION.stable" "$out/data/godot/export_templates/$GODOT_VERSION.stable"
slot() { GODOT_SLOT_CLASS=worker "$ROOT/scripts/godot_slot.sh" "$@"; }
(
  cd "$out/project"
  REQUIRE_ANDROID=1 EXPORT_LOG_DIR="$out/logs" GODOT_EXPORT_TEMP_DIR="$out/tmp" scripts/export_smoke.sh "$out"
) >"$out/export.log" 2>&1
cp "$out/logs/export_boot_linux.log" "$out/linux-boot.log"
# Check Windows and Android content with the editor against each actual pack.
python3 - "$out" <<'PY'
import sys, zipfile
from pathlib import Path
out = Path(sys.argv[1])
with zipfile.ZipFile(out / 'android/bramble.apk') as apk, zipfile.ZipFile(out / 'android-assets.zip', 'w') as pack:
    assert apk.testzip() is None
    for name in apk.namelist():
        if name.startswith('assets/') and not name.endswith('/'):
            pack.writestr(name[7:], apk.read(name))
with zipfile.ZipFile(out / 'Bramble-windows.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in ('bramble.exe', 'bramble.pck'):
        archive.write(out / 'windows' / name, 'windows/' + name)
PY
cp "$out/android/bramble.apk" "$out/Bramble.apk"
for pack in windows/bramble.pck android-assets.zip; do
  label="$(basename "$pack")"
  slot timeout 120 godot --headless --main-pack "$out/$pack" \
    -s "$out/project/tools/sim/export_field_probe.gd" >"$out/logs/field-$label.log" 2>&1
  grep -qxF "export-field: loaded sha256=$library_sha" "$out/logs/field-$label.log"
done
slot timeout -k 5 150 xvfb-run -a env WINEPREFIX="$out/wine" WINEDEBUG=-all \
  wine "$out/windows/bramble.console.exe" --headless --quit-after 60 >"$out/windows-boot.log" 2>&1
grep -qxF 'boot: main scene ready' "$out/linux-boot.log"
tr -d '\r' <"$out/windows-boot.log" | grep -qxF 'boot: main scene ready'
# Validate the APK signer against the specified keystore and build 7's published certificate.
apksigner="$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS/apksigner"
"$apksigner" verify --verbose --print-certs "$out/Bramble.apk" >"$out/android-signing.txt"
keytool -exportcert -keystore /opt/godot-data/godot/keystores/debug.keystore \
  -alias androiddebugkey -storepass android -file "$out/debug-certificate.der" >"$out/keytool.log" 2>&1
cert_sha="$(sha256sum "$out/debug-certificate.der" | cut -d' ' -f1)"
awk '/certificate SHA-256 digest:/ {print $NF}' "$out/android-signing.txt" >"$out/certificate-sha256.txt"
[ "$(cat "$out/certificate-sha256.txt")" = "$cert_sha" ]
awk '/certificate SHA-256 digest:/ {print $NF}' /data/bramble-builds/1108-2016-ideation7/android-signing.txt >"$out/build7-certificate-sha256.txt"
cmp "$out/certificate-sha256.txt" "$out/build7-certificate-sha256.txt"
cp "$out/project/docs/ideation/PLAYTEST.md" "$out/PLAYTEST.md"
cat >"$out/README.txt" <<README
Ideation build $number: $summary
Source commit: $commit
Tag: $tag
Strong-field library SHA-256: $library_sha
Library source: $library
Dry run: $dry; a dry run creates no tag and does not update latest.
Dry-run library is throwaway and is not the shipped library.
Dry-run snapshot enables strong_field for testing only; it does not select the shipped default.

Windows: unzip Bramble-windows.zip and run windows/bramble.exe beside bramble.pck.
Android: install Bramble.apk. Debug certificate SHA-256: $cert_sha
Linux: linux/bramble.x86_64
Checked: pack listings, library load and SHA from Windows and APK packs, APK signing certificate against the debug keystore and build 7, Linux and Wine boots.
PLAYTEST.md is frozen at the source commit. No real device was tested.
Balance, soak and UI depth gates remain separate plan steps; this export does not certify them.
README
# Catch changes during the export before creating the delivery tag or publishing latest.
[ "$(git rev-parse HEAD)" = "$commit" ] && [ -z "$(git status --porcelain)" ]
evidence="$out/build-$number.md"
cat >"$evidence" <<EVIDENCE
# Ideation build $number delivery

- Source: \`$commit\`
- Tag: \`$tag\` — created only for a real delivery; dry run: $dry.
- Folder: \`$out\`
- Summary: $summary
- Strong-field library SHA-256: \`$library_sha\`
- Certificate SHA-256: \`$cert_sha\`; matches keystore and build 7.
- Checks: three pack listings; Windows/APK field load and SHA; APK verification;
  Linux and Wine boots. Logs and frozen PLAYTEST accompany the artifacts.
- No real device tested. Soak, balance and UI-depth acceptance are separate gates.
EVIDENCE
if [ "$dry" = 0 ]; then
  mkdir -p docs/ideation/evidence/builds
  [ ! -e "docs/ideation/evidence/builds/build-$number.md" ]
  git tag "$tag" "$commit"
  cp "$evidence" "docs/ideation/evidence/builds/build-$number.md"
  ln -s "$out" "/data/bramble-builds/.latest-$number-$$"
  mv -Tf "/data/bramble-builds/.latest-$number-$$" /data/bramble-builds/latest
fi
printf 'export passed: %s\nREADME: %s/README.txt\n' "$out" "$out"
