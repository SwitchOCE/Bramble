"""Supply lens for the wave 1 triage.

Reads the wave1-accounting captures (fights.jsonl.gz for R1-R16 ownership, rounds.csv for tier and
paid refreshes, seat labels for lines) and the pool rules (game_config.gd full_game(): copies
[15,15,13,13,11,9], shop slots [4,4,4,5,5,6], tier odds SLICE_SHOP_ODDS, all six tribes since the run's
config.json sets tribes_per_lobby 0). Writes supply.json next to itself.

Run: python3 -I supply.py <run_dir> <seat_labels.json.gz> <units_dir>
"""
import csv, glob, gzip, json, math, os, sys, collections

RUN, LABELS, UNITS = sys.argv[1], sys.argv[2], sys.argv[3]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "supply.json")

COPIES = [15, 15, 13, 13, 11, 9]
SLOTS = [4, 4, 4, 5, 5, 6]
ODDS = [[100], [50, 50], [20, 30, 50], [10, 15, 25, 50], [5, 10, 15, 25, 45], [5, 5, 10, 15, 25, 40]]

# ---- pool
units = {}
for f in glob.glob(os.path.join(UNITS, "*.json")):
    d = json.load(open(f))
    if d.get("set") == "slice" and d.get("pool", True):
        units[d["id"]] = dict(tier=int(d["tier"]), tribes=d.get("tribes", []))
n_tier = collections.Counter(u["tier"] for u in units.values())
tribe_tier = collections.Counter((u["tribes"][0] if u["tribes"] else "neutral", u["tier"]) for u in units.values())
copies_tier = {t: n_tier[t] * COPIES[t - 1] for t in range(1, 7)}
TRIBE = {k: (v["tribes"][0] if v["tribes"] else "neutral") for k, v in units.items()}

KEY = {
    "Fairies": ["nan_toadstool", "rainbow_chaser", "hedge_witch", "old_moth_annis", "sally_spore", "hob_in_the_hearth",
                "cluricaun", "lob_lie_by_the_fire", "silky", "cradle_fetch", "will_o_the_wisp", "changeling",
                "belladonna", "reel_mistress", "fairy_monarch", "queen_of_elfland"],
    "Birds": ["chiffchaff", "one_swallow", "mrs_dunnock", "mr_redbreast", "mrs_jay", "redwing", "tom_tit", "jack_daw",
              "old_tern", "mrs_stork", "cuckoo", "mag_pye", "great_lump", "mother_goose", "gabble_ratchet",
              "seven_whistlers"],
}
PAPER = {  # arrival rounds in the paper plans the accounting compares against
    "line_fairies_ring": {"nan_toadstool": 1, "old_moth_annis": 3, "sally_spore": 4, "cluricaun": 5,
                          "lob_lie_by_the_fire": 5, "hob_in_the_hearth": 8, "silky": 9, "cradle_fetch": 10,
                          "belladonna": 10, "fairy_monarch": 12, "will_o_the_wisp": 12, "reel_mistress": 13},
    "line_fairies_court": {"nan_toadstool": 1, "old_moth_annis": 3, "rainbow_chaser": 4, "sally_spore": 5,
                           "cluricaun": 7, "hedge_witch": 7, "lob_lie_by_the_fire": 7, "changeling": 7, "silky": 8,
                           "belladonna": 9, "queen_of_elfland": 11, "will_o_the_wisp": 11, "fairy_monarch": 13},
    "line_birds_homecoming": {"chiffchaff": 1, "one_swallow": 2, "mrs_jay": 3, "mr_redbreast": 3, "mrs_dunnock": 4,
                              "tom_tit": 5, "jack_daw": 6, "old_tern": 6, "mrs_stork": 7, "cuckoo": 9,
                              "mother_goose": 10, "great_lump": 11, "gabble_ratchet": 12, "seven_whistlers": 13},
    # paper line U, tier-gated by its climb T2 R3, T3 R5, T4 R7, T5 R10, T6 R12
    "line_birds_tempo": {"chiffchaff": 1, "mrs_dunnock": 1, "mrs_jay": 3, "mr_redbreast": 3, "one_swallow": 2,
                         "redwing": 3, "tom_tit": 5, "jack_daw": 5, "mag_pye": 7, "mrs_stork": 7, "cuckoo": 7,
                         "great_lump": 10, "mother_goose": 10, "old_tern": 8, "gabble_ratchet": 12,
                         "seven_whistlers": 12},
}
LINES = list(PAPER)


def p_slot_full(card, shop_tier):
    t = units[card]["tier"]
    if t > shop_tier:
        return 0.0
    row = ODDS[shop_tier - 1]
    return row[t - 1] / sum(row) / n_tier[t]


def p_fill(card, shop_tier, p_slot=None):
    p = p_slot_full(card, shop_tier) if p_slot is None else p_slot
    return 1 - (1 - p) ** SLOTS[shop_tier - 1]


# ---- captures
labels = {(r["seed"], r["seat"]): r for r in json.load(gzip.open(LABELS))}
rounds = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.rounds.csv"))):
    for r in csv.DictReader(open(f)):
        rounds[(int(r["seed"]), int(r["seat"]), int(r["round"]))] = (int(r["tier"]), int(r["paid_refreshes"]))

