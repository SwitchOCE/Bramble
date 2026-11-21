#!/usr/bin/env bash
# Prepare a team's practice worktree on the frozen engine.
set -euo pipefail
export PATH="$HOME/.cargo/bin:$PATH"

die() { echo "$*" >&2; exit 2; }

(($# >= 2)) || die 'usage: practice_setup.sh <red|blue> <other-tag-or-commit> [...]'
team=$1
shift
case $team in
  red) other=blue; cores=0,1 ;;
  blue) other=red; cores=2,3 ;;
  *) die 'team must be red or blue' ;;
esac

repo=/home/alex/code/Bramble
league_home=/home/alex/league
clone=$league_home/$team
opponent=$league_home/$other
practice=$league_home/practice-$team
frozen=$(git -C "$repo" rev-parse --verify 'refs/tags/league-engine-v1^{commit}')
live=tools/league/bots/$team
submitted=tools/league/bots/$other

tags=()
declare -A commits
for tag in "$@"; do
  [[ $tag =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]*$ ]] || die "tag is not a Cargo package name: $tag"
  [[ ! ${commits[$tag]+set} ]] || continue
  if commit=$(git -C "$opponent" rev-parse -q --verify "refs/tags/$tag^{commit}"); then
    :
  elif [[ $tag =~ ^[0-9a-f]{4,40}$ ]] &&
    commit=$(git -C "$opponent" rev-parse -q --verify "$tag^{commit}") &&
    [[ $commit == "$tag"* ]]; then
    :
  else
    die "tag or commit not found in $opponent: $tag"
  fi
  tags+=("$tag")
  commits[$tag]=$commit
done

if [[ ! -e $practice && ! -L $practice ]]; then
  git -C "$repo" worktree add --detach "$practice" "$frozen"
fi
[[ ! -L $practice && -f $practice/.git &&
  $(git -C "$practice" rev-parse --show-toplevel) == "$practice" &&
  $(git -C "$practice" rev-parse --path-format=absolute --git-common-dir) == "$repo/.git" &&
  $(git -C "$practice" rev-parse HEAD) == "$frozen" &&
  $(git -C "$practice" rev-parse --abbrev-ref HEAD) == HEAD ]] ||
  die "expected a detached league-engine-v1 worktree at $practice"

# Play and setup share the directory lock, so a rebuild cannot overlap a refresh.
exec 9<"$practice"
flock -n 9 || die "another setup or match is active in $practice"
rm -f -- "$practice/play.sh"
if [[ -L $practice/$live ]]; then
  rm -- "$practice/$live"
fi
git -C "$practice" restore --source="$frozen" --staged --worktree -- tools/league
git -C "$practice" clean -q -fdx -e /tools/league/target/ -- tools/league
rm -rf -- "${practice:?}/${live:?}"
ln -s -- "$clone/$live" "$practice/$live"

cd "$practice/tools/league"
export CARGO_TARGET_DIR="$PWD/target"
mkdir -p -- "$CARGO_TARGET_DIR"

for tag in "${tags[@]}"; do
  dest=bots/$tag
  mkdir -- "$dest"
  git -C "$opponent" archive "${commits[$tag]}" "$submitted" |
    tar -x -C "$dest" --strip-components=4 --exclude="$submitted/tools" ||
    die "could not archive the $other bot from $tag"
done

# As in ladder.sh, rename only the package and give each registry dependency
# its own Rust crate alias.
python3 - "$other" "${tags[@]}" <<'PY'
import re
import sys
import tomllib
from pathlib import Path

other, *tags = sys.argv[1:]
members = []
dependencies = []
factories = []
for number, tag in enumerate(tags, 1):
    bot = Path("bots", tag)
    manifest = bot / "Cargo.toml"
    text = manifest.read_text()
    sections = re.split(r"(?m)^(?=[ \t]*\[)", text)
    for index, section in enumerate(sections):
        if re.match(r"^[ \t]*\[[ \t]*package[ \t]*\]", section):
            sections[index], count = re.subn(
                r'(?m)^([ \t]*(?:name|"name")[ \t]*=[ \t]*)["\x27][^"\x27\n]*["\x27]',
                lambda match: f'{match[1]}"{tag}"',
                section,
            )
            if count == 1 and tomllib.loads(text)["package"]["name"] == other:
                break
    else:
        sys.exit(f"{tag}: could not rename the {other} package")
    manifest.write_text("".join(sections))
    alias = f"practice-bot-{number}"
    members.append(f'    "{bot}",\n')
    dependencies.append(f'{alias} = {{ package = "{tag}", path = "../{tag}" }}\n')
    factories.append(f'        ("{tag}", {alias.replace("-", "_")}::new_bot),\n')

workspace = Path("Cargo.toml")
workspace.write_text(workspace.read_text().replace(
    "members = [\n", "members = [\n" + "".join(members), 1
))
with Path("bots/registry/Cargo.toml").open("a") as registry:
    registry.writelines(dependencies)
registry = Path("bots/registry/src/lib.rs")
registry.write_text(registry.read_text().replace(
    "    vec![\n", "    vec![\n" + "".join(factories), 1
))
PY

