#!/usr/bin/env python3
"""Read authored wave-1 paper figures in the harness's pre-start convention.

The authored denominator is kept intact. A separate timing-reconciliation
diagnostic applies the two intentional built/paper trigger changes; it must not
be described as the original paper model or a full reproduction of Godot.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import types
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "docs/ideation/content/pass3"
ROUNDS = (8, 10, 12, 14)


def _model(tribe, parameters):
    path = MODEL_DIR / f"{tribe}-pass3-model.py"
    module = types.ModuleType(f"wave1_paper_{tribe}")
    module.__file__ = str(path)
    args = [f"{key}={value}" for key, value in parameters.items()]
    with patch.object(sys, "argv", [str(path), *args]):
        exec(compile(path.read_text(), str(path), "exec"), module.__dict__)
    return module


def _sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _bird_figures(module, key):
    game, out = module.run(key)
    return {
        str(number): {
            "pre_start": out[number][0],
            "paper_printed_board": out[number][0],
            "sky_excluded": out[number][2],
            "active_bodies": len(out[number][3]),
            "eggs": sum(bool(unit[2].get("egg")) for unit in out[number][3]),
            "homecomings_this_round": game.stats[number]["homecomings"],
        }
        for number in range(8, 15)
    }


def _fairy_figures(module, plan):
    out = module.play("accounting", plan, show=False)
    return {
        str(number): {
            "pre_start": out[number]["rec"],
            "paper_combat_including_twin_and_wisps": out[number]["comb"],
            "removed_start_effect_stats": out[number]["comb"] - out[number]["rec"],
            "ring_size": out[number]["S"],
            "rings": out[number]["rings"],
            "active_bodies": len(out[number]["board"]),
        }
        for number in range(8, 15)
    }


def _timing_reconciled_birds(module, rates):
    original = module.Game

    class BuiltTrips(original):
        def fly(self, bird):
            super().fly(bird)
            key = (
                "birds_swallow_trip_turns"
                if bird.card == "Swallow"
                else "birds_golden_tern_trip_turns"
                if bird.card == "Tern" and bird.golden
                else "birds_trip_turns"
            )
            bird.due = self.t + int(rates[key])

    module.Game = BuiltTrips


def _timing_reconciled_fairies(module, rates):
    original = module.Game

    class BuiltCluricaun(original):
        def __init__(self, parameters):
            super().__init__(parameters)
            self.S = rates["fairies_initial_ring_size"]

        def act(self, action):
            super().act(action)
            if action[0] != "tier" or not all(self.ring[slot] > 0 for slot in module.SLOTS):
                return
            copies = [unit for unit in self.b.values() if unit.name == "clur"]
            if copies:
                factor = 2 if any(unit.golden for unit in copies) else 1
                self.S += rates["fairies_ring_growth"] * factor

        def end_of_turn(self, tithe=False):
            # Disable the authored periodic Cluricaun branch only. All other
            # original End-of-Turn ordering, model actions and budgets remain.
            saved = self.p["g"]
            self.p["g"] = 1e-12
            try:
                super().end_of_turn(tithe)
            finally:
                self.p["g"] = saved

    module.Game = BuiltCluricaun


def build_paper_reference(rates=None):
    """Return authored and explicitly distinguished built-timing denominators."""
    rates_path = ROOT / "content/pass3/rates.json"
    document = json.loads(rates_path.read_text()) if rates is None else dict(rates)
    rates = dict(document.get("rates", document))
    if "presets" in document:
        rates.update(document["presets"].get(document.get("default_preset", "B"), {}))
    # These rates are hard-coded, rather than parameterized, in the paper
    # engines. Refuse changed values instead of claiming to have mapped them.
    fixed = {
        "birds_golden_homecoming_multiplier": rates["birds_homecoming_multiplier"],
        "birds_jack_daw_permanent": True,
        "birds_stork_recalls": 1,
        "birds_golden_egg_multiplier": 2,
        "birds_lump_multiplier": 1,
        "birds_ratchet_multiplier": 1,
        "birds_redwing_share": 0.5,
        "birds_redwing_targets": 2,
        "birds_dunnock_turns": 1,
        "birds_dunnock_targets": 1,
        "fairies_initial_ring_size": 1,
        "fairies_lob_growth": 1,
        "fairies_silky_growth": 1,
        "fairies_monarch_multiplier": 2,
        "fairies_golden_monarch_multiplier": 3,
        "fairies_annis_sale": True,
        "fairies_nan_rings": 1,
        "fairies_annis_rings": 1,
        "fairies_sally_rings": 1,
        "fairies_chaser_gold": 1,
        "fairies_wisp_attack": 1,
        "fairies_wisp_health": 1,
    }
    changed = {
        key: {"built": rates[key], "paper": expected} for key, expected in fixed.items() if rates[key] != expected
    }
    if changed:
        raise ValueError(f"paper has no parameter for changed fixed rates: {changed}")
    bird_parameters = {
        "h": rates["birds_homecoming_multiplier"],
        "s": rates["birds_redbreast_share"],
        "k": rates["birds_cuckoo_share"],
        "f": rates["birds_jack_daw_share"],
        "g": rates["birds_stork_gold_step"],
        "egg": int(rates["birds_golden_egg_enabled"]),
        "n": 0,
        "lines": "A,U",
    }
    fairy_parameters = {
        "fetch": rates["fairies_fetch_share"],
        "lob": rates["fairies_lob_turns"],
        "p": rates["fairies_monarch_period"],
        "qk": rates["fairies_queen_rings"],
        "qp": rates["fairies_queen_period"],
        "guards": 1,
        "g": 1 / 3,
        "supply": 2,
    }
    birds, fairies = _model("birds", bird_parameters), _model("fairies", fairy_parameters)
    authored = {name: _bird_figures(birds, key) for name, key in (("birds_homecoming", "A"), ("birds_tempo", "U"))}
    for name, maker in (("fairies_ring", fairies.ring_plan), ("fairies_court", fairies.court_plan)):
        authored[name] = _fairy_figures(fairies, maker("typ"))
    _timing_reconciled_birds(birds, rates)
    _timing_reconciled_fairies(fairies, rates)
    reconciled = {name: _bird_figures(birds, key) for name, key in (("birds_homecoming", "A"), ("birds_tempo", "U"))}
    for name, maker in (("fairies_ring", fairies.ring_plan), ("fairies_court", fairies.court_plan)):
        reconciled[name] = _fairy_figures(fairies, maker("typ"))
    for table in (authored, reconciled):
        for values in table.values():
            values["growth_r8_r14"] = (values["14"]["pre_start"] / values["8"]["pre_start"]) ** (1 / 6)
    paths = [MODEL_DIR / f"{tribe}-pass3-model.py" for tribe in ("birds", "fairies")]
    return {
        "version": 1,
        "rates": rates,
        "model_sha256": {str(path.relative_to(ROOT)): _sha(path) for path in paths},
        "rates_sha256": _sha(rates_path),
        "parameters": {"birds": bird_parameters, "fairies": fairy_parameters},
        "fixed_rate_checks": fixed,
        "requested_rounds": list(ROUNDS),
        "authored_paper_pre_start": authored,
        "built_timing_reconciliation": reconciled,
        "conversion": {
            "birds": (
                "Sum original Game.snapshot active Attack+Health after auras, before Start of Combat. "
                "Eggs and the Lump's borrowed Nest stats are already included. The printed board total already "
                "excludes sky/away and hand bodies; do not add or subtract the separately printed sky."
            ),
            "fairies": (
                "Use original snapshot recruit total (rec), not combat (comb): this retains the printed Fetch "
                "body and occupied-slot Rings, removes the Start-of-Combat Fetch replacement/twin and Wisps "
                "on empty Ring slots. Per-round removed_start_effect_stats is comb minus rec. "
                "Built Fetch share 0.5 replaces authored default 1.0, though it changes only combat, not rec."
            ),
        },
        "intentional_timing_differences": [
            {
                "piece": "Cluricaun",
                "authored": "+1 Ring size every third rainbow-complete End of Turn (g=1/3)",
                "built": "+1 Ring size after tier-up when every slot has a Ring (golden +2)",
                "diagnostic_translation": (
                    "Suppress only the periodic Cluricaun branch; apply built growth on each scripted tier-up."
                ),
                "source": "docs/ideation/DECISIONS.md: Wave 1 review: calls on the asks, item 1",
                "same_numeric_dial_is_not_equivalent": True,
            },
            {
                "piece": "One Swallow trip",
                "authored": "2 turns, hard-coded with ordinary fliers",
                "built": f"{rates['birds_swallow_trip_turns']} turn(s)",
                "diagnostic_translation": (
                    "Original fly action, then due round from the built ordinary/Swallow/golden-Tern trip dial."
                ),
                "source": "content/units/one_swallow.json and RecruitUnit.flight_turns",
            },
        ],
        "not_modelled": [
            (
                "Real shops, shared-pool depletion, heroes, opponent composition, "
                "survival selection and actual line-policy decisions."
            ),
            (
                "Bird Jack Daw permanent carry uses a target-shape opponent proxy and floor rounding; "
                "Godot uses actual across stats and ceil."
            ),
            "Reel combat movement, holder keywords and answer damage do not enter the paper pre-start denominator.",
            (
                "The reconciliation changes the two listed timing rules only, "
                "not authored arrivals, budgets or all game rules."
            ),
        ],
        "comparability": (
            "Primary figures retain the authored algorithms with semantically mapped built dials. No single "
            "paper g parameter represents the built Cluricaun event, and no original Bird CLI parameter "
            "represents Swallow duration; primary ratios therefore retain an explicit timing qualification. "
            "The supplemental diagnostic is separately labelled and never replaces the authored denominator."
        ),
        "out_text": {
            "birds": (
                "docs/ideation/content/pass3/birds-pass3-model.out.txt exists; "
                "rerun uses current model source and built mapped dials"
            ),
            "fairies": (
                "No fairies-pass3-model.out.txt exists on this tree; "
                "tables in fairies-pass3.md are the archived printed figures"
            ),
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(build_paper_reference(), indent=2) + "\n")


if __name__ == "__main__":
    main()
