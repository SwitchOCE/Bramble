#!/bin/bash
OUT=${OUT:-/home/alex/league/red/out}
# usage: prq.sh games name "k=v,k=v" [name "k=v" ...]  -- practice vs blue-m1, one at a time
# Writes the overrides file, runs play.sh, restores it, appends the score to out/pr_results.txt
g=$1; shift; SEEDS=${SEEDS:-$OUT/seeds100.txt}
ov=/home/alex/league/red/tools/league/bots/red/src/overrides.rs
while [ $# -ge 2 ]; do
  name=$1; o=$2; shift 2
  tab=$(echo "$o" | tr ',' '\n' | grep '^table=' | cut -d= -f2)
  [ -n "$tab" ] && cp "$tab" /home/alex/league/red/tools/league/bots/red/data/cards.tsv
  printf '//! Settings applied over the defaults (written by the team'"'"'s practice script).\npub const OVERRIDES: &str = "%s";\n' "$o" > $ov
  timeout 1800 /home/alex/league/practice-red/play.sh blue-m1 $g $OUT/pr/$name --seeds $SEEDS > $OUT/pr/$name.log 2>&1
  printf '//! Settings applied over the defaults (written by the team'"'"'s practice script).\npub const OVERRIDES: &str = "";\n' > $ov
  [ -n "$tab" ] && git -C /home/alex/league/red checkout -- tools/league/bots/red/data/cards.tsv
  echo "$(date +%H:%M) $g $name [$o] :: $(grep -m1 "red minus blue" $OUT/pr/$name.log)" >> $OUT/pr_results.txt
done
