# Observed presence of key pieces (board, hand or away) by R6/R8/R10/R12 against an estimated chance the
# piece was offered at least once. Estimate: no pool depletion, no freezes; each round = a start shop at
# last round's tier + paid refreshes at this round's tier; per slot P(tier t) / (pool units at tier t).
import pickle, os, csv, glob, statistics as st, collections, sys
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/"
ODDS = [[100], [50, 50], [20, 30, 50], [10, 15, 25, 50], [5, 10, 15, 25, 45], [5, 5, 10, 15, 25, 40]]
SIZE = [4, 4, 4, 5, 5, 6]
UNITS = [21, 21, 21, 20, 13, 13]
def p_shop(card_tier, tier):
    if card_tier > tier: return 0.0
    p = ODDS[tier-1][card_tier-1] / 100 / UNITS[card_tier-1]
    return 1 - (1-p) ** SIZE[tier-1]
rounds = {}
for path in glob.glob(RUN + "chunk-*.rounds.csv"):
    for row in csv.DictReader(open(path)):
        rounds[(int(row["seed"]), int(row["seat"]), int(row["round"]))] = row
PIECES = {"fairies": [("old_moth_annis", 2), ("nan_toadstool", 1), ("sally_spore", 2), ("rainbow_chaser", 1), ("hob_in_the_hearth", 2),
          ("cluricaun", 3), ("lob_lie_by_the_fire", 3), ("silky", 3), ("cradle_fetch", 4), ("will_o_the_wisp", 4), ("changeling", 4),
          ("belladonna", 5), ("reel_mistress", 5), ("fairy_monarch", 6), ("queen_of_elfland", 6)],
          "birds": [("chiffchaff",1),("one_swallow",1),("mrs_dunnock",1),("mr_redbreast",2),("mrs_jay",2),("redwing",2),("tom_tit",3),("old_tern",3),("jack_daw",3),
                    ("mrs_stork",4),("cuckoo",4),("mag_pye",4),("mother_goose",5),("great_lump",5),("gabble_ratchet",6),("seven_whistlers",6)]}
lines = sys.argv[1:] or ["line_fairies_ring", "line_fairies_court"]
for line in lines:
    tribe = "birds" if "birds" in line else "fairies"
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    print("==", line, len(seats), "seats.  card: observed by R6/R8/R10/R12 | est. offered at least once by R6/R8/R10/R12 (survivors)")
    for card, ct in PIECES[tribe]:
        obs = {6: [], 8: [], 10: [], 12: []}; est = {6: [], 8: [], 10: [], 12: []}
        for sd, se in seats:
            seen = False; miss = 1.0
            for r in range(1, 13):
                v = S.get((sd, se, r)); row = rounds.get((sd, se, r)); prev = rounds.get((sd, se, r-1))
                if v is None or row is None: break
                t_now = int(row["tier"]); t_start = int(prev["tier"]) if prev else 1
                miss *= (1 - p_shop(ct, t_start))
                for _ in range(int(row["paid_refreshes"])): miss *= (1 - p_shop(ct, t_now))
                if any(u[0] == card for u in v["units"]) or any(x[0] == card for x in v["rec"]): seen = True
                if r in obs:
                    obs[r].append(seen); est[r].append(1 - miss)
        f = lambda xs: round(100 * sum(xs) / len(xs)) if xs else None
        print(f"{card:22s} T{ct}  obs " + "/".join(str(f(obs[r])) for r in obs) + "   est " + "/".join(str(f(est[r])) for r in est))
    pr = collections.defaultdict(list); gl = collections.defaultdict(list)
    for sd, se in seats:
        for r in range(1, 15):
            row = rounds.get((sd, se, r))
            if row: pr[r].append(int(row["paid_refreshes"])); gl[r].append(int(row["gold_left"]))
    print("mean paid refreshes R1-14:", [round(st.mean(pr[r]), 2) for r in range(1, 15)])
    print("mean gold left    R1-14:", [round(st.mean(gl[r]), 2) for r in range(1, 15)])
