#!/usr/bin/env bash
# Runs flat-figure art batches with Codex's built-in image tool (Linux, e.g. the Optiplex).
# usage: tools/art/run-flat-figure.sh c d   -> runs prompts/direction-flat-c.txt and -d.txt side by side
# Output: $ART_OUT/<letter>/*.png and $ART_OUT/<letter>.log.
#   ART_OUT      where the PNGs go (default /data/bramble-art/flat-figure/out; PNG masters are not committed)
#   ART_TIMEOUT  seconds per batch (default 2400)
# The six owner-approved examples are attached to every batch as style references.
# Style, rules and item recipe: docs/design/art-direction/README.md
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
out="${ART_OUT:-/data/bramble-art/flat-figure/out}"
export PATH="$HOME/.local/bin:$PATH"
NOTE="The attached images are approved examples of this game's art style. Match their style exactly: flat hard-edged figure in full natural colour, soft layered background, same framing and level of detail. Do NOT copy their characters, places or palettes.

"
refs=()
for n in hedgerow-hedgehog birds-owl bog-toad fairies-duellist hunters-fox oozes-brute; do
  refs+=(-i "$repo/docs/design/art-direction/examples/flat-$n.jpg")
done
for b in "$@"; do
  mkdir -p "$out/$b"
  ( timeout "${ART_TIMEOUT:-2400}" codex exec --skip-git-repo-check -s workspace-write -C "$out/$b" \
      "${refs[@]}" -- "$NOTE$(cat "$here/prompts/direction-flat-$b.txt")" </dev/null > "$out/$b.log" 2>&1 \
      || echo "batch $b failed or timed out" ) &
done
wait
for b in "$@"; do echo "== $b: $(ls "$out/$b" | tr '\n' ' ')"; done
