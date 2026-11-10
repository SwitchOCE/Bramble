#!/usr/bin/env bash
# Compare the ideation review range and every local path, including untracked files.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
ref=refs/remotes/origin/ideation/main
if ! git rev-parse --verify -q "$ref^{commit}" >/dev/null; then
  # Full-history CI checkouts don't always create every remote-tracking branch.
  if [ "${GITHUB_ACTIONS:-false}" = true ]; then
    git fetch --no-tags origin "ideation/main:$ref" >&2 || true
  fi
fi
if ! git rev-parse --verify -q "$ref^{commit}" >/dev/null; then
  echo 'scope-fence: skipped (origin/ideation/main is unavailable)'
  exit 0
fi
base="$(git merge-base "$ref" HEAD)" || {
  echo 'scope-fence: no merge-base with origin/ideation/main' >&2
  exit 1
}
gate=0
if git cat-file -e "$base:tools/checks/scope_fence.sh" 2>/dev/null; then
  gate=1
fi
# --no-renames includes both sides of a rename; a move out of a fenced directory still fails.
# Compare each layer independently so a local reversal cannot hide a committed change.
paths="$(mktemp)"
trap 'rm -f "$paths"' EXIT
{
  git diff --no-renames --name-only -z "$base" HEAD
  git diff --no-renames --name-only -z --cached
  git diff --no-renames --name-only -z
  git ls-files --others --exclude-standard -z
} >"$paths"
failed=0
while IFS= read -r -d '' file; do
  case "$file" in
    src/core/* | content/* | tools/sim/* | tests/core/*)
      printf 'scope-fence: forbidden: %s\n' "$file"
      failed=1
      ;;
    .github/* | scripts/cloud-gate.sh | tools/checks/*)
      if [ "$gate" -eq 1 ]; then
        printf 'scope-fence: forbidden gate file: %s\n' "$file"
        failed=1
      fi
      ;;
  esac
done < <(sort -zu "$paths")
[ "$failed" -eq 0 ] || exit 1
echo "scope-fence: passed (base $base; gate files fenced: $gate)"
