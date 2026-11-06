#!/usr/bin/env bash
# Downloads the official Godot export templates, verifies them and installs only the files named.
# Used by CI (job `exports`); handy on a fresh machine too.
#   ./scripts/install_export_templates.sh <version> <sha512> <dest_dir> <template file>...
# e.g. with tools/versions.env sourced:
#   ./scripts/install_export_templates.sh "$GODOT_VERSION" "$GODOT_TEMPLATES_SHA512" \
#     ~/.local/share/godot/export_templates/"$GODOT_VERSION".stable linux_debug.x86_64
# <sha512> is the line for Godot_v<version>-stable_export_templates.tpz in the release's
# SHA512-SUMS.txt. version.txt is always installed (Godot reads it to match the editor).
set -euo pipefail

if [ "$#" -lt 4 ]; then
  sed -n '2,10p' "$0"
  exit 2
fi
VERSION="$1" SHA512="$2" DEST="$3"
shift 3

tag="${VERSION}-stable"
tpz="Godot_v${tag}_export_templates.tpz"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsSL --retry 3 -o "$work/$tpz" \
  "https://github.com/godotengine/godot/releases/download/${tag}/${tpz}"
if command -v sha512sum >/dev/null 2>&1; then
  echo "${SHA512}  $work/$tpz" | sha512sum -c -
else
  echo "${SHA512}  $work/$tpz" | shasum -a 512 -c -
fi

members=("templates/version.txt")
for file in "$@"; do
  members+=("templates/$file")
done
mkdir -p "$DEST"
unzip -q -o -j "$work/$tpz" "${members[@]}" -d "$DEST"
echo "installed into $DEST: version.txt $*"
