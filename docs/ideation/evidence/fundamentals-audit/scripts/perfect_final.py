import json, sys, statistics as st, collections
d = json.load(open(sys.argv[1]))
rows = []
for g in d:
    bh = g['postMatchStats']['boardHistory']
    if not bh: continue
    b = bh[-1]['board']
    stats = sorted([(m['tags'].get('ATK', 0) + m['tags'].get('HEALTH', 0)) for m in b], reverse=True)
    if not stats: continue
    tot = sum(stats)
    rows.append(dict(turn=bh[-1]['turn'], n=len(stats), tot=tot, top1=stats[0], share1=stats[0] / tot if tot else 0,
                     share2=sum(stats[:2]) / tot if tot else 0, arch=g.get('archetype'), rank=int(g['playerRank'] or 0)))
print('games', len(rows))
def q(v, p): v = sorted(v); return v[min(len(v) - 1, int(p * len(v)))]
print('final turn dist', collections.Counter(r['turn'] for r in rows).most_common())
for lo, hi in [(7, 10), (11, 12), (13, 13), (14, 14), (15, 15), (16, 20)]:
    rr = [r for r in rows if lo <= r['turn'] <= hi]
    if not rr: continue
    tot = [r['tot'] for r in rr]; t1 = [r['top1'] for r in rr]; sh = [r['share1'] for r in rr]
    print(f'turn {lo}-{hi} n={len(rr)} total p10/p50/p90 {q(tot,.1)}/{q(tot,.5)}/{q(tot,.9)}  biggest unit p10/p50/p90 {q(t1,.1)}/{q(t1,.5)}/{q(t1,.9)}  top1 share p10/p50/p90 {q(sh,.1):.2f}/{q(sh,.5):.2f}/{q(sh,.9):.2f}  units<7 {sum(r["n"]<7 for r in rr)}')
sh = [r['share1'] for r in rows]
print('top1 share overall: median', round(st.median(sh), 3), ' share>0.5:', round(sum(s > 0.5 for s in sh) / len(sh), 3), ' share>0.3:', round(sum(s > 0.3 for s in sh) / len(sh), 3), ' even (<=1/7*1.5):', round(sum(s <= 0.214 for s in sh) / len(sh), 3))
print('ranks p10/p50/p90', q([r['rank'] for r in rows], .1), q([r['rank'] for r in rows], .5), q([r['rank'] for r in rows], .9))
ac = collections.defaultdict(list)
for r in rows: ac[r['arch']].append(r)
print('archetype: n, median total, median top1 share')
for a, rr in sorted(ac.items(), key=lambda x: -len(x[1]))[:25]:
    print(f'  {str(a):<28} {len(rr):>4} {st.median([r["tot"] for r in rr]):>9.0f} {st.median([r["share1"] for r in rr]):.2f} {st.median([r["turn"] for r in rr]):.0f}')
