# Chance that real shops offer each paper arrival by the paper's round, on the paper's climb.
# Estimate: no pool depletion, no freezes, independent cards; one start shop a round (+ extra refreshes).
import math
ODDS = [[100], [50, 50], [20, 30, 50], [10, 15, 25, 50], [5, 10, 15, 25, 45], [5, 5, 10, 15, 25, 40]]
SIZE = [4, 4, 4, 5, 5, 6]; UNITS = [21, 21, 21, 20, 13, 13]
def p_shop(ct, t):
    if ct > t: return 0.0
    p = ODDS[t-1][ct-1] / 100 / UNITS[ct-1]
    return 1 - (1 - p) ** SIZE[t-1]
def tier_at(climb, r):  # tier for the start shop of round r (tier-ups happen during the round)
    t = 1
    for tt, rr in sorted(climb.items()):
        if rr < r: t = tt
    return t
def offered_by(card_tier, by, climb, refresh):
    miss = 1.0
    for r in range(1, by + 1):
        t = tier_at(climb, r)
        miss *= (1 - p_shop(card_tier, t)) ** (1 + (refresh if r >= 3 else 0))
    return 1 - miss
plans = {
 "fairies_ring (paper full line)": ({2: 2, 3: 4, 4: 6, 5: 9, 6: 11}, [("Annis", 2, 3), ("Sally", 2, 4), ("Cluricaun", 3, 5), ("Lob", 3, 5), ("Hob", 2, 8), ("Silky", 3, 9), ("Fetch", 4, 10), ("Belladonna", 5, 10), ("Monarch", 6, 12)]),
 "fairies_court (paper full line)": ({2: 2, 3: 4, 4: 6, 5: 8, 6: 10}, [("Annis", 2, 3), ("Chaser", 1, 4), ("Sally", 2, 5), ("Cluricaun", 3, 7), ("Lob", 3, 7), ("Changeling", 4, 7), ("Silky", 3, 8), ("Belladonna", 5, 9), ("Queen", 6, 11), ("Will", 4, 11)]),
 "birds line A (paper typical)": ({2: 3, 3: 5, 4: 7, 5: 10, 6: 12}, [("Chiffchaff", 1, 1), ("Swallow", 1, 2), ("Jay", 2, 4), ("Redbreast", 2, 4), ("Dunnock", 1, 4), ("Tom Tit", 3, 6), ("Jack Daw", 3, 6), ("Tern", 3, 6), ("Stork", 4, 7), ("Cuckoo", 4, 9), ("Goose", 5, 10), ("Lump", 5, 11)]),
}
for name, (climb, arr) in plans.items():
    for refresh in (0, 1, 2):
        ps = [(c, offered_by(ct, by, climb, refresh)) for c, ct, by in arr]
        joint = math.prod(p for _, p in ps)
        print(f"{name}, +{refresh} refreshes/round from R3: joint {100*joint:.4f}%  " + ", ".join(f"{c} {round(100*p)}%" for c, p in ps))
