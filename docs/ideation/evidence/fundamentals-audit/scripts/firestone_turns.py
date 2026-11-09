import json, sys, statistics as st
path = sys.argv[1]
d = json.load(open(path))
hs = d['heroStats']
print(path.split('/')[-1], 'lastUpdate', d['lastUpdateDate'], 'games', d['dataPoints'], 'heroes', len(hs))
turns = {}
for h in hs:
    for w in h.get("warbandStats") or []:
        if w.get("averageStats") is None: continue
        turns.setdefault(w['turn'], []).append((w['averageStats'], h['dataPoints'], h['averagePosition']))
print('turn  wmean   hero_min  hero_p25 hero_med hero_p75 hero_max  nheroes')
for t in sorted(turns):
    if t > 20: continue
    v = turns[t]
    tot = sum(n for _, n, _ in v)
    wm = sum(a*n for a, n, _ in v) / tot
    vals = sorted(a for a, _, _ in v if True)
    q = st.quantiles(vals, n=4) if len(vals) > 3 else [0,0,0]
    print(f'{t:>4} {wm:>8.0f} {vals[0]:>9.0f} {q[0]:>8.0f} {q[1]:>8.0f} {q[2]:>8.0f} {vals[-1]:>9.0f} {len(v):>5}')
