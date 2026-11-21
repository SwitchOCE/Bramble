#!/bin/bash
# per-file compression of the 200 records: total bytes, compress s, decompress s
S=/data/dbtest/sample/records; W=/data/dbtest/surrealdb/tmp/cb; rm -rf $W; mkdir -p $W
run() { name=$1; ext=$2; c=$3; d=$4
  t0=$(date +%s.%N); for f in $S/*.jsonl; do $c < $f > $W/$(basename $f).$ext; done; t1=$(date +%s.%N)
  for f in $W/*.$ext; do $d < $f > /dev/null; done; t2=$(date +%s.%N)
  sz=$(cat $W/*.$ext | wc -c); echo "$name $sz $(echo "$t1-$t0"|bc) $(echo "$t2-$t1"|bc)"; rm $W/*.$ext; }
echo "raw $(cat $S/*.jsonl | wc -c) 0 0"
run gzip-6 gz "gzip -6" "gzip -d"
run zstd-3 zst "zstd -q -3 -T1" "zstd -q -d"
run zstd-19 zst "zstd -q -19 -T1" "zstd -q -d"
run xz-6 xz "xz -6 -T1" "xz -d"
