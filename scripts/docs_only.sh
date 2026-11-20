#!/usr/bin/env bash
# Reads changed file paths on stdin, one per line. Exit 0 if every one is docs or an art or
# research tool, which the quality gate doesn't read; exit 1 if any isn't, or if none are given.
# CI uses it to decide whether a pull request needs check.sh. By hand:
#   git diff --name-only origin/dev...HEAD | ./scripts/docs_only.sh
set -uo pipefail

count=0
while IFS= read -r path || [ -n "$path" ]; do
  [ -n "$path" ] || continue
  count=$((count + 1))
  case "$path" in
    docs/* | *.md | tools/art/* | tools/research/* | tools/folio/*) ;;
    *)
      echo "not docs only: $path"
      exit 1
      ;;
  esac
done
if [ "$count" -eq 0 ]; then
  echo "no changed files given"
  exit 1
fi
echo "docs only: $count file(s)"
