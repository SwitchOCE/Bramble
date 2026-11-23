#!/usr/bin/env bash
# Puts a finished build zip at its fixed public download link, for the owner to share with friends.
#   ./scripts/share_build.sh <Bramble-windows-*.zip | Bramble-macos-*.zip>
# The zip goes to the bramble-builds bucket in Cloudflare R2 as Bramble-windows.zip or
# Bramble-macos.zip, replacing the build that was there. So each link stays the same and always
# gives the newest build. The download keeps the zip's own name, which says which build it is.
# Anyone who has a link can download it; there is no password.
# Needs Node's npx and a Cloudflare login on this machine (npx wrangler login), or
# CLOUDFLARE_API_TOKEN, and curl. wrangler refuses files over about 300 MB.
# Exit 0 = uploaded, and the public link serves a file of the same size under the zip's name.
set -uo pipefail

BUCKET="bramble-builds"
PUBLIC="https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev"

fail() {
  echo "share_build: $*" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  echo "usage: share_build.sh <Bramble-windows-*.zip | Bramble-macos-*.zip>" >&2
  exit 2
fi
[ -f "$1" ] || fail "no such file: $1"
zip="$(realpath -- "$1")" || exit 2
name="$(basename -- "$zip")"
case "$name" in
  Bramble-windows-*.zip) key="Bramble-windows.zip" ;;
  Bramble-macos-*.zip) key="Bramble-macos.zip" ;;
  *) fail "not a build zip name (Bramble-windows-*.zip or Bramble-macos-*.zip): $name" ;;
esac
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || fail "zip name has characters a download name can't carry: $name"

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
# shellcheck source=tools/versions.env
. tools/versions.env
command -v npx >/dev/null || fail "needs Node's npx for wrangler"
command -v curl >/dev/null || fail "needs curl"

size="$(stat -c %s "$zip")" || exit 2
echo "uploading $name ($((size / 1048576)) MB) as $key ..."
npx -y "wrangler@${WRANGLER_VERSION}" r2 object put "$BUCKET/$key" --remote --file "$zip" \
  --content-type application/zip \
  --content-disposition "attachment; filename=\"$name\"" \
  --cache-control "no-cache" ||
  fail "upload failed (if the Cloudflare login has lapsed: npx wrangler login)"

# Prove the link serves this build, not the one before it.
headers="$(curl -sS -I --max-time 60 "$PUBLIC/$key" | tr -d '\r')" || fail "could not reach $PUBLIC/$key"
served="$(printf '%s\n' "$headers" | grep -i '^content-length:' | tr -dc '0-9')"
[ "$served" = "$size" ] || fail "the link serves ${served:-nothing} bytes, the zip is $size"
printf '%s\n' "$headers" | grep -i '^content-disposition:' | grep -qF "$name" ||
  fail "the link does not serve the file under the name $name"
echo "shared: $PUBLIC/$key"
echo "holds:  $name"