own = {}          # (seed, seat, round) -> Counter of def_id owned (any location), bought or created
held = collections.defaultdict(collections.Counter)  # (seed, round) -> pool copies held by all seats
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.fights.jsonl.gz"))):
    for line in gzip.open(f, "rt"):
        d = json.loads(line)
        for side, seat in zip(d["combat_start"], d["players"]):
            if "recruit_units" not in side:
                continue  # ghost
            key = (d["seed"], seat, d["round"])
            if key in own:
                continue
            c = collections.Counter(u["def_id"] for u in side["recruit_units"])
            own[key] = c
            gold = collections.Counter(u["def_id"] for u in side["units"] if u.get("golden"))
            for u in side["recruit_units"]:
                if u["origin"] == "bought" and u["def_id"] in units:
                    held[(d["seed"], d["round"])][u["def_id"]] += 1
            for k, n in gold.items():
                if k in units:
                    held[(d["seed"], d["round"])][k] += 2 * n


LEFT = {}


def p_slot_depleted(card, shop_tier, seed, rnd, self_seat):
    """Pool odds after the copies other seats (and this seat) hold at that round's combat."""
    t = units[card]["tier"]
    if t > shop_tier:
        return 0.0
    h = held.get((seed, rnd), {})
    lk = (seed, rnd)
    if lk not in LEFT:
        LEFT[lk] = {tt: copies_tier[tt] - sum(n for k, n in h.items() if units[k]["tier"] == tt) for tt in range(1, 7)}
    left_t = LEFT[lk]
    row = ODDS[shop_tier - 1]
    tot = sum(row[tt - 1] for tt in range(1, shop_tier + 1) if left_t[tt] > 0)
    left_x = max(0, COPIES[t - 1] - h.get(card, 0))
    return row[t - 1] / tot * left_x / max(1, left_t[t])


seats = collections.defaultdict(list)
for (seed, seat), r in labels.items():
    if r["starting_line"] in PAPER:
        seats[r["starting_line"]].append((seed, seat))

# competition: other seats per lobby on the same tribe at R10 (by final line label)
compete = collections.defaultdict(collections.Counter)
for (seed, seat), r in labels.items():
    fl = r["final_line"]
    tribe = "Fairies" if fl.startswith(("fairies", "line_fairies")) else "Birds" if fl.startswith(("birds", "line_birds")) else None
    if tribe:
        compete[seed][tribe] += 1

res = {"pool": {"n_by_tier": dict(n_tier), "copies_by_tier": copies_tier}, "per_fill_full_pool": {}, "lines": {}}
for tribe in KEY:
    for c in KEY[tribe]:
        res["per_fill_full_pool"][c] = {f"T{T}": round(p_fill(c, T), 4) for T in range(1, 7)}

for line in LINES:
    tribe = "Fairies" if "fairies" in line else "Birds"
    out = {}
    for card in KEY[tribe]:
        rows = {}
        for R in range(1, 15):
            alive = exp_full = exp_dep = seen_full = seen_dep = owned_now = owned_ever = 0
            fills = 0
            for seed, seat in seats[line]:
                if (seed, seat, R) not in own:
                    continue
                alive += 1
                logq_f = logq_d = 0.0
                ever = False
                for r in range(1, R + 1):
                    tier, refr = rounds.get((seed, seat, r), (1, 0))
                    prev = rounds.get((seed, seat, r - 1), (1, 0))[0] if r > 1 else 1
                    fl = [prev] + [tier] * refr
                    for T in fl:
                        pf = p_fill(card, T)
                        ps = p_slot_depleted(card, T, seed, max(1, r - 1), seat)
                        pd = 1 - (1 - ps) ** SLOTS[T - 1]
                        logq_f += math.log(max(1e-12, 1 - pf))
                        logq_d += math.log(max(1e-12, 1 - pd))
                        if r == R:
                            exp_full += pf
                            exp_dep += pd
                            fills += 1
                    if own.get((seed, seat, r), {}).get(card):
                        ever = True
                seen_full += 1 - math.exp(logq_f)
                seen_dep += 1 - math.exp(logq_d)
                owned_ever += ever
                owned_now += bool(own[(seed, seat, R)].get(card))
            if alive:
                rows[R] = dict(alive=alive, fills_this_round=round(fills / alive, 2),
                               p_offer_this_round_full=round(exp_full / alive, 3),
                               p_offer_this_round_depleted=round(exp_dep / alive, 3),
                               p_seen_by_R_full=round(seen_full / alive, 3),
                               p_seen_by_R_depleted=round(seen_dep / alive, 3),
                               owned_ever_by_R=round(owned_ever / alive, 3),
                               owned_at_R=round(owned_now / alive, 3))
        out[card] = rows
    # tier and fills trajectory
    traj = {}
    for R in range(1, 15):
        ts = [rounds[(s, st, R)] for s, st in seats[line] if (s, st, R) in rounds and (s, st, R) in own]
        if ts:
            traj[R] = dict(tier_mean=round(sum(t for t, _ in ts) / len(ts), 2),
                           refreshes_mean=round(sum(r for _, r in ts) / len(ts), 2))
    comp = collections.Counter(compete[s][tribe] for s, _ in seats[line])
    res["lines"][line] = dict(cards=out, trajectory=traj, same_tribe_seats_in_lobby=dict(sorted(comp.items())))

json.dump(res, open(OUT, "w"), indent=1)
print("wrote", OUT)
