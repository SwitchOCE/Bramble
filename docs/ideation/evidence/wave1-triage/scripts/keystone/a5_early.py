"""Keystone timing: owned at R8 (bought early) vs first seen R9-R12 vs never; R12 outcome; rings/size."""
import sys; sys.path.insert(0, '.')
from common import *
WH = ("board", "away", "hand")
def has(b, ids): return b is not None and any(u[0] in ids and u[6] in WH for u in b['units'])
SPEC = {
 "line_fairies_ring": [("Annis", {"old_moth_annis"})],
 "line_fairies_court": [("Annis", {"old_moth_annis"})],
 "line_birds_homecoming": [("Chiffchaff or Swallow", {"chiffchaff", "one_swallow"}), ("Goose", {"mother_goose"})],
 "line_birds_tempo": [("Chiffchaff or Swallow", {"chiffchaff", "one_swallow"}), ("Goose", {"mother_goose"})],
}
for line, specs in SPEC.items():
    seats = [sr for sr in BY_SEAT.values() if sr.get(8, {}).get('start') == line]
    for name, ids in specs:
        g = {"at R8": [], "first R9-12": [], "never by R12": []}
        for sr in seats:
            if has(sr.get(8), ids): g["at R8"].append(sr)
            elif any(has(sr.get(r), ids) for r in range(9, 13)): g["first R9-12"].append(sr)
            else: g["never by R12"].append(sr)
        print("=====", line, name)
        for k, v in g.items():
            r12 = [sr[12] for sr in v if 12 in sr]
            r8 = [sr[8] for sr in v]
            print("  %-13s n%3d (%4.1f%%) surv12 %3.0f%%  R8 med %4.0f  R12 med %4.0f (%.2f of paper)  R8 rings %4.1f  R12 rings %4.1f size %.1f" % (
                k, len(v), 100*len(v)/len(seats), 100*len(r12)/max(1,len(v)), med([b['stats'] for b in r8]), med([b['stats'] for b in r12]), med([b['stats'] for b in r12])/PAPER12[line],
                med([sum(b['rings']) for b in r8]), med([sum(b['rings']) for b in r12]), med([b['ring_size'] for b in r12])))
