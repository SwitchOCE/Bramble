#!/bin/bash
# per-game compression of the 200 records, single thread; prints method total_bytes compress_s decompress_s
R=/data/dbtest/sample/records; O=/data/dbtest/sqlite/comp
run(){ name=$1; ext=$2; c=$3; d=$4; mkdir -p $O/$name
  t0=$(date +%s.%N); for f in $R/*.jsonl; do b=$(basename $f); eval "$c" < $f > $O/$name/$b.$ext; done; t1=$(date +%s.%N)
  for f in $O/$name/*.$ext; do eval "$d" < $f > /dev/null; done; t2=$(date +%s.%N)
  sz=$(cat $O/$name/*.$ext | wc -c)
  echo "$name $sz $(echo "$t1-$t0"|bc) $(echo "$t2-$t1"|bc)"; }
run gzip6 gz "gzip -6 -c" "gzip -dc"
run zstd3 zst "zstd -3 -q -c -T1" "zstd -dc -q"
run zstd19 zst "zstd -19 -q -c -T1" "zstd -dc -q"
run xz6 xz "xz -6 -c -T1" "xz -dc"
# whole sample as one stream (cross-game redundancy), not per-game accessible
t0=$(date +%s.%N); cat $R/*.jsonl | zstd -19 --long=27 -q -c -T1 > $O/all.long19.zst; t1=$(date +%s.%N)
echo "zstd19_long_concat $(wc -c < $O/all.long19.zst) $(echo "$t1-$t0"|bc) -"
