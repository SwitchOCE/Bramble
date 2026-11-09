"""Journey by stage from rounds.csv (all rounds) for each committed starting line vs the Hard field.
rounds.csv attack/health = board after that round's recruit (per the csv), result = fight result."""
import sys; sys.path.insert(0, '.')
from common import *
import collections
R = D['rounds']
lab = {}
for b in BOARDS: lab[(b['seed'], b['seat'])] = b['start']
for p in D['players']: lab[(int(p['seed']), int(p['seat']))] = p['start']
by = collections.defaultdict(lambda: collections.defaultdict(list))
res = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
for r in R:
    k = (int(r['seed']), int(r['seat']))
    line = lab.get(k, '?')
    rd = int(r['round'])
    by[line][rd].append(int(r['attack']) + int(r['health']))
    res[line][rd][r['result']] += 1
    by['ALL'][rd].append(int(r['attack']) + int(r['health']))
    by[line+'_tier'][rd].append(int(r['tier']))
    by[line+'_spent'][rd].append(int(r['spent']))
lines = LINES + ['hard_field']
print("round " + " ".join("%22s" % l.replace('line_', '') for l in lines) + "   ALL")
for rd in range(1, 15):
    cells = []
    for l in lines:
        v = by[l][rd]; c = res[l][rd]; n = sum(c.values())
        w = (c['win'] + 0.5 * c['tie']) / n if n else float('nan')
        cells.append("%5.0f t%.0f w%3.0f%% n%3d" % (med(v), med(by[l+'_tier'][rd]), 100 * w, n))
    print("R%-4d" % rd + " ".join("%22s" % c for c in cells) + "  %5.0f" % med(by['ALL'][rd]))
print()
print(collections.Counter(r['result'] for r in R))
