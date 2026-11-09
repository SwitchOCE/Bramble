"""R12 pre-start stats of committed seats split by whether key engine pieces were owned early.

Run: python3 -I condstats.py <run_dir> <seat_labels.json.gz>
Ownership from fights.jsonl.gz recruit_units (any location) at each round's combat; stats from boards.json.gz.
"""
import glob, gzip, json, os, sys, statistics, collections

RUN, LABELS = sys.argv[1], sys.argv[2]
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LABELS))}
own = collections.defaultdict(dict)  # (seed, seat) -> def_id -> first round owned
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.fights.jsonl.gz"))):
    for line in gzip.open(f, "rt"):
        d = json.loads(line)
        for side, seat in zip(d["combat_start"], d["players"]):
            for u in side.get("recruit_units", []):
                fr = own[(d["seed"], seat)]
                if u["def_id"] not in fr or d["round"] < fr[u["def_id"]]:
                    fr[u["def_id"]] = d["round"]
stats = collections.defaultdict(dict)
ring = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.boards.json.gz"))):
    for b in json.load(gzip.open(f)):
        stats[(b["seed"], b["seat"])][b["round"]] = b["stats"]
        if b["round"] == 12:
            ring[(b["seed"], b["seat"])] = (b.get("ring_size"), b.get("slots"))

CONDS = {
    "line_fairies_ring": [("annis<=R6", [("old_moth_annis", 6)]), ("clur<=R9", [("cluricaun", 9)]),
                          ("annis<=R6 & clur<=R9", [("old_moth_annis", 6), ("cluricaun", 9)]),
                          ("monarch<=R11", [("fairy_monarch", 11)]),
                          ("annis<=R6 & clur<=R9 & monarch<=R11", [("old_moth_annis", 6), ("cluricaun", 9), ("fairy_monarch", 11)])],
    "line_fairies_court": [("annis<=R6", [("old_moth_annis", 6)]), ("clur<=R9", [("cluricaun", 9)]),
                           ("annis<=R6 & clur<=R9", [("old_moth_annis", 6), ("cluricaun", 9)]),
                           ("queen<=R11", [("queen_of_elfland", 11)]),
                           ("annis<=R6 & clur<=R9 & queen<=R11", [("old_moth_annis", 6), ("cluricaun", 9), ("queen_of_elfland", 11)])],
    "line_birds_homecoming": [("redbreast<=R6", [("mr_redbreast", 6)]), ("stork<=R9", [("mrs_stork", 9)]),
                              ("cuckoo<=R10", [("cuckoo", 10)]),
                              ("redbreast<=R6 & stork<=R9", [("mr_redbreast", 6), ("mrs_stork", 9)]),
                              ("redbreast<=R6 & stork<=R9 & cuckoo<=R10", [("mr_redbreast", 6), ("mrs_stork", 9), ("cuckoo", 10)])],
    "line_birds_tempo": [("redbreast<=R6", [("mr_redbreast", 6)]), ("stork<=R9", [("mrs_stork", 9)]),
                         ("cuckoo<=R10", [("cuckoo", 10)]),
                         ("redbreast<=R6 & stork<=R9", [("mr_redbreast", 6), ("mrs_stork", 9)]),
                         ("redbreast<=R6 & stork<=R9 & cuckoo<=R10", [("mr_redbreast", 6), ("mrs_stork", 9), ("cuckoo", 10)])],
}
out = {}
for line, conds in CONDS.items():
    seats = [k for k, v in labels.items() if v == line and 12 in stats.get(k, {})]
    allmed = statistics.median(stats[k][12] for k in seats)
    rows = {"all": dict(n=len(seats), median=allmed)}
    print(f"\n{line}: R12 survivors {len(seats)}, median {allmed}")
    for name, need in conds:
        yes = [k for k in seats if all(own[k].get(c, 99) <= r for c, r in need)]
        no = [k for k in seats if k not in set(yes)]
        my = statistics.median(stats[k][12] for k in yes) if yes else None
        mn = statistics.median(stats[k][12] for k in no) if no else None
        # also the lobby-level share among all committed seats of this line (incl. eliminated before R12)
        allseats = [k for k, v in labels.items() if v == line]
        share_all = sum(all(own[k].get(c, 99) <= r for c, r in need) for k in allseats) / len(allseats)
        rows[name] = dict(share_r12=round(len(yes) / len(seats), 3), share_all=round(share_all, 3),
                          median_yes=my, median_no=mn, n_yes=len(yes))
        print(f"  {name:42s} have {len(yes)/len(seats)*100:5.1f}% of R12 survivors ({share_all*100:4.1f}% of all)  median R12 with {my}  without {mn}")
    out[line] = rows
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "condstats.json"), "w"), indent=1)
