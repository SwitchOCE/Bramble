#!/usr/bin/env bash
# The quality gate. Same script locally, in cloud sessions and in CI.
#   ./scripts/check.sh               run every step, stop at the first failure
#   ./scripts/check.sh --keep-going  run every step, report all failures at the end
#   ./scripts/check.sh --docs-only   skip import, compile, parity and tests, and never start Godot;
#                                    refused unless every change since the upstream branch is under
#                                    docs/ and not read by the game or tests
#                                    (tools/checks/docs_only_paths.py). Run it without the Godot lock.
#   ./scripts/check.sh --docs-only --base <sha>
#                                    the same, but compares against <sha> instead of the upstream
#   ./scripts/check.sh --help        print this help
#   GODOT=/path/to/godot             Godot binary (default: godot on PATH)
#   PARITY_STRICT=1                 Fail shop-pool parity mismatches (default: warn)
#   GODOT_SLOT_CLASS=gate           Class for the slot log (scripts/godot_slot.sh; default other)
# Import through tests hold one of the two local Godot slots (scripts/godot_slot.sh), unless
# BRAMBLE_SLOT_HELD=1 says the caller holds one. The static steps run without a slot. Where
# systemd-run --user works, each Godot step runs in a scope capped at MemoryMax=3G.
# The tests step writes JUnit XML to build/check/gut.xml and prints the 20 slowest scripts.
# Steps: tools, versions, shell, python, content, format, lint, import, compile, parity, tests.
# Any problem line in a Godot log fails its step (scripts/godot_log.sh says what counts, and
# tools/checks/log_allowlist.txt lists the known engine noise it tolerates). Logs: build/check/.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
ROOT="$(pwd)"
LOG_DIR="$ROOT/build/check"
mkdir -p "$LOG_DIR"
# build/ holds exports and logs; keep Godot from importing anything in it.
: >"$ROOT/build/.gdignore"

# shellcheck source=tools/versions.env
. "$ROOT/tools/versions.env"

CHECK_ARGS="$*"
GODOT="${GODOT:-godot}"
GODOT_TIMEOUT=600
GD_DIRS=(src tools/checks tools/play tools/sim)
KEEP_GOING=0
DOCS_ONLY=0
DOCS_BASE=""
case "${1:-}" in
  --keep-going) KEEP_GOING=1 ;;
  --docs-only)
    DOCS_ONLY=1
    if [ "${2:-}" = "--base" ]; then
      [ -n "${3:-}" ] || { echo "--base needs a commit"; exit 2; }
      DOCS_BASE="$3"
      shift 2
    fi
    ;;
  -h | --help)
    sed -n '2,/^set /{/^#/s/^# \{0,1\}//p}' "$ROOT/scripts/check.sh"
    exit 0
    ;;
  "") ;;
  *)
    echo "unknown option: $1 (try --help)"
    exit 2
    ;;
esac
if [ "$#" -gt 1 ]; then
  echo "unknown option: $2 (try --help)"
  exit 2
fi

if [ -t 1 ]; then
  RED=$'\e[31m' GREEN=$'\e[32m' BOLD=$'\e[1m' RESET=$'\e[0m'
else
  RED="" GREEN="" BOLD="" RESET=""
fi

FAILED=()
PASSED=()

# --docs-only is allowed only when every change since the upstream branch, committed or not, is
# under docs/ and not read by the game or tests (tools/checks/docs_only_paths.py decides).
# --base <sha> compares against that commit instead.
if [ "$DOCS_ONLY" -eq 1 ]; then
  if [ -n "$DOCS_BASE" ]; then
    base="$(git rev-parse --verify -q "${DOCS_BASE}^{commit}")" || {
      echo "--docs-only --base: '$DOCS_BASE' is not a commit"
      exit 2
    }
  else
    upstream="$(git rev-parse --verify -q '@{upstream}')" || {
      echo "--docs-only needs an upstream branch to compare against (or --base <sha>)"
      exit 2
    }
    base="$(git merge-base "$upstream" HEAD)" || {
      echo "--docs-only: no common ancestor with the upstream branch"
      exit 2
    }
  fi
  if ! needs="$(python3 "$ROOT/tools/checks/docs_only_paths.py" "$base" "$ROOT")"; then
    echo "--docs-only refused: these changes need the Godot steps:"
    echo "$needs"
    exit 2
  fi
