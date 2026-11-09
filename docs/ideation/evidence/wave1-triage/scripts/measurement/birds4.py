# Split the "bigger eligible flier stayed home" turns by the elimination guard (health <= max(8, 2*round))
# and by whether the bigger stayer is the biggest Bird on the board.
import pickle, os, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
B = pickle.load(open(os.path.join(D, "birds.pkl"), "rb"))
FLIERS = {"one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"}
c = collections.Counter(); who = collections.Counter()
for (sd, se, r), b in B.items():
    v = S.get((sd, se, r)); p = S.get((sd, se, r - 1)); bp = B.get((sd, se, r - 1))
    if r < 7 or not v or v["line"] not in ("line_birds_homecoming", "line_birds_tempo") or not p or not bp: continue
    new = [a for a in b["away"] if a[1] not in {x[1] for x in bp["away"]}]
    prev_board = {x[3] for x in p["rec"] if x[1] == "board"}
    elig = {x[0] for x in v["rec"] if x[1] == "board" and x[0] in FLIERS and x[3] in prev_board}
    home = [(u[2] + u[3], u[0]) for u in v["units"] if u[5] == "board" and u[0] in elig]
    if not new or not home: continue
    flown = max(a[2] + a[3] for a in new)
    big = max(home)
    if big[0] <= flown: continue
    danger = (p["health"] or 40) <= max(8, 2 * r)   # health going into this turn's recruit, approx.
    biggest_bird = max((u[2] + u[3]) for u in v["units"] if u[5] == "board" and "Birds" in u[7])
    c[("guard" if danger else "no guard", "stayer is biggest Bird" if big[0] >= biggest_bird else "not biggest")] += 1
    who[big[1]] += 1
print(dict(c)); print("bigger eligible stayer by card:", who.most_common())
