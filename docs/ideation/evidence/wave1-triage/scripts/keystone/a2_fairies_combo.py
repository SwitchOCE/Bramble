"""Fairies: engine combinations seen R8-R12, Ring size sources, and growth by group."""
import sys; sys.path.insert(0, '.')
from common import *
import collections, itertools
for line in ["line_fairies_ring", "line_fairies_court"]:
    bs = committed(line, 12)
    print("=====", line, len(bs))
    groups = collections.defaultdict(list)
    for b in bs:
        sr = BY_SEAT[(b['seed'], b['seat'])]
        A = seen(sr, {"old_moth_annis"}, 8, 12)
        C = seen(sr, {"cluricaun"}, 8, 12)
        M = seen(sr, {"fairy_monarch"}, 8, 12)
        Q = seen(sr, {"queen_of_elfland"}, 8, 12)
        L = seen(sr, {"lob_lie_by_the_fire", "silky"}, 8, 12)
        key = ("A" if A else "-") + ("C" if C else "-") + ("L" if L else "-") + ("M" if M else "-") + ("Q" if Q else "-")
        groups[key].append(b)
    print(" group  n  share  medR12  ringsize_med  rings_med  ratio_to_paper")
    for k, v in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        print(" %s %4d %5.1f%% %7.1f %5.1f %6.1f %5.2f" % (k, len(v), 100*len(v)/len(bs), med([b['stats'] for b in v]), med([b['ring_size'] for b in v]), med([sum(b['rings']) for b in v]), med([b['stats'] for b in v])/PAPER12[line]))
    # count engine (Annis) vs size engines
    def grp(f):
        w=[b for b in bs if f(BY_SEAT[(b['seed'],b['seat'])])]
        return w
    full = grp(lambda sr: seen(sr,{"old_moth_annis"},8,12) and seen(sr,{"cluricaun"},8,12) and seen(sr,{"fairy_monarch"},8,12))
    print(" Annis+Clu+Monarch seen:", len(full), "%.1f%%"%(100*len(full)/len(bs)), "median", med([b['stats'] for b in full]), "q90", q([b['stats'] for b in full], .9))
    none = grp(lambda sr: not seen(sr,{"old_moth_annis","cluricaun","fairy_monarch","queen_of_elfland","lob_lie_by_the_fire","silky"},8,12))
    print(" none of Annis/Clu/Mon/Queen/Lob/Silky:", len(none), "median", med([b['stats'] for b in none]))
    allst=[b['stats'] for b in bs]
    print(" all q10/25/50/75/90/97", [round(q(allst,p)) for p in (.1,.25,.5,.75,.9,.97)])
    # Ring size by size-source
    for k in ["cluricaun","lob_lie_by_the_fire","silky","fairy_monarch"]:
        w=[b['ring_size'] for b in bs if seen(BY_SEAT[(b['seed'],b['seat'])],{k},8,12)]
        wo=[b['ring_size'] for b in bs if not seen(BY_SEAT[(b['seed'],b['seat'])],{k},8,12)]
        print("  ring_size with %-20s mean %.2f med %.1f | without mean %.2f med %.1f" % (k, st.mean(w), med(w), st.mean(wo), med(wo)))
    # Monarch timing: first round seen on board
    first=[]
    for b in bs:
        sr=BY_SEAT[(b['seed'],b['seat'])]
        fr=[r for r in range(8,15) if r in sr and any(u[0]=='fairy_monarch' and u[6]=='board' for u in sr[r]['units'])]
        if fr: first.append(fr[0])
    print("  Monarch first seen round (R8-14):", sorted(collections.Counter(first).items()))
    # Rainbow by round
    for r in (8,9,10,11,12):
        bb=committed(line,r)
        print("  R%d rainbow %.1f%%  ring_size med %.1f mean %.2f  rings med %.0f  tier med %.0f" % (r, 100*sum(len(b['rings'])==7 and all(c>0 for c in b['rings']) for b in bb)/len(bb), med([b['ring_size'] for b in bb]), st.mean([b['ring_size'] for b in bb]), med([sum(b['rings']) for b in bb]), med([b['tier'] for b in bb])))