fi

# run_step <name> <function>
run_step() {
  local name="$1" fn="$2" start
  echo "${BOLD}==> ${name}${RESET}"
  start=$SECONDS
  if "$fn"; then
    echo "${GREEN}PASS${RESET} ${name} ($((SECONDS - start))s)"
    PASSED+=("$name")
  else
    echo "${RED}FAIL${RESET} ${name} ($((SECONDS - start))s)"
    FAILED+=("$name")
    if [ "$KEEP_GOING" -eq 0 ]; then
      summary
      exit 1
    fi
  fi
  echo
}

summary() {
  echo "${BOLD}==> Summary${RESET}"
  [ "${#PASSED[@]}" -gt 0 ] && echo "${GREEN}passed:${RESET} ${PASSED[*]}"
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "${RED}failed:${RESET} ${FAILED[*]}  (logs: build/check/)"
  else
    if [ "$DOCS_ONLY" -eq 1 ]; then
      echo "${GREEN}check.sh: docs-only steps passed (Godot steps skipped)${RESET}"
    else
      echo "${GREEN}check.sh: all steps passed${RESET}"
    fi
  fi
}

# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
godot_log_init "$LOG_DIR"
problems() { godot_log_problems "$1"; }

# fd 9 holds the slot's lock; Godot steps close it, so a stray child can't keep the slot.
# Each Godot step runs under MEMCAP: a systemd scope capped at 3 GB where systemd-run --user
# works (the local machine), nothing in cloud sessions and CI.
MEMCAP=()
SLOT_TAKEN=0
# shellcheck source=scripts/godot_slot.sh
. "$ROOT/scripts/godot_slot.sh"

# Takes a Godot slot for import through tests, unless the caller already holds one.
slot_take() {
  if systemd-run --user --scope -q -p MemoryMax=3G true >/dev/null 2>&1; then
    MEMCAP=(systemd-run --user --scope -q -p MemoryMax=3G)
  fi
  [ "${BRAMBLE_SLOT_HELD:-0}" = 1 ] && return 0
  godot_slot_acquire
  SLOT_TAKEN=1
  export BRAMBLE_SLOT_HELD=1
  trap 'slot_give $?' EXIT
}

# slot_give <exit-code>: frees the slot this script took, and logs it.
slot_give() {
  [ "$SLOT_TAKEN" -eq 1 ] || return 0
  SLOT_TAKEN=0
  unset BRAMBLE_SLOT_HELD
  godot_slot_release "$1" "scripts/check.sh${CHECK_ARGS:+ $CHECK_ARGS}"
}

# Strips ANSI colour codes (GUT colours its log).
strip_ansi() { sed $'s/\e\\[[0-9;]*m//g' "$@"; }

