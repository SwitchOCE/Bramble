"""Cards: who buys what by stage and final tribe, how long units stay, and
which cards go with winning fights, winning games and top-four games."""
from collections import Counter, defaultdict
import json
import math

from match_data import Stat, band, BANDS, NONE
from cards import adjusted_lift, card_stats
from common import (SCOPES, TEAMS, THIN_COUNT, Z, thin, scopes_of, round_bucket, fmt, card_label, Acc,
                    team_shares, team_tag)

PREDICT_ROUNDS = (6, 9)
HEADLINE_MIN = 100       # fight sides (or boards) a card needs before it can head a table


# ---------------------------------------------------------------------------
# Shop pass: only the card-tribe aggregate, which cards.py does not count.
# Per-card buy rates come from cards.card_stats (see pick_rows).

class StatTable:
    def __init__(self):
        self.stats = defaultdict(Stat)

    def add(self, key, pair, x, n=1):
        self.stats[key].add(pair, x, n)

    def rows(self, names):
        out = []
        for key, st in self.stats.items():
            r = st.result(True)
            row = dict(zip(names, key))
            row.update(r)
            row["thin"] = thin(r["count"], r["pairs"])
            out.append(row)
        return out


def read_shops(deep):
    """Opportunity = one shop line showing at least one buyable copy of the
    unit (as cards.py). Hit = the seat bought that unit from that shop. Summed
    by card tribe and tier."""
    per_tribe = StatTable()     # scope, card tribe, card tier, band, final tribe
    seats = deep.seats
    for raw in deep.match.lines("shops"):
        shop = json.loads(raw)
        seat = seats[shop["game"], shop["seat"]]
        eligible = {o["card"] for o in shop["offers"] if o["buyable"] and not o["spell"]}
        bought = {b["card"] for b in shop["bought"]}
        pair, stage, final = shop["game"] // 2, band(shop["round"]), seat.tribe
        for card in eligible:
            hit = card in bought
            info = deep.library.get(card, {})
            ctribe = "/".join(t for t in info.get("tribes", [])) or NONE
            for scope in scopes_of(seat.colour):
                for b in (stage, "all"):
                    for ft in (final, "all"):
                        per_tribe.add((scope, ctribe, info.get("tier"), b, ft), pair, hit)
    rows = per_tribe.rows(("scope", "card_tribe", "card_tier", "band", "final_tribe"))
    deep.shop = {"per_card_tribe": team_shares(rows, ("card_tribe", "card_tier", "band", "final_tribe"))}


def pick_rows(deep):
    """cards.card_stats (the section 9 count) flattened into rows of
    (scope, card, band, final_tribe); band and final tribe 'all' for margins."""
    stats = card_stats(deep.match)
    rows = []
    for scope, cards in stats.items():
        for card, d in cards.items():
            def add(b, t, s):
                if s and s.get("count"):
                    rows.append({"scope": scope, "card": card, "band": b, "final_tribe": t, **s,
                                 "thin": thin(s["count"], s["pairs"])})
            add("all", "all", d.get("buy"))
            for b, s in d.get("by_band", {}).items():
                add(b, "all", s)
            for t, s in d.get("by_final_tribe", {}).items():
                add("all", t, s)
            for b, ts in d.get("band_and_final_tribe", {}).items():
                for t, s in ts.items():
                    add(b, t, s)
    return team_shares(rows, ("card", "band", "final_tribe"))


# ---------------------------------------------------------------------------
# Record pass: unit tenure by uid.

