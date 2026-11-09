#!/usr/bin/env python3
"""Size a fixed head-to-head sample from independent-seed pilot variance, before running.

Normal-approximation 80% power at two-sided alpha .05; round up to ten seeds.
The effect is a declared minimum placement gain, not a stopping target.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path
from statistics import NormalDist

from check_lines import head_to_head
from summarize_bench import t95


def required_seeds(sd: float, effect: float, power: float = 0.8) -> int:
    if sd <= 0 or effect <= 0 or not 0.5 < power < 1:
        raise ValueError("need positive pilot SD/effect and power between .5 and 1")
    normal = NormalDist()
    count = math.ceil(((normal.inv_cdf(0.975) + normal.inv_cdf(power)) * sd / effect) ** 2)
    return max(2, count)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pilot", type=Path)
    parser.add_argument("--effect", type=float, required=True)
    parser.add_argument("--candidate")
    parser.add_argument("--profiles", type=Path, required=True)
    parser.add_argument("--first-seed", type=int, required=True)
    parser.add_argument("--seconds-per-seed", type=float, default=17.5)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    pilot = head_to_head(args.pilot)
    minimum = required_seeds(pilot["seed_sd"], args.effect)
    count = math.ceil(minimum / 10) * 10
    plan = {
        "suite": "head_to_head",
        "candidate": args.candidate or pilot["candidate"],
        "incumbent": pilot["incumbent"],
        "profiles": str(args.profiles),
        "profiles_sha256": hashlib.sha256(args.profiles.read_bytes()).hexdigest(),
        "revision": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
        "pilot": str(args.pilot),
        "pilot_seed_sd": pilot["seed_sd"],
        "minimum_detectable_effect": args.effect,
        "normal_power80_required_seeds": minimum,
        "independent_seeds": count,
        "lobbies": 2 * count,
        "seed_range": [args.first_seed, args.first_seed + count - 1],
        "planned_ci_halfwidth_at_pilot_sd": t95(count - 1) * pilot["seed_sd"] / math.sqrt(count),
        "power": 0.8,
        "confidence": 0.95,
        "estimated_seconds": count * args.seconds_per_seed,
        "pass_rule": "lower two-sided 95% Student-t bound on seed-cluster mean placement gain exceeds zero",
        "stopping_rule": f"exactly {count} seeds; no extensions or policy changes after results",
        "shop_comparisons": "unpaired shop RNG; swapped legs clustered by seed",
        "planning_limit": "power uses pilot variance; no sample size guarantees a positive result",
    }
    rendered = json.dumps(plan, indent=2) + "\n"
    if args.out:
        with args.out.open("x") as output:
            output.write(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
