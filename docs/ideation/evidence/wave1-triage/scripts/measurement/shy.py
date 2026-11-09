# Shy units: how long each copy stood, how it left (thanked = Ring size grew that round, else sold/still there).
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
SHY = ["lob_lie_by_the_fire", "silky", "hob_in_the_hearth"]
for line in ["line_fairies_ring", "line_fairies_court"]:
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    print("==", line)
    for card in SHY:
        stays = []; how = collections.Counter(); left_round = collections.Counter(); silky_with = 0; n = 0
        for sd, se in seats:
            life = collections.defaultdict(list)
            last = max(r for r in range(1, 30) if (sd, se, r) in S)
            for r in range(1, last + 1):
                v = S[(sd, se, r)]
                for x in v["rec"]:
                    if x[0] == card and x[1] == "board": life[x[3]].append(r)
            for iid, rs in life.items():
                n += 1; a, b = min(rs), max(rs); stays.append(b - a + 1)
                if b == last: how["still on board at game end/last capture"] += 1; continue
                v0, v1 = S[(sd, se, b)], S[(sd, se, b + 1)]
                grew = (v1["ring_size"] or 1) > (v0["ring_size"] or 1)
                how["left, Ring size grew (thanked?)" if grew else "left, no growth (sold / no Rings yet)"] += 1
                left_round[b + 1] += 1
        print(f" {card}: copies {n}, median turns stood {st.median(stays) if stays else None}, stood>=6 turns {sum(1 for s in stays if s >= 6)}")
        for k, c in how.most_common(): print("    ", k, c)
        print("     leave round:", sorted(left_round.items()))
