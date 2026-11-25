#!/usr/bin/env bash
# Puts a finished build at its fixed public download link, for the owner to share with friends.
#   ./scripts/share_build.sh <build file>
# The file's name picks the link:
#   Bramble-windows-*.zip -> Bramble-windows.zip     Bramble-macos-*.zip   -> Bramble-macos.zip
#   Bramble-linux-*.zip   -> Bramble-linux.zip       Bramble-android-*.apk -> Bramble-android.apk
# It goes to the bramble-builds bucket in Cloudflare R2 under that fixed name, replacing the build
# that was there. So each link stays the same and always gives the newest build. The download
# keeps the file's own name, which says which build it is.
# Anyone who has a link can download it; there is no password.
# Needs Node's npx and a Cloudflare login on this machine (npx wrangler login), or
# CLOUDFLARE_API_TOKEN, and curl. wrangler refuses files over about 300 MB.
# Exit 0 = uploaded, and the public link serves a file of the same size under the file's name.
set -uo pipefail

BUCKET="bramble-builds"
PUBLIC="https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev"

fail() {
  echo "share_build: $*" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  echo "usage: share_build.sh <Bramble-{windows,macos,linux}-*.zip | Bramble-android-*.apk>" >&2
  exit 2
fi
[ -f "$1" ] || fail "no such file: $1"
zip="$(realpath -- "$1")" || exit 2
name="$(basename -- "$zip")"
case "$name" in
  Bramble-windows-*.zip) key="Bramble-windows.zip" ;;
  Bramble-macos-*.zip) key="Bramble-macos.zip" ;;
  Bramble-linux-*.zip) key="Bramble-linux.zip" ;;
  Bramble-android-*.apk) key="Bramble-android.apk" ;;
  *) fail "not a build name (Bramble-{windows,macos,linux}-*.zip or Bramble-android-*.apk): $name" ;;
esac
case "$key" in
  *.apk) type="application/vnd.android.package-archive" ;;
  *) type="application/zip" ;;
esac
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || fail "file name has characters a download name can't carry: $name"

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
# shellcheck source=tools/versions.env
. tools/versions.env
command -v npx >/dev/null || fail "needs Node's npx for wrangler"
command -v curl >/dev/null || fail "needs curl"

size="$(stat -c %s "$zip")" || exit 2
echo "uploading $name ($((size / 1048576)) MB) as $key ..."
npx -y "wrangler@${WRANGLER_VERSION}" r2 object put "$BUCKET/$key" --remote --file "$zip" \
  --content-type "$type" \
  --content-disposition "attachment; filename=\"$name\"" \
  --cache-control "no-cache" ||
  fail "upload failed (if the Cloudflare login has lapsed: npx wrangler login)"

# Prove the link serves this build, not the one before it.
headers="$(curl -sS -I --max-time 60 "$PUBLIC/$key" | tr -d '\r')" || fail "could not reach $PUBLIC/$key"
served="$(printf '%s\n' "$headers" | grep -i '^content-length:' | tr -dc '0-9')"
[ "$served" = "$size" ] || fail "the link serves ${served:-nothing} bytes, the file is $size"
printf '%s\n' "$headers" | grep -i '^content-disposition:' | grep -qF "$name" ||
  fail "the link does not serve the file under the name $name"
echo "shared: $PUBLIC/$key"
echo "holds:  $name"
