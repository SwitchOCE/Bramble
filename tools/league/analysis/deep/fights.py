"""Fights and game shape: damage, upsets on paper, when games are decided,
comebacks, seat effects and tribe against tribe by stage."""
from collections import defaultdict

from match_data import band, BANDS, NONE
from common import SCOPES, Table, Contrast, scopes_of, round_bucket, fmt

RATIO_BUCKETS = ((1.0, "1-1.25x"), (1.25, "1.25-1.5x"), (1.5, "1.5-2x"), (2.0, "2-3x"), (3.0, "3x+"))


def ratio_bucket(strong, weak):
    ratio = strong / weak if weak > 0 else float("inf")
    label = RATIO_BUCKETS[0][1]
    for lo, name in RATIO_BUCKETS:
        if ratio >= lo:
            label = name
    return label


def decided_round(game, winner):
    """First round from which the eventual winner led on health (ties count as
    leading) at the end of every later round. None if never (cannot happen when
    the winner leads the final round, which it always does once alone)."""
    hp = game["hp"]
    decided = None
    for r in range(1, game["rounds"] + 1):
        alive = {s: hp[r, s] for s in range(8) if (r, s) in hp and hp[r, s] > 0}
        if not alive or winner not in alive:
            decided = None
            continue
        leads = alive[winner] >= max(alive.values())
        if leads and decided is None:
            decided = r
        elif not leads:
            decided = None
    return decided


def hp_rank(game, seat, r):
    """1 + number of alive seats with strictly more health after round r."""
    hp = game["hp"]
    mine = hp.get((r, seat))
    if not mine:
        return None
    return 1 + sum(1 for s in range(8) if hp.get((r, s), 0) > mine)


def analyse(deep):
    t = Table()
    upsets = Table()
    h2h = Table()
    for s in deep.sides:
        for scope in scopes_of(s.colour):
            rb = round_bucket(s.round)
            t.add((scope, rb, "damage_taken_per_fight"), s.pair, s.damage)
            if s.score == 0.0:
                t.add((scope, rb, "damage_when_losing"), s.pair, s.damage)
            t.add((scope, rb, "draw"), s.pair, s.score == 0.5, rate=True)
            t.add((scope, rb, "ghost_fight"), s.pair, s.opp < 0, rate=True)
            t.add((scope, rb, "fight_score"), s.pair, s.score)
            if s.opp >= 0 and s.opp_tribe is not None:
                for stage in (band(s.round), "all"):
                    h2h.add((scope, stage, s.tribe, s.opp_tribe, "score"), s.pair, s.score, rate=True)
                    if s.opp_tribe != s.tribe:
                        h2h.add((scope, stage, s.tribe, "(other tribes)", "score"), s.pair, s.score, rate=True)
        # Upsets: each live fight once, from the side with fewer stats on paper.
        if s.opp >= 0 and s.opp_stats is not None and s.stats < s.opp_stats:
            bucket = ratio_bucket(s.opp_stats, s.stats)
            for scope in ("both",):
                for stage in (band(s.round), "all"):
                    upsets.add((scope, stage, bucket, "all", "score"), s.pair, s.score, rate=True)
                    upsets.add((scope, stage, "any", s.tribe, "score"), s.pair, s.score, rate=True)
                    upsets.add((scope, stage, "any", "all", "score"), s.pair, s.score, rate=True)
    games = Table()
    by_rank = Table()
    seats = Table()
    seat_gap = defaultdict(Contrast)
    for g in deep.games:
        winner = next(s for s, p in g["places"].items() if p == 1)
        d = decided_round(g, winner)
        games.add(("all", "decided_round"), g["pair"], d if d is not None else g["rounds"])
        games.add(("all", "decided_share_of_game"), g["pair"], (d or g["rounds"]) / g["rounds"])
        games.add(("all", "rounds"), g["pair"], g["rounds"])
        colour = g["colours"][winner]
        games.add((colour, "decided_round"), g["pair"], d if d is not None else g["rounds"])
        ranks = [hp_rank(g, winner, r) for r in range(1, g["rounds"] + 1)]
        ranks = [x for x in ranks if x is not None]
        worst = max(ranks) if ranks else None
        mins = [g["hp"][r, winner] for r in range(1, g["rounds"] + 1) if (r, winner) in g["hp"]]
        for scope in (colour, "all"):
            games.add((scope, "winner_worst_hp_rank"), g["pair"], worst)
            games.add((scope, "winner_was_bottom_half"), g["pair"], worst >= 5, rate=True)
            games.add((scope, "winner_min_hp"), g["pair"], min(mins))
        for seat_id in range(8):
            seat = deep.seats[g["game"], seat_id]
            for scope in scopes_of(seat.colour):
                seats.add((scope, seat_id, "place"), g["pair"], seat.place)
                seats.add((scope, seat_id, "win"), g["pair"], seat.place == 1, rate=True)
                group = 0 if seat_id <= 2 else 1 if seat_id >= 5 else None
                if group is not None:
                    seat_gap[scope].add(g["pair"], group, seat.place)
            for R in (4, 6, 8, 10):
                rank = hp_rank(g, seat_id, R)
                if rank is not None:
                    for scope in scopes_of(seat.colour):
                        by_rank.add((scope, R, rank, "win"), g["pair"], seat.place == 1, rate=True)
                        by_rank.add((scope, R, rank, "top4"), g["pair"], seat.place <= 4, rate=True)
    ghosts = Table()
    for s in deep.sides:
        ghosts.add(("both", s.seat, "ghost_fight"), s.pair, s.opp < 0, rate=True)
    gap = []
    for scope, c in seat_gap.items():
        row = {"scope": scope, "metric": "place_seats_0_2_minus_5_7"}
        row.update(c.result())
        gap.append(row)
    return {
        "by_round": t.rows(("scope", "round")),
        "upsets": upsets.rows(("scope", "band", "stat_ratio", "weaker_tribe")),
        "tribe_vs_tribe": h2h.rows(("scope", "band", "tribe", "opponent")),
        "game_shape": games.rows(("scope",)),
        "outcome_by_hp_rank": by_rank.rows(("scope", "round", "hp_rank")),
        "by_seat": seats.rows(("scope", "seat")) + ghosts.rows(("scope", "seat")),
        "seat_gap": gap,
    }


