#!/usr/bin/env bash
# Builds the Windows game the owner plays, from the committed HEAD, and zips it for them.
#   ./scripts/build_windows.sh [--push] [--ghost-field <dir>] [label]
#   --push      upload the zip to Cloudflare R2 (tools/assets/assets.py) and print the one line
#               the owner types in PowerShell on their PC to download and unzip it
#   label       a short word added to the zip's name, such as first-playable
#   --ghost-field  use a field made with make_field.sh (default: play and cut 1,000 live games)
#   GODOT=...   Godot binary (default: godot on PATH)
# Steps: copy HEAD into a fresh folder (git archive, so no import cache and no uncommitted
# changes come along), import it, export the Windows preset as a release build, check the pack
# holds the project's data (tools/checks/pack_contents.py), autoplay a ghost game headless with
# the Linux release template and with wine when present, then zip the exe, the pack
# and a README.txt for the player into build/windows/Bramble-windows-<commit>-<time>[-label].zip.
# Needs the export templates of the pinned Godot (tools/versions.env): (windows_release_x86_64.exe, linux_release.x86_64), installed
# by scripts/install_export_templates.sh. Exit 0 = built and every check passed.
set -uo pipefail

PUSH=0
FIELD=""
LABEL=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --push) PUSH=1 ;;
    --ghost-field)
      if [ "$#" -lt 2 ] || [[ "$2" == -* ]] || [ ! -d "$2" ]; then
        echo "--ghost-field needs a directory" >&2
        exit 2
      fi
      FIELD="$(realpath -- "$2")" || exit 2
      shift
      ;;
    -*)
      echo "unknown option: $1" >&2
      exit 2
      ;;
    *)
      [ -z "$LABEL" ] || { echo "expected a single build label" >&2; exit 2; }
      LABEL="$1"
      ;;
  esac
  shift
done
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
READY_LINE="boot: main scene ready"
FINISHED_LINE="boot: ghost game finished"

commit="$(git rev-parse --short=9 HEAD)" || exit 2
name="Bramble-windows-${commit}-$(date +%m%d-%H%M)${LABEL:+-$LABEL}"
OUT="$ROOT/build/windows"
mkdir -p "$OUT/work" || exit 2
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
exec 9>"${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/bramble-build-windows.lock"
flock -n 9 || fail "another build_windows.sh is running"

# A clean copy of the commit: nothing from this checkout's import cache or untracked files.
WORK="$(mktemp -d "$OUT/work/$name.XXXXXXXX")" || fail "cannot create build work folder"
PROJECT="$WORK/project"
GAME="$WORK/$name"
mkdir "$PROJECT" "$GAME" || fail "cannot create project and game folders"
echo "build work: $WORK"
stop_wine() {
  local server candidate
  if command -v wine >/dev/null 2>&1 && [ -d "$WORK/wine" ]; then
    server="$(command -v wineserver || true)"
    if [ -z "$server" ]; then
      for candidate in /usr/lib/x86_64-linux-gnu/wine/wineserver /usr/lib/wine/wineserver \
        /usr/lib64/wine/wineserver /opt/wine*/bin/wineserver; do
        if [ -x "$candidate" ]; then
          server="$candidate"
          break
        fi
      done
    fi
    if [ -n "$server" ]; then
      WINEPREFIX="$WORK/wine" timeout -k 10 20 "$server" -k || true
    else
      echo "note: wineserver not found; Wine may be left running"
    fi
  fi
}
trap stop_wine EXIT
git archive HEAD | tar -x -C "$PROJECT" || fail "git archive"
# The exact committed build is also written into each local game record.
python3 - "$PROJECT/project.godot" "$commit" <<'PY'
import pathlib
import sys

p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace('[application]\n', f'[application]\n\nconfig/build="{sys.argv[2]}"\n', 1))
PY

# The first import can log errors from a cold class cache (check.sh, step import); judge a second.
echo "importing $commit"
timeout -k 10 600 "$GODOT" --headless --path "$PROJECT" --import >"$WORK/import1.log" 2>&1
timeout -k 10 600 "$GODOT" --headless --path "$PROJECT" --import >"$WORK/import.log" 2>&1 \
  || fail "import (log: $WORK/import.log)"
