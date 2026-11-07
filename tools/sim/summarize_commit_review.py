#!/usr/bin/env python3
"""Commitment review: fixed round-10 six-or-more-board headline, purchase share and actual burns.

Run from a variant snapshot: python3 tools/sim/summarize_commit_review.py LOG
The original final-board result remains separately visible, never substituted for round 10.
"""

import collections
import json
import statistics
import sys
from pathlib import Path

from summarize_commit import summarize as original_summary


def average(values):
    return round(statistics.mean(values), 3) if values else None


def summarize(path):
    result = original_summary(path)
    rows, auxiliary = [], []
    for line in Path(path).read_text().splitlines():
        if line.startswith("commit_row: "):
            rows.append(json.loads(line.removeprefix("commit_row: ")))
        elif line.startswith("commit_aux: "):
            auxiliary.append(json.loads(line.removeprefix("commit_aux: ")))
    final = [r for r in rows if r["round"] == "final"]
    seats = {(r["seed"], r["player"]) for r in final}
    place = {(r["seed"], r["player"]): r["place"] for r in final}
    full = [r for r in rows if r["round"] == 10 and len(r["board"]) >= 6]
    seven = [r for r in full if len(r["board"]) == 7]

    def main_count(row):
        counts = collections.Counter(t for unit in row["board"] for t in unit["tribes"])
        return max(counts.values(), default=0)

    def cohort(entries):
        return {
            "n": len(entries),
            "place": average([r["place"] for r in entries]),
            "board_stats": average([sum(u["attack"] + u["health"] for u in r["board"]) for r in entries]),
        }

    committed = [r for r in full if main_count(r) >= 6]
    mixed = [r for r in full if main_count(r) <= 4]
    result["final_board_commitment"] = {
        "committed_6plus": result["committed_6plus"],
        "mixed_4minus": result["mixed_4minus"],
    }
    result["headline"] = "round10_full_board_commitment"
    result["round10_full_board_commitment"] = {
        "full_boards": len(full),
        "committed_6plus": cohort(committed),
        "mixed_4minus": cohort(mixed),
        "passes": bool(
            committed and mixed and average([r["place"] for r in committed]) < average([r["place"] for r in mixed])
        ),
        "definition": "At least six recruit-board units at round 10; max tribe count >=6 versus <=4. "
        "Eggs/away units do not acquire a tribe.",
    }
    result["round10_seven_unit_boards_only"] = {
        "full_boards": len(seven),
        "committed_6plus": cohort([r for r in seven if main_count(r) >= 6]),
        "mixed_4minus": cohort([r for r in seven if main_count(r) <= 4]),
    }
    result["passes"]["final_board_commitment"] = result["passes"]["commitment"]
    result["passes"]["commitment"] = result["round10_full_board_commitment"]["passes"]
    buys = [r for r in auxiliary if r["type"] == "buy" and (r["seed"], r["player"]) in seats]
    result["unit_purchases"] = {"events": len(buys), "observed": bool(auxiliary)}
    for card, summary in result["cards"].items():
        purchases = [r for r in buys if r["fields"].get("unit") == card]
        buyers = {(r["seed"], r["player"]) for r in purchases}
        copies = sum(u["id"] == card for r in final for u in r["board"])
        summary.update(
            {
                "buy_events": len(purchases),
                "buy_event_share_percent": round(100 * len(purchases) / max(1, len(buys)), 3),
                "buyer_seats": len(buyers),
                "buyer_share_percent": round(100 * len(buyers) / max(1, len(seats)), 3),
                "buyer_place": average([place[key] for key in buyers]),
                "final_board_share_percent": round(100 * summary["final_boards"] / max(1, len(final)), 3),
                "final_unit_share_percent": round(100 * copies / max(1, sum(len(r["board"]) for r in final)), 3),
            }
        )
    burns = [r for r in auxiliary if r["type"] == "burn" and r["source"] == "unit:charcoal_burner"]
    amounts = [int(r["fields"].get("amount", 0)) for r in burns]
    result["charcoal_burner_burns"] = {
        "events": len(burns),
        "positive_events": sum(amount > 0 for amount in amounts),
        "zero_events": sum(amount == 0 for amount in amounts),
        "gold_total": sum(amounts),
        "gold_mean": average(amounts),
        "gold_max": max(amounts, default=0),
    }
    result["flight_events"] = dict(
        collections.Counter(r["type"] for r in auxiliary if r["type"] in ["fly_south", "home", "sell", "play"])
    )
    flights = [r for r in auxiliary if r["type"] == "fly_south"]
    observed = [r for r in flights if r["fields"].get("body_observed", False)]
    body_groups = collections.defaultdict(list)
    for row in observed:
        body_groups[row["fields"].get("unit", "unknown")].append(row["fields"])
    result["flight_body_cost"] = {
        "flight_events": len(flights),
        "observed_events": len(observed),
        "measurements_available": bool(observed),
        "free_body_flights": sum(r["fields"].get("free_body", False) for r in observed),
        "free_body_native_home_flights": sum(
            r["fields"].get("free_body", False) and r["fields"].get("native_on_home", False) for r in observed
        ),
        "mean_body_loss": average([r["fields"]["body_loss"] for r in observed]),
        "by_card": {
            card: {
                "events": len(values),
                "free_body_flights": sum(v["free_body"] for v in values),
                "native_on_home_events": sum(v["native_on_home"] for v in values),
                "mean_bird_attack": average([v["bird_attack"] for v in values]),
                "mean_bird_health": average([v["bird_health"] for v in values]),
                "mean_egg_attack": average([v["egg_attack"] for v in values]),
                "mean_egg_health": average([v["egg_health"] for v in values]),
                "mean_body_loss": average([v["body_loss"] for v in values]),
            }
            for card, values in sorted(body_groups.items())
        },
    }
    return result


if __name__ == "__main__":
    print(json.dumps(summarize(sys.argv[1]), indent=2))
