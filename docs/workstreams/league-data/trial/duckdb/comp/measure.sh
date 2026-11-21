#!/bin/bash
# per-file compression of the 200 replay records, single-threaded, 2 jobs max in total
S=/data/dbtest/sample/records; O=/data/dbtest/duckdb/comp; cd $O
run(){ name=$1; ext=$2; c=$3; d=$4; mkdir -p $name; t0=$(date +%s.%N); for f in $S/*.jsonl; do $c < $f > $name/$(basename $f).$ext; done; t1=$(date +%s.%N)
  for f in $name/*; do $d < $f > /dev/null; done; t2=$(date +%s.%N)
  echo "$name bytes=$(cat $name/* | wc -c) comp_s=$(echo "$t1-$t0"|bc) decomp_s=$(echo "$t2-$t1"|bc)"; }
echo "raw bytes=$(cat $S/*.jsonl | wc -c)"
run gzip6 gz "gzip -6" "gzip -dc"
run zstd3 zst "zstd -q -3 -T1" "zstd -q -dc"
run zstd19 zst "zstd -q -19 -T1" "zstd -q -dc"
run xz6 xz "xz -6 -T1" "xz -dc"
