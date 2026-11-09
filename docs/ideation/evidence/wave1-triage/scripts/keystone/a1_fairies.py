"""Fairies: keystone presence and R12 boards with and without each keystone."""
import sys; sys.path.insert(0, '.')
from common import *
import collections, math
KEYS = ["old_moth_annis", "cluricaun", "fairy_monarch", "queen_of_elfland", "lob_lie_by_the_fire", "silky", "cradle_fetch", "nan_toadstool", "sally_spore", "rainbow_chaser", "hob_in_the_hearth", "belladonna", "changeling", "will_o_the_wisp", "reel_mistress", "hedge_witch"]
for line in ["line_fairies_ring", "line_fairies_court"]:
    bs = committed(line, 12)
    print("=====", line, "R12 survivors", len(bs), "median", med([b['stats'] for b in bs]), "paper", PAPER12[line])
    rs = [b['ring_size'] for b in bs]
    print(" ring_size quartiles", q(rs,.1), q(rs,.25), med(rs), q(rs,.75), q(rs,.9))
    print(" ring_size dist", sorted(collections.Counter(rs).items()))
    nr = [sum(b['rings']) for b in bs]
    print(" total rings q10/25/50/75/90", q(nr,.1), q(nr,.25), med(nr), q(nr,.75), q(nr,.9))
    rainbow = [all(c>0 for c in b['rings']) and len(b['rings'])==7 for b in bs]
    print(" rainbow at R12", sum(rainbow)/len(bs))
    print(" tier6 at R12", sum(b['tier']==6 for b in bs)/len(bs))
    # ring stats on occupied slots vs body
    ringpart=[]; bodypart=[]
    for b in bs:
        occ = {u[5] for u in b['units'] if u[6]=='board' and u[7]}
        rp = sum(2*math.ceil(c*b['ring_size']) for i,c in enumerate(b['rings']) if i in occ)
        ringpart.append(rp); bodypart.append(b['stats']-rp)
    print(" median ring stats on occupied slots", med(ringpart), " median body stats", med(bodypart), " ring share of median-ish", med([r/max(1,r+bd) for r,bd in zip(ringpart,bodypart)]))
    print(" %-22s %7s %7s %7s %7s %7s | seenR8-12 %7s %7s" % ("card","onR12%","med_w","med_wo","n_w","n_wo","seen%","med_wSeen"))
    for k in KEYS:
        w=[b['stats'] for b in bs if k in on_board(b,[k])]
        wo=[b['stats'] for b in bs if k not in on_board(b,[k])]
        sw=[b['stats'] for b in bs if seen(BY_SEAT[(b['seed'],b['seat'])], {k}, 8, 12)]
        print(" %-22s %6.1f%% %7.1f %7.1f %7d %7d | %6.1f%% %7.1f" % (k, 100*len(w)/len(bs), med(w), med(wo), len(w), len(wo), 100*len(sw)/len(bs), med(sw)))
