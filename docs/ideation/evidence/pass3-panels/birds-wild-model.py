"""Birds pass 3 (birds-wild.md): growth calculator behind the R6/R9/R12/R15 boards.
Not a combat sim. Usage: python3 birds-wild-model.py [r=0.5] [lump=0.25]
Round t = recruit turn t -> End of Turn t -> fight t. A Bird flown on turn s Grows at each
End of Turn away; Stork recall = Grow + home now; Cuckoo = Grow when it flies; Tern landing =
other Birds away Grow; Golden Egg = x2; Lump eats lump*its Bird at End of Turn; Redbreast +1/+1
per Bird away each End of Turn; Supper +1/+1 tribe bonus at R8, R10, R12 (cap +3/+3)."""
import math, sys
R = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
LF = float(sys.argv[2]) if len(sys.argv) > 2 else 0.25
def up(x): return int(math.ceil(x))
class B:
    def __init__(s,n,a,h,t0): s.n=n;s.a=a;s.h=h;s.t0=t0;s.away=False;s.due=None
    def g(s,k=1):
        for _ in range(k): s.a=up(s.a*(1+R)); s.h=up(s.h*(1+R))
def sim(spec, events, supper, rounds=16, title=""):
    U={n:B(n,a,h,t0) for n,(a,h,t0) in spec.items()}
    snap={}; tribe=0
    for t in range(1,rounds+1):
        for u in U.values():
            if u.away and u.due==t: u.away=False
        if t in supper: tribe=min(3,tribe+1)
        for ev in events.get(t,[]):
            op=ev[0]; u=U.get(ev[1]) if len(ev)>1 else None
            if op=='fly': u.away=True; u.due=t+ev[2]; u.g(ev[3] if len(ev)>3 else 0)
            elif op=='stork': u.g(1); u.away=False
            elif op=='egg': u.a*=2; u.h*=2
            elif op=='add': u.a+=ev[2]; u.h+=ev[3]
            elif op=='tern':
                for v in U.values():
                    if v.away and v.n!=ev[1] and v.t0<=t: v.g(1)
            elif op=='gone': u.t0=999
        aw=[u for u in U.values() if u.away and u.t0<=t]
        for u in aw: u.g(1)
        for u in U.values():
            if u.t0>t or u.away: continue
            if u.n.startswith('Redbreast'): u.a+=len(aw); u.h+=len(aw)
            if u.n.startswith('Lump') and aw:
                b=max(aw,key=lambda v:v.a+v.h); u.a+=up(b.a*LF); u.h+=up(b.h*LF)
        snap[t]={u.n:(u.a+tribe,u.h+tribe,u.away) for u in U.values() if u.t0<=t}
    return snap
def board(snap,t,home,eggs,label):
    s=snap[t]; tot=0; parts=[]
    for n in home:
        a,h,aw=s[n]; assert not aw, (t,n); tot+=a+h; parts.append(f"{n} {a}/{h}")
    for n,kind in eggs:
        a,h,aw=s[n]; assert aw,(t,n)
        ea = a if 'A' in kind else (up(a/2) if 'a' in kind else 0); eh = h if 'H' in kind else 1
        tot+=ea+eh; parts.append(f"Egg({n}) {ea}/{eh}")
    away=[f"{n} {a}/{h}" for n,(a,h,aw) in s.items() if aw]
    big=max(((s[n][0]+s[n][1],n) for n in home))
    print(f"R{t} {label}: {tot} stats in {len(home)+len(eggs)} slots; biggest {big[1]} ({big[0]}, {100*big[0]//tot}%)")
    print("   ", "; ".join(parts)); print("    sky:", ", ".join(away) or "-")
    return tot





# Line 1, Homecoming (tempo -> Golden Egg carry), typical roll: T4 R7, T5 R10, T6 R12
S1={'Chiffchaff':(2,3,1),'Redbreast':(2,4,3),'Swallow':(1,2,3),'Dunnock':(2,3,4),'Jay':(3,3,4),
    'JackDaw':(3,3,6),'TomTit':(3,4,6),'Stork':(4,7,7),'Tern':(3,4,8),'Jay2':(3,3,9),
    'Goose':(6,8,10),'Whistlers':(7,9,12)}
