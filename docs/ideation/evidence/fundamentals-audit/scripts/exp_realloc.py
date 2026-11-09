import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
def split_unit(t, ashare):
    a=max(1,round(t*ashare)); return (a, max(1,t-a))
def realloc(b, carry_share, carry_slot_pref='front'):
    units=[u for u in b if u]; n=len(units)
    A=sum(u[0] for u in units); H=sum(u[1] for u in units); T=A+H; ash=A/T
    slots=[i for i,u in enumerate(b) if u]
    if carry_share is None:
        per=[T//n + (1 if i < T%n else 0) for i in range(n)]
        out=[None]*7
        for s,t in zip(slots,per): out[s]=split_unit(t,ash)
        return out
    ct=round(T*carry_share); rest=T-ct; m=n-1
    per=[rest//m + (1 if i < rest%m else 0) for i in range(m)]
    out=[None]*7
    cs = slots[0] if carry_slot_pref=='front' else slots[-1]
    out[cs]=split_unit(ct,ash)
    others=[s for s in slots if s!=cs]
    for s,t in zip(others,per): out[s]=split_unit(t,ash)
    return out
print('Each R9 board keeps its total stats, unit count, slots and attack share; only the split changes.')
print('Win % vs the 11 original boards (same-roll in brackets). carry% = share of all stats on one unit.')
hdr=['original','even','carry 25% F','carry 40% F','carry 40% back','carry 55% F']
print(f'{"board":14s} '+'  '.join(f'{h:>15s}' for h in hdr))
tot=[[0,0] for _ in hdr]
for x in names:
    vs=[boards[x], realloc(boards[x],None), realloc(boards[x],0.25), realloc(boards[x],0.40), realloc(boards[x],0.40,'back'), realloc(boards[x],0.55)]
    cells=[]
    for i,b in enumerate(vs):
        oa=[y for y in names if y!=x]; os=[y for y in oa if y.split('_')[1]==x.split('_')[1]]
        a=sum(match(b,boards[y],n=100,seed=4)['win'] for y in oa)/len(oa)
        s=sum(match(b,boards[y],n=100,seed=4)['win'] for y in os)/len(os)
        tot[i][0]+=a; tot[i][1]+=s
        cells.append(f'{100*a:6.1f} ({100*s:5.1f})')
    print(f'{x:14s} '+'  '.join(f'{c:>15s}' for c in cells))
print(f'{"MEAN":14s} '+'  '.join(f'{100*t[0]/12:6.1f} ({100*t[1]/12:5.1f})'.rjust(15) for t in tot))
