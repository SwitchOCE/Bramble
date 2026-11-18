"""Tempo and economy: when seats level, what they paid, how they spend, and
how tempo relates to first place versus top four."""
from collections import Counter

from common import SCOPES, TEAMS, THIN_COUNT, Contrast, Table, scopes_of, round_bucket, fmt, team_shares, team_tag

OUTCOME_ROUNDS = (4, 6, 8, 10)
MAX_TIER = 6
# Fixed-horizon curves: tiers held at these rounds, among seats alive at the last one.
HORIZONS = {8: (2, 4, 6, 8), 11: (3, 5, 7, 9, 11)}
# "Tier N reached by round R" groups, among seats alive at R.
REACH_HORIZON = {3: 8, 4: 10, 5: 12, 6: 14}


def list_prices(config):
    """{from tier: base price} from the record header's upgrade_costs; {} if absent."""
    return {i + 1: c for i, c in enumerate(config.get("upgrade_costs", []))}


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


def horizon_curve(seat, rounds):
    """Tiers held at each of `rounds`, e.g. '1-2-3-4', or None if the seat was
    not alive at the last of them. The label no longer encodes how long the
    seat lived."""
    if rounds[-1] not in seat.rounds:
        return None
    return "-".join(str(seat.rounds[r].tier) for r in rounds)


def outcomes(table, key, pair, place):
    table.add(key + ("place",), pair, place)
    table.add(key + ("win",), pair, place == 1, rate=True)
    table.add(key + ("top4",), pair, place <= 4, rate=True)
    if place <= 4:
        table.add(key + ("win_given_top4",), pair, place == 1, rate=True)


def lobby(deep):
    """Per team and game: did one of its seats come first, and how many lobbies
    it would win if first place fell at random among the four top-four seats
    (its top-four seats / 4). Per top-four finish that null is exactly 25%,
    however many of the top four a team fills."""
    t = Table()
    for g in deep.games:
        for colour in TEAMS:
            places = [p for s, p in g["places"].items() if g["colours"][s] == colour]
            won = any(p == 1 for p in places)
            expected = sum(p <= 4 for p in places) / 4
            t.add((colour, "lobby_win"), g["pair"], won, rate=True)
            t.add((colour, "lobby_win_expected_if_random_among_top4"), g["pair"], expected)
            t.add((colour, "lobby_win_minus_expected"), g["pair"], won - expected)
            t.add((colour, "top4_seats_per_game"), g["pair"], sum(p <= 4 for p in places))
    return t.rows(("scope",))


def tribe_gap(deep, conversion):
    """Within each team: worst minus best average place over final tribes with
    at least 30 seats, as a contrast over the same seed pairs. Picking the best
    and worst after looking makes the gap a little larger than the truth; the
    interval does not correct for that."""
    out = []
    for team in TEAMS:
        rows = [r for r in conversion if r["scope"] == team and r["metric"] == "place"
                and r["final_tribe"] not in ("all", "(none)") and r["count"] >= THIN_COUNT]
        if len(rows) < 2:
            out.append({"scope": team, "best": None, "worst": None, "tribes": len(rows), "gap": None})
            continue
        best = min(rows, key=lambda r: r["mean"])["final_tribe"]
        worst = max(rows, key=lambda r: r["mean"])["final_tribe"]
        c = Contrast()
        for seat in deep.seats.values():
            if seat.colour == team and seat.tribe in (best, worst):
                c.add(seat.pair, 0 if seat.tribe == worst else 1, seat.place)
        out.append({"scope": team, "best": best, "worst": worst, "tribes": len(rows), "gap": c.result()})
    return out


