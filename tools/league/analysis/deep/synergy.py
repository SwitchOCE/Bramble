"""Card pairs that do better together than either does without the other,
measured on fight results after removing team, tribe and round."""
from collections import Counter, defaultdict
from itertools import combinations

from common import ONE_TEAM, Combo, Contrast, round_bucket, thin, fmt, card_label

FROM_ROUND = 7
ONE_TEAM_LOW = 1 - ONE_TEAM
MIN_TOGETHER = 100   # fight sides holding both
MIN_APART = 50       # fight sides holding one without the other


def residuals(sides):
    """Fight score minus the mean score of its stratum (team, current main
    tribe, round up to 15), over all rounds."""
    tot = defaultdict(lambda: [0.0, 0])
    for s in sides:
        c = tot[s.colour, s.tribe, round_bucket(s.round)]
        c[0] += s.score
        c[1] += 1
    base = {k: x / n for k, (x, n) in tot.items()}
    return [(s, s.score - base[s.colour, s.tribe, round_bucket(s.round)]) for s in sides]


def pair_stats(sides, from_round=FROM_ROUND):
    total = defaultdict(lambda: [0.0, 0])                          # pair -> [sum res, n]
    single = defaultdict(lambda: defaultdict(lambda: [0.0, 0]))   # card -> pair -> [sum res, n]
    double = defaultdict(lambda: defaultdict(lambda: [0.0, 0]))   # (a, b) -> pair -> [sum res, n]
    red = Counter()                                                # (a, b) -> red sides together
    for s, res in residuals(sides):
        if s.round < from_round:
            continue
        cards = sorted(set(s.cards))
        total[s.pair][0] += res
        total[s.pair][1] += 1
        for c in cards:
            cell = single[c][s.pair]
            cell[0] += res
            cell[1] += 1
        for a, b in combinations(cards, 2):
            cell = double[a, b][s.pair]
            cell[0] += res
            cell[1] += 1
            if s.colour == "red":
                red[a, b] += 1
    pair_stats.red = red
    return total, single, double


def interaction(together, a_only, b_only, neither):
    """(AB) - (A without B) - (B without A) + (neither), on residuals. Zero when
    the two cards' effects simply add up; positive when they do better together."""
    c = Combo((1, -1, -1, 1))
    for g, cells in enumerate((together, a_only, b_only, neither)):
        for p, (x, n) in cells.items():
            if n:
                c.add(p, g, x, n)
    return c.estimate()


def contrast(together, alone_cells):
    c = Contrast()
    for p, (x, n) in together.items():
        c.add(p, 0, x, n)
    for p, (x, n) in alone_cells.items():
        if n:
            c.add(p, 1, x, n)
    return c.result()


def apart(single_cells, together):
    """Cells of 'holds the card but not its partner' = single minus together."""
    return {p: [x - together.get(p, [0, 0])[0], n - together.get(p, [0, 0])[1]]
            for p, (x, n) in single_cells.items()}


def analyse(deep):
    total, single, double = pair_stats(deep.sides)
    rows = []
    for (a, b), together in double.items():
        n_ab = sum(c[1] for c in together.values())
        if n_ab < MIN_TOGETHER:
            continue
        a_only, b_only = apart(single[a], together), apart(single[b], together)
        n_a, n_b = sum(c[1] for c in a_only.values()), sum(c[1] for c in b_only.values())
        if n_a < MIN_APART or n_b < MIN_APART:
            continue
        mean = lambda cells: sum(c[0] for c in cells.values()) / sum(c[1] for c in cells.values())
        m_ab, m_a, m_b = mean(together), mean(a_only), mean(b_only)
        best = a_only if m_a >= m_b else b_only
        excess = contrast(together, best)
        neither = {}
        for p, (x, n) in total.items():
            ab, sa, sb = together.get(p, [0, 0]), single[a].get(p, [0, 0]), single[b].get(p, [0, 0])
            neither[p] = [x - sa[0] - sb[0] + ab[0], n - sa[1] - sb[1] + ab[1]]
        inter = interaction(together, a_only, b_only, neither)
        if inter["value"] is None or excess["diff"] is None:
            continue
        rows.append({"a": a, "b": b, "together": n_ab, "a_without_b": n_a, "b_without_a": n_b,
                     "residual_together": m_ab, "residual_a_without_b": m_a, "residual_b_without_a": m_b,
                     "residual_neither": inter["groups"][3],
                     "red_share": pair_stats.red[a, b] / n_ab,
                     "one_team": not ONE_TEAM_LOW <= pair_stats.red[a, b] / n_ab <= 1 - ONE_TEAM_LOW,
                     "interaction": inter, "excess_over_best_single": excess,
                     "pairs": excess["pairs"], "thin": excess["thin"] or thin(n_ab, excess["pairs"])})
    rows.sort(key=lambda r: -r["interaction"]["value"])
    return {"from_round": FROM_ROUND, "min_together": MIN_TOGETHER, "min_apart": MIN_APART, "pairs": rows}


def show(e):
    if e["value"] is None:
        return "—"
    ci = e["ci95"]
    return f"{e['value']:+.2f}" + (f" [{ci[0]:+.2f}, {ci[1]:+.2f}]" if ci else "")


def markdown(deep, data):
    rows = [r for r in data["pairs"] if not r["thin"]]
    lab = lambda c: card_label(deep, c)
    L = ["## Synergy", "",
         f"Fights from round {data['from_round']}. A side's **residual** is its fight score minus the mean of its "
         "team, current tribe and round. **Interaction** = residual(A and B) - residual(A without B) - "
         "residual(B without A) + residual(neither): zero when the two cards just add up. "
         "Boards holding two specific cards are often more developed boards, and the residual does not remove "
         "that, so treat a large interaction as a lead to test with a constructed fight, not as proof. "
         f"Pairs tested: {len(data['pairs'])} with at least {data['min_together']} fights together and "
         f"{data['min_apart']} apart; about 1 in 20 will clear a 95% interval by chance.", "",
         "| A | B | Fights together | Red share | Interaction | Together vs best single |",
         "|---|---|---|---|---|---|"]
    for r in rows[:10] + [None] + rows[::-1][:6]:
        if r is None:
            L.append("| … | | | | | |")
            continue
        tag = f"{100 * r['red_share']:.0f}%" + (" ⚠one team" if r["one_team"] else "")
        L.append(f"| {lab(r['a'])} | {lab(r['b'])} | {r['together']} | {tag} | {show(r['interaction'])} | "
                 f"{fmt(r['excess_over_best_single'], False)} |")
    return "\n".join(L)
