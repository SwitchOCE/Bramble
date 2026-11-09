import json, sys, statistics as st, collections
path = sys.argv[1]
games = [json.loads(l) for l in open(path)]
def q(v, p):
    v = sorted(v); return v[min(len(v) - 1, int(p * len(v)))] if v else float('nan')
ok = []
for g in games:
    c = g['combats']
    if not c or c[0]['combat'] != 1: continue
    if sum(m[1] + m[2] for m in c[0]['me']) > 15: continue
    if abs(len(c) - g['turns']) > 1: continue
    ok.append(g)
print('games parsed', len(games), 'valid', len(ok))
opp = collections.defaultdict(list); me = collections.defaultdict(list)
ghosts = 0
for g in ok:
    for c in g['combats']:
        t = c['combat']
        oh = c.get('opp_hero') or {}
        for side, store, board in (('opp', opp, c['opp']), ('me', me, c['me'])):
            if side == 'opp' and oh.get('hp', 1) <= 0: ghosts += 1; continue
            stats = sorted([m[1] + m[2] for m in board], reverse=True)
            if not stats: continue
            tot = sum(stats)
            store[t].append(dict(tot=tot, n=len(stats), top1=stats[0], s1=stats[0] / tot if tot else 0,
                                 s2=sum(stats[:2]) / tot if tot else 0, med=st.median(stats), atk=sum(m[1] for m in board)))
print('ghost fights skipped', ghosts)
hdr = 'turn  n   tot_p10  tot_p25  tot_p50  tot_mean  tot_p75  tot_p90  tot_max | top1_p50 top1_p90 top1_max | share1_p50 share1_p90 | units_p50 | unit_median_p50'
for name, store in (('OPPONENTS of perfect-game winners (= ordinary lobby players)', opp), ('PERFECT-GAME WINNERS', me)):
    print('\n' + name); print(hdr)
    for t in sorted(store):
        if t > 18: continue
        r = store[t]; tot = [x['tot'] for x in r]; t1 = [x['top1'] for x in r]; s1 = [x['s1'] for x in r]
        print(f"{t:>4} {len(r):>4} {q(tot,.1):>8} {q(tot,.25):>8} {q(tot,.5):>8} {st.mean(tot):>9.0f} {q(tot,.75):>8} {q(tot,.9):>8} {max(tot):>8} | {q(t1,.5):>8} {q(t1,.9):>8} {max(t1):>8} | {q(s1,.5):>10.2f} {q(s1,.9):>10.2f} | {q([x['n'] for x in r],.5):>9} | {q([x['med'] for x in r],.5):>8}")
