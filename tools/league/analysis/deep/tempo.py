"""Tempo and economy: when seats level, what they paid, how they spend, and
how tempo relates to first place versus top four."""
from collections import Counter

from common import SCOPES, Table, scopes_of, round_bucket, fmt

LIST_PRICE = {1: 8, 2: 12, 3: 16, 4: 19, 5: 26}   # upgrade_costs from the record header
OUTCOME_ROUNDS = (4, 6, 8, 10)
MAX_TIER = 6


def reach_rounds(seat):
    """Round each tier 2..6 was first held at the end of a turn, or None."""
    out = {}
    for t in range(2, MAX_TIER + 1):
        out[t] = next((r for r in sorted(seat.rounds) if seat.rounds[r].tier >= t), None)
    return out


def tier2_group(r):
    if r is None:
        return "never"
    return str(r) if r <= 5 else "6+"


def outcomes(table, key, pair, place):
    table.add(key + ("place",), pair, place)
    table.add(key + ("win",), pair, place == 1, rate=True)
    table.add(key + ("top4",), pair, place <= 4, rate=True)
    if place <= 4:
        table.add(key + ("win_given_top4",), pair, place == 1, rate=True)


def analyse(deep):
    by_round = Table()       # scope, final tribe ('all' or tribe), round
    groups = Table()         # scope, grouping, group
    conversion = Table()     # scope, final tribe
    curves = {s: Counter() for s in SCOPES}
    curve_outcome = Table()
    upgrades = Table()
    for seat in deep.seats.values():
        pair = seat.pair
        reach = reach_rounds(seat)
        sig = "-".join(str(reach[t]) if reach[t] else "x" for t in range(2, MAX_TIER + 1))
        for scope in scopes_of(seat.colour):
            outcomes(groups, (scope, "tier2_round", tier2_group(reach[2])), pair, seat.place)
            for t in range(3, MAX_TIER + 1):
                g = reach[t]
                label = "never" if g is None else str(g if g <= 14 else "15+")
                outcomes(groups, (scope, f"tier{t}_round", label), pair, seat.place)
            for R in OUTCOME_ROUNDS:
                if R in seat.rounds:
                    outcomes(groups, (scope, f"tier_at_round_{R}", str(seat.rounds[R].tier)), pair, seat.place)
            rounds_t1 = sum(1 for r in seat.rounds.values() if r.tier == 1)
            outcomes(groups, (scope, "turns_on_tier1", str(rounds_t1 if rounds_t1 < 5 else "5+")), pair, seat.place)
            curves[scope][sig] += 1
            outcomes(curve_outcome, (scope, sig), pair, seat.place)
            for tribe in ("all", seat.tribe):
                outcomes(conversion, (scope, tribe), pair, seat.place)
                for p in range(1, 9):
                    conversion.add((scope, tribe, f"place_{p}"), pair, seat.place == p, rate=True)
        last_upgrade = 1   # the discount counts turns from round 2 (rulebook 4.6.3)
        for r, rd in sorted(seat.rounds.items()):
            rb = round_bucket(r)
            turn = deep.turns.get((seat.game, seat.seat, r))
            for scope in scopes_of(seat.colour):
                for tribe in ("all", seat.tribe):
                    key = (scope, tribe, rb)
                    by_round.add(key + ("alive",), pair, 1)
                    by_round.add(key + ("tier",), pair, rd.tier)
                    by_round.add(key + ("board_stats",), pair, rd.stats)
                    by_round.add(key + ("board_units",), pair, rd.board_n)
                    by_round.add(key + ("golden_units",), pair, rd.golden)
                    by_round.add(key + ("hand_end_of_turn",), pair, rd.hand)
                    by_round.add(key + ("gold_left",), pair, rd.gold_left)
                    by_round.add(key + ("gold_from_cards",), pair, rd.gold_from_cards)
                    if rd.gold_start is not None:
                        by_round.add(key + ("gold_start",), pair, rd.gold_start)
                        by_round.add(key + ("unspent_share",), pair, rd.gold_left, n=max(rd.gold_start, 0) or 0)
                    if rd.hp is not None:
                        by_round.add(key + ("hp_alive",), pair, rd.hp)
                    if turn is not None:
                        for name in ("buys", "spell_buys", "sells", "refreshes", "upgrades",
                                     "plays", "abilities", "freezes", "buy_gold"):
                            by_round.add(key + (name,), pair, getattr(turn, name))
            if turn is not None:
                for from_tier, paid in turn.upgrade_paid:
                    listed = LIST_PRICE.get(from_tier, paid)
                    waited = r - last_upgrade
                    last_upgrade = r
                    for scope in scopes_of(seat.colour):
                        upgrades.add((scope, from_tier, "paid"), pair, paid)
                        upgrades.add((scope, from_tier, "discount"), pair, listed - paid)
                        upgrades.add((scope, from_tier, "share_of_list_paid"), pair, paid, n=listed)
                        upgrades.add((scope, from_tier, "turns_waited"), pair, waited)
                        upgrades.add((scope, from_tier, "round"), pair, r)
    # Health over time counting the dead at zero: no survivor bias.
    hp_all = Table()
    for g in deep.games:
        for seat_id in range(8):
            seat = deep.seats[g["game"], seat_id]
            for r in range(1, g["rounds"] + 1):
                hp = g["hp"].get((r, seat_id))
                if hp is None:
                    continue
                for scope in scopes_of(seat.colour):
                    hp_all.add((scope, round_bucket(r), "hp_dead_as_zero"), g["pair"], hp)
                    hp_all.add((scope, round_bucket(r), "alive_share"), g["pair"], hp > 0, rate=True)
    top_curves = []
    for scope in SCOPES:
        for sig, n in curves[scope].most_common(8):
            row = {"scope": scope, "curve": sig, "seats": n}
            for m in ("place", "win", "top4", "win_given_top4"):
                row[m] = curve_outcome.get((scope, sig, m))
            top_curves.append(row)
    return {
        "by_round": by_round.rows(("scope", "final_tribe", "round")),
        "hp_by_round": hp_all.rows(("scope", "round")),
        "outcome_by_tempo": groups.rows(("scope", "grouping", "group")),
        "conversion": conversion.rows(("scope", "final_tribe")),
        "common_curves": top_curves,
        "upgrade_prices": upgrades.rows(("scope", "from_tier")),
        "list_price": LIST_PRICE,
    }


