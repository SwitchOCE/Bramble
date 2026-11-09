import json, sys, collections
games = [json.loads(l) for l in open(sys.argv[1])]
by = collections.defaultdict(lambda: [0, 0, 0, 0, 0])
ex = []
for g in games:
    c = g['combats']
    if not c or c[0]['combat'] != 1 or sum(m[1] + m[2] for m in c[0]['me']) > 15 or abs(len(c) - g['turns']) > 1: continue
    for x in c:
        t = x['combat']
        if (x.get('opp_hero') or {}).get('hp', 1) <= 0 or not x['opp'] or not x['me']: continue
        mt = sum(m[1] + m[2] for m in x['me']); ot = sum(m[1] + m[2] for m in x['opp'])
        m1 = max(m[1] + m[2] for m in x['me']); o1 = max(m[1] + m[2] for m in x['opp'])
        b = by[min(t, 15)]
        b[0] += 1
        if mt < ot: b[1] += 1
        if mt < 0.5 * ot: b[2] += 1
        if mt < ot and m1 / mt > o1 / ot: b[3] += 1
        if mt < 0.25 * ot: b[4] += 1; ex.append((t, mt, ot, round(m1 / mt, 2), round(o1 / ot, 2), g.get('archetype'), len(x['me']), len(x['opp'])))
print('turn  fights  winner_had_fewer_stats  winner_had_<half  winner_<quarter  (of fewer: winner more concentrated)')
for t in sorted(by):
    n, a, h, cc, qq = by[t]
    print(f'{t:>4} {n:>6} {a:>6} ({a/n:.0%}) {h:>6} ({h/n:.0%}) {qq:>5} ({qq/n:.0%})  {cc}/{a}')
print('examples where the never-damaged winner had <25% of the opponent stats (turn, me, opp, me top1 share, opp top1 share, archetype, my units, opp units):')
for e in sorted(ex)[-25:]: print(' ', e)
