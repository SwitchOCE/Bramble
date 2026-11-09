# Simple growth model for the main permanent engines, highroll (everything lines up) and typical.
# Prints the biggest single unit each engine can build by R8, R12, R16. Assumptions in comments.
def cuckoo_bird(start_round, end_round, per_eot=2, away_share=0.75, base=(1,2), plays_per_4=1, supper=3):
    # Bird beside Cuckoo: away 3 of every 4 EOTs (trip lengthened to 3, one home fight).
    eots = max(0, end_round - start_round + 1)
    grow = int(eots * away_share) * per_eot
    plays = eots // 4 + 1  # Chiffchaff +1/+1 per replay
    a = base[0] + grow + plays + supper
    h = base[1] + grow + plays + supper
    return a, h
def supper_by(r, typical):
    if typical: return 1 if r < 10 else (2 if r < 14 else 3)
    return 1 if r < 9 else (2 if r < 11 else 3)
print("Birds: Cuckoo-grown Chiffchaff (full stats; Egg shows half Attack unless Redwing beside)")
for r in (8,12,16):
    t = cuckoo_bird(9, r, supper=supper_by(r,True)) if r >= 9 else (2+supper_by(r,True), 3+supper_by(r,True))
    h = cuckoo_bird(6, r, supper=supper_by(r,False))
    g = cuckoo_bird(6, min(r,10), supper=0); 
    if r > 10:
        extra = int((r-10)*0.8)*4  # golden Cuckoo from R11: +4/+4, trip +2 (away 4 of 5)
        g = (g[0]+extra+supper_by(r,False), g[1]+extra+supper_by(r,False))
    print(f"  R{r}: typical {t[0]}/{t[1]}  highroll {h[0]}/{h[1]}  highroll+golden Cuckoo from R11 {g[0]}/{g[1]}")
print("Bog: Ranocchio (+1/+1 per fight it attacks a Mired enemy; printed 3/4)")
for r in (8,12,16):
    t = (3+max(0,r-9)+supper_by(r,True), 4+max(0,r-9)+supper_by(r,True)) if r>=9 else None
    h = (3+(r-6)+supper_by(r,False), 4+(r-6)+supper_by(r,False))
    g = (6+2*(r-6)+supper_by(r,False), 8+2*(r-6)+supper_by(r,False))
    print(f"  R{r}: typical {t}  highroll {h}  golden-from-R6 {g}")
print("Bog: Lantern Man in combat (4/8 printed, +3 Attack per Mired enemy)")
for r,m in ((12,5),(16,6)):
    print(f"  R{r}: {m} Mired enemies, Supper +3: {4+3+3*m}/{8+3}; golden {8+3+6*m}/{16+3}")
print("Fairies: best standing Fairy on a full Ring (+4/+4), Monarch +1/+1, Supper, Hob Health")
for r in (8,12,16):
    s = supper_by(r,False); mon = 1 if r >= 10 else 0; hob = min(r-3, 10) if r>3 else 0
    print(f"  R{r}: Reel-Mistress/Belladonna-size body (4/7-4/8) + Ring 4/4 + Monarch {mon} + Supper {s} + Hob {hob//2} Health: {4+4+mon+s}/{8+4+mon+s+hob//2}")
print("Fairies: Queen Teind every 3 turns from R10, two T5 bodies (printed 8/15 total, +perms 4/4) to ONE other Fairy")
for r in (12,16):
    teinds = (r-10)//3 + 1
    pool = (8+4, 15+4)
    print(f"  R{r}: {teinds} Teind(s): recipient +{pool[0]*teinds}/+{pool[1]*teinds} (golden x2); cost {6*teinds} gold of rebuys")
