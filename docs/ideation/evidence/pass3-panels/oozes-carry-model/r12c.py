import sys; sys.path.insert(0, sys.argv[1])
from ooze_combat2 import match
even=[(54,54)]*7
bgshape=[(130,130)]+[(42,42)]*6
two_carry=[(90,90),(90,90)]+[(36,36)]*5
def ooze(scale=1.0, kw=None, slot=1, gap=False, inside=None):
    c=int(157*scale); s=int(37*scale)
    b=[(s,s)]*7; k=dict(kw or {})
    if inside: k["inside"]=(int(inside*scale),int(inside*scale))
    b[slot]=(c,c,k)
    if gap: b[2]=None; b[slot]=(c+s//2,c+s-s//2,k)   # leave F3 empty, its stats folded into the carry
    return b
print("Conserving split (current Bubble rule: after it survives a hit, halve current stats into a copy)")
print("%-46s %6s | %6s %8s %9s"%("Ooze board","total","even","BG-shape","2 carries"))
for kw,name,gap in [({"shield":1},"Shield, full board",False),
                    ({"shield":1,"bubble":1},"Shield + Bubble once, full board (no room)",False),
                    ({"shield":1,"bubble":1},"Shield + Bubble once, gap at F3",True),
                    ({"shield":1,"bubble":2},"Shield + golden Bubble (twice), gap at F3",True),
                    ({"shield":1,"bubble":1,"inside":(37,37)},"Shield + Bubble + meal inside, gap F3",True)]:
    for sc in (0.85,1.0,1.2):
        k=dict(kw); ins=k.pop("inside",None)
        b=ooze(sc,k,gap=gap,inside=ins[0] if ins else None)
        print("%-46s %6d | %6.1f %8.1f %9.1f"%(name,int(760*sc),match(b,even,2000)[0],match(b,bgshape,2000)[0],match(b,two_carry,2000)[0]))
