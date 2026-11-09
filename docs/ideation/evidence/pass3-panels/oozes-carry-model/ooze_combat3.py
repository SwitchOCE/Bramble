"""Extension of the audit's Bramble combat model (docs/ideation/evidence/fundamentals-audit/scripts/bramble_combat.py),
copied, with pass 3 Ooze effects:
  split (on death once: two copies with frac of max stats; first in own slot, second nearest empty, 8.4.2),
  inside (Belly reserve spec that comes out on death, first into own slot),
  swallow (Start of Combat: remove the biggest enemy, A+H, any row; returns to its slot when this dies),
  curdle (on death: killer loses half Attack; golden also half Health),
  shield, cleave, dr_pct (percent damage reduction).
"""
import random
FRONT=(0,1,2,3)
ADJ=((1,),(0,2),(1,3),(2,),(5,),(4,6),(5,))
NEAR={0:[1,2,3,4,5,6],1:[2,0,3,5,4,6],2:[3,1,0,6,5,4],3:[2,1,0,6,5,4],4:[5,6,1,0,2,3],5:[6,4,2,1,3,0],6:[5,4,3,2,1,0]}
class U:
    def __init__(s,a,h,slot,kw=None,start=True):
        s.a=a; s.h=h; s.maxh=h; s.slot=slot; s.flag=False; s.start=start; s.kw=dict(kw or {})
        s.shield=bool(s.kw.get("shield")); s.held=None
def make_side(board):
    side={}
    for slot,spec in enumerate(board):
        if spec is None: continue
        side[slot]=U(spec[0],spec[1],slot,spec[2] if len(spec)>2 else None)
    return side