# Tools are present and at the versions tools/versions.env pins, so results match CI.
step_tools() {
  local ok=0 tool got
  local tools=(gdformat gdlint python3 ruff shellcheck)
  # --docs-only never starts Godot, so it can run without the Godot lock.
  [ "$DOCS_ONLY" -eq 1 ] || tools=("$GODOT" "${tools[@]}")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "missing tool: $tool (docs/CLOUD_SETUP.md lists how each is installed)"
      ok=1
    fi
  done
  [ "$ok" -eq 0 ] || return 1
  if [ "$DOCS_ONLY" -eq 0 ]; then
    got="$("$GODOT" --headless --version 2>/dev/null | head -n1)"
    case "$got" in "${GODOT_VERSION}.stable"*) ;; *) echo "godot is '$got', pinned ${GODOT_VERSION}"; ok=1 ;; esac
  fi
  got="$(gdlint --version 2>&1 | head -n1 | tr -s ' ')"
  [ "$got" = "gdlint ${GDTOOLKIT_VERSION}" ] || { echo "'$got', pinned gdtoolkit ${GDTOOLKIT_VERSION}"; ok=1; }
  got="$(ruff --version)"
  [ "$got" = "ruff ${RUFF_VERSION}" ] || { echo "'$got', pinned ruff ${RUFF_VERSION}"; ok=1; }
  [ "$ok" -eq 0 ] && echo "godot ${GODOT_VERSION}, gdtoolkit ${GDTOOLKIT_VERSION}, ruff ${RUFF_VERSION}, $(shellcheck --version | grep -E '^version')"
  return "$ok"
}

# Every pin agrees with tools/versions.env (tools/checks/versions.py).
step_versions() {
  python3 tools/checks/versions.py
}