def read_records(deep):
    sold, eaten = defaultdict(set), defaultdict(set)
    for s in deep.sales:
        sold[s["game"], s["seat"]].add(s["uid"])
    for g_, s_, u in deep.eaten:
        eaten[g_, s_].add(u)
    rows = []
    for g in deep.games:
        path = deep.match.path / "records" / f"game-{g['game']:05}.jsonl"
        if not path.exists():
            continue
        snaps = defaultdict(dict)   # seat -> turn -> {uid: (def, golden)}
        with path.open("rb") as f:
            for line in f:
                if b'"fight_boards"' not in line:
                    continue
                row = json.loads(line)
                if row.get("op") != "fight_boards":
                    continue
                for p in row["players"]:
                    seat = deep.seats.get((g["game"], p["id"]))
                    if p["id"] < 0 or seat is None or row["turn"] not in seat.rounds:
                        continue
                    snaps[p["id"]][row["turn"]] = {u["uid"]: (u["def"], u["golden"]) for u in p["board"] if u}
        for sid, turns in snaps.items():
            key = (g["game"], sid)
            events = None
            if deep.coverage.get("events"):
                events = {"sold": sold.get(key, set()), "eaten": eaten.get(key, set())}
            rows.extend(tenure_rows(deep.seats[key], turns, events))
    deep.tenure = rows


def tenure_rows(seat, turns, events=None):
    """One row per unit uid seen on this seat's fight boards.

    fights: number of fight snapshots it was in. end:
      'kept'    on the seat's last fight board;
      'sold'    a sale of this uid is in events.jsonl.gz (exact);
      'eaten'   eaten by a unit without a sale (exact);
      'tripled' gone, not sold or eaten, and the next board has a new golden
                copy of the same card (inferred);
      'left'    gone otherwise. Without the events log, sold and eaten
                units land here too."""
    order = sorted(turns)
    first, last, count, golden, card = {}, {}, Counter(), {}, {}
    for t in order:
        for uid, (d, gold) in turns[t].items():
            first.setdefault(uid, t)
            last[uid] = t
            count[uid] += 1
            golden[uid] = gold
            card[uid] = d
    final_turn = order[-1] if order else None
    out = []
    for uid in first:
        if last[uid] == final_turn:
            end = "kept"
        elif events is not None and uid in events["sold"]:
            end = "sold"
        elif events is not None and uid in events["eaten"]:
            end = "eaten"
        else:
            nxt = next((t for t in order if t > last[uid]), None)
            new_golden = (not golden[uid]) and nxt is not None and any(
                d == card[uid] and g and first[u] == nxt for u, (d, g) in turns[nxt].items())
            end = "tripled" if new_golden else "left"
        out.append({"pair": seat.pair, "colour": seat.colour, "card": card[uid], "golden": golden[uid],
                    "first": first[uid], "fights": count[uid], "end": end, "final_tribe": seat.tribe,
                    "place": seat.place})
    return out


def tenure(deep):
    exact = deep.coverage.get("events", False)
    t = defaultdict(Acc)
    kinds = {}
    for r in deep.tenure:
        gone = r["end"] not in ("kept", "tripled")
        for scope in scopes_of(r["colour"]):
            key = (scope, r["card"])
            def add(name, x, rate):
                t[key + (name,)].add(r["pair"], x)
                kinds[key + (name,)] = rate
            add("fights_on_board", r["fights"], False)
            add("kept_to_end", r["end"] == "kept", True)
            add("tripled", r["end"] == "tripled", True)
            add("left", gone, True)      # same meaning as before: gone, not kept, not tripled
            if exact:
                add("sold", r["end"] == "sold", True)
                add("eaten", r["end"] == "eaten", True)
                add("left_unexplained", r["end"] == "left", True)
            if gone:
                add("fights_before_leaving", r["fights"], False)
                add("left_after_one_fight", r["fights"] == 1, True)
    rows = []
    for key, acc in t.items():
        row = {"scope": key[0], "card": key[1], "metric": key[2]}
        row.update(acc.result(kinds[key]))
        rows.append(row)
    return team_shares(rows, ("card", "metric"))


# ---------------------------------------------------------------------------
# Lifts.

