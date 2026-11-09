import sys; sys.path.insert(0, sys.argv[1])
from ooze_combat import match
def sq(x): return (x//2, x-x//2)
# R12 boards near 760 total stats (BG Sep 2025 mean 759)
even   = [ (54,54) ]*7
bgshape= [ (130,130) ] + [ (42,42) ]*6                      # ~a third in one unit, like BG
# Ooze carry line, no Aspic: carry 157/157, six supports ~74 total each (37/37) = 760
def ooze(carry_slot=1, kw=None, inside=None, supports=(37,37)):
    b=[None]*7; s=[i for i in range(7) if i!=carry_slot]
    for i in s: b[i]=supports
    k=dict(kw or {})
    if inside: k["inside"]=inside
    b[carry_slot]=(157,157,k)
    return b
rows=[
 ("plain carry F2", ooze(1)),
 ("plain carry B2", ooze(5)),
 ("carry F2 + Shield", ooze(1,{"shield":1})),
 ("carry F2 + split (Bubble)", ooze(1,{"split":0.5})),
 ("carry F2 + Shield + split", ooze(1,{"shield":1,"split":0.5})),
 ("carry F2 + Shield + split + meal inside 37/37", ooze(1,{"shield":1,"split":0.5},inside=(37,37))),
 ("carry B2 + Shield + split + meal inside", ooze(5,{"shield":1,"split":0.5},inside=(37,37))),
 ("carry F2 + golden split (full stats)", ooze(1,{"shield":1,"split":1.0})),
 ("carry F2 + Shield + Cleave (Frumenty borrows)", ooze(1,{"shield":1,"cleave":1})),
]
print("R12, every board ~760 stats. Win% (tie%) for the Ooze board")
print("%-50s %14s %14s"%("Ooze board","vs 7x54/54","vs BG-shape"))
for name,b in rows:
    w1,t1=match(b,even); w2,t2=match(b,bgshape)
    print("%-50s %8.1f (%4.1f) %8.1f (%4.1f)"%(name,w1,t1,w2,t2))
print("reference: BG-shape vs even: %.1f"%match(bgshape,even)[0])
