"""Birds: carry identity at R12; per-card win rate R10-R14 with/without on board (combat-only effects
don't show in pre-start stats); Redbreast and Cuckoo gains; flier copies."""
import sys, csv, glob; sys.path.insert(0, '.')
from common import *
import collections
res = {}
for f in sorted(glob.glob('/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/chunk-*.rounds.csv')):
    for row in csv.DictReader(open(f)):
        res[(int(row['seed']), int(row['seat']), int(row['round']))] = row['result']
CARDS = ["mrs_stork","mother_goose","great_lump","mr_redbreast","cuckoo","old_tern","chiffchaff","mrs_jay","one_swallow","mrs_dunnock","redwing","jack_daw","tom_tit","mag_pye","gabble_ratchet","seven_whistlers"]
for line in ["line_birds_homecoming","line_birds_tempo"]:
    print("=====", line)
    bs = committed(line, 12)
    carry = collections.Counter(); cst = collections.defaultdict(list)
    for b in bs:
        us = [u for u in b['units'] if u[6] in ('board','away','hand') and 'Birds' in u[8]]
        if not us: continue
        u = max(us, key=lambda u: u[2]+u[3])
        carry[u[0]] += 1; cst[u[0]].append(u[2]+u[3])
    print("  biggest Bird at R12 (anywhere):", [(k, v, med(cst[k])) for k, v in carry.most_common(8)])
    lump = [next((u[2]+u[3] for u in b['units'] if u[0]=='great_lump' and u[6]=='board'), None) for b in bs]
    lump = [x for x in lump if x is not None]
    print("  Great Lump stats on board at R12 med", med(lump), "q75", q(lump,.75))
    rb = [next((u[2]+u[3] for u in b['units'] if u[0]=='mr_redbreast' and u[6]=='board'), None) for b in bs]
    rb = [x for x in rb if x is not None]
    print("  Redbreast stats R12 med", med(rb), " (paper 105 at R12)")
    print("  win rate R10-R14 with/without card on board:")
    for c in CARDS:
        w = []; wo = []
        for (seed, seat), sr in BY_SEAT.items():
            if sr.get(8, {}).get('start') != line: continue
            for r in range(10, 15):
                b = sr.get(r)
                if not b: continue
                x = res.get((seed, seat, r))
                v = 1.0 if x == 'win' else 0.5 if x == 'tie' else 0.0
                (w if any(u[0]==c and u[6]=='board' for u in b['units']) else wo).append(v)
        print("    %-16s with %.0f%% (n%d)  without %.0f%% (n%d)" % (c, 100*st.mean(w) if w else float('nan'), len(w), 100*st.mean(wo), len(wo)))
    dup = collections.Counter()
    for b in bs:
        cnt = collections.Counter(u[0] for u in b['units'] if u[6] in ('board','away','hand'))
        for k in ("chiffchaff","one_swallow","mrs_jay","old_tern","mother_goose"):
            if cnt[k] >= 2: dup[k] += 1
    print("  seats with 2+ copies of a flier at R12:", dict(dup))
