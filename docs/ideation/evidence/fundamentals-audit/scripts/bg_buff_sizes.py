import csv, re, sys, collections, statistics as st
rows = [r for r in csv.DictReader(open(sys.argv[1])) if r['in_current_pool'] == 'True' and r['duos_exclusive'] == 'False']
mag = collections.defaultdict(list); mult = []; growth = collections.Counter(); n = collections.Counter()
for r in rows:
    t = r['text']; tier = int(r['tier']); n[tier] += 1
    for a, h in re.findall(r'\+(\d+)/\+(\d+)', t): mag[tier].append(int(a) + int(h))
    for a in re.findall(r'\+(\d+) (?:Attack|Health)', t): mag[tier].append(int(a))
    if re.search(r'doubl|twice (?:its|their)|triple|equal to|set (?:its|their)|copy of its stats|stats of', t, re.I): mult.append((tier, r['name'], t[:150]))
    if re.search(r'permanent|this game|wherever|improve', t, re.I): growth[tier] += 1
print('current BG pool (solo):', sum(n.values()), 'minions')
for k in sorted(mag):
    v = mag[k]
    print(f'tier {k}: n={n[k]} cards with permanent/this-game/improve text={growth[k]} buff sizes in text (A+H or single stat) median={st.median(v)} p75={sorted(v)[int(.75*len(v))]} max={max(v)} count={len(v)}')
print('\nmultiplicative / stat-copy text (%d):' % len(mult))
for m in mult: print(' ', m)
