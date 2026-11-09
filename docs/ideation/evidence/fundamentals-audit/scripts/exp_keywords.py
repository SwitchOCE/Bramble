import sys; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
hl=boards['hedgerow_low']; others=[y for y in names if y!='hedgerow_low']
def vs_all(b, opp_mod=None):
    tot=0
    for y in others:
        ob=boards[y] if opp_mod is None else opp_mod(boards[y])
        tot+=match(b,ob,n=300,seed=8)['win']
    return tot/len(others)
def with_kw(kw):
    b=list(hl); u=b[6]; b[6]=(u[0],u[1],kw); return b
base=vs_all(hl)
print(f'Plain hedgerow_low (Dozey 10/16 in B3) vs the other 11 plain R9 boards: {100*base:.1f}%')
print('Give Dozey one keyword (none of these is in the pass 2 slice except where noted):')
for name,kw in [('shield (first hit ignored)',{'shield':True}),('cleave (also hits units beside the target)',{'cleave':True}),
                ('takes 2 less damage',{'dr':2}),('Hunker (half damage when attacked)',{'hunker':True}),
                ('takes no damage while attacking (Barn Owl does this vs back row only)',{'immune_attacking':True}),
                ('windfury (two attacks a turn)',{'windfury':True}),('Bitter 2 (slice keyword)',{'bitter':2}),
                ('Nightshade on Dozey (slice Belladonna across from B3)',{'nightshade':True})]:
    w=vs_all(with_kw(kw)); print(f'  {name:68s} {100*w:5.1f}%  ({100*(w-base):+5.1f})')
print('Answers on every opponent board:')
def venom_front(b):
    out=list(b)
    for i in range(4):
        if out[i]: out[i]=(out[i][0],out[i][1],{'venom':True}); break
    return out
def bitter_front(b):
    return [ (u[0],u[1],{'bitter':2}) if (u and i<4) else u for i,u in enumerate(b)]
for name,f in [('first front unit has venom (any damage kills)',venom_front),('every front unit has Bitter 2',bitter_front)]:
    w=vs_all(hl,f); print(f'  {name:68s} {100*w:5.1f}%  ({100*(w-base):+5.1f})')