echo 'Updating Cargo.lock offline for the archived workspace packages.'
taskset -c "$cores" env CARGO_BUILD_JOBS=2 cargo update --offline --workspace ||
  die "could not update the practice workspace lockfile for $team"
taskset -c "$cores" env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league ||
  die "could not build the practice league for $team"

duplicates=$("$CARGO_TARGET_DIR/release/league" bots | sort | uniq -d)
[[ -z $duplicates ]] || die "opponent name already registered: $duplicates"

{
  cat <<'PLAY'
#!/usr/bin/env bash
# The red side in these results is your live bot, whatever your team colour.
# The blue side is the other team's old bot. Run this, don't open bots/<other-tag>/.
set -euo pipefail
export PATH="$HOME/.cargo/bin:$PATH"
PLAY
  printf 'team=%q\nclone=%q\ncores=%q\n' "$team" "$clone" "$cores"
  printf 'opponents=('
  printf ' %q' "${tags[@]}"
  printf ' )\n'
  cat <<'PLAY'

die() { echo "$*" >&2; exit 2; }
usage() { die 'usage: play.sh <other-tag> <games> <out-dir> [--seeds FILE]'; }

(($# == 3 || $# == 5)) || usage
tag=$1
games=$2
out=$3
[[ $games =~ ^[1-9][0-9]*$ ]] || die 'games must be a positive integer'
seeds=
if (($# == 5)); then
  [[ $4 == --seeds ]] || usage
  [[ -f $5 && -r $5 ]] || die "cannot read seeds file: $5"
  seeds=$(realpath -e -- "$5")
fi
available=false
for opponent in "${opponents[@]}"; do
  if [[ $tag == "$opponent" ]]; then
    available=true
    break
  fi
done
$available || die "unknown practice opponent: $tag (available: ${opponents[*]})"

[[ ! -e $out && ! -L $out ]] || die "output folder already exists: $out"
out=$(realpath -m -- "$out")
[[ $out == "$clone/"* ]] || die "output folder must be inside $clone"
[[ ! -e $out && ! -L $out ]] || die "output folder already exists: $out"

practice=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec 9<"$practice"
flock -n 9 || die "another setup or match is active in $practice"
taskset -pc -- "$cores" "$$" >/dev/null
cd "$practice/tools/league"
export CARGO_TARGET_DIR="$PWD/target" CARGO_BUILD_JOBS=2

cargo clean --offline --release -p "$team" || die "could not clean the $team bot build"
cargo build --offline --locked --release -p league || die "could not build the $team live bot for practice"
league=$CARGO_TARGET_DIR/release/league

if [[ -z $seeds ]]; then
  seeds=$(mktemp "$CARGO_TARGET_DIR/practice-seeds.XXXXXXXX")
  trap 'rm -f -- "$seeds"' EXIT
  python3 -c 'import secrets, sys; print("\n".join(str(secrets.randbits(63)) for _ in range((int(sys.argv[1]) + 1) // 2)))' "$games" > "$seeds"
fi

mkdir -p -- "$(dirname -- "$out")"
staged=$(mktemp -d "$practice/.practice-match.XXXXXXXX")
"$league" match --red "$team" --blue "$tag" --games "$games" --seeds "$seeds" \
  --clock-ms 1000 --threads 2 --out "$staged"
"$league" analyze "$staged" | sed -n '1,8p'
# The practising bot is red. The referee's 19 Nov ruling keeps blue's card
# values and strategy labels private.
python3 - "$staged" <<'PY'
import gzip
import json
from pathlib import Path
import sys

match = Path(sys.argv[1])
for log in ("shops", "decisions"):
    for suffix in (".jsonl", ".jsonl.gz"):
        path = match / (log + suffix)
        if not path.is_file():
            continue
        compressed = suffix.endswith(".gz")
        temporary = path.with_name(path.name + ".tmp")
        with path.open("rb") as raw, temporary.open("wb") as target:
            source = gzip.GzipFile(fileobj=raw) if compressed else raw
            output = gzip.GzipFile(fileobj=target, mode="wb", filename="", mtime=0) if compressed else target
            with source, output:
                for line in source:
                    row = json.loads(line)
                    if row["colour"] == "blue":
                        if "values" in row or "strategy" in row:
                            row.pop("values", None)
                            row.pop("strategy", None)
                            line = json.dumps(row, separators=(",", ":")).encode() + b"\n"
                    output.write(line)
        temporary.replace(path)
PY
[[ ! -e $out && ! -L $out ]] || die "output folder already exists: $out"
mv -T -- "$staged" "$out"
PLAY
} > "$practice/play.sh"
chmod +x -- "$practice/play.sh"

cat > "$practice/README.md" <<EOF
Run \`./play.sh <other-tag> <games> <out-dir> [--seeds FILE]\`. Opponents here are ${tags[*]}.
Choose a new output folder inside \`$clone\`. For fixed seeds, supply one decimal seed per pair of games, rounding up.
The output holds the score, logs and game records. See [LOGS.md](tools/league/league/LOGS.md).
Red is your live bot and blue is the other team's old bot, whatever your team colour.
Run this, don't open \`bots/<other-tag>/\`.
EOF
