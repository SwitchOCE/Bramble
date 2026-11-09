"""ESTIMATED offer rates from pool rules (game_config.gd full_game, tribes_per_lobby=0 in the accounting plan):
shop_units_by_tier [4,4,4,5,5,6]; SLICE_SHOP_ODDS; units per tier counted from content/units pool:true.
Assumes a full pool (no depletion), copies equal within a tier, one shop = one fresh roll of all unit slots.
Uses observed median tier per round and observed mean paid refreshes (rounds.csv) per line."""
import sys, json, glob, collections; sys.path.insert(0, '.')
from common import *
SLOTS=[4,4,4,5,5,6]
ODDS=[[100],[50,50],[20,30,50],[10,15,25,50],[5,10,15,25,45],[5,5,10,15,25,40]]
N=collections.Counter()
for f in glob.glob('/home/alex/code/Bramble-ideation-sol/content/units/*.json'):
    d=json.load(open(f))
    if d.get('pool'): N[d['tier']]+=1
print("units per tier in pool:", dict(sorted(N.items())))
def p_shop(card_tier, tav, k=1):
    o=ODDS[tav-1]
    if card_tier>len(o): return 0.0
    per=o[card_tier-1]/100.0*k/N[card_tier]
    return 1-(1-per)**SLOTS[tav-1]
print("P(a given card appears in one shop): rows = card tier, cols = tavern tier 1..6")
for ct in range(1,7):
    print("  T%d card: " % ct + " ".join("%5.1f%%" % (100*p_shop(ct,t)) for t in range(1,7)))
# observed tier and refreshes per line per round
R=D['rounds']; lab={(int(p['seed']),int(p['seat'])):p['start'] for p in D['players']}
tier=collections.defaultdict(lambda: collections.defaultdict(list)); ref=collections.defaultdict(lambda: collections.defaultdict(list))
import csv
for f in sorted(glob.glob('/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/chunk-*.rounds.csv')):
    for row in csv.DictReader(open(f)):
        l=lab.get((int(row['seed']),int(row['seat'])))
        tier[l][int(row['round'])].append(int(row['tier'])); ref[l][int(row['round'])].append(int(row['paid_refreshes']))
CARDS={"old_moth_annis":2,"cluricaun":3,"lob_lie_by_the_fire":3,"silky":3,"queen_of_elfland":6,"fairy_monarch":6,
       "chiffchaff":1,"one_swallow":1,"mrs_jay":2,"old_tern":3,"mother_goose":5,"mrs_stork":4,"cuckoo":4,"great_lump":5}
for line in LINES:
    print("=====", line)
    print("  round: " + " ".join("R%-5d"%r for r in range(1,13)))
    print("  tier : " + " ".join("%-6.1f"%st.mean(tier[line][r]) for r in range(1,13)))
    print("  shops: " + " ".join("%-6.2f"%(1+st.mean(ref[line][r])) for r in range(1,13)))
    for c,ct in CARDS.items():
        if ('fair' in line) != (c in ("old_moth_annis","cluricaun","lob_lie_by_the_fire","silky","queen_of_elfland","fairy_monarch")): continue
        miss=1.0; cum=[]
        for r in range(1,13):
            t=round(med(tier[line][r])); shops=1+st.mean(ref[line][r])
            # tier at time of shopping ~ the tier after tier-up this round (snapshot); use it
            miss*= (1-p_shop(ct,t))**shops
            cum.append(1-miss)
        print("  P(seen %s by R)" % c.ljust(20) + " ".join("%5.0f%%"%(100*x) for x in cum))
# any of the 5 fliers
for line in ["line_birds_homecoming","line_birds_tempo"]:
    exp=0.0
    out=[]
    for r in range(1,13):
        t=round(med(tier[line][r])); shops=1+st.mean(ref[line][r])
        e=sum(shops*(1-(1-ODDS[t-1][ct-1]/100.0/N[ct])**SLOTS[t-1]) if ct<=len(ODDS[t-1]) else 0 for ct in (1,1,2,3,5))
        exp+=e; out.append(exp)
    print(line, "expected flier offers seen (sum over shops, 5 fliers) cumulative by round:", " ".join("%.1f"%x for x in out))
