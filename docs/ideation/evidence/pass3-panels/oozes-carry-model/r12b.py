import sys; sys.path.insert(0, sys.argv[1])
from ooze_combat import match
even=[(54,54)]*7
bgshape=[(130,130)]+[(42,42)]*6
two_carry=[(90,90),(90,90)]+[(36,36)]*5
def ooze(scale=1.0, kw=None, slot=1, inside=None):
    c=int(157*scale); s=int(37*scale)
    b=[(s,s)]*7; k=dict(kw or {})
    if inside: k["inside"]=(int(inside*scale),int(inside*scale))
    b[slot]=(c,c,k); return b
print("Ooze carry (41% share) win% vs three field shapes, by split fraction and Ooze total")
print("%-34s %6s | %8s %8s %8s"%("carry text","total","even","BG-shape","2 carries"))
for kw,name in [({"shield":1},"Shield only"),
                ({"shield":1,"split":0.25},"Shield + split 1/4"),
                ({"shield":1,"split":0.33},"Shield + split 1/3"),
                ({"split":0.33},"split 1/3"),
                ({"shield":1,"split":0.5},"Shield + split 1/2")]:
    for sc in (0.7,0.85,1.0):
        b=ooze(sc,kw)
        print("%-34s %6d | %8.1f %8.1f %8.1f"%(name,int(760*sc),match(b,even,2000)[0],match(b,bgshape,2000)[0],match(b,two_carry,2000)[0]))
print()
print("pot line R12 (35% share: pot 122/122 in B2, 6 supports 76 avg = 38/38, ~4 reserves inside front Oozes)")
pot=[(38,38,{"inside":(45,45)}),(38,38,{"inside":(45,45)}),(38,38,{"inside":(45,45)}),(38,38,{"inside":(45,45)}),(38,38),(122,122,{"shield":1}),(38,38)]
print(" pot vs even %.1f  vs BG-shape %.1f  vs 2 carries %.1f"%(match(pot,even,2000)[0],match(pot,bgshape,2000)[0],match(pot,two_carry,2000)[0]))
pot_no=[(38,38)]*4+[(38,38),(122,122,{"shield":1}),(38,38)]
print(" pot with empty Bellies: vs even %.1f"%match(pot_no,even,2000)[0])
