#!/usr/bin/env bash
# Run the strength ladder on the frozen engine. Run in the background with a time limit.
set -euo pipefail
export PATH="$HOME/.cargo/bin:$PATH"

usage() {
  echo 'usage: ladder.sh <tag> [<tag> ...] -- <A:B> [<A:B> ...] [--games N] [--cores LIST] [--threads N] [--force]'
}

die() { echo "$*" >&2; exit 2; }

games=200; cores=4,5; threads=2; force=false; after_separator=false
tags=(); pairings=()
declare -A seen_tags seen_outputs
bot_name='[a-z0-9]+(-[a-z0-9]+)*'
while (($#)); do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --games|--cores|--threads)
      (($# >= 2)) || die "$1 needs a value"
      case $1 in
        --games) games=$2 ;;
        --cores) cores=$2 ;;
        --threads) threads=$2 ;;
      esac
      shift ;;
    --force) force=true ;;
    --) $after_separator && die 'only one -- separator is allowed'; after_separator=true ;;
    *)
      if $after_separator; then
        [[ $1 =~ ^$bot_name:$bot_name$ ]] || die "invalid pairing: $1"
        name=${1/:/-vs-}
        [[ ! ${seen_outputs[$name]+set} ]] || die "duplicate match folder: ladder-$name"
        seen_outputs[$name]=1
        pairings+=("$1")
      else
        [[ $1 =~ ^(red|blue)-$bot_name$ ]] || die "invalid team tag: $1"
        if [[ ! ${seen_tags[$1]+set} ]]; then tags+=("$1"); seen_tags[$1]=1; fi
      fi ;;
  esac
  shift
