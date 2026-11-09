# Breaker check: wild design with common extra copies (2nd Cluricaun, 2nd Monarch). Same model as fairies-wild-model.py, plus a clur count.
import sys
T={6:53,7:79,8:123,9:194,10:305,11:482,12:759,13:1177,14:1751,15:2600,16:3900}
base={1:3,2:6,3:10,4:15,5:21,6:27,7:33,8:40,9:46,10:52,11:58,12:65,13:71,14:77,15:83,16:89}
def run(label, ev, g=1, mon_period=3, mon_mult=2, lob_div=2, bumps={7:1,10:1,11:1}):
    C=0; cy=0; S=1; lob=None; rainbow=False; mons=[]; clur=0; out={}
    for r in range(1,17):
        e=ev.get(r,{})
        C+=e.get('r',0); cy+=e.get('c',0)
        if e.get('rainbow'): rainbow=True
        clur+=e.get('clur',0)
        if e.get('lob'): lob=0
        if e.get('lobthank'): S+=g*e['lobthank']*(lob//lob_div); lob=None
        S+=bumps.get(r,0)
        for _ in range(e.get('mon',0)): mons.append(r)
        C+=e.get('er',0); cy+=e.get('ec',0)
        if rainbow: S+=g*clur
        if lob is not None: lob+=1
        for m in mons:
            if (r-m)%mon_period==mon_period-1: S*=mon_mult
        out[r]=(C,S,base[r]+2*C*S)
    print(label)
    print("  "+"  ".join("R%d %d (%.1fx)"%(r,out[r][2],out[r][2]/T[r]) for r in (9,10,12,13,14,15)))
    return out
A={1:dict(r=1,c=1), 3:dict(er=1,ec=1), 4:dict(er=2,ec=1),
   5:dict(r=1,c=1,er=2,ec=1,lob=1), 6:dict(r=2,er=2,ec=1,clur=1),
   7:dict(r=2+3,c=3,er=2,ec=1,rainbow=1), 8:dict(r=2,c=2,er=2,ec=1),
   9:dict(r=2,c=2,er=1,ec=1), 10:dict(lobthank=1,r=3,c=3,er=1,ec=1),
   11:dict(mon=1,r=2,c=2,er=1,ec=1), 12:dict(r=3,c=3,er=1,ec=1),
   13:dict(r=3,c=3,er=1,ec=1), 14:dict(r=4,c=4,er=1,ec=1),
   15:dict(r=4,c=4,er=1,ec=1), 16:dict(r=4,c=4,er=1,ec=1)}
import copy
run("designer's typical (1 Cluricaun, 1 Monarch R11)",A)
B=copy.deepcopy(A); B[8]['clur']=1
run("+ 2nd Cluricaun R8 (T3, 13 copies)",B)
C=copy.deepcopy(A); C[13]['mon']=1
run("+ 2nd Monarch R13",C)
D=copy.deepcopy(B); D[13]['mon']=1
run("+ 2nd Cluricaun R8 and 2nd Monarch R13",D)
E=copy.deepcopy(D); E[10]['clur']=1
run("+ 3 Cluricauns (R6, R8, R10) and 2 Monarchs",E)
