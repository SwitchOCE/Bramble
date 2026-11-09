"""Birds: R12 boards with and without each Bird card; sky stats; homecomings."""
import sys; sys.path.insert(0, '.')
from common import *
import collections
KEYS = ["mrs_stork","mother_goose","great_lump","mr_redbreast","cuckoo","old_tern","chiffchaff","mrs_jay","one_swallow","mrs_dunnock","redwing","jack_daw","tom_tit","mag_pye","gabble_ratchet","seven_whistlers"]
for line in ["line_birds_homecoming","line_birds_tempo"]:
    bs = committed(line, 12)
    print("=====", line, len(bs), "median", med([b['stats'] for b in bs]), "paper", PAPER12[line])
    allst=[b['stats'] for b in bs]
    print(" q10/25/50/75/90/97", [round(q(allst,p)) for p in (.1,.25,.5,.75,.9,.97)])
    sky=[sum(u[2]+u[3] for u in b['units'] if u[6]=='away') for b in bs]
    hand=[sum(u[2]+u[3] for u in b['units'] if u[6]=='hand') for b in bs]
    print(" sky stats med", med(sky), "hand stats med", med(hand), " board+sky+hand med", med([b['stats']+s+h for b,s,h in zip(bs,sky,hand)]))
    nb=[sum(1 for u in b['units'] if u[6]=='board' and 'Birds' in u[8]) for b in bs]
    nn=[sum(1 for u in b['units'] if u[6]=='board' and 'Birds' not in u[8]) for b in bs]
    print(" Bird units on board med", med(nb), " non-Bird units on board med", med(nn))
    big=[max([u[2]+u[3] for u in b['units'] if u[6] in ('board','away','hand') and 'Birds' in u[8]] or [0]) for b in bs]
    print(" biggest Bird anywhere (board/sky/hand) q25/50/75/90", [round(q(big,p)) for p in (.25,.5,.75,.9)])
    hc=[b['home'] for b in bs]; print(" homecomings this round med/mean", med(hc), st.mean(hc))
    # cumulative homecomings R8-12
    cum=[sum((BY_SEAT[(b['seed'],b['seat'])].get(r) or {}).get('home',0) or 0 for r in range(8,13)) for b in bs]
    print(" homecomings R8-R12 total q25/50/75", q(cum,.25), med(cum), q(cum,.75))
    print(" %-18s %6s %7s %7s %5s | %6s %7s %7s" % ("card","onR12","med_w","med_wo","n_w","seen","med_wS","med_woS"))
    for k in KEYS:
        w=[b['stats'] for b in bs if k in on_board(b,[k])]
        wo=[b['stats'] for b in bs if k not in on_board(b,[k])]
        sw=[b['stats'] for b in bs if seen(BY_SEAT[(b['seed'],b['seat'])],{k},8,12,("board","away","hand"))]
        swo=[b['stats'] for b in bs if not seen(BY_SEAT[(b['seed'],b['seat'])],{k},8,12,("board","away","hand"))]
        print(" %-18s %5.1f%% %7.1f %7.1f %5d | %5.1f%% %7.1f %7.1f" % (k, 100*len(w)/len(bs), med(w), med(wo), len(w), 100*len(sw)/len(bs), med(sw), med(swo)))