def get(rows, metric, **k):
    for r in rows:
        if r["metric"] == metric and all(r.get(a) == b for a, b in k.items()):
            return r
    return None


def markdown(deep, data):
    L = ["## Fights and game shape", ""]
    up = data["upsets"]
    L += ["**Underdogs on paper.** Live fights from the side with fewer total stats (attack + health). "
          "The rate is its fight score (draw = half).", "",
          "| Stats ratio | All rounds | 1-3 | 4-6 | 7-9 | 10-12 | 13+ |", "|---|---|---|---|---|---|---|"]
    for _, name in RATIO_BUCKETS:
        L.append(f"| {name} | " + " | ".join(fmt(row_of(up, b, name, "all")) for b in ("all", *BANDS)) + " |")
    L += ["", "| Weaker side's tribe | All rounds | 7-9 | 10-12 | 13+ |", "|---|---|---|---|---|"]
    for tribe in (*deep.tribes, NONE):
        L.append(f"| {tribe} | " + " | ".join(fmt(row_of(up, b, "any", tribe)) for b in ("all", "7-9", "10-12", "13+")) + " |")
    L += ["", "**Tribe against other tribes, by stage** (current main tribes, live opponents of a different tribe; "
          "fight score). Pooled seats mix the two bots' strength into each tribe.", "",
          "| Tribe | Seats | 1-3 | 4-6 | 7-9 | 10-12 | 13+ |", "|---|---|---|---|---|---|---|"]
    for tribe in deep.tribes:
        for scope in SCOPES:
            cells = [tvt(data["tribe_vs_tribe"], scope, b, tribe) for b in BANDS]
            if any(c is not None for c in cells):
                L.append(f"| {tribe} | {scope} | " + " | ".join(fmt(c) for c in cells) + " |")
    gs = data["game_shape"]
    L += ["", "**When games are decided.** The decided round is the first round from which the eventual winner "
          "had the most health (ties count) at the end of every later round.", "",
          "| | Value |", "|---|---|",
          f"| Game length (rounds) | {fmt(get(gs, 'rounds', scope='all'))} |",
          f"| Decided round | {fmt(get(gs, 'decided_round', scope='all'))} |",
          f"| Decided, share of the game | {fmt(get(gs, 'decided_share_of_game', scope='all'), True)} |",
          f"| Winner's worst health rank | {fmt(get(gs, 'winner_worst_hp_rank', scope='all'))} |",
          f"| Winner was ever in the bottom half on health | {fmt(get(gs, 'winner_was_bottom_half', scope='all'))} |",
          f"| Winner's lowest health | {fmt(get(gs, 'winner_min_hp', scope='all'))} |"]
    L += ["", "**Win rate by health rank after round 8** (rank 1 = most health).", "",
          "| Rank | Red | Blue |", "|---|---|---|"]
    for rank in range(1, 9):
        L.append(f"| {rank} | " + " | ".join(fmt(get(data["outcome_by_hp_rank"], "win", scope=s, round=8, hp_rank=rank))
                                              for s in ("red", "blue")) + " |")
    L += ["", "**Seats.** Average place by seat id (lower is better).", "",
          "| Seat | " + " | ".join(str(i) for i in range(8)) + " |", "|---|" + "---|" * 8]
    for scope in SCOPES:
        L.append(f"| {scope} | " + " | ".join(
            f"{get(data['by_seat'], 'place', scope=scope, seat=i)['mean']:.2f}" for i in range(8)) + " |")
    for g in data["seat_gap"]:
        L.append("")
        L.append(f"Seats 0-2 minus seats 5-7, {g['scope']}: {fmt(g, False)} places (negative = low seats place better).")
    return "\n".join(L)


def tvt(rows, scope, b, tribe):
    for r in rows:
        if r["scope"] == scope and r["band"] == b and r["tribe"] == tribe and r["opponent"] == "(other tribes)":
            return r
    return None


def row_of(rows, b, ratio, tribe):
    for r in rows:
        if r["band"] == b and r["stat_ratio"] == ratio and r["weaker_tribe"] == tribe:
            return r
    return None

