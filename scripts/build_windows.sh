#!/usr/bin/env bash
# Builds the Windows game the owner plays, from the committed HEAD, and zips it for them.
#   ./scripts/build_windows.sh [--push] [label]
#   --push      upload the zip to Cloudflare R2 (tools/assets/assets.py) and print the one line
#               the owner types in PowerShell on their PC to download and unzip it
#   label       a short word added to the zip's name, such as first-playable
#   GODOT=...   Godot binary (default: godot on PATH)
# Steps: copy HEAD into a fresh folder (git archive, so no import cache and no uncommitted
# changes come along), import it, export the Windows preset as a release build, check the pack
# holds the project's data (tools/checks/pack_contents.py), boot that same pack headless with
# the Linux release template, boot the exe under wine when present, then zip the exe, the pack
# and a README.txt for the player into build/windows/Bramble-windows-<commit>-<time>[-label].zip.
# Needs the export templates of the pinned Godot (tools/versions.env): (windows_release_x86_64.exe, linux_release.x86_64), installed
# by scripts/install_export_templates.sh. Exit 0 = built and every check passed.
set -uo pipefail

PUSH=0
if [ "${1:-}" = "--push" ]; then
  PUSH=1
  shift
fi
LABEL="${1:-}"
if [ -n "$LABEL" ] && ! [[ "$LABEL" =~ ^[A-Za-z0-9-]+$ ]]; then
  echo "label must be letters, digits and dashes: '$LABEL'"
  exit 2
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
ROOT="$(pwd)"
# shellcheck source=tools/versions.env
. "$ROOT/tools/versions.env"
# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
GODOT="${GODOT:-godot}"
TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
BOOT_TIMEOUT=120
BOOT_FRAMES=120
READY_LINE="boot: main scene ready"

commit="$(git rev-parse --short=9 HEAD)" || exit 2
name="Bramble-windows-${commit}-$(date +%m%d-%H%M)${LABEL:+-$LABEL}"
OUT="$ROOT/build/windows"
WORK="$OUT/work/$name"
mkdir -p "$OUT"
: >"$ROOT/build/.gdignore"
godot_log_init "$OUT"

fail() {
  echo "FAIL $*"
  exit 1
}

for t in windows_release_x86_64.exe linux_release.x86_64; do
  [ -f "$TEMPLATES/$t" ] || fail "missing export template $TEMPLATES/$t (scripts/install_export_templates.sh)"
done
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "note: uncommitted changes are not in this build; it is built from $commit"
fi

# One build at a time on this machine: two Godot exports at once only slow each other down.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/bramble-build-windows.lock"
flock -n 9 || fail "another build_windows.sh is running"

# A clean copy of the commit: nothing from this checkout's import cache or untracked files.
rm -rf "${WORK:?}"
mkdir -p "$WORK/project" "$WORK/game"
# The project copy and scratch folders go on any exit; the logs stay in $WORK.
cleanup() {
  if command -v wine >/dev/null 2>&1 && [ -d "$WORK/wine" ]; then
    WINEPREFIX="$WORK/wine" wineserver -k || true
  fi
  rm -rf "${WORK:?}/project" "${WORK:?}/empty" "${WORK:?}/wine" "${WORK:?}/linux"
}
trap cleanup EXIT
git archive HEAD | tar -x -C "$WORK/project" || fail "git archive"
PROJECT="$WORK/project"
GAME="$WORK/game"
# The exact committed build is also written into each local game record.
python3 - "$PROJECT/project.godot" "$commit" <<'PY'
import pathlib
import sys

p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace('[application]\n', f'[application]\n\nconfig/build="{sys.argv[2]}"\n', 1))
PY

# The first import can log errors from a cold class cache (check.sh, step import); judge a second.
echo "importing $commit"
timeout 600 "$GODOT" --headless --path "$PROJECT" --import >"$WORK/import1.log" 2>&1
timeout 600 "$GODOT" --headless --path "$PROJECT" --import >"$WORK/import.log" 2>&1 \
  || fail "import (log: $WORK/import.log)"
found="$(godot_log_problems "$WORK/import.log")"
[ -z "$found" ] || { head -n 20 <<<"$found"; fail "import logged problems (log: $WORK/import.log)"; }

echo "exporting Windows (release)"
timeout 600 "$GODOT" --headless --path "$PROJECT" --export-release Windows "$GAME/bramble.exe" \
  >"$WORK/export.log" 2>&1
status=$?
found="$(godot_log_problems "$WORK/export.log")"
if [ "$status" -ne 0 ] || [ -n "$found" ] || [ ! -f "$GAME/bramble.exe" ] || [ ! -f "$GAME/bramble.pck" ]; then
  [ -n "$found" ] && head -n 20 <<<"$found"
  fail "export (exit $status, log: $WORK/export.log)"
fi
echo "exported: bramble.exe $(($(stat -c %s "$GAME/bramble.exe") / 1048576)) MB," \
  "bramble.pck $(($(stat -c %s "$GAME/bramble.pck") / 1024)) KB"

