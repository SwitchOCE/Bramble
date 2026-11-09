import sys, random; sys.path.insert(0,'.')
import bramble_combat as bc
L=['F1','F2','F3','F4','B1','B2','B3']
# instrumented copy: wrap random to log choices
A=[(10,11),(10,11),(10,11),None,None,None,None]
B=[(10,10),(10,10),(10,10),(10,10),(10,10),None,None]
class Log(random.Random): pass
rng=random.Random(3)
# Re-implement a verbose fight loop using the module's pieces
sides=[bc.make_side(A), bc.make_side(B)]
names=['A(3x10/11)','B(5x10/10)']
first=1
ptr=[-1,-1]; active=first; ex=0
while sides[0] and sides[1]:
    s=active
    units=[sides[s][k] for k in sorted(sides[s])]
    att=next((u for u in units if not u.flag),None)
    if att is None:
        for u in units: u.flag=False
        att=units[0]
    for u in units:
        if u.slot<=att.slot: u.flag=True
    en=sides[1-s]; front=[en[k] for k in sorted(en) if k<4]; c=front or [en[k] for k in sorted(en)]
    d=c[rng.randrange(len(c))]
    d.h-=att.a; att.h-=d.a; ex+=1
    print(f'exchange {ex}: {names[s]} {L[att.slot]} hits {names[1-s]} {L[d.slot]} -> attacker {max(att.h,0)} hp, defender {max(d.h,0)} hp')
    for ss in (0,1):
        for u in [u for u in sides[ss].values() if u.h<=0]: del sides[ss][u.slot]
    active=1-s
print('winner:', names[0] if sides[0] else names[1], 'survivors:', [(L[u.slot],u.a,u.h) for side in sides for u in side.values()])