E1={}
def a(E,t,*e): E.setdefault(t,[]).extend(e)
a(E1,4,('fly','Chiffchaff',1)); a(E1,5,('add','Chiffchaff',1,1),('fly','Swallow',1))
a(E1,6,('fly','Jay',1),('fly','Chiffchaff',2))
a(E1,7,('stork','Chiffchaff'),('add','Chiffchaff',1,1),('fly','Swallow',2))
a(E1,8,('stork','Swallow'),('fly','Jay',2),('gone','Dunnock'))
a(E1,9,('stork','Jay'),('fly','Tern',2),('fly','Chiffchaff',2))
a(E1,10,('egg','Jay'),('stork','Tern'),('tern','Tern'),('fly','Jay2',2),('fly','Swallow',2))
a(E1,11,('stork','Jay2'),('stork','Swallow'),('fly','Jay',2),('fly','Goose',2),('add','Chiffchaff',1,1))
a(E1,12,('stork','Jay'),('stork','Goose'),('egg','Jay'),('fly','Tern',2),('fly','Chiffchaff',2),('gone','Swallow'))
a(E1,13,('stork','Tern'),('tern','Tern'),('stork','Chiffchaff'),('add','Chiffchaff',1,1),('fly','Jay',2),('fly','Goose',2))
a(E1,14,('stork','Jay'),('stork','Goose'),('egg','Jay'),('fly','Jay2',2),('fly','Tern',2))
a(E1,15,('stork','Jay2'),('stork','Tern'),('tern','Tern'),('fly','Goose',2),('fly','Chiffchaff',2))
# Line 2, Sky (Cuckoo, Lump, Ratchet), typical roll: Cuckoo R7, Lump R10, Ratchet R12. No Stork, no Goose.
S2={'Chiffchaff':(2,3,1),'Swallow':(1,2,2),'Redbreast':(2,4,3),'Jay':(3,3,3),'Redwing':(2,4,4),
    'TomTit':(3,4,5),'Tern':(3,4,6),'Cuckoo':(4,7,7),'Lump':(5,7,10),'Ratchet':(6,10,12),'JackDaw':(3,3,8)}
E2={}
a(E2,3,('fly','Chiffchaff',2)); a(E2,4,('fly','Swallow',2)); a(E2,5,('add','Chiffchaff',1,1),('fly','Jay',2))
a(E2,7,('fly','Chiffchaff',2,1),('fly','Tern',2)); a(E2,8,('fly','Jay',2,1))
a(E2,9,('add','Chiffchaff',1,1),('fly','Swallow',2),('tern','Tern')); a(E2,10,('fly','Chiffchaff',2,1),('fly','JackDaw',2))
a(E2,11,('fly','Jay',2,1),('fly','Tern',2)); a(E2,12,('add','Chiffchaff',1,1),('gone','Swallow'))
a(E2,13,('fly','Chiffchaff',2,1),('tern','Tern'),('fly','JackDaw',2)); a(E2,14,('fly','Jay',2,1),('fly','Tern',2))
a(E2,15,('add','Chiffchaff',1,1))
if __name__ == '__main__':
    s=sim(S1,E1,supper=(8,10,12))
    print(f"=== Line 1 Homecoming, r={R}")
    board(s,6,['Redbreast','Swallow','Dunnock','JackDaw','TomTit'],[('Jay','H'),('Chiffchaff','H')],"L1")
    board(s,9,['Redbreast','Swallow','Jay','JackDaw','TomTit','Stork'],[('Chiffchaff','H')],"L1")
    board(s,12,['Redbreast','Jay','TomTit','Stork','Goose','Whistlers'],[('Chiffchaff','H')],"L1")
    board(s,15,['Redbreast','Jay','Tern','TomTit','Stork','Whistlers'],[('Chiffchaff','H')],"L1")
    s=sim(S2,E2,supper=(8,10,12))
    print(f"=== Line 2 Sky, r={R}, lump={LF}  (Egg 'aH' = half Attack via Redwing, Health via Tom Tit)")
    board(s,6,['Redbreast','Redwing','Chiffchaff','Swallow','Tern','TomTit'],[('Jay','aH')],"L2")
    board(s,9,['Redwing','Cuckoo','Chiffchaff','Redbreast','Tern','TomTit'],[('Jay','aH')],"L2")
    board(s,12,['Redbreast','Lump','Cuckoo','Chiffchaff','Ratchet','TomTit'],[('Tern','H')],"L2")
    board(s,15,['Redbreast','Lump','Cuckoo','Chiffchaff','Ratchet','TomTit'],[('Tern','H')],"L2")
