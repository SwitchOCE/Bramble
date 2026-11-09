"""Within-seat growth R8->R12 and R10->R14 by keystone group; survival to R12 by keystone seen R8-R10;
keystone share counted over ALL 640 seats (eliminated included)."""
import sys; sys.path.insert(0, '.')
from common import *
GROUPS = {
 "line_fairies_ring": {"Annis": {"old_moth_annis"}, "Cluricaun": {"cluricaun"}, "Monarch": {"fairy_monarch"}, "Queen": {"queen_of_elfland"}, "Lob/Silky": {"lob_lie_by_the_fire","silky"}},
 "line_fairies_court": {"Annis": {"old_moth_annis"}, "Cluricaun": {"cluricaun"}, "Monarch": {"fairy_monarch"}, "Queen": {"queen_of_elfland"}, "Lob/Silky": {"lob_lie_by_the_fire","silky"}},
 "line_birds_homecoming": {"Stork": {"mrs_stork"}, "Goose": {"mother_goose"}, "Cuckoo": {"cuckoo"}, "Lump": {"great_lump"}, "3+fliers@R10": None},
 "line_birds_tempo": {"Stork": {"mrs_stork"}, "Goose": {"mother_goose"}, "Cuckoo": {"cuckoo"}, "Lump": {"great_lump"}, "3+fliers@R10": None},
}
FLIERS={"one_swallow","chiffchaff","mrs_jay","old_tern","mother_goose"}
WH=("board","away","hand")
for line, gs in GROUPS.items():
    seats = {k: v for k, v in BY_SEAT.items() if v.get(8, {}).get('start') == line}
    print("=====", line, "seats", len(seats))
    for name, ids in gs.items():
        def has(sr, r1):
            if ids is None:
                b = sr.get(10)
                return b is not None and sum(1 for u in b['units'] if u[0] in FLIERS and u[6] in WH) >= 3
            return seen(sr, ids, 8, r1, WH)
        out = []
        for flag in (True, False):
            grp = [sr for sr in seats.values() if has(sr, 10) == flag]
            surv = sum(1 for sr in grp if 12 in sr) / max(1, len(grp))
            g812 = [(sr[12]['stats'] / sr[8]['stats']) ** 0.25 for sr in grp if 12 in sr and sr[8]['stats'] > 0]
            g1014 = [(sr[14]['stats'] / sr[10]['stats']) ** 0.25 for sr in grp if 14 in sr and 10 in sr and sr[10]['stats'] > 0]
            r12 = [sr[12]['stats'] for sr in grp if 12 in sr]
            out.append("%s: n%3d (%4.1f%%) surv12 %4.0f%% medR12 %4.0f  x/round R8-12 %.3f R10-14 %.3f" % ("with" if flag else "w/o ", len(grp), 100*len(grp)/len(seats), 100*surv, med(r12), med(g812), med(g1014)))
        # share lacking by R12 over all seats (eliminated ones: seen up to their last round)
        lack = sum(1 for sr in seats.values() if not (has(sr, 12) if ids is not None else has(sr, 10)))
        print("  %-12s lacking by R12 (all seats, elim incl.) %4.1f%%" % (name, 100*lack/len(seats)))
        for o in out: print("     ", o)
