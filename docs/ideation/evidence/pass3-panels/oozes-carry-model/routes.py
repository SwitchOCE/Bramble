# Two Ooze lines under the pass 3 cards. Stats are A+H totals; carry kept square.
# r: Stone Soup fraction; e: Elder fraction; s: Cut-and-Come-Again slice; aspic: eat multiplier.
import itertools
BASE={1:5,2:6.5,3:8,4:9.5,5:11,6:13}
def line(r,e,s,route,verbose=False, aspic_on=True, nell_on=True, cut_on=True):
    tiers={1:1,2:1,3:2,4:2,5:3,6:3,7:4,8:4,9:5,10:5,11:6,12:6,13:6,14:6,15:6,16:6}
    C=3.0; pending=0.0
    sup=[]  # supports (not the carry): list of stats; oozes flagged
    rows=[]
    for t in range(1,17):
        tier=tiers[t]
        # Start of Turn: digest
        mult = 2.0 if (aspic_on and route=='carry' and t>=6) else 1.0
        C += pending*mult; pending=0.0
        soup = t>=3
        S = (r*C if soup else 0.0)
        # Cut-and-Come-Again slice (from R12): carry route feeds it, pot route plays it
        if cut_on and t>=12:
            sl = s*C
            if route=='carry': pending += sl
            else: sup.append(sl)
        # bought meals
        if route=='carry':
            meals = {2:1,3:1,4:1,5:1,6:1,7:1,8:2,9:1,10:2,11:1,12:2,13:2,14:2,15:2,16:2}.get(t,0)
            buys  = {1:0,2:0,3:1,4:1,5:1,6:1,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,15:1,16:1}.get(t,0)
        else: # pot: fewer meals, more support buys, Oozes into Bellies
            meals = {2:1,3:1,4:1,5:1,6:0,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,15:1,16:1}.get(t,0)
            buys  = {1:1,2:1,3:1,4:1,5:1,6:2,7:1,8:2,9:1,10:2,11:1,12:2,13:2,14:2,15:2,16:2}.get(t,0)
        pending += meals*(BASE[1]+S)
        for _ in range(buys):
            sup.append(BASE[tier]+S)
        # End of Turn: Nell eats biggest leftover into the carry
        if nell_on and t>=4:
            C += (BASE[tier]+r*C)*mult
        # Elder: other Oozes gain e*C (assume 4 of the 6 supports are Oozes, plus reserves for pot)
        cap = 6 if route=='carry' else 10   # pot route keeps ~4 reserves inside Bellies
        sup.sort(reverse=True); sup=sup[:cap]
        if t>=10:
            n_ooze = 4 if route=='carry' else 7
            for i in range(min(n_ooze,len(sup))): sup[i]+=e*C
        board_sup = sorted(sup,reverse=True)[:6]
        board = C+sum(board_sup)
        inside = sum(sorted(sup,reverse=True)[6:])
        rows.append(dict(t=t,C=C,S=S,avg=sum(board_sup)/max(1,len(board_sup)),board=board,share=C/board,inside=inside))
    return rows
def show(rows,label):
    print(label)
    print("  rnd  carry(A/H)  shop+  avgSupport  board  carry%  inside")
    for x in rows:
        if x['t'] in (4,6,8,9,10,12,13,14,15):
            print("  %3d  %5d/%-5d %5.0f   %7.0f   %6.0f   %3.0f%%  %5.0f"%(x['t'],x['C']/2,x['C']/2,x['S'],x['avg'],x['board'],100*x['share'],x['inside']))
import sys
for r,e,s in [(0.10,0.10,0.25),(0.125,0.10,0.2),(0.10,0.05,0.2)]:
    show(line(r,e,s,'carry'),"CARRY r=%.3f e=%.2f s=%.2f"%(r,e,s))
    show(line(r,e,s,'pot'),"POT   r=%.3f e=%.2f s=%.2f"%(r,e,s))
print("target strong board (BG Sep 2025 means): R6 53, R8 123, R9 194, R10 305, R12 759, R13 1177, R14 1751, R15 ~2600")

