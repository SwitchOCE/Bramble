import json, sys, collections
games = [json.loads(l) for l in open(sys.argv[1])]
res = collections.Counter(); n = 0; tall_opp = 0; tall_me = 0; opp_n = 0
for g in games:
    c = g['combats']
    if not c or c[0]['combat'] != 1 or sum(m[1] + m[2] for m in c[0]['me']) > 15 or abs(len(c) - g['turns']) > 1: continue
    for x in c:
        if x['combat'] < 8 or (x.get('opp_hero') or {}).get('hp', 1) <= 0 or not x['opp'] or not x['me']: continue
        n += 1
        def prof(b):
            s = sorted([m[1] + m[2] for m in b], reverse=True); t = sum(s)
            return t, s[0] / t, len(s)
        mt, ms, mn = prof(x['me']); ot, os_, on = prof(x['opp'])
        tall = lambda sh: sh >= 0.6
        wide = lambda sh, k: sh <= 0.3 and k >= 6
        if tall(os_): tall_opp += 1
        if tall(ms): tall_me += 1
        if tall(ms) and wide(os_, on): res['winner tall vs loser wide'] += 1; res['  ...and winner had fewer stats'] += mt < ot
        if wide(ms, mn) and tall(os_): res['winner wide vs loser tall'] += 1; res['  ...and winner had fewer stats '] += mt < ot
print('fights from turn 8 on (non-ghost):', n)
print('boards with one unit >= 60% of stats: winners', tall_me, f'({tall_me/n:.0%})', ' opponents', tall_opp, f'({tall_opp/n:.0%})')
for k, v in res.items(): print(k, v)
