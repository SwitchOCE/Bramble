#!/bin/bash
# Rebuild the measured card table (src/lift.rs) from self-play, for changed card numbers.
#
# usage: rebuild_lift.sh <steps> [games-per-step] [threads]
#
# Each step: build the A/B tool with the current table, play <games> self-play games
# (current bot vs itself, simulated arrangement off for speed), measure each card's placement
# lift on round 4/6/9/12 boards (tools/scripts/lift.py), and move the table toward it.
# Step 1 replaces the table outright (alpha 1.0, which helped most in round 1); later steps
# move half-way (alpha 0.5). In round 1, one full step and two half-steps helped and further
# steps stopped helping, so 3 steps is the default to try; A/B each new table against the
# previous one (ab "cur:..." vs an old snapshot) before keeping it.
#
# Starting from scratch on new cards: empty src/lift.rs's table (keep the `_ => 0.0` arm) so
# every card starts at 0, then run this. The hand-written part (src/cards.rs) only holds a
# row preference and a small text bonus per card; new or renamed cards default to "Any, 0".
set -eu
STEPS=${1:-3}; GAMES=${2:-1000}; THREADS=${3:-2}
ROOT=/home/alex/league/blue
LEAGUE=$ROOT/tools/league
BOT=$LEAGUE/bots/blue
OUT=$ROOT/out/rebuild_$(date +%H%M)
mkdir -p $OUT
cd $LEAGUE
for i in $(seq 1 $STEPS); do
  ALPHA=0.5; [ $i -eq 1 ] && ALPHA=1.0
  CARGO_BUILD_JOBS=$THREADS CARGO_TARGET_DIR=$ROOT/out/tgt cargo build --release -q -p blue-tools --bin ab
  cp $ROOT/out/tgt/release/ab $OUT/ab_step$i
  python3 -c "import random; r=random.Random($i*7919); print('\n'.join(str(r.randrange(1,2**31)) for _ in range($GAMES)))" > $OUT/seeds$i.txt
  $OUT/ab_step$i "cur:sim_arrange=0" "cur:sim_arrange=0" $GAMES $OUT/seeds$i.txt $OUT/data$i $THREADS > /dev/null
  cp $BOT/src/lift.rs $OUT/lift_before_step$i.rs
  python3 $BOT/tools/scripts/lift.py $BOT/src/lift.rs $ALPHA $OUT/data$i | tail -3
  cp $BOT/src/lift.rs $OUT/lift_after_step$i.rs
  echo "step $i done (alpha $ALPHA); table saved in $OUT/lift_after_step$i.rs"
done
