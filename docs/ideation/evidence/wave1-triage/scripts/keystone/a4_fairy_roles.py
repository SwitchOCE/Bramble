"""Fairy card roles in play, seat-rounds R9-R14 (state at r-1 snapshot -> change by r snapshot).
Count sources: Rings added per round. Size sources: Ring size change per round. Cluricaun: fire rate at tier-ups."""
import sys; sys.path.insert(0, '.')
from common import *
import collections
def onb(b, i): return any(u[0] == i and u[6] == 'board' for u in b['units'])
def rainbow(b): return len(b['rings']) == 7 and all(c > 0 for c in b['rings'])
for line in ["line_fairies_ring", "line_fairies_court"]:
    dr = collections.defaultdict(list); ds = collections.defaultdict(list)
    clu = collections.Counter(); lob = collections.Counter(); mon = collections.Counter()
    for sr in BY_SEAT.values():
        if sr.get(8, {}).get('start') != line: continue
        for r in range(9, 15):
            p, b = sr.get(r-1), sr.get(r)
            if not p or not b: continue
            d_r = sum(b['rings']) - sum(p['rings'])
            for i in ("old_moth_annis", "queen_of_elfland", "sally_spore", "nan_toadstool"):
                dr[(i, onb(p, i))].append(d_r)
            dr[("none", not any(onb(p, i) for i in ("old_moth_annis","queen_of_elfland","sally_spore")))].append(d_r)
            # Cluricaun at tier-up
            if onb(p, 'cluricaun') and b['tier'] > p['tier']:
                clu['tierups_with_clu'] += 1
                clu['rainbow_before'] += rainbow(p)
                clu['rainbow_after'] += rainbow(b)
                clu['size_up'] += (b['ring_size'] > p['ring_size'])
            if onb(p, 'cluricaun'):
                clu['clu_seat_rounds'] += 1
                clu['tierup_rounds'] += b['tier'] > p['tier']
                clu['at_t6_already'] += p['tier'] == 6
            # Lob/Silky leaving
            for i in ('lob_lie_by_the_fire', 'silky', 'hob_in_the_hearth'):
                if onb(p, i) and not any(u[0] == i for u in b['units']):
                    lob[i + '_left'] += 1
                    lob[i + '_left_size_up'] += b['ring_size'] > p['ring_size']
            if onb(p, 'fairy_monarch'):
                mon['rounds'] += 1
                mon['doubled'] += (b['ring_size'] >= 2 * p['ring_size'] - 1e-9 and b['ring_size'] > p['ring_size'])
    print("=====", line)
    for i in ("old_moth_annis", "queen_of_elfland", "sally_spore", "nan_toadstool", "none"):
        a = dr[(i, True)]; c = dr[(i, False)]
        print("  Rings added per round with %-17s on board at r-1: mean %.1f med %.0f (n%d) | without mean %.1f (n%d)" % (i, st.mean(a), med(a), len(a), st.mean(c), len(c)))
    print("  Cluricaun:", dict(clu))
    print("    fire rate per tier-up %.0f%% ; share of Cluricaun seat-rounds already at T6 %.0f%%" % (100*clu['size_up']/max(1,clu['tierups_with_clu']), 100*clu['at_t6_already']/max(1,clu['clu_seat_rounds'])))
    print("  Shy departures:", dict(lob))
    print("  Monarch:", dict(mon), "double rate per Monarch-round %.0f%%" % (100*mon['doubled']/max(1,mon['rounds'])))