done
((${#tags[@]} && ${#pairings[@]})) || { usage >&2; exit 2; }
[[ $games =~ ^[1-9][0-9]*$ && $threads =~ ^[1-9][0-9]*$ ]] || die 'games and threads must be positive integers'
taskset -pc -- "$cores" "$$" >/dev/null || die "invalid CPU list: $cores"

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=/home/alex/code/Bramble
league_home=/home/alex/league
ladder=$league_home/ladder
matches=$league_home/matches
frozen='league-engine-v1'

# Keep concurrent invocations from refreshing the same tree or replacing a running match.
exec 9<"$league_home"
flock -n 9 || die 'another ladder run is active'
if [[ -e $ladder || -L $ladder ]]; then
  [[ ! -L $ladder && -f $ladder/.git && $(git -C "$ladder" rev-parse --show-toplevel) == "$ladder" &&
     $(git -C "$ladder" rev-parse --path-format=absolute --git-common-dir) == "$repo/.git" &&
     $(git -C "$ladder" rev-parse HEAD) == "$(git -C "$repo" rev-parse "$frozen^{commit}")" &&
     $(git -C "$ladder" rev-parse --abbrev-ref HEAD) == HEAD ]] || die "expected a detached $frozen worktree at $ladder"
  git -C "$ladder" restore --source="$frozen" --staged --worktree -- tools/league
  git -C "$ladder" clean -q -fdx -e /tools/league/target/ -- tools/league
else
  git -C "$repo" worktree add --detach "$ladder" "$frozen"
fi

cd "$ladder/tools/league"
export CARGO_TARGET_DIR="$PWD/target" CARGO_BUILD_JOBS=2
mkdir -p "$CARGO_TARGET_DIR"
scratch=$(mktemp -d "$CARGO_TARGET_DIR/ladder.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cp Cargo.toml "$scratch/workspace.toml"
# check-crate only accepts --name red or blue. Use its frozen static checker directly,
# then compile each renamed crate and type-check its factory before registering it.
cat > "$scratch/static-check.rs" <<'RS'
#[path = "../../league/src/checkcrate.rs"]
mod checkcrate;

fn main() {
    let path = std::env::args_os().nth(1).expect("crate path");
    if checkcrate::static_checks(std::path::Path::new(&path)).is_err() {
        std::process::exit(1);
    }
}
RS
rustc --edition=2024 -A dead_code "$scratch/static-check.rs" -o "$scratch/static-check"

check_dir="target/${scratch##*/}/check"
mkdir -p "$check_dir/src"
cat > "$check_dir/src/lib.rs" <<'RS'
pub const FACTORY: league_api::Factory = candidate::new_bot;
RS

prepare_manifest() {
  python3 - "$1" "$2" <<'PY'
import re
import sys
import tomllib
from pathlib import Path

tag, colour = sys.argv[1:]
manifest = Path('bots', tag, 'Cargo.toml')
try:
    text = manifest.read_text()
    data = tomllib.loads(text)
    api = data['dependencies']['league-api']['path']
    if data['package']['name'] != colour or (manifest.parent / api).resolve() != Path('league-api').resolve():
        sys.exit(1)
    sections = re.split(r'(?m)^(?=[ \t]*\[)', text)
    for i, section in enumerate(sections):
        if re.match(r'^[ \t]*\[[ \t]*package[ \t]*\]', section):
            sections[i], count = re.subn(r'(?m)^([ \t]*(?:name|"name")[ \t]*=[ \t]*)"[^"\n]*"',
                                         lambda match: f'{match[1]}"{tag}"', section)
            if count == 1:
                manifest.write_text(''.join(sections))
                sys.exit(0)
except (OSError, KeyError, TypeError, ValueError):
    pass
sys.exit(1)
PY
}

workspace_members() {
  printf '    "%s",\n' "$@" | sed '/^members = \[$/r /dev/stdin' "$scratch/workspace.toml" > Cargo.toml
}

passed=()
for tag in "${tags[@]}"; do
  colour=${tag%%-*}; path=tools/league/bots/$colour; dest=bots/$tag
  clone=$league_home/$colour
  if ! git -C "$clone" rev-parse -q --verify "refs/tags/$tag^{commit}" >/dev/null 2>&1; then
    echo "skipping $tag: tag not found"
    continue
  fi
  mkdir -- "$dest"
  if ! git -C "$clone" archive "refs/tags/$tag" "$path" 2>"$scratch/archive.log" |
    tar -x -C "$dest" --strip-components=4 --exclude="$path/tools" 2>>"$scratch/archive.log"; then
    echo "skipping $tag: bot folder could not be archived"
  elif ! "$scratch/static-check" "$dest" >"$scratch/check.log" 2>&1; then
    echo "skipping $tag: check-crate static checks failed"
  elif ! prepare_manifest "$tag" "$colour" >"$scratch/check.log" 2>&1; then
    echo "skipping $tag: invalid package name or league-api path in Cargo.toml"
  else
    workspace_members "$dest" "$check_dir"
    cat > "$check_dir/Cargo.toml" <<TOML
[package]
name = "ladder-check"
version = "0.0.0"
edition.workspace = true
[dependencies]
league-api = { path = "../../../league-api" }
candidate = { package = "$tag", path = "../../../$dest" }
TOML
    if cargo build --offline --release -p ladder-check >"$scratch/check.log" 2>&1; then
      echo "$tag: passed check-crate static checks and isolated factory build"
      passed+=("$tag")
      continue
    fi
    echo "skipping $tag: isolated crate build or new_bot factory check failed"
  fi
  rm -rf -- "$dest"
done

cp "$scratch/workspace.toml" Cargo.toml
git -C "$ladder" restore --source="$frozen" --worktree -- tools/league/Cargo.lock
if ((${#passed[@]})); then
  workspace_members "${passed[@]/#/bots/}"
  for tag in "${passed[@]}"; do
    # A distinct dependency key also handles bots with an explicit [lib] name.
    printf 'ladder-%s = { package = "%s", path = "../%s" }\n' "$tag" "$tag" "$tag" >> bots/registry/Cargo.toml
    printf '        ("%s", ladder_%s::new_bot),\n' "$tag" "${tag//-/_}"
  done | sed '/^    vec!\[$/r /dev/stdin' bots/registry/src/lib.rs > "$scratch/registry.rs"
  mv -- "$scratch/registry.rs" bots/registry/src/lib.rs
  # Mark intent to add so git diff includes the archived folders without staging their contents.
  git add -N -f -- "${passed[@]/#/bots/}"
  echo 'updating Cargo.lock offline for the added workspace packages'
  cargo update --offline --workspace >"$scratch/build.log" 2>&1 || die 'offline workspace lock update failed'
fi
cargo build --offline --locked --release -p league >"$scratch/build.log" 2>&1 || die 'frozen league build failed'
league=$CARGO_TARGET_DIR/release/league
bot_list=$("$league" bots)
declare -A available
while IFS= read -r bot; do available[$bot]=1; done <<< "$bot_list"

skipped=(); runnable=(); completed=(); status=0
for pair in "${pairings[@]}"; do
  red=${pair%:*}; blue=${pair#*:}; out=$matches/ladder-${pair/:/-vs-}
  missing=()
  for bot in "$red" "$blue"; do
    if [[ ! ${available[$bot]+set} ]]; then missing+=("$bot"); fi
  done
  if ((${#missing[@]})); then
    skipped+=("$pair (unavailable: ${missing[*]})")
  else
    if ! $force && [[ -e $out || -L $out ]]; then die "refusing: $out already exists (use --force)"; fi
    runnable+=("$pair")
  fi
done

seeds=$scratch/seeds.txt
if ((${#runnable[@]})); then mkdir -p -- "$matches"; fi
for pair in "${runnable[@]}"; do
  red=${pair%:*}; blue=${pair#*:}; out=$matches/ladder-${pair/:/-vs-}
  if $force; then rm -rf -- "$out"; fi
  mkdir -- "$out"
  python3 -c 'import secrets, sys; print("\n".join(str(secrets.randbits(63)) for _ in range((int(sys.argv[1])+1)//2)))' "$games" > "$seeds"
  echo "playing $games games: red=$red blue=$blue"
  if "$league" match --red "$red" --blue "$blue" --games "$games" --seeds "$seeds" \
      --clock-ms 1000 --threads "$threads" --out "$out" --red-label "$red" --blue-label "$blue" >"$scratch/match.log" 2>&1; then
    if "$league" analyze "$out" >"$scratch/analysis.log" 2>&1; then
      completed+=("$out")
    else
      skipped+=("$pair (league analyze failed)")
      status=1
    fi
  else
    skipped+=("$pair (match failed, exit $?)")
    status=1
  fi
done

if ((${#completed[@]})); then
  python3 -B "$here/analysis/ladder.py" "${completed[@]}" || status=1
  echo
  python3 -B "$here/analysis/winscore.py" "${completed[@]}" || status=1
fi
if ((${#skipped[@]})); then
  echo 'Skipped pairings'
  printf '  %s\n' "${skipped[@]}"
fi
exit "$status"
