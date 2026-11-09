import csv, collections, statistics, sys
D = '/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
P = list(csv.DictReader(open(D + 'free_choice_plain.players.csv')))
seeds = set(p['seed'] for p in P)
tribe = {(p['seed'], p['seat']): p['final_tribe'] for p in P}
place = {(p['seed'], p['seat']): int(p['place']) for p in P}
R = [r for r in csv.DictReader(open(D + 'free_choice_plain.rounds.csv'))
     if r['seed'] in seeds and all(v != '' for k, v in r.items() if k != 'strategy')]

def q(xs, p):
    xs = sorted(xs)
    if not xs:
        return float('nan')
    i = min(len(xs) - 1, max(0, int(round(p * (len(xs) - 1)))))
    return xs[i]

TR = ['Hedgerow folk', 'Hunters', 'Oozes', 'Bog folk', 'Birds', 'no_tribe', 'Fairies']
out = []
for rnd in (6, 8, 10, 12, 14, 16):
    out.append(f'\n== round {rnd} (alive players only; total = attack+health on board; per-unit = total/units)')
    out.append('tribe            n   units  tot_p10 tot_p50 tot_p90 tot_p99 tot_max  perunit_p50 perunit_p90  p90/p50 max/p50 tier_mean')
    for t in TR + ['ALL']:
        rows = [r for r in R if int(r['round']) == rnd and (t == 'ALL' or tribe[(r['seed'], r['seat'])] == t)]
        if not rows:
            continue
        tot = [int(r['attack']) + int(r['health']) for r in rows]
        pu = [(int(r['attack']) + int(r['health'])) / int(r['units']) for r in rows if int(r['units']) > 0]
        un = statistics.mean(int(r['units']) for r in rows)
        tier = statistics.mean(int(r['tier']) for r in rows)
        p50 = q(tot, .5)
        out.append(f'{t:15s} {len(rows):4d}  {un:5.2f}  {q(tot,.1):6d} {p50:6d} {q(tot,.9):6d} {q(tot,.99):6d} {max(tot):6d}   {q(pu,.5):8.1f} {q(pu,.9):8.1f}   {q(tot,.9)/p50:5.2f} {max(tot)/p50:5.2f}  {tier:4.2f}')
# winners vs others at round 12
out.append('\n== round 12 total stats by final place (all tribes)')
for pl in range(1, 9):
    rows = [r for r in R if int(r['round']) == 12 and place[(r['seed'], r['seat'])] == pl]
    tot = [int(r['attack']) + int(r['health']) for r in rows]
    if tot:
        out.append(f'place {pl}: n={len(rows)} p50={q(tot,.5)} p90={q(tot,.9)}')
# end-of-game: last round each player played
last = {}
for r in R:
    k = (r['seed'], r['seat'])
    if k not in last or int(r['round']) > int(last[k]['round']):
        last[k] = r
out.append('\n== winners (place 1) final board: total stats and per unit, by tribe')
for t in TR:
    ks = [k for k in last if tribe[k] == t and place[k] == 1]
    tot = [int(last[k]['attack']) + int(last[k]['health']) for k in ks]
    pu = [(int(last[k]['attack']) + int(last[k]['health'])) / max(1, int(last[k]['units'])) for k in ks]
    rd = [int(last[k]['round']) for k in ks]
    if tot:
        out.append(f'{t:15s} wins={len(ks):3d} final_round_p50={q(rd,.5)} tot_p50={q(tot,.5)} tot_p90={q(tot,.9)} tot_max={max(tot)} perunit_p50={q(pu,.5):.1f} perunit_max={max(pu):.1f}')
# place distribution per tribe
out.append('\n== place distribution by final tribe')
for t in TR:
    ks = [k for k in place if tribe[k] == t]
    c = collections.Counter(place[k] for k in ks)
    out.append(f'{t:15s} n={len(ks):4d} ' + ' '.join(f'{pl}:{c[pl]/len(ks):.2f}' for pl in range(1, 9)) + f' mean={statistics.mean(place[k] for k in ks):.2f}')
# win rate per round per tribe (fight results)
out.append('\n== fight win share (wins/(wins+losses)) by round band')
for t in TR:
    line = f'{t:15s}'
    for lo, hi in ((1, 4), (5, 8), (9, 12), (13, 16), (17, 30)):
        rows = [r for r in R if lo <= int(r['round']) <= hi and tribe[(r['seed'], r['seat'])] == t]
        w = sum(r['result'] == 'win' for r in rows); l = sum(r['result'] == 'loss' for r in rows)
        line += f'  R{lo}-{hi}: {w/(w+l) if w+l else float("nan"):.2f} (n={w+l})'
    out.append(line)
# larder / bank for Hedgerow
out.append('\n== bank and larder (held acorn gold) p50/p90 by tribe at rounds 8/12')
for t in TR:
    line = f'{t:15s}'
    for rnd in (8, 12):
        rows = [r for r in R if int(r['round']) == rnd and tribe[(r['seed'], r['seat'])] == t]
        if rows:
            line += f'  R{rnd} bank p50={q([int(r["bank"]) for r in rows],.5)} p90={q([int(r["bank"]) for r in rows],.9)} larder p50={q([int(r["larder"]) for r in rows],.5)} p90={q([int(r["larder"]) for r in rows],.9)} spent p50={q([int(r["spent"]) for r in rows],.5)}'
    out.append(line)
print('\n'.join(out))
