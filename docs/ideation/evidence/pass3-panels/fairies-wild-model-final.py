exec(open(__file__.replace("fairies-wild-model-final.py","fairies-wild-model.py")).read().split("a=run(")[0])
# Final line A ('fairy_ring'): + Silky (T3, R6): +1 size at each Shy departure: Hob R7, Lob R10, Silky herself R11
A={1:dict(r=1,c=1), 3:dict(er=1,ec=1), 4:dict(er=2,ec=1),
   5:dict(r=1,c=1,er=2,ec=1,lob=1), 6:dict(r=2,er=2,ec=1,clur=1),
   7:dict(r=2+3,c=3,er=2,ec=1,rainbow=1,lobthank=0),  # Hob thanked on B1: 4 turns -> 3 rings (R3-R6) [counted in r/c]
   8:dict(r=2,c=2,er=2,ec=1),
   9:dict(r=2,c=2,er=1,ec=1), 10:dict(lobthank=1,r=3,c=3,er=1,ec=1),
   11:dict(mon=1,r=2,c=2,er=1,ec=1), 12:dict(r=3,c=3,er=1,ec=1),
   13:dict(r=3,c=3,er=1,ec=1), 14:dict(r=4,c=4,er=1,ec=1),
   15:dict(r=4,c=4,er=1,ec=1), 16:dict(r=4,c=4,er=1,ec=1)}
# emulate silky +1 size at R7, R10, R11 by adding to lobthank-like bumps: patch run via extra 'sz'
def run2(label, ev, base, **kw):
    import copy
    ev=copy.deepcopy(ev)
    return ev
# simple: add size bumps manually by wrapping
import math
def runS(label, ev, base, bumps, g=1, mon_period=3, mon_mult=2, lob_div=2):
    C=0; cy=0; S=1; lob=None; rainbow=False; mons=[]; out={}; clur=False
    for r in range(1,17):
        e=ev.get(r,{})
        C+=e.get('r',0); cy+=e.get('c',0)
        if e.get('rainbow'): rainbow=True
        if e.get('clur'): clur=True
        if e.get('lob'): lob=0
        if e.get('lobthank'): S+=g*e['lobthank']*(lob//lob_div); lob=None
        S+=bumps.get(r,0)
        if e.get('mon'): mons.append(r)
        C+=e.get('er',0); cy+=e.get('ec',0)
        if rainbow and clur: S+=g
        if lob is not None: lob+=1
        for m in mons:
            if (r-m)%mon_period==mon_period-1: S*=mon_mult
        tot=base[r]+2*C*S; cs=2*cy*S+6; out[r]=(C,cy,S,tot,cs)
    print(label)
    for r in (6,7,8,9,10,11,12,13,14,15,16):
        C,cy,S,tot,cs=out[r]
        print(" R%2d rings %3d (carry %3d) size %4d | board %6d = %.2fx | carry %5d (%2.0f%%)"%(r,C,cy,S,tot,tot/T[r],cs,100*cs/tot))
    print()
runS("FINAL fairy_ring: Hob bank, Lob per 2 turns, Silky +1 per departure, Cluricaun, Monarch R11",A,base,{7:1,10:1,11:1})
