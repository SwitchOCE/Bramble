"""Cards: who buys what by stage and final tribe, how long units stay, and
which cards go with winning fights, winning games and top-four games."""
from collections import Counter, defaultdict
import json

from match_data import Stat, band, BANDS, NONE
from cards import adjusted_lift
from common import SCOPES, THIN_COUNT, thin, scopes_of, round_bucket, fmt, card_label, Acc

PREDICT_ROUNDS = (6, 9)


# ---------------------------------------------------------------------------
# Shop pass: buy opportunities, streamed (shops are in game order, so the
# O(1)-memory match_data.Stat is safe here).

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
    unit (as cards.py). Hit = the seat bought that unit from that shop."""
    per_card = StatTable()      # scope, card, band, final tribe
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
                        per_card.add((scope, card, b, ft), pair, hit)
                        per_tribe.add((scope, ctribe, info.get("tier"), b, ft), pair, hit)
    deep.shop = {"per_card": per_card.rows(("scope", "card", "band", "final_tribe")),
                 "per_card_tribe": per_tribe.rows(("scope", "card_tribe", "card_tier", "band", "final_tribe"))}


# ---------------------------------------------------------------------------
# Record pass: unit tenure by uid.

def read_records(deep):
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
            rows.extend(tenure_rows(deep.seats[g["game"], sid], turns))
    deep.tenure = rows


def tenure_rows(seat, turns):
    """One row per unit uid seen on this seat's fight boards.

    fights: number of fight snapshots it was in; end: 'kept' (on the seat's
    last fight board), 'tripled' (gone, and the next board has a new golden
    copy of the same card), or 'left' (gone otherwise: sold, eaten or
    consumed)."""
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
    t = defaultdict(Acc)
    kinds = {}
    for r in deep.tenure:
        for scope in scopes_of(r["colour"]):
            key = (scope, r["card"])
            def add(name, x, rate):
                t[key + (name,)].add(r["pair"], x)
                kinds[key + (name,)] = rate
            add("fights_on_board", r["fights"], False)
            add("kept_to_end", r["end"] == "kept", True)
            add("tripled", r["end"] == "tripled", True)
            add("left", r["end"] == "left", True)
            if r["end"] == "left":
                add("fights_before_leaving", r["fights"], False)
                add("left_after_one_fight", r["fights"] == 1, True)
    rows = []
    for key, acc in t.items():
        row = {"scope": key[0], "card": key[1], "metric": key[2]}
        row.update(acc.result(kinds[key]))
        rows.append(row)
    return rows


# ---------------------------------------------------------------------------
# Lifts.

def lift(present, reference, higher_is_better):
    """Difference between boards holding a card and the baseline of the same
    stratum (cards.adjusted_lift, which reports baseline minus observed). For an
    outcome where higher is better we pass 1 - outcome so that a positive lift
    is always good."""
    def flip(cells):
        return {p: [n - x, n] for p, (x, n) in cells.items()}
    if higher_is_better:
        present = {k: flip(v) for k, v in present.items()}
        reference = {k: flip(v) for k, v in reference.items()}
    r = adjusted_lift(present, reference)
    r["thin"] = thin(r["count"], r["pairs"])
    return r


def cell(table, key, pair, x):
    c = table[key].setdefault(pair, [0, 0])
    c[0] += x
    c[1] += 1


def fight_lift(deep):
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
                row.update(lift(strata, {k: ref[k] for k in strata}, True))
                out.append(row)
    return out


def board_predicts(deep):
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
                    row[m] = lift(strata, {k: ref[m][k] for k in strata}, hib)
                out.append(row)
    return out


def winning_boards(deep):
    """Per final tribe: share of first-place final boards holding each card,
    against the share of 5th-8th final boards of the same tribe."""
    out = []
    for scope in SCOPES:
        groups = defaultdict(lambda: {"first": Acc(), "bottom": Acc(), "n_first": 0, "n_bottom": 0})
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
                            "share_first": ra, "share_bottom": rb})
    return out


def resales(deep):
    """Buys and sells per card from the decision log, and sells in a turn in
    which the same seat bought a copy (a quick flip or a triple setup)."""
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
    return [{"scope": s, "card": c, "buys": b, "sells": n, "sold_same_turn_as_a_buy": q,
             "sells_per_buy": n / b if b else None, "thin": b < THIN_COUNT}
            for (s, c), (b, n, q) in sorted(acc.items())]


def analyse(deep):
    data = {"fight_lift": fight_lift(deep), "board_predicts": board_predicts(deep),
            "winning_boards": winning_boards(deep)}
    if deep.shop is not None:
        data["pick_rate"] = deep.shop["per_card"]
        data["pick_rate_by_card_tribe"] = deep.shop["per_card_tribe"]
    if deep.coverage.get("records"):
        data["tenure"] = tenure(deep)
    if deep.coverage.get("decisions"):
        data["resales"] = resales(deep)
    return data


# ---------------------------------------------------------------------------

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
            if len(tribes) == len(deep.tribes):
                low = min(d[t]["rate"] for t in tribes)
                universal.append((low, card, d))
        universal.sort(reverse=True)
        L += ["**Early picks every final tribe makes** (rounds 1-3, buy rate when buyable; the column is the "
              "lowest rate over the five final tribes, so a high value means every eventual tribe buys it).", "",
              "| Card | Lowest over final tribes | All seats | " + " | ".join(deep.tribes) + " |",
              "|---|---|---|" + "---|" * len(deep.tribes)]
        for low, card, d in universal[:8]:
            L.append(f"| {lab(card)} | {100*low:.0f}% | {fmt(d['all'])} | " +
                     " | ".join(f"{100*d[t]['rate']:.0f}%" for t in deep.tribes) + " |")
    fl = [r for r in data["fight_lift"] if r["scope"] == "both" and r["band"] == "all" and not r["thin"]]
    fl.sort(key=lambda r: r["mean"])
    L += ["", "**Per-fight lift** (fight score of boards holding the card minus the same team, tribe and round; "
          "+0.10 = ten points more fights won). Lowest and highest with enough fights:", "",
          "| Card | Lift | Fights | | Card | Lift | Fights |", "|---|---|---|---|---|---|---|"]
    for lo, hi in zip(fl[:8], reversed(fl[-8:])):
        L.append(f"| {lab(lo['card'])} | {fmt(lo)} | {lo['count']} | | {lab(hi['card'])} | {fmt(hi)} | {hi['count']} |")
    bp = [r for r in data["board_predicts"] if r["scope"] == "both" and r["round"] == 9
          and not r["win"]["thin"]]
    bp.sort(key=lambda r: -(r["win"]["mean"] or 0))
    L += ["", "**On the round-9 board: wins versus top fours.** Lift in win rate and top-four rate over the same "
          "team and round-9 tribe. A card high on win but flat on top four is a high roll; the reverse is a "
          "safe floor.", "", "| Card | Win lift | Top-four lift | Place lift | Boards |", "|---|---|---|---|---|"]
    for r in bp[:10]:
        L.append(f"| {lab(r['card'])} | {fmt(r['win'], True)} | {fmt(r['top4'], True)} | "
                 f"{fmt(r['place'], False)} | {r['win']['count']} |")
    if "tenure" in data:
        rows = defaultdict(dict)
        for r in data["tenure"]:
            if r["scope"] == "both":
                rows[r["card"]][r["metric"]] = r
        short = [(d["left_after_one_fight"]["rate"] * d["left"]["rate"], c, d) for c, d in rows.items()
                 if "left_after_one_fight" in d and d["fights_on_board"]["count"] >= THIN_COUNT]
        short.sort(reverse=True)
        L += ["", "**Units that do not stay** (from replay records: a unit is one uid on a fight board).", "",
              "| Card | Units | Fights on board | Kept to the end | Tripled | Left after one fight |",
              "|---|---|---|---|---|---|"]
        for _, c, d in short[:10]:
            share = d["left_after_one_fight"]["rate"] * d["left"]["rate"]
            L.append(f"| {lab(c)} | {d['fights_on_board']['count']} | {d['fights_on_board']['mean']:.1f} | "
                     f"{100*d['kept_to_end']['rate']:.0f}% | {100*d['tripled']['rate']:.0f}% | {100*share:.0f}% |")
    return "\n".join(L)
