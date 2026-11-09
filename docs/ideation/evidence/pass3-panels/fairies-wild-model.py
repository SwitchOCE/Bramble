# Final pass-3 wild Fairies model. Rings: count per slot x Ring size S (player-level, retroactive).
import math
T={6:53,7:79,8:123,9:194,10:305,11:482,12:759,13:1177,14:1751,15:2600,16:3900}
def run(label, ev, base, g=1, mon_period=3, mon_mult=2, lob_div=1, show=True):
    C=0; cy=0; S=1; lob=None; rainbow=False; mons=[]; queen=None; perm=0; clur=False
    out={}
    for r in range(1,17):
        e=ev.get(r,{})
        C+=e.get('r',0); cy+=e.get('c',0)
        if e.get('rainbow'): rainbow=True
        if e.get('clur'): clur=True
        if e.get('lob'): lob=0
        if e.get('lobthank'): S+=g*e['lobthank']*(lob//lob_div); lob=None
        if e.get('mon'): mons.append(r)
        if e.get('queen'): queen=r
        C+=e.get('er',0); cy+=e.get('ec',0)
        if rainbow and clur: S+=g
        if lob is not None: lob+=1
        for m in mons:
            if (r-m)%mon_period==mon_period-1: S*=mon_mult
        if queen is not None and (r-queen)%3==2:
            k=(C-cy)/6.0
            perm+= 2*(2*k*S+6)
        tot=base[r]+2*C*S+perm
        cs=2*cy*S+6
        out[r]=(C,cy,S,tot,cs)
    if show:
        print(label)
        for r in (5,6,7,8,9,10,11,12,13,14,15,16):
            C,cy,S,tot,cs=out[r]
            print(" R%2d rings %3d (carry slot %3d) size %4d | board %6d = %.2fx target | carry %5d (%2.0f%%)"%(r,C,cy,S,tot,tot/T.get(r,tot),cs,100*cs/tot))
        print()
    return out
base={1:3,2:6,3:10,4:15,5:21,6:27,7:33,8:40,9:46,10:52,11:58,12:65,13:71,14:77,15:83,16:89}
A={1:dict(r=1,c=1), 3:dict(er=1,ec=1), 4:dict(er=2,ec=1),
   5:dict(r=1,c=1,er=2,ec=1,lob=1), 6:dict(r=2,er=2,ec=1,clur=1),
   7:dict(r=2,er=2,ec=1,rainbow=1), 8:dict(r=2,c=2,er=2,ec=1),
   9:dict(r=2,c=2,er=1,ec=1), 10:dict(lobthank=1,r=3,c=3,er=1,ec=1),
   11:dict(mon=1,r=2,c=2,er=1,ec=1), 12:dict(r=3,c=3,er=1,ec=1),
   13:dict(r=3,c=3,er=1,ec=1), 14:dict(r=4,c=4,er=1,ec=1),
   15:dict(r=4,c=4,er=1,ec=1), 16:dict(r=4,c=4,er=1,ec=1)}
a=run("A  Fairy Ring (engine/carry): Lob per turn",A,base)
a2=run("A' Fairy Ring: Lob per 2 turns",A,base,lob_div=2)
# B: Court (tempo). Annis F2 2/turn from R3, Sally R4-R6, rainbow R7 with Cluricaun, Chaser sold R7,
# Queen R11, Monarch R13 (found late), Lob not taken.
B={1:dict(r=1), 3:dict(er=2), 4:dict(er=3), 5:dict(r=2,er=3), 6:dict(r=1,er=3,clur=1),
   7:dict(r=2,er=2,rainbow=1), 8:dict(r=2,er=2), 9:dict(r=2,er=2), 10:dict(r=3,er=2),
   11:dict(r=2,er=2,queen=1), 12:dict(r=3,er=2), 13:dict(r=3,er=2,mon=1), 14:dict(r=3,er=2),
   15:dict(r=4,er=2), 16:dict(r=4,er=2)}
b=run("B  Fairy Court (tempo): Queen R11, Monarch R13",B,base)
Bn={k:dict(v) for k,v in B.items()}; Bn[13].pop('mon')
run("B' Fairy Court without Monarch",Bn,base)
# Low roll A: no Lob, rainbow late R10, Monarch R13
L={k:dict(v) for k,v in A.items()}; L[5].pop('lob'); L[10].pop('lobthank'); L[7].pop('rainbow'); L[10]['rainbow']=1; L[11].pop('mon'); L[13]['mon']=1
run("A low: no Lob, rainbow R10, Monarch R13",L,base)
H={k:dict(v) for k,v in A.items()}; H[10]['lobthank']=2
run("A high: golden Lob, golden Monarch (triple)",H,base,mon_mult=3)
X={k:dict(v) for k,v in A.items()}; X[10]['lobthank']=2; X[11].pop('mon'); X[10]['mon']=1; X[12]['mon']=1
run("A top 1%: two Monarchs R10+R12, golden Lob",X,base)
# per-card helpers at R9/R12/R15 using line A sizes
for r in (9,12,15):
    C,cy,S,tot,cs=a[r]
    print("R%d: S=%d C=%d carry rings=%d  one Ring = +%d/+%d"%(r,S,C,cy,S,S))
print("==== with Lob per 2 turns (default) ====")
run("A low",L,base,lob_div=2)
run("A high: golden Lob, golden Monarch",H,base,mon_mult=3,lob_div=2)
run("A top1%: two Monarchs, golden Lob",X,base,lob_div=2)
run("A smooth Monarch variant (+quarter each EoT ~ x1.26): use period 1 mult 1.26",A,base,lob_div=2,mon_period=1,mon_mult=1.26)