def analyse(deep):
    prices = list_prices(deep.config)
    by_round = Table()       # scope, final tribe ('all' or tribe), round
    groups = Table()         # scope, grouping, group
    conversion = Table()     # scope, final tribe
    curves = {s: Counter() for s in SCOPES}
    curve_outcome = Table()
    horizon = {R: {s: Counter() for s in SCOPES} for R in HORIZONS}
    horizon_outcome = Table()
    upgrades = Table()
    for seat in deep.seats.values():
        pair = seat.pair
        reach = reach_rounds(seat)
        sig = "-".join(str(reach[t]) if reach[t] else "x" for t in range(2, MAX_TIER + 1))
        hz = {R: horizon_curve(seat, rs) for R, rs in HORIZONS.items()}
        for scope in scopes_of(seat.colour):
            outcomes(groups, (scope, "tier2_round", tier2_group(reach[2])), pair, seat.place)
            for t in range(3, MAX_TIER + 1):
                g = reach[t]
                label = "never" if g is None else str(g if g <= 14 else "15+")
                outcomes(groups, (scope, f"tier{t}_round", label), pair, seat.place)
                R = REACH_HORIZON[t]
                if R in seat.rounds:
                    label = str(g) if g is not None and g <= R else f"after_{R}_or_never"
                    outcomes(groups, (scope, f"tier{t}_round_alive_at_{R}", label), pair, seat.place)
            for R in OUTCOME_ROUNDS:
                if R in seat.rounds:
                    outcomes(groups, (scope, f"tier_at_round_{R}", str(seat.rounds[R].tier)), pair, seat.place)
            rounds_t1 = sum(1 for r in seat.rounds.values() if r.tier == 1)
            outcomes(groups, (scope, "turns_on_tier1", str(rounds_t1 if rounds_t1 < 5 else "5+")), pair, seat.place)
            curves[scope][sig] += 1
            outcomes(curve_outcome, (scope, sig), pair, seat.place)
            for R, c in hz.items():
                if c is not None:
                    horizon[R][scope][c] += 1
                    outcomes(horizon_outcome, (scope, R, c), pair, seat.place)
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
                    listed = prices.get(from_tier)
                    waited = r - last_upgrade
                    last_upgrade = r
                    for scope in scopes_of(seat.colour):
                        upgrades.add((scope, from_tier, "paid"), pair, paid)
                        if listed is not None:
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
    hz_rows = []
    for R, rounds in HORIZONS.items():
        for scope in SCOPES:
            alive = sum(horizon[R][scope].values())
            for sig, n in horizon[R][scope].most_common(10):
                row = {"scope": scope, "alive_at": R, "rounds": list(rounds), "curve": sig, "seats": n,
                       "alive_seats": alive}
                for m in ("place", "win", "top4", "win_given_top4"):
                    row[m] = horizon_outcome.get((scope, R, sig, m))
                hz_rows.append(row)
    team_shares(hz_rows, ("alive_at", "curve"), count=lambda r: r["seats"])
    conv_rows = team_shares(conversion.rows(("scope", "final_tribe")), ("final_tribe", "metric"))
    return {
        "by_round": team_shares(by_round.rows(("scope", "final_tribe", "round")), ("final_tribe", "round", "metric")),
        "hp_by_round": hp_all.rows(("scope", "round")),
        "outcome_by_tempo": team_shares(groups.rows(("scope", "grouping", "group")), ("grouping", "group", "metric")),
        "conversion": conv_rows,
        "tribe_gap_within_team": tribe_gap(deep, conv_rows),
        "lobby": lobby(deep),
        "common_curves": top_curves,
        "curves_at_horizon": hz_rows,
        "upgrade_prices": upgrades.rows(("scope", "from_tier")),
        "list_price": prices,
    }


def lookup(rows, metric, **match):
    for row in rows:
        if row["metric"] == metric and all(row.get(k) == v for k, v in match.items()):
            return row
    return None