def lookup(rows, metric, **match):
    for row in rows:
        if row["metric"] == metric and all(row.get(k) == v for k, v in match.items()):
            return row
    return None


def markdown(deep, data):
    L = ["## Tempo and economy", ""]
    conv = data["conversion"]
    L += ["**First place against top four.** `win | top4` is the share of top-four finishes that were wins "
          "(12.5% of seats win and 50% make top four, so an even bot converts 25%).", "",
          "| Seats | Avg place | Win | Top four | Win given top four |", "|---|---|---|---|---|"]
    for scope in SCOPES:
        L.append(f"| {scope} | " + " | ".join(fmt(lookup(conv, m, scope=scope, final_tribe="all"))
                                             for m in ("place", "win", "top4", "win_given_top4")) + " |")
    L += ["", "**Round of the first tier-up, against outcome** (within a team the bot chose its own tempo, "
          "so a difference here is the bot's habit meeting the game, not a controlled trial).", "",
          "| Seats | Tier 2 in round | Seats | Avg place | Win | Win given top four |", "|---|---|---|---|---|---|"]
    rows = [r for r in data["outcome_by_tempo"] if r["grouping"] == "tier2_round" and r["metric"] == "place"
            and r["scope"] != "both"]
    for r in rows:
        k = dict(scope=r["scope"], grouping="tier2_round", group=r["group"])
        L.append(f"| {r['scope']} | {r['group']} | {r['count']} | {fmt(r)} | "
                 f"{fmt(lookup(data['outcome_by_tempo'], 'win', **k))} | "
                 f"{fmt(lookup(data['outcome_by_tempo'], 'win_given_top4', **k))} |")
    L += ["", "**Most common levelling curves** (round reaching tier 2-3-4-5-6, x = never).", "",
          "| Seats | Curve | n | Avg place | Win | Win given top four |", "|---|---|---|---|---|---|"]
    for r in data["common_curves"]:
        if r["scope"] == "both":
            continue
        L.append(f"| {r['scope']} | {r['curve']} | {r['seats']} | {fmt(r['place'])} | {fmt(r['win'])} | "
                 f"{fmt(r['win_given_top4'])} |")
    L += ["", "**Upgrade price paid** (gold before the upgrade minus gold at the next decision; list price "
          "from the rules header). Waiting n turns takes 1+2+..+n off (rulebook 4.6.3), so 3 turns = 6 off, "
          "4 turns = 10 off.", "",
          "| Seats | From tier | List | Paid | Turns waited | Round |", "|---|---|---|---|---|---|"]
    up = data["upgrade_prices"]
    for scope in ("red", "blue"):
        for t in range(1, 6):
            paid = lookup(up, "paid", scope=scope, from_tier=t)
            if paid:
                L.append(f"| {scope} | {t} | {data['list_price'][t]} | {fmt(paid)} | "
                         f"{fmt(lookup(up, 'turns_waited', scope=scope, from_tier=t))} | "
                         f"{fmt(lookup(up, 'round', scope=scope, from_tier=t))} |")
    L += ["", "**Per round, alive seats** (means; survivors only, so late rounds describe the boards that "
          "lived; health counting the dead as zero is in `tempo.json` `hp_by_round`).", "",
          "| Round | Seats | Alive | Tier | Board stats | Gold at start | Gold left | Buys | Refreshes | Sells |",
          "|---|---|---|---|---|---|---|---|---|---|"]
    br = data["by_round"]
    for r in (1, 2, 3, 4, 5, 6, 8, 10, 12, 14):
        for scope in ("red", "blue"):
            k = dict(scope=scope, final_tribe="all", round=r)
            alive = lookup(br, "alive", **k)
            if not alive:
                continue
            cells = []
            for m in ("tier", "board_stats", "gold_start", "gold_left", "buys", "refreshes", "sells"):
                s = lookup(br, m, **k)
                cells.append(f"{s['mean']:.1f}" if s and s["mean"] is not None else "—")
            L.append(f"| {r} | {scope} | {alive['count']} | " + " | ".join(cells) + " |")
    return "\n".join(L)
