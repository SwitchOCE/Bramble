"""Shop-luck estimate from the pool rules (game_config.gd full_game, unit_pool.gd draw_by_odds,
recruit_rules.gd _fill_shop). An estimate: no pool depletion by other seats, no freezes, no
discovers/hero powers/triple rewards. Each seat replays a real seat's tier and paid-refresh
history (rounds.csv), so shop exposure matches what the bots actually saw in volume.

Prints P(seen at least once by round r) for each piece, against the captured share that owns it.
Also the expected number of Ring/thank spells offered by R12, against what the paper plans.
"""
import json, os, random, statistics as st

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "seats.json")))
A1 = json.load(open(os.path.join(HERE, "a1_presence.json")))
E = D["econ"]

ODDS = [[100], [50, 50], [20, 30, 50], [10, 15, 25, 50], [5, 10, 15, 25, 45], [5, 5, 10, 15, 25, 40]]
SHOP = [4, 4, 4, 5, 5, 6]
# cards in the pool per tier with six tribes in the lobby (all tribes available) + neutrals
CARDS_PER_TIER = [21, 21, 21, 20, 13, 13]
# spells in the pool by tier (pool: true), and which of them are aimed at a board slot/unit
SPELLS = {1: ["elderflower_cordial", "pinch_of_dust", "rainy_day"],
          2: ["bread_from_the_back", "cold_frame", "horseshoe", "hungry_gap", "shake_the_tree", "spore_cloud", "squirrel_away"],
          3: ["harvest_supper", "stand_behind_me"],
          4: ["boundary_stone", "market_day", "market_stall"],
          5: ["hiring_fair", "last_orders"],
          6: ["beltane_bonfire"]}
AIMED = {"elderflower_cordial", "pinch_of_dust", "bread_from_the_back", "cold_frame", "horseshoe", "spore_cloud",
         "harvest_supper", "stand_behind_me", "boundary_stone", "last_orders", "beltane_bonfire"}
TIER = {"chiffchaff": 1, "one_swallow": 1, "mrs_dunnock": 1, "mrs_jay": 2, "mr_redbreast": 2, "redwing": 2,
        "jack_daw": 3, "tom_tit": 3, "old_tern": 3, "mrs_stork": 4, "mag_pye": 4, "cuckoo": 4, "great_lump": 5,
        "mother_goose": 5, "gabble_ratchet": 6, "seven_whistlers": 6,
        "nan_toadstool": 1, "rainbow_chaser": 1, "hedge_witch": 1, "old_moth_annis": 2, "sally_spore": 2,
        "hob_in_the_hearth": 2, "cluricaun": 3, "lob_lie_by_the_fire": 3, "silky": 3, "changeling": 4,
        "will_o_the_wisp": 4, "cradle_fetch": 4, "belladonna": 5, "reel_mistress": 5, "fairy_monarch": 6,
        "queen_of_elfland": 6}


def p_card_slot(card_tier, shop_tier):
    """Chance one shop slot shows one given card (tier by odds, then uniform over that tier's cards)."""
    row = ODDS[shop_tier - 1]
    if card_tier > shop_tier:
        return 0.0
    return row[card_tier - 1] / sum(row) / CARDS_PER_TIER[card_tier - 1]


def p_spell(spell, shop_tier):
    row = ODDS[shop_tier - 1]
    for t, names in SPELLS.items():
        if spell in names:
            return 0.0 if t > shop_tier else row[t - 1] / sum(row) / len(names)


def p_aimed(shop_tier):
    row = ODDS[shop_tier - 1]
    return sum(row[t - 1] / sum(row) * sum(1 for s in SPELLS[t] if s in AIMED) / len(SPELLS[t]) for t in range(1, shop_tier + 1))


def run(line, pieces, n=4000, seed=11):
    rng = random.Random(seed)
    histories = list(E[line].values())
    seen = {p: {r: 0 for r in range(1, 15)} for p in pieces}
    sightings12 = {p: [] for p in pieces}
    spells = {k: {r: [] for r in range(1, 15)} for k in ("spore_cloud", "boundary_stone", "pinch_of_dust", "aimed", "harvest_supper")}
    for _ in range(n):
        h = rng.choice(histories)
        first = {}
        cnt = {p: 0 for p in pieces}
        sc = {k: 0 for k in spells}
        for r in range(1, 15):
            x = h.get(str(r)) or h[max(h, key=int)]
            tier = x["tier"]
            refills = 1 + x["refresh"]
            for _ in range(refills):
                for p in pieces:
                    q = p_card_slot(TIER[p], tier)
                    k = sum(1 for _ in range(SHOP[tier - 1]) if rng.random() < q)
                    if k:
                        cnt[p] += k
                        first.setdefault(p, r)
                # one spell slot
                for k2 in ("spore_cloud", "boundary_stone", "pinch_of_dust", "harvest_supper"):
                    if rng.random() < p_spell(k2, tier):
                        sc[k2] += 1
                if rng.random() < p_aimed(tier):
                    sc["aimed"] += 1
            for k2 in spells:
                spells[k2][r].append(sc[k2])
            if r == 12:
                for p in pieces:
                    sightings12[p].append(cnt[p])
        for p in pieces:
            for r in range(1, 15):
                if first.get(p, 99) <= r:
                    seen[p][r] += 1
    return ({p: {r: seen[p][r] / n for r in seen[p]} for p in pieces},
            {p: st.mean(v) for p, v in sightings12.items()},
            {k: {r: st.mean(v) for r, v in d.items()} for k, d in spells.items()})


if __name__ == "__main__":
    res = {}
    for line in ("line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court"):
        pieces = [p for p in TIER if (p in A1[line]["first"])]
        seen, sight, spells = run(line, pieces)
        print("\n=====", line, " P(seen by R) from shop luck  |  captured share owning it by R (from R8 snapshots)")
        print("    %-22s %6s %6s %6s | %6s %6s %6s | sightings by R12" % ("piece", "by8", "by10", "by12", "own8", "own10", "own12"))
        for p in pieces:
            f = A1[line]["first"][p]
            print("    %-22s %5.0f%% %5.0f%% %5.0f%% | %5.0f%% %5.0f%% %5.0f%% | %.2f" % (
                p, 100 * seen[p][8], 100 * seen[p][10], 100 * seen[p][12], 100 * f["by8"], 100 * f["by10"], 100 * f["by12"], sight[p]))
        print("    spells offered, cumulative mean by R6/R8/R10/R12: " + "; ".join(
            "%s %s" % (k, "/".join("%.2f" % spells[k][r] for r in (6, 8, 10, 12))) for k in spells))
        res[line] = dict(seen=seen, sightings12=sight, spells=spells)
    json.dump(res, open(os.path.join(HERE, "a2_shopluck.json"), "w"), indent=1)