def markdown(deep, data):
    L = ["## Tempo and economy", ""]
    conv, lob = data["conversion"], data["lobby"]
    L += ["**First place against top four, per team.** *Win given top four* is the share of a team's top-four "
          "finishes that were wins. If first place fell at random among the four top-four seats, that share "
          "would be 25% whatever the team's number of top-four seats, so 25% is the yardstick for each top-four "
          "finish. *Lobby wins* is the share of games one of the team's four seats won (two even teams: 50%); "
          "*expected* is what the team's top-four seats would win at random among the top four.", "",
          "| Team | Avg place | Seat win | Top four | Win given top four | Lobby wins | Expected lobby wins | "
          "Lobby wins minus expected |", "|---|---|---|---|---|---|---|---|"]
    for scope in TEAMS:
        L.append(f"| {scope} | " + " | ".join(fmt(lookup(conv, m, scope=scope, final_tribe="all"))
                                             for m in ("place", "win", "top4", "win_given_top4")) + " | "
                 + " | ".join(fmt(lookup(lob, m, scope=scope), pct=True) for m in
                              ("lobby_win", "lobby_win_expected_if_random_among_top4", "lobby_win_minus_expected"))
                 + " |")
    L += ["", "**Round of the first tier-up, against outcome.** When every seat of one team levels in the same round, "
          "this table **compares the two bots**, not two "
          "tempos: everything else those bots do differs too. Only a group that splits one team's seats is a "
          "within-team comparison, and even then the bot chose its tempo for its own reasons.", "",
          "| Team | Tier 2 in round | Seats | Avg place | Seat win | Win given top four |", "|---|---|---|---|---|---|"]
    rows = [r for r in data["outcome_by_tempo"] if r["grouping"] == "tier2_round" and r["metric"] == "place"
            and r["scope"] != "both"]
    for r in rows:
        k = dict(scope=r["scope"], grouping="tier2_round", group=r["group"])
        L.append(f"| {r['scope']} | {r['group']} | {r['count']} | {fmt(r)} | "
                 f"{fmt(lookup(data['outcome_by_tempo'], 'win', **k))} | "
                 f"{fmt(lookup(data['outcome_by_tempo'], 'win_given_top4', **k))} |")
    for R, rounds in HORIZONS.items():
        L += ["", f"**Levelling by round {R}** (tier held at rounds {', '.join(map(str, rounds))}, among seats "
              f"alive at round {R}, so the label does not encode how long the seat lived; most common per team).", "",
              "| Team | Tiers | Seats | Of alive | Avg place | Seat win | Win given top four |",
              "|---|---|---|---|---|---|---|"]
        for scope in TEAMS:
            for r in [x for x in data["curves_at_horizon"] if x["scope"] == scope and x["alive_at"] == R][:5]:
                L.append(f"| {scope} | {r['curve']} | {r['seats']} | {r['alive_seats']} | {fmt(r['place'])} | "
                         f"{fmt(r['win'])} | {fmt(r['win_given_top4'])} |")
    prices = data["list_price"]
    L += ["", "**Upgrade price paid** (gold before the upgrade minus gold at the next decision; list price from "
          "the record header's `upgrade_costs`). Waiting n turns takes 1+2+..+n off (rulebook 4.6.3), so 3 turns "
          "= 6 off, 4 turns = 10 off.", "",
          "| Team | From tier | List | Paid | Turns waited | Round |", "|---|---|---|---|---|---|"]
    up = data["upgrade_prices"]
    for scope in TEAMS:
        for t in range(1, MAX_TIER):
            paid = lookup(up, "paid", scope=scope, from_tier=t)
            if paid:
                L.append(f"| {scope} | {t} | {prices.get(t, '?')} | {fmt(paid)} | "
                         f"{fmt(lookup(up, 'turns_waited', scope=scope, from_tier=t))} | "
                         f"{fmt(lookup(up, 'round', scope=scope, from_tier=t))} |")
    L += ["", "**Per round, alive seats** (means; survivors only, so late rounds describe the boards that "
          "lived; health counting the dead as zero is in `tempo.json` `hp_by_round`).", "",
          "| Round | Team | Alive | Tier | Board stats | Gold at start | Gold left | Buys | Refreshes | Sells |",
          "|---|---|---|---|---|---|---|---|---|---|"]
    br = data["by_round"]
    for r in (1, 2, 3, 4, 5, 6, 8, 10, 12, 14):
        for scope in TEAMS:
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
