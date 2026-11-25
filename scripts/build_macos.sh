#!/usr/bin/env bash
# Builds a macOS game from the committed HEAD and zips it, for the owner to send to a Mac player.
#   ./scripts/build_macos.sh [--ghost-field <dir>] [label]
# Run it ONLY when the owner explicitly asks for a Mac build. It is never part of another build,
# never run after a Windows build on its own, and never sent to the owner's PC unasked.
# (Owner, 21 Nov 2026: "it's to be triggered only when I request it, explicitly only".)
#   label          a short word added to the zip's name
#   --ghost-field  use a field made with make_field.sh (default: play and cut 1,000 live games)
#   GODOT=...      Godot binary (default: godot on PATH)
# Steps, as in build_windows.sh: copy HEAD into a fresh folder (git archive), add a macOS preset to
# that copy only (export_presets.cfg in the repo has none, so the quality gate never needs the
# macOS template), import, stage a ghost field, export a universal (Intel and Apple Silicon) app
# with Godot's built-in ad-hoc signing, check the pack's contents, autoplay a ghost game with the
# app's pack on the Linux release runtime, then zip Bramble.app and a README.txt for the player
# into build/macos/Bramble-macos-<commit>-<time>[-label].zip.
# What it cannot check: nothing here runs the app on a Mac. Ad-hoc signing is not notarisation,
# so macOS blocks the app on first open; the README says how to allow it.
# Needs the export templates macos.zip and linux_release.x86_64 of the pinned Godot
# (tools/versions.env), installed by scripts/install_export_templates.sh. The download is about
# 1 GB and uses mktemp: on the Optiplex set TMPDIR under /data, since /tmp is RAM.
# Exit 0 = built and every check passed.
set -uo pipefail

FIELD=""
LABEL=""
while [ "$#" -gt 0 ]; do
  case "$1" in
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
name="Bramble-macos-${commit}-$(date +%m%d-%H%M)${LABEL:+-$LABEL}"
OUT="$ROOT/build/macos"
mkdir -p "$OUT/work" || exit 2
: >"$ROOT/build/.gdignore"
godot_log_init "$OUT"

fail() {
  echo "FAIL $*"
  exit 1
}

for t in macos.zip linux_release.x86_64; do
  [ -f "$TEMPLATES/$t" ] || fail "missing export template $TEMPLATES/$t (scripts/install_export_templates.sh)"
done
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "note: uncommitted changes are not in this build; it is built from $commit"
fi

# Shares build_windows.sh's lock: two Godot exports at once only slow each other down.
exec 9>"${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/bramble-build-windows.lock"
flock -n 9 || fail "another build_windows.sh or build_macos.sh is running"

WORK="$(mktemp -d "$OUT/work/$name.XXXXXXXX")" || fail "cannot create build work folder"
PROJECT="$WORK/project"
mkdir "$PROJECT" || fail "cannot create project folder"
echo "build work: $WORK"
git archive HEAD | tar -x -C "$PROJECT" || fail "git archive"
# Stamp the build, and add a macOS preset that ships what the Windows preset ships.
python3 - "$PROJECT" "$commit" <<'PY' || fail "add the macOS preset"
import pathlib
import re
import sys

project, commit = pathlib.Path(sys.argv[1]), sys.argv[2]
p = project / "project.godot"
p.write_text(p.read_text().replace("[application]\n", f'[application]\n\nconfig/build="{commit}"\n', 1))

cfg = project / "export_presets.cfg"
text = cfg.read_text()
win = next(
    (m for m in re.finditer(r"^\[preset\.(\d+)\]\n(.*?)^\[preset\.\1\.options\]", text, re.S | re.M)
     if re.search(r'^platform="Windows Desktop"$', m.group(2), re.M)),
    None,
)
if win is None:
    sys.exit("no Windows preset to copy")
head = win.group(2)
head = re.sub(r"^name=.*$", 'name="macOS"', head, flags=re.M)
head = re.sub(r"^platform=.*$", 'platform="macOS"', head, flags=re.M)
head = re.sub(r"^export_path=.*$", 'export_path="build/export/macos/Bramble.zip"', head, flags=re.M)
n = len(re.findall(r"^\[preset\.\d+\]$", text, re.M))
# A neutral bundle identifier: no person's name or account in the app.
cfg.write_text(
    text.rstrip()
    + f"\n\n[preset.{n}]\n{head.rstrip()}\n\n[preset.{n}.options]\n\n"
    'binary_format/architecture="universal"\n'
    'application/bundle_identifier="com.bramble.testbuild"\n'
    "codesign/codesign=1\n"
    "notarization/notarization=0\n"
)
PY

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