found="$(godot_log_problems "$WORK/import.log")"
[ -z "$found" ] || { head -n 20 <<<"$found"; fail "import logged problems (log: $WORK/import.log)"; }

export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$ROOT/tools/league/target}"
if [ -z "$FIELD" ]; then
  FIELD="$WORK/field"
  timeout -k 10 4800 "$PROJECT/tools/league/proof/make_field.sh" "$FIELD" || fail "generate ghost field"
fi
GODOT="$GODOT" "$PROJECT/scripts/stage_ghost_field.sh" "$PROJECT" "$FIELD" || fail "validate ghost field"

echo "exporting Windows (release)"
timeout -k 10 600 "$GODOT" --headless --path "$PROJECT" --export-release Windows "$GAME/bramble.exe" \
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
timeout -k 10 "$BOOT_TIMEOUT" "$GODOT" --headless --path "$empty" -s "$PROJECT/tools/checks/pck_files.gd" \
  -- "$GAME/bramble.pck" 2>"$WORK/pack.err" | sed -n 's|^res://||p' >"$WORK/pack.files"
[ "${PIPESTATUS[0]}" -eq 0 ] || { cat "$WORK/pack.err"; fail "cannot list the pack"; }
python3 "$PROJECT/tools/checks/pack_contents.py" "$WORK/pack.files" "$PROJECT" || fail "pack contents"

# boot_ok <log> <what>: the main scene opened and reached a ghost game's result without errors.
boot_ok() {
  found="$(godot_log_problems "$1")"
  [ -z "$found" ] || { head -n 20 <<<"$found"; fail "$2 logged problems (log: $1)"; }
  grep -qF "$READY_LINE" "$1" || { tail -n 20 "$1"; fail "$2 never reached the main scene (log: $1)"; }
  grep -qF "$FINISHED_LINE" "$1" || { tail -n 20 "$1"; fail "$2 did not finish a ghost game (log: $1)"; }
  echo "boot ok: $2 reached the main scene and finished a ghost game"
}

# The exact pack the owner gets, run by the Linux release runtime of the same Godot. Release
# runtimes refuse --main-pack, so the runtime sits beside a copy of the pack with the same name.
mkdir -p "$WORK/linux"
cp "$TEMPLATES/linux_release.x86_64" "$WORK/linux/bramble.x86_64"
ln "$GAME/bramble.pck" "$WORK/linux/bramble.pck" || fail "stage the Windows pack for Linux"
timeout -k 10 "$BOOT_TIMEOUT" "$WORK/linux/bramble.x86_64" --headless \
  --audio-driver Dummy -- --autoplay --seed 7 >"$WORK/boot-linux.log" 2>&1 \
  || { tail -n 20 "$WORK/boot-linux.log"; fail "Linux ghost autoplay exited non-zero"; }
boot_ok "$WORK/boot-linux.log" "the Windows pack on the Linux runtime"

# The exe itself, under wine when this machine has it. Its own prefix, so no state is shared.
if command -v wine >/dev/null 2>&1; then
  WINEPREFIX="$WORK/wine" WINEDEBUG=-all timeout -k 10 "$BOOT_TIMEOUT" xvfb-run -a wine "$GAME/bramble.exe" \
    --headless --audio-driver Dummy -- --autoplay --seed 7 >"$WORK/boot-wine.log" 2>&1 \
    || { tail -n 20 "$WORK/boot-wine.log"; fail "Wine ghost autoplay exited non-zero"; }
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
[ ! -e "$zip" ] || fail "zip already exists: $zip"
(cd "$WORK" && zip -q -9 -r "$zip" "$name") || fail "zip"
python3 - "$zip" "$name" <<'PY' || fail "zip lacks the exe, the pack or the README"
import sys
import zipfile

names = set(zipfile.ZipFile(sys.argv[1]).namelist())
sys.exit(0 if all(f"{sys.argv[2]}/{f}" in names for f in ("bramble.exe", "bramble.pck", "README.txt")) else 1)
PY
echo "zip ok: ${zip#"$ROOT"/} $(($(stat -c %s "$zip") / 1048576)) MB"
# The zip holds the game; the work folder (project copy, field, wine prefix, logs) goes once every
# check has passed. A failed build keeps it, for its logs.
stop_wine
trap - EXIT
rm -rf "${WORK:?}"

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
echo "build_windows: $name passed"
