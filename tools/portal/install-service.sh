#!/usr/bin/env bash
# Installs (or repoints) the bramble-portal systemd user service at the
# checkout this script lives in, then enables, restarts and checks it.
# Re-run it from another checkout to move the service there.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node="$(command -v node)"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
unit="$unit_dir/bramble-portal.service"
port=8780

[ -x "$node" ] || { echo "node not found on PATH"; exit 1; }
mkdir -p "$unit_dir"
sed -e "s#@PORTAL_DIR@#$here#g" -e "s#@NODE@#$node#g" "$here/bramble-portal.service" > "$unit.tmp"
mv "$unit.tmp" "$unit"
echo "wrote $unit (serving from $here)"

systemctl --user daemon-reload
systemctl --user enable bramble-portal.service >/dev/null
systemctl --user restart bramble-portal.service

for _ in $(seq 1 25); do
  if curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null 2>&1; then
    echo "running: $(curl -fsS "http://127.0.0.1:$port/healthz")"
    systemctl --user is-enabled bramble-portal.service
    if [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" != "yes" ]; then
      echo "note: linger is off, so the service stops when you log out (sudo loginctl enable-linger $USER)"
    fi
    exit 0
  fi
  sleep 0.2
done
echo "the service didn't answer on port $port; recent log:"
journalctl --user -u bramble-portal.service -n 30 --no-pager || true
exit 1
