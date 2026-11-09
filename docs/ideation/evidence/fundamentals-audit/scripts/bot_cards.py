import csv, collections, json, glob
D = '/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
U = {}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d = json.load(open(f))
    if d.get('set') == 'slice':
        U[d['id']] = d
P = list(csv.DictReader(open(D + 'free_choice_plain.players.csv')))
seeds = set(p['seed'] for p in P)
tribe = {(p['seed'], p['seat']): p['final_tribe'] for p in P}
place = {(p['seed'], p['seat']): int(p['place']) for p in P}
C = [r for r in csv.DictReader(open(D + 'free_choice_plain.cards.csv')) if r['seed'] in seeds and all(v != '' for k, v in r.items() if k != 'strategy')]
boards = collections.defaultdict(list)
for r in C:
    boards[(r['seed'], r['seat'])].append((r['card'], int(r['golden'])))
allk = list(place)
out = []
for T in ['Hedgerow folk', 'Hunters', 'Oozes', '']:
    ids = sorted([i for i, d in U.items() if (d['tribes'][:1] == [T] if T else not d['tribes']) and d.get('pool')], key=lambda i: (U[i]['tier'], i))
    out.append(f'\n== {T or "neutral"} cards on final boards (all players; top4 = place 1-4)')
    out.append('card                      T  boards  copies golden%  top4_share_with  top4_share_without  win_with  avgplace_with  avgplace_without')
    for i in ids:
        withk = [k for k in allk if any(c == i for c, g in boards[k])]
        cop = sum(1 for k in allk for c, g in boards[k] if c == i)
        gold = sum(g for k in allk for c, g in boards[k] if c == i)
        wo = [k for k in allk if k not in set(withk)]
        if T:
            wo = [k for k in wo if tribe[k] == T]
        def top4(ks):
            return sum(place[k] <= 4 for k in ks) / len(ks) if ks else float('nan')
        def ap(ks):
            return sum(place[k] for k in ks) / len(ks) if ks else float('nan')
        win = sum(place[k] == 1 for k in withk) / len(withk) if withk else float('nan')
        out.append(f'{i:25s} {U[i]["tier"]}  {len(withk):5d}  {cop:5d}  {100*gold/cop if cop else 0:5.1f}   {top4(withk):.2f}            {top4(wo):.2f}              {win:.2f}     {ap(withk):.2f}          {ap(wo):.2f}')
out.append('\n(\"without\" for tribe cards = players whose final tribe is that tribe but who lack the card; for neutrals = everyone without it)')
print('\n'.join(out))
