"""Does Mrs Stork add homecomings? Seat-rounds R9-R14: Stork on board at r-1 snapshot, away Birds at r-1."""
import sys; sys.path.insert(0, '.')
from common import *
import collections
for line in ["line_birds_homecoming", "line_birds_tempo"]:
    cells = collections.defaultdict(list)
    turns = collections.defaultdict(list)
    for (seed, seat), sr in BY_SEAT.items():
        if sr.get(8, {}).get('start') != line: continue
        for r in range(9, 15):
            p, b = sr.get(r-1), sr.get(r)
            if not p or not b: continue
            stork = any(u[0] == 'mrs_stork' and u[6] == 'board' for u in p['units'])
            away = sum(1 for u in p['units'] if u[6] == 'away')
            cells[(stork, min(away, 3))].append(b['home'] or 0)
            # gold spent this round
            turns[stork].append(b['gold'] - p['gold'])
    print("=====", line)
    for away in range(0, 4):
        a = cells[(True, away)]; c = cells[(False, away)]
        print("  away at r-1 = %s: homecomings at r  Stork %.2f (n%d)  no Stork %.2f (n%d)" % (away if away < 3 else '3+', st.mean(a) if a else float('nan'), len(a), st.mean(c) if c else float('nan'), len(c)))
    print("  gold spent per round, Stork %.1f  no Stork %.1f" % (st.mean(turns[True]), st.mean(turns[False])))
    # Away count distribution and away birds' trip state
    aw = [sum(1 for u in sr[12]['units'] if u[6]=='away') for sr in BY_SEAT.values() if sr.get(8,{}).get('start')==line and 12 in sr]
    print("  away Birds at R12 snapshot:", sorted(collections.Counter(aw).items()))