def line2(r,e,s,route,aspic=1.5,aspic_from=6,nell_mult=False,nell_from=4):
    tiers={1:1,2:1,3:2,4:2,5:3,6:3,7:4,8:4,9:5,10:5,11:6,12:6,13:6,14:6,15:6,16:6}
    C=3.0; pending=0.0; sup=[]; rows=[]
    for t in range(1,17):
        tier=tiers[t]
        mult = aspic if (route=='carry' and t>=aspic_from) else 1.0
        C += pending*mult; pending=0.0
        S = r*C if t>=3 else 0.0
        if t>=12:
            sl=s*C
            if route=='carry': pending+=sl
            else: sup.append(sl)
        if route=='carry':
            meals={2:1,3:1,4:1,5:1,6:1,7:1,8:2,9:1,10:2,11:1,12:2,13:2,14:2,15:2,16:2}.get(t,0)
            buys={3:1,4:1,5:1,6:1,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,15:1,16:1}.get(t,0)
        else:
            meals={2:1,3:1,4:1,5:1,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,15:1,16:1}.get(t,0)
            buys={1:1,2:1,3:1,4:1,5:1,6:2,7:1,8:2,9:1,10:2,11:1,12:2,13:2,14:2,15:2,16:2}.get(t,0)
        pending += meals*(BASE[1]+S)
        for _ in range(buys): sup.append(BASE[tier]+S)
        if t>=nell_from:
            C += (BASE[tier]+r*C)*(mult if nell_mult else 1.0)
        cap = 6 if route=='carry' else 10
        sup.sort(reverse=True); sup=sup[:cap]
        if t>=10:
            n_ooze = 4 if route=='carry' else 7
            for i in range(min(n_ooze,len(sup))): sup[i]+=e*C
        bs=sorted(sup,reverse=True)[:6]
        board=C+sum(bs)
        rows.append(dict(t=t,C=C,S=S,avg=sum(bs)/max(1,len(bs)),board=board,share=C/board,inside=sum(sorted(sup,reverse=True)[6:])))
    return rows
tgt={6:53,9:194,12:759,15:2600}
best=[]
for r in (0.05,0.0625,0.075,0.1,0.125):
  for a in (1.0,1.5,2.0):
    for e in (0.05,0.1):
      for s in (0.1,0.2,0.25):
        for nf in (4,5,6):
          rows=line2(r,e,s,'carry',aspic=a,nell_from=nf)
          b={x['t']:x['board'] for x in rows}
          import math
          err=sum((math.log(b[k]/tgt[k]))**2 for k in tgt)
          best.append((err,r,a,e,s,nf,[round(b[k]) for k in (6,9,12,15)],round(100*rows[11]['share'])))
best.sort()
print("best carry-route settings (err, r, aspic, e, s, nell_from, boards R6/9/12/15, carry share R12)")
for x in best[:12]: print(x)
print()
print("Soup a tenth, Elder a tenth, slice a fifth: carry line by what the player found")
for label,kw in [("no Aspic, Nell R6",dict(aspic=1.0,nell_from=6)),
                 ("Aspic x2 from R6, Nell R6",dict(aspic=2.0,nell_from=6)),
                 ("Aspic x1.5, Nell R6",dict(aspic=1.5,nell_from=6)),
                 ("no Aspic, no Nell",dict(aspic=1.0,nell_from=99)),
                 ("Aspic x2 from R5, Nell R4 (highroll)",dict(aspic=2.0,aspic_from=5,nell_from=4))]:
    rows=line2(0.1,0.1,0.2,'carry',**kw)
    b={x['t']:x for x in rows}
    print("  %-38s"%label, " ".join("R%d %5.0f (carry %4.0f/%-4.0f %2.0f%%)"%(k,b[k]['board'],b[k]['C']/2,b[k]['C']/2,100*b[k]['share']) for k in (6,9,12,15)))
rows=line2(0.1,0.1,0.2,'pot',nell_from=6)
b={x['t']:x for x in rows}
print("  %-38s"%"POT line, Nell R6", " ".join("R%d %5.0f (pot %4.0f/%-4.0f %2.0f%%)"%(k,b[k]['board'],b[k]['C']/2,b[k]['C']/2,100*b[k]['share']) for k in (6,9,12,15)))
for k in (9,12,15): print("   pot R%d avg support %.0f, inside reserves total %.0f"%(k,b[k]['avg'],b[k]['inside']))