# The pack's file list, read from an empty project so only the pack's files show.
empty="$WORK/empty"
mkdir -p "$empty" && touch "$empty/project.godot"
timeout "$BOOT_TIMEOUT" "$GODOT" --headless --path "$empty" -s "$ROOT/tools/checks/pck_files.gd" \
  -- "$GAME/bramble.pck" 2>"$WORK/pack.err" | sed -n 's|^res://||p' >"$WORK/pack.files"
[ "${PIPESTATUS[0]}" -eq 0 ] || { cat "$WORK/pack.err"; fail "cannot list the pack"; }
python3 "$ROOT/tools/checks/pack_contents.py" "$WORK/pack.files" "$PROJECT" || fail "pack contents"

# boot_ok <log> <what>: the log has the main scene's ready line and no problem lines.
boot_ok() {
  found="$(godot_log_problems "$1")"
  [ -z "$found" ] || { head -n 20 <<<"$found"; fail "$2 logged problems (log: $1)"; }
  grep -qF "$READY_LINE" "$1" || { tail -n 20 "$1"; fail "$2 never reached the main scene (log: $1)"; }
  echo "boot ok: $2 reached the main scene"
}

# The exact pack the owner gets, run by the Linux release runtime of the same Godot. Release
# runtimes refuse --main-pack, so the runtime sits beside a copy of the pack with the same name.
mkdir -p "$WORK/linux"
cp "$TEMPLATES/linux_release.x86_64" "$WORK/linux/bramble.x86_64"
cp "$GAME/bramble.pck" "$WORK/linux/bramble.pck"
timeout "$BOOT_TIMEOUT" "$WORK/linux/bramble.x86_64" --headless \
  --audio-driver Dummy --quit-after "$BOOT_FRAMES" >"$WORK/boot-linux.log" 2>&1 \
  || { tail -n 20 "$WORK/boot-linux.log"; fail "Linux boot of the Windows pack exited non-zero"; }
boot_ok "$WORK/boot-linux.log" "the Windows pack on the Linux runtime"

# The exe itself, under wine when this machine has it. Its own prefix, so no state is shared.
if command -v wine >/dev/null 2>&1; then
  WINEPREFIX="$WORK/wine" WINEDEBUG=-all timeout "$BOOT_TIMEOUT" xvfb-run -a wine "$GAME/bramble.exe" \
    --headless --audio-driver Dummy --quit-after "$BOOT_FRAMES" >"$WORK/boot-wine.log" 2>&1
  boot_ok "$WORK/boot-wine.log" "bramble.exe under wine"
else
  echo "note: bramble.exe was not run (wine is not installed)"
fi

# README.txt for the player, with Windows line endings so Notepad shows it properly.
sed 's/$/\r/' >"$GAME/README.txt" <<EOF
Bramble test build, $(date '+%d %b %Y %H:%M'), from commit $commit${LABEL:+ ($LABEL)}

1. Unzip this whole folder.
2. Run bramble.exe. Keep bramble.pck next to it: the game is inside that file.

Windows may say it protected your PC, because the game is not signed.
Click "More info", then "Run anyway".

Game records stay on this PC. In Explorer, open:
%APPDATA%\Godot\app_userdata\Bramble\records
Copy or zip that folder to export them. Keep this build to replay its records.
EOF

zip="$OUT/$name.zip"
rm -f "$zip"
(cd "$WORK" && mv game "$name" && zip -q -9 -r "$zip" "$name") || fail "zip"
python3 - "$zip" "$name" <<'PY' || fail "zip lacks the exe, the pack or the README"
import sys
import zipfile

names = set(zipfile.ZipFile(sys.argv[1]).namelist())
sys.exit(0 if all(f"{sys.argv[2]}/{f}" in names for f in ("bramble.exe", "bramble.pck", "README.txt")) else 1)
PY
echo "zip ok: ${zip#"$ROOT"/} $(($(stat -c %s "$zip") / 1048576)) MB"

if [ "$PUSH" -eq 1 ]; then
  rel="${zip#"$ROOT"/}"
  python3 "$ROOT/tools/assets/assets.py" push --allow-large "$rel" || fail "push to R2"
  digest="$(sha256sum "$zip" | cut -d' ' -f1)"
  bucket="$(cat "$ROOT/tools/assets/bucket")"
  echo "pushed. tools/assets/manifest.tsv now lists it: commit that file."
  echo "The owner's line (PowerShell, on their PC):"
  echo "npx.cmd -y wrangler@${WRANGLER_VERSION} r2 object get ${bucket}/sha256/${digest:0:2}/${digest}.zip --remote" \
    "--file \"\$HOME\\Downloads\\$name.zip\"; Expand-Archive \"\$HOME\\Downloads\\$name.zip\"" \
    "\"\$HOME\\Downloads\" -Force; ii \"\$HOME\\Downloads\\$name\""
fi
rm -rf "${WORK:?}/${name:?}"
echo "build_windows: $name passed"