step_shell() {
  shellcheck -x scripts/*.sh tools/play/*.sh
}

# Python under tools/checks (config: ruff.toml): lint, formatting, unit tests.
step_python() {
  ruff check --output-format concise || return 1
  ruff format --check 2>&1 | tail -n 20
  local status=${PIPESTATUS[0]}
  [ "$status" -eq 0 ] || { echo "fix with: ruff format"; return "$status"; }
  python3 -m unittest discover -s tools/checks/tests -t . 2>&1 | tail -n 3
  return "${PIPESTATUS[0]}"
}

# Prototype unit files in content/units match docs/prototype/SPEC.md (tools/checks/check_units.py).
step_content() {
  python3 tools/checks/check_units.py
}

step_format() {
  gdformat --check "${GD_DIRS[@]}" tests 2>&1 | tail -n 20
  local status=${PIPESTATUS[0]}
  [ "$status" -eq 0 ] || echo "fix with: gdformat ${GD_DIRS[*]} tests"
  return "$status"
}

# Tests have their own rules (tests/gdlintrc); gdlint reads the config from the working directory.
step_lint() {
  gdlint "${GD_DIRS[@]}" || return 1
  (cd tests && gdlint .)
}

# Builds the import cache. The first import after a merge can log script errors from a stale
# class cache (Autobattler toolchain notes 2.7), so a failed first pass gets one more import and
# only the second is judged. Real problems repeat on the second pass.
step_import() {
  local pass log status found
  for pass in 1 2; do
    log="$LOG_DIR/import-$pass.log"
    "${MEMCAP[@]}" timeout "$GODOT_TIMEOUT" "$GODOT" --headless --import >"$log" 2>&1 9>&-
    status=$?
    found="$(problems "$log")"
    if [ "$status" -eq 0 ] && [ -z "$found" ]; then
      [ "$pass" -eq 2 ] && echo "second import clean; the first logged problems (stale cache): $LOG_DIR/import-1.log"
      return 0
    fi
    [ "$pass" -eq 1 ] && echo "first import: exit $status, $(wc -l <<<"$found") problem line(s); importing again"
  done
  echo "godot --import exited with $status (full log: $log)"
  [ -n "$found" ] && head -n 40 <<<"$found"
  tail -n 10 "$log"
  return 1
}

# --import does not compile scripts; this loads every script, scene and resource.
step_compile() {
  local log="$LOG_DIR/compile.log" status found
  "${MEMCAP[@]}" timeout "$GODOT_TIMEOUT" "$GODOT" --headless -s res://tools/checks/compile_all.gd >"$log" 2>&1 9>&-
  status=$?
  grep -E "compile_all:" "$log"
  found="$(problems "$log")"
  if [ "$status" -ne 0 ] || [ -n "$found" ]; then
    [ -n "$found" ] && head -n 40 <<<"$found"
    echo "script compilation failed (exit $status, full log: $log)"
    return 1
  fi
}

# TODO: When pass 2 merges, make PARITY_STRICT=1 the default here.
# Actual UnitLibrary pool for full_game, after imports/compilation establish the class cache.
step_parity() {
  local log="$LOG_DIR/parity.log" status found
  "${MEMCAP[@]}" timeout "$GODOT_TIMEOUT" "$GODOT" --headless -s res://tools/checks/check_parity.gd >"$log" 2>&1 9>&-
  status=$?
  grep -E "^parity:" "$log"
  found="$(problems "$log")"
  if [ "$status" -ne 0 ] || [ -n "$found" ]; then
    [ -n "$found" ] && head -n 40 <<<"$found"
    echo "shop-pool parity failed (exit $status, full log: $log)"
    return 1
  fi
}

step_tests() {
  local log="$LOG_DIR/gut.log" xml="$LOG_DIR/gut.xml" status hook found ran
  # GUT hangs when post_run_script is missing; fail fast instead.
  hook=$(python3 -c 'import json; print(json.load(open(".gutconfig.json")).get("post_run_script", ""))')
  if [ -z "$hook" ] || [ ! -f "${hook#res://}" ]; then
    echo ".gutconfig.json post_run_script '$hook' is missing (expected res://tools/checks/gut_strict_hook.gd)"
    return 1
  fi
  rm -f "$xml"
  "${MEMCAP[@]}" timeout "$GODOT_TIMEOUT" "$GODOT" --headless -s addons/gut/gut_cmdln.gd \
    -gjunit_xml_file="$xml" >"$log" 2>&1 9>&-
  status=$?
  sed -n '/= Run Summary/,$p' "$log" | strip_ansi
  strip_ansi "$log" | grep -E "^gut_strict: "
  [ -s "$xml" ] && python3 tools/checks/junit_slowest.py "$xml" 20
  if [ "$status" -ne 0 ]; then
    echo "GUT exited with $status (full log: $log)"
    return 1
  fi
  # GUT skips test scripts that fail to parse and still exits 0.
  found="$(strip_ansi "$log" | problems /dev/stdin)"
  if [ -n "$found" ]; then
    head -n 40 <<<"$found"
    echo "test run logged errors or warnings (full log: $log)"
    return 1
  fi
  # Backstop: GUT exits 0 when it collects nothing, and only its [GUT ERROR] line above fails
  # that today. If an upgrade drops that line, a run with no tests still fails here.
  ran="$(strip_ansi "$log" | sed -n 's/^Tests  *\([0-9][0-9]*\).*/\1/p' | head -n 1)"
  if [ "${ran:-0}" -eq 0 ]; then
    echo "no tests ran (full log: $log)"
    return 1
  fi
  # The strict hook (risky, pending, no-assert tests) must have run.
  if ! strip_ansi "$log" | grep -E "^gut_strict: ok" >/dev/null; then
    echo "risky/pending hook did not run (tools/checks/gut_strict_hook.gd, full log: $log)"
    return 1
  fi
  # Per-case risky lines the hook cannot see (a parameterized case that asserted nothing).
  if strip_ansi "$log" | grep -E "\[Risky\]"; then
    echo "GUT logged risky tests (full log: $log)"
    return 1
  fi
}

run_step "tools" step_tools
run_step "versions" step_versions
run_step "shell" step_shell
run_step "python" step_python
run_step "content" step_content
run_step "format" step_format
run_step "lint" step_lint
if [ "$DOCS_ONLY" -eq 1 ]; then
  echo "docs-only: skipped import, compile, parity and tests (only docs/ changed, none read by code)"
else
  slot_take
  run_step "import" step_import
  run_step "compile" step_compile
  run_step "parity" step_parity
  run_step "tests" step_tests
  slot_give "$([ "${#FAILED[@]}" -eq 0 ] && echo 0 || echo 1)"
fi
summary
[ "${#FAILED[@]}" -eq 0 ]
