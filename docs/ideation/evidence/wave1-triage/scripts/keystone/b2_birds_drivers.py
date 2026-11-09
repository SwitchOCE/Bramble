"""Birds: what drives homecoming size. Homecomings, fliers owned, biggest Bird, by Stork/Goose/Cuckoo."""
import sys; sys.path.insert(0, '.')
from common import *
import collections
FLIERS={"one_swallow","chiffchaff","mrs_jay","old_tern","mother_goose"}
ENG={"S":"mrs_stork","G":"mother_goose","C":"cuckoo","L":"great_lump"}
for line in ["line_birds_homecoming","line_birds_tempo"]:
    bs=committed(line,12)
    print("=====",line,len(bs))
    rows=[]
    for b in bs:
        sr=BY_SEAT[(b['seed'],b['seat'])]
        hc=sum((sr.get(r) or {}).get('home',0) or 0 for r in range(8,13))
        fl=sum(1 for u in b['units'] if u[0] in FLIERS and u[6] in ('board','away','hand'))
        flst=sum(u[2]+u[3] for u in b['units'] if u[0] in FLIERS and u[6] in ('board','away','hand'))
        big=max([u[2]+u[3] for u in b['units'] if u[6] in ('board','away','hand') and 'Birds' in u[8]] or [0])
        key="".join(k if seen(sr,{v},8,12,("board","away","hand")) else "-" for k,v in ENG.items())
        rows.append((key,b['stats'],hc,fl,flst,big,b['tier'],b['gold']))
    g=collections.defaultdict(list)
    for r in rows: g[r[0]].append(r)
    print(" group(S=Stork G=Goose C=Cuckoo L=Lump)  n share  medR12  ratio  homecomingsR8-12  fliers  flierStats  biggestBird")
    for k,v in sorted(g.items(), key=lambda kv:-len(kv[1])):
        print("  %s %4d %5.1f%% %6.0f %5.2f %5.1f %4.1f %6.0f %6.0f" % (k,len(v),100*len(v)/len(rows),med([x[1] for x in v]),med([x[1] for x in v])/PAPER12[line],med([x[2] for x in v]),med([x[3] for x in v]),med([x[4] for x in v]),med([x[5] for x in v])))
    # Stork effect on homecomings
    for k,v in ENG.items():
        w=[r for r in rows if k in r[0]]; wo=[r for r in rows if k not in r[0]]
        print("  %s seen %.1f%%: homecomings med %.1f vs %.1f; biggest %.0f vs %.0f; stats %.0f vs %.0f" % (v,100*len(w)/len(rows),med([x[2] for x in w]),med([x[2] for x in wo]),med([x[5] for x in w]),med([x[5] for x in wo]),med([x[1] for x in w]),med([x[1] for x in wo])))
    # fliers owned bins
    for n in range(0,7):
        v=[r for r in rows if r[3]==n]
        if v: print("  fliers owned=%d n=%d medR12 %.0f homecomings %.1f biggest %.0f" % (n,len(v),med([x[1] for x in v]),med([x[2] for x in v]),med([x[5] for x in v])))
    # gold spent
    print("  gold spent by R12 med", med([r[7] for r in rows]))
    # by R8-R12 homecomings bins
    for lo,hi in ((0,1),(2,3),(4,5),(6,7),(8,20)):
        v=[r for r in rows if lo<=r[2]<=hi]
        if v: print("  homecomings %d-%d n=%d (%.0f%%) medR12 %.0f biggest %.0f" % (lo,hi,len(v),100*len(v)/len(rows),med([x[1] for x in v]),med([x[5] for x in v])))
