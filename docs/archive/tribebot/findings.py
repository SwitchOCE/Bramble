#!/usr/bin/env python3
"""Side-by-side observations for the original ten findings."""
from pathlib import Path

from behaviours import behaviour_stats
from cards import card_stats
from match_data import Match, parser, publish, show
from tribes import tribe_stats


TITLES = ("Pigeons ahead of the field", "Colour Sergeant slot growth", "The Colonel's Reserve",
          "Gleaner and friendly deaths", "Mouse weakness", "Late Locust fights",
          "Badger Fury supports", "Briar Compost", "Gold supply", "Granary Glutton")


def evidence(match):
    c = card_stats(match, ("both",))["both"]
    t = tribe_stats(match)["both"]
    b = behaviour_stats(match).get("both", {})
    def card(ids):
        return {i: {k: c[i][k] for k in ("buy", "lift_places", "golden")} for i in ids if i in c}
    def tribe(name):
        return {"final": t["final"].get(name), "stage_win": t.get("fight_win", {}).get(name, {}),
                "stage_win_other_live_tribes": t.get("fight_win_other_tribes", {}).get(name, {}),
                "opponent_win": t.get("head_to_head", {}).get(name, {})}
    return [
        {"tribes": {k: tribe(k) for k in match.tribes},
         "board_stats": {k: {r: v["board_stats"] for r, v in rounds.items()}
                         for k, rounds in t["tribe_rounds"].items()}},
        {"cards": card(["colour-sergeant", "regimental-sergeant-major"]),
         "slot_change": b.get("slot_stat_change_by_sergeants", {}),
         "any_slot_change": b.get("any_slot_change_by_sergeants", {})},
        {"card": card(["the-colonel"]), "hand_units": b.get("colonel_hand_units"),
         "win_by_hand_units": b.get("colonel_win_by_hand_units", {})},
        {"cards": card(["gleaner", "the-eighth-plague"]), "gleaners": b.get("gleaners", {}),
         "locust_gleaners": b.get("locust_gleaners", {})},
        tribe("Mouse"), tribe("Locust"),
        {"tribe": tribe("Badger"), "win_by_outnumbered": b.get("badger_win_by_outnumbered", {}),
         "supports": card(["master-at-arms", "dame-of-the-old-sett", "marshal-of-the-red-mist", "old-brock"])},
        {"tribe": tribe("Briar"), "compost_by_round": b.get("briar_compost_by_round", {}),
         "win_by_compost": b.get("briar_win_by_compost", {})},
        {"rounds": {r: {k: v[k] for k in ("gold_left", "gold_from_cards")} for r, v in t["rounds"].items()},
         "cards": card(["relic-seeker", "shrew-cutpurse", "hedge-layer"])},
        {"cards": card(["granary-glutton", "gorger", "horde-runner", "mother-of-thousands", "famine-caller"]),
         "sales_per_seat_game": b.get("per_seat_game", {}),
         "surviving_gorgers_marked_ate": b.get("surviving_gorgers_marked_ate")}]


# Keep the printed comparison short. The JSON contains all strata, including sparse ones.
EXAMPLES = [
    [("Pigeon final placement", ("tribes", "Pigeon", "final", "placement"))],
    [("Total slot stat change with Colour Sergeant alone of the two officers", ("slot_change", "colour-sergeant"))],
    [("Hand units with Colonel", ("hand_units",)), ("Fight win with two reserve units", ("win_by_hand_units", "2"))],
    [("Friendly deaths with one Gleaner", ("gleaners", "1", "friendly_deaths"))],
    [("Mouse final placement", ("final", "placement"))],
    [("Locust fight win, rounds 7–9", ("stage_win", "7-9")), ("Locust fight win, rounds 13+", ("stage_win", "13+"))],
    [("Master-at-Arms placement lift", ("supports", "master-at-arms", "lift_places"))],
    [("Briar Compost, round 10", ("compost_by_round", "10")), ("Briar fight win, rounds 13+", ("tribe", "stage_win", "13+"))],
    [("Unspent gold, round 12", ("rounds", "12", "gold_left"))],
    [("Locust sales with Glutton per seat-game", ("sales_per_seat_game", "locust_sales_with_glutton"))],
]


def main():
    p = parser(__doc__)
    p.add_argument("naive", type=Path)
    args = p.parse_args()
    match, naive = Match(args.match), Match(args.naive)
    if any(naive.summary[k] != "tribe" for k in ("red", "blue")):
        p.error("the naive comparison must be a tribe vs tribe match")
    if any(match.summary[k] != naive.summary[k] for k in ("rules_hash", "content")):
        p.error("the matches must have the same rules hash and content")
    strong, baseline = evidence(match), evidence(naive)
    rows = []
    lines = ["# Balance findings", "", "| Finding | Observation | Match | TribeBot A/A |", "|---|---|---|---|"]
    for i, (title, a, b, example) in enumerate(zip(TITLES, strong, baseline, EXAMPLES), 1):
        rows.append({"finding": i, "title": title, "match": a, "naive": b})
        for label, path in example:
            cells = []
            for side in (a, b):
                stat = side
                for k in path:
                    stat = (stat or {}).get(k)
                cells.append(show(stat) if stat is not None else "—")
            lines.append(f"| {i}. {title} | {label} | " + " | ".join(cells) + " |")
    lines += ["", "Final tribe is selected during free play and can favour boards that succeeded. "
              "The comparison groups both matches by the observed board. "
              "A pooled final share below 5% leaves that tribe's finding unresolved."]
    data = {"matches": {label: {k: source.summary[k] for k in ("red_label", "blue_label", "games", "rules_hash")}
                        for label, source in (("match", match), ("naive", naive))}, "findings": rows}
    publish(args.out_dir or args.match, "findings", data, "\n".join(lines))


if __name__ == "__main__":
    main()

