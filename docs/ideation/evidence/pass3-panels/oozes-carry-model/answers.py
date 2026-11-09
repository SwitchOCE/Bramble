import sys; sys.path.insert(0, sys.argv[1])
from ooze_combat2 import match
bg_carry=[(42,42),(42,42),(42,42),(42,42),(42,42),(130,130),(42,42)]      # carry hidden in B2
bg_carry_front=[(42,42),(130,130),(42,42),(42,42),(42,42),(42,42),(42,42)]
big_carry=[(30,30)]*4+[(30,30),(230,230),(30,30)]                          # 60% carry in B2, same ~760
even=[(54,54)]*7
def board(pudding_slot=None, posset=0, base=(46,46)):
    b=[base]*7
    if pudding_slot is not None: b[pudding_slot]=(30,40,{"swallow":1})
    for i in range(posset): b[i]=(20,10,{"curdle":1})
    return b
print("R12 Ooze answer boards (~740 stats, no carry) vs carry boards (~760)")
print("%-40s %10s %12s %12s %8s"%("Ooze board","BG back","BG front","60% carry","even"))
for name,b in [("plain 7x46/46",board()),
               ("Hasty Pudding in F2",board(1)),
               ("Hasty Pudding in B2",board(5)),
               ("two Possets in F1-F2",board(None,2)),
               ("Pudding B2 + two Possets",board(5,2))]:
    print("%-40s %10.1f %12.1f %12.1f %8.1f"%(name,match(b,bg_carry,2000)[0],match(b,bg_carry_front,2000)[0],match(b,big_carry,2000)[0],match(b,even,2000)[0]))