def fight(b0,b1,rng,attack_limit=300,first=None):
    sides=[make_side(b0),make_side(b1)]
    if first is None:
        n0,n1=len(sides[0]),len(sides[1])
        first=0 if n0>n1 else 1 if n1>n0 else rng.randint(0,1)
    pointer=[-1,-1]; attacks=0; last_blow=-1; active=first
    def place(s,u,slot,src):
        if slot not in sides[s]: u.slot=slot
        else:
            free=[k for k in NEAR[src] if k not in sides[s]]
            if not free: return False
            u.slot=free[0]
        u.flag = u.slot < pointer[s]
        sides[s][u.slot]=u; return True
    # Start of Combat: swallows, side 'first' then other, reading order
    for s in (first,1-first):
        for k in sorted(sides[s]):
            u=sides[s].get(k)
            if u and u.kw.get("swallow") and u.held is None:
                en=sides[1-s]
                if en:
                    big=max(en.values(),key=lambda v:(v.a+v.h,-v.slot))
                    del en[big.slot]; u.held=(1-s,big)
    for s in (0,1):
        for k in sorted(list(sides[s])):
            g=sides[s].get(k)
            if g and g.kw.get("gather"):
                fam=[u for u in list(sides[s].values()) if u is not g and u.kw.get("ooze")]
                for u in fam:
                    del sides[s][u.slot]
                    g.a+=u.a*g.kw["gather"]
                    if g.kw.get("gather_health"): g.h+=u.h*g.kw["gather"]; g.maxh=g.h
                g.fam=fam
    def choose_attacker(s):
        units=[sides[s][k] for k in sorted(sides[s])]
        ready=[u for u in units if u.a>0]
        if not ready: return None
        att=next((u for u in ready if not u.flag),None)
        if att is None:
            for u in units: u.flag=False
            att=ready[0]
        pointer[s]=att.slot
        for u in units:
            if u.slot<=att.slot: u.flag=True
        return att
    def choose_target(s):
        en=sides[1-s]
        front=[en[k] for k in sorted(en) if k in FRONT]
        c=front if front else [en[k] for k in sorted(en)]
        return c[rng.randrange(len(c))] if c else None
    def hit(t,amt,src=None):
        if amt<=0: return
        if t.kw.get("dr_pct"): amt-= (amt*t.kw["dr_pct"])//100
        amt-=t.kw.get("dr",0)
        if amt<=0: return
        if t.shield: t.shield=False; return
        t.h-=amt
        if t.h<=0 and src is not None: t.killer=src
    def resolve(s_act):
        for s in (s_act,1-s_act):
            dead=[u for u in list(sides[s].values()) if u.h<=0]
            for u in dead: del sides[s][u.slot]
            for u in dead:
                k=getattr(u,"killer",None)
                if u.kw.get("curdle") and k is not None and k.h>0:
                    k.a=max(0,k.a-k.a//2)
                    if u.kw["curdle"]>=2: k.h=max(1,k.h-k.h//2); k.maxh=max(1,k.maxh-k.maxh//2)
                src=u.slot
                if u.kw.get("inside"):
                    sp=u.kw["inside"]; nu=U(sp[0],sp[1],src,sp[2] if len(sp)>2 else None,start=False)
                    place(s,nu,src,src)
                if u.kw.get("split") and not u.kw.get("is_copy"):
                    f=u.kw["split"]
                    for i in range(2):
                        kw=dict(u.kw); kw["is_copy"]=True; kw.pop("inside",None); kw.pop("swallow",None)
                        nu=U(max(1,int(u.a_max*f)) if hasattr(u,'a_max') else max(1,int(u.a*f)), max(1,int(u.maxh*f)), src, kw, start=False)
                        place(s,nu,src,src)
                for v in getattr(u,"fam",[]) or []:
                    v.flag=v.slot<pointer[s]; place(s,v,v.slot,v.slot)
                u.fam=[]
                if u.held is not None:
                    side_i,v=u.held; u.held=None
                    v.flag = v.slot < pointer[side_i]
                    place(side_i,v,v.slot,v.slot)
    def one(s,att):
        nonlocal last_blow
        d=choose_target(s)
        if d is None: return
        hit(d,att.a,att)
        if att.kw.get("cleave"):
            for k in ADJ[d.slot]:
                v=sides[1-s].get(k)
                if v is not None: hit(v,att.a,att)
        hit(att,d.a,d)
        for side_i,u in ((1-s,d),(s,att)):
            if u.kw.get("bubble") and u.h>0 and u.slot in sides[side_i] and sides[side_i][u.slot] is u and u.kw["bubble"]>0:
                free=[k for k in NEAR[u.slot] if k not in sides[side_i]]
                if free:
                    u.kw["bubble"]-=1
                    na,nh=u.a//2,u.h//2
                    kw={k:v for k,v in u.kw.items() if k not in ("inside","bubble","swallow")}
                    c=U(u.a-na,u.h-nh,free[0],kw,start=False); u.a,u.h=na,nh
                    c.flag=c.slot<pointer[side_i]; sides[side_i][c.slot]=c
        last_blow=s; resolve(s)
    # record attack at start for split copies
    for s in (0,1):
        for u in sides[s].values(): u.a_max=u.a
    while True:
        if not sides[0] or not sides[1]: break
        if not any(u.a>0 for u in sides[0].values()) and not any(u.a>0 for u in sides[1].values()):
            return {"winner":-1}
        if attacks>=attack_limit: return {"winner":-1}
        att=choose_attacker(active)
        if att is not None:
            attacks+=1; one(active,att)
        active=1-active
    if sides[0] and not sides[1]: return {"winner":0}
    if sides[1] and not sides[0]: return {"winner":1}
    return {"winner":last_blow}
def match(b0,b1,n=4000,seed=7):
    rng=random.Random(seed); w=t=0
    for i in range(n):
        if i%2==0: r=fight(b0,b1,rng); me=0
        else: r=fight(b1,b0,rng); me=1
        if r["winner"]==me: w+=1
        elif r["winner"]==-1: t+=1
    return 100*w/n, 100*t/n