def lift(present, reference, higher_is_better):
    """Old lift (kept for the `fight_lift` and `board_predicts` keys): boards
    holding the card against the whole stratum, the card's own boards
    included (cards.adjusted_lift, which reports baseline minus observed).
    For higher-is-better outcomes 1 - outcome is passed so positive is good."""
    def flip(cells):
        return {p: [n - x, n] for p, (x, n) in cells.items()}
    if higher_is_better:
        present = {k: flip(v) for k, v in present.items()}
        reference = {k: flip(v) for k, v in reference.items()}
    r = adjusted_lift(present, reference)
    r["thin"] = thin(r["count"], r["pairs"])
    return r


def lift_vs_others(present, reference, higher_is_better):
    """Boards holding the card against boards of the same stratum that do NOT
    hold it. With b_s = baseline of the other boards in stratum s:

        lift = sum_s (X_cs - N_cs b_s) / sum_s N_cs    (sign flipped when lower is better)

    Strata where every board holds the card have no comparison and are left
    out (`strata_without_comparison`). The interval is clustered on seed
    pairs and includes the baseline's own uncertainty: pair p's influence is
    sum_s [(x_cps - n_cps b_s) - N_cs/N_os (x_ops - b_s n_ops)]."""
    sign = 1 if higher_is_better else -1
    infl = defaultdict(float)
    weight = defaultdict(int)
    total = count = dropped = 0
    for key, cells in present.items():
        ref = reference[key]
        other = {p: [x - cells.get(p, [0, 0])[0], n - cells.get(p, [0, 0])[1]] for p, (x, n) in ref.items()}
        n_o = sum(c[1] for c in other.values())
        n_c = sum(c[1] for c in cells.values())
        if n_o == 0:
            dropped += n_c
            continue
        b = sum(c[0] for c in other.values()) / n_o
        for p, (x, n) in cells.items():
            d = sign * (x - n * b)
            total += d
            infl[p] += d
            weight[p] += n
        for p, (x, n) in other.items():
            infl[p] -= sign * n_c / n_o * (x - b * n)
        count += n_c
    mean = total / count if count else None
    ci = None
    k = len(infl)
    if count and len(weight) > 1:
        residual = sum((v - mean * weight.get(p, 0)) ** 2 for p, v in infl.items())
        half = Z * math.sqrt(k / (k - 1) * residual) / count
        ci = [mean - half, mean + half]
    return {"mean": mean, "count": count, "pairs": len(weight), "ci95": ci,
            "strata_without_comparison": dropped, "thin": thin(count, len(weight))}


def cell(table, key, pair, x):
    c = table[key].setdefault(pair, [0, 0])
    c[0] += x
    c[1] += 1


def fight_lift(deep, estimator=lift):
    """Per fight side: stratum = (team, current main tribe, round up to 15).
    Outcome = fight score (win 1, draw 0.5, loss 0). Pooled seats compare each
    side with its own team's stratum, so a strong team does not lift its cards."""
    out = []
    for scope in SCOPES:
        for stage in ("all", *BANDS):
            ref = defaultdict(dict)
            pres = defaultdict(lambda: defaultdict(dict))
            for s in deep.sides:
                if scope != "both" and s.colour != scope:
                    continue
                if stage != "all" and band(s.round) != stage:
                    continue
                key = (s.colour, s.tribe, round_bucket(s.round))
                cell(ref, key, s.pair, s.score)
                for card in set(s.cards):
                    cell(pres[card], key, s.pair, s.score)
            for card, strata in pres.items():
                row = {"scope": scope, "band": stage, "card": card}
                row.update(estimator(strata, {k: ref[k] for k in strata}, True))
                out.append(row)
    return team_shares(out, ("band", "card"))