echo "exporting macOS (release, universal, ad-hoc signed)"
# The zip is made in the work folder and moved out only after every check, so a failed build
# never leaves a finished-looking zip in build/macos.
final="$OUT/$name.zip"
[ ! -e "$final" ] || fail "zip already exists: $final"
zip="$WORK/$name.zip"
timeout -k 10 1200 "$GODOT" --headless --path "$PROJECT" --export-release macOS "$zip" \
  >"$WORK/export.log" 2>&1
status=$?
found="$(godot_log_problems "$WORK/export.log")"
if [ "$status" -ne 0 ] || [ -n "$found" ] || [ ! -f "$zip" ]; then
  [ -n "$found" ] && head -n 20 <<<"$found"
  fail "export (exit $status, log: $WORK/export.log)"
fi
python3 - "$zip" <<'PY' || fail "the app lacks its binary, pack or signature, or is not universal"
import sys
import zipfile

z = zipfile.ZipFile(sys.argv[1])
names = set(z.namelist())
need = ("Bramble.app/Contents/MacOS/Bramble", "Bramble.app/Contents/Resources/Bramble.pck",
        "Bramble.app/Contents/_CodeSignature/CodeResources", "Bramble.app/Contents/Info.plist")
missing = [n for n in need if n not in names]
if missing:
    sys.exit(f"missing: {missing}")
# A universal (fat) Mach-O starts with 0xcafebabe.
if z.open(need[0]).read(4) != b"\xca\xfe\xba\xbe":
    sys.exit("binary is not universal")
PY
echo "exported: $(($(stat -c %s "$zip") / 1048576)) MB"

# The app's own pack, run by the Linux release runtime of the same Godot (beside it, same name).
mkdir -p "$WORK/linux"
cp "$TEMPLATES/linux_release.x86_64" "$WORK/linux/bramble.x86_64"
unzip -q -p "$zip" Bramble.app/Contents/Resources/Bramble.pck >"$WORK/linux/bramble.pck" \
  || fail "take the pack out of the app"

empty="$WORK/empty"
mkdir -p "$empty" && touch "$empty/project.godot"
timeout -k 10 "$BOOT_TIMEOUT" "$GODOT" --headless --path "$empty" -s "$PROJECT/tools/checks/pck_files.gd" \
  -- "$WORK/linux/bramble.pck" 2>"$WORK/pack.err" | sed -n 's|^res://||p' >"$WORK/pack.files"
[ "${PIPESTATUS[0]}" -eq 0 ] || { cat "$WORK/pack.err"; fail "cannot list the pack"; }
python3 "$PROJECT/tools/checks/pack_contents.py" "$WORK/pack.files" "$PROJECT" || fail "pack contents"

timeout -k 10 "$BOOT_TIMEOUT" "$WORK/linux/bramble.x86_64" --headless \
  --audio-driver Dummy -- --autoplay --seed 7 >"$WORK/boot-linux.log" 2>&1 \
  || { tail -n 20 "$WORK/boot-linux.log"; fail "Linux ghost autoplay exited non-zero"; }
found="$(godot_log_problems "$WORK/boot-linux.log")"
[ -z "$found" ] || { head -n 20 <<<"$found"; fail "boot logged problems (log: $WORK/boot-linux.log)"; }
grep -qF "$READY_LINE" "$WORK/boot-linux.log" || { tail -n 20 "$WORK/boot-linux.log"; fail "never reached the main scene"; }
grep -qF "$FINISHED_LINE" "$WORK/boot-linux.log" || { tail -n 20 "$WORK/boot-linux.log"; fail "did not finish a ghost game"; }
echo "boot ok: the app's pack on the Linux runtime reached the main scene and finished a ghost game"
echo "note: the app itself was not run (no Mac here)"

cat >"$WORK/README.txt" <<EOF
Bramble test build for Mac, $(date '+%d %b %Y %H:%M'), from commit $commit${LABEL:+ ($LABEL)}

1. Unzip this file. You get Bramble.app.
2. Open Bramble.app. The first time, macOS will refuse, because the game is not
   signed by a registered Apple developer. To allow it:
   - Open System Settings, then Privacy & Security.
   - Scroll down to "Bramble was blocked" and click "Open Anyway".
   - Open Bramble.app again and click "Open".
   If macOS says the app is damaged, open Terminal and run this, with the path
   to where you unzipped it, then open the app again:
       xattr -cr ~/Downloads/Bramble.app

If the game does not start, please say what macOS showed.

Game records stay on this Mac, in:
~/Library/Application Support/Godot/app_userdata/Bramble/records
EOF
(cd "$WORK" && zip -q "$zip" README.txt) || fail "add the README"
mv -- "$zip" "$final" || fail "move the zip to $final"
echo "zip ok: ${final#"$ROOT"/} $(($(stat -c %s "$final") / 1048576)) MB"
rm -rf "${WORK:?}"
echo "build_macos: $name passed"