def board_predicts(deep, estimator=lift):
    """Board at round R (seats alive at R): does holding the card predict
    place, win and top four? Stratum = (team, main tribe of the round-R board)."""
    out = []
    for R in PREDICT_ROUNDS:
        for scope in SCOPES:
            outcomes = {"place": (lambda p: p, False), "win": (lambda p: p == 1, True),
                        "top4": (lambda p: p <= 4, True)}
            ref = {m: defaultdict(dict) for m in outcomes}
            pres = {m: defaultdict(lambda: defaultdict(dict)) for m in outcomes}
            for seat in deep.seats.values():
                if scope != "both" and seat.colour != scope:
                    continue
                rd = seat.rounds.get(R)
                if rd is None:
                    continue
                key = (seat.colour, rd.tribe)
                for m, (f, _) in outcomes.items():
                    cell(ref[m], key, seat.pair, f(seat.place))
                    for card in set(rd.cards):
                        cell(pres[m][card], key, seat.pair, f(seat.place))
            for card in pres["place"]:
                row = {"scope": scope, "round": R, "card": card}
                for m, (_, hib) in outcomes.items():
                    strata = pres[m][card]
                    row[m] = estimator(strata, {k: ref[m][k] for k in strata}, hib)
                row["count"] = row["win"]["count"]
                out.append(row)
    return team_shares(out, ("round", "card"))


def winning_boards(deep):
    """Per final tribe: share of first-place final boards holding each card,
    against the share of 5th-8th final boards of the same tribe."""
    out = []
    for scope in SCOPES:
        boards = defaultdict(list)
        for seat in deep.seats.values():
            if scope != "both" and seat.colour != scope:
                continue
            last = seat.rounds.get(seat.last_round)
            if last is None:
                continue
            group = "first" if seat.place == 1 else "bottom" if seat.place >= 5 else None
            if group:
                boards[seat.tribe].append((seat.pair, group, set(last.cards)))
        for tribe, rows in boards.items():
            cards = set().union(*(c for _, _, c in rows))
            nf = sum(1 for _, g, _ in rows if g == "first")
            nb = sum(1 for _, g, _ in rows if g == "bottom")
            for card in cards:
                a, b = Acc(), Acc()
                for pair, g, c in rows:
                    (a if g == "first" else b).add(pair, card in c)
                ra, rb = a.result(True), b.result(True)
                out.append({"scope": scope, "final_tribe": tribe, "card": card,
                            "first_boards": nf, "bottom_boards": nb,
                            "share_first": ra, "share_bottom": rb, "count": ra["hits"] + rb["hits"]})
    return team_shares(out, ("final_tribe", "card"))


def resales(deep):
    """Buys and sells per card from the decision log, and sells in a turn in
    which the same seat bought a copy (a guess: the log has no unit id; see
    `sales` for the exact version)."""
    acc = defaultdict(lambda: [0, 0, 0])   # (scope, card) -> buys, sells, same-turn sells
    bought = defaultdict(Counter)
    for pair, colour, seat_key, r, card, kind in deep.card_moves:
        turn = (seat_key, r)
        for scope in scopes_of(colour):
            if kind == "buy":
                acc[scope, card][0] += 1
            else:
                acc[scope, card][1] += 1
                if bought[turn][card] > 0:
                    acc[scope, card][2] += 1
        if kind == "buy":
            bought[turn][card] += 1
        elif bought[turn][card] > 0:
            bought[turn][card] -= 1
    rows = [{"scope": s, "card": c, "buys": b, "sells": n, "sold_same_turn_as_a_buy": q,
             "sells_per_buy": n / b if b else None, "thin": b < THIN_COUNT, "count": b}
            for (s, c), (b, n, q) in sorted(acc.items())]
    return team_shares(rows, ("card",))


def sales(deep):
    """Exact, from events.jsonl.gz: per card, sales, rounds on the board at the
    sale (round boundaries crossed), the share sold in the round it entered
    the board, and the share whose sale fed an eat or a slot growth."""
    t = defaultdict(Acc)
    kinds = {}
    for s in deep.sales:
        for scope in scopes_of(s["colour"]):
            for name, x, rate in (("rounds_on_board", s["rounds_on_board"], False),
                                  ("sold_in_entry_round", s["rounds_on_board"] == 0, True),
                                  ("sale_fed_something", s["fed"], True)):
                t[scope, s["card"], name].add(s["pair"], x)
                kinds[scope, s["card"], name] = rate
    rows = []
    for key, a in t.items():
        rows.append({"scope": key[0], "card": key[1], "metric": key[2], **a.result(kinds[key])})
    return team_shares(rows, ("card", "metric"))


def analyse(deep):
    data = {"fight_lift": fight_lift(deep),
            "fight_lift_vs_other_boards": fight_lift(deep, lift_vs_others),
            "board_predicts": board_predicts(deep),
            "board_predicts_vs_other_boards": board_predicts(deep, lift_vs_others),
            "winning_boards": winning_boards(deep)}
    if deep.coverage.get("shops"):
        data["pick_rate"] = pick_rows(deep)
        data["pick_rate_by_card_tribe"] = deep.shop["per_card_tribe"]
    if deep.coverage.get("records"):
        data["tenure"] = tenure(deep)
    if deep.coverage.get("decisions"):
        data["resales"] = resales(deep)
    if deep.coverage.get("events"):
        data["sales"] = sales(deep)
    return data


# ---------------------------------------------------------------------------

def tier_of(deep, card):
    return deep.library.get(card, {}).get("tier") or 0


def markdown(deep, data):
    L = ["## Cards", ""]
    lab = lambda c: card_label(deep, c)
    if "pick_rate" in data:
        early = [r for r in data["pick_rate"] if r["scope"] == "both" and r["band"] == "1-3"]
        by = defaultdict(dict)
        for r in early:
            by[r["card"]][r["final_tribe"]] = r
        universal = []
        for card, d in by.items():
            tribes = [t for t in deep.tribes if t in d and not d[t]["thin"]]
            if len(tribes) == len(deep.tribes) and "all" in d:
                low = min(d[t]["rate"] for t in tribes)
                universal.append((low, card, d))
        universal.sort(reverse=True)
        L += ["**Early picks every final tribe makes** (rounds 1-3, buy rate when buyable, from `cards.py`; the "
              "column is the lowest rate over the five final tribes). Pooled over both teams: `red` is the red "
              "seats' share of the shops.", "",
              "| Card | Lowest over final tribes | All seats | " + " | ".join(deep.tribes) + " |",
              "|---|---|---|" + "---|" * len(deep.tribes)]
        for low, card, d in universal[:8]:
            L.append(f"| {lab(card)} | {100*low:.0f}% | {fmt(d['all'])}{team_tag(d['all'])} | " +
                     " | ".join(f"{100*d[t]['rate']:.0f}%" for t in deep.tribes) + " |")
    L += ["", "**Per-fight lift, within each team, by tier.** Fight score of boards holding the card minus boards "
          "of the same team, current tribe and round that do *not* hold it (+0.10 = ten points more fights won). "
          f"Only cards with {HEADLINE_MIN}+ fights and an interval clear of zero; ranked by the interval's near "
          "bound, so a small sample cannot top the table.", "",
          "> **Read with care.** Boards that still hold a cheap card late are often undeveloped boards, so low "
          "tiers read low; boards that found a high-tier card read high. Compare cards of the same tier, and "
          "treat a lift as a lead for a constructed fight, not a verdict.", "",
          "| Team | Tier | Highest | Lowest |", "|---|---|---|---|"]
    fl = [r for r in data["fight_lift_vs_other_boards"] if r["band"] == "all" and r["ci95"]
          and r["count"] >= HEADLINE_MIN and not r["thin"]]
    for team in TEAMS:
        for tier in range(1, 7):
            rows = [r for r in fl if r["scope"] == team and tier_of(deep, r["card"]) == tier]
            hi = sorted([r for r in rows if r["ci95"][0] > 0], key=lambda r: -r["ci95"][0])[:2]
            lo = sorted([r for r in rows if r["ci95"][1] < 0], key=lambda r: r["ci95"][1])[:2]
            if hi or lo:
                cell_ = lambda rs: "; ".join(f"{lab(r['card'])} {fmt(r, False)}" for r in rs) or "—"
                L.append(f"| {team} | {tier} | {cell_(hi)} | {cell_(lo)} |")
    bp = [r for r in data["board_predicts_vs_other_boards"] if r["round"] == 9 and r["scope"] in TEAMS
          and r["win"]["ci95"] and r["win"]["count"] >= 50]
    L += ["", "**On the round-9 board: win and top-four lifts side by side, within each team** (seats alive at "
          "round 9, against same-team boards of the same round-9 tribe without the card; 50+ boards; win-lift "
          "interval clear of zero). Calling a card a high roll needs the win lift to clear zero while the "
          "top-four lift does not *and* the two to differ by more than their intervals; on samples this size few "
          "rows do, so the table shows both and draws no label.", "",
          "| Team | Card | Win lift | Top-four lift | Place lift | Boards |", "|---|---|---|---|---|---|"]
    for team in TEAMS:
        rows = [r for r in bp if r["scope"] == team and (r["win"]["ci95"][0] > 0 or r["win"]["ci95"][1] < 0)]
        rows.sort(key=lambda r: -abs(r["win"]["mean"]))
        for r in rows[:6]:
            L.append(f"| {team} | {lab(r['card'])} | {fmt(r['win'], True)} | {fmt(r['top4'], True)} | "
                     f"{fmt(r['place'], False)} | {r['win']['count']} |")
    if "tenure" in data:
        rows = defaultdict(dict)
        for r in data["tenure"]:
            if r["scope"] == "both":
                rows[r["card"]][r["metric"]] = r
        exact = "sold" in next(iter(rows.values()), {})
        short = [(d["left_after_one_fight"]["rate"] * d["left"]["rate"], c, d) for c, d in rows.items()
                 if "left_after_one_fight" in d and d["fights_on_board"]["count"] >= THIN_COUNT]
        short.sort(reverse=True)
        L += ["", "**Units that do not stay** (replay records; a unit is one uid on a fight board"
              + ("; sold and eaten are exact, from `events.jsonl.gz`" if exact else "") + "). Pooled; `red` share "
              "of the units shown.", "",
              "| Card | Units | Fights on board | Kept to the end | Tripled | Sold | Eaten | Left after one fight |",
              "|---|---|---|---|---|---|---|---|"]
        pc = lambda d, m: f"{100*d[m]['rate']:.0f}%" if m in d else "—"
        for _, c, d in short[:10]:
            share = d["left_after_one_fight"]["rate"] * d["left"]["rate"]
            L.append(f"| {lab(c)} | {d['fights_on_board']['count']}{team_tag(d['fights_on_board'])} | "
                     f"{d['fights_on_board']['mean']:.1f} | {pc(d, 'kept_to_end')} | {pc(d, 'tripled')} | "
                     f"{pc(d, 'sold')} | {pc(d, 'eaten')} | {100*share:.0f}% |")
    if "sales" in data:
        rows = defaultdict(dict)
        for r in data["sales"]:
            if r["scope"] == "both":
                rows[r["card"]][r["metric"]] = r
        quick = [(d["sold_in_entry_round"]["rate"], c, d) for c, d in rows.items()
                 if d["sold_in_entry_round"]["count"] >= THIN_COUNT]
        quick.sort(reverse=True)
        L += ["", "**Sold in the round it entered the board** (exact, `events.jsonl.gz`; pooled, `red` share of "
              "sales).", "", "| Card | Sales | Sold in entry round | Rounds on board at sale | Sale fed something |",
              "|---|---|---|---|---|"]
        for _, c, d in quick[:10]:
            L.append(f"| {lab(c)} | {d['sold_in_entry_round']['count']}{team_tag(d['sold_in_entry_round'])} | "
                     f"{fmt(d['sold_in_entry_round'])} | {d['rounds_on_board']['mean']:.1f} | "
                     f"{fmt(d['sale_fed_something'])} |")
    return "\n".join(L)
