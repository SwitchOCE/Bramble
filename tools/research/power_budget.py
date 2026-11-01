#!/usr/bin/env python3
"""First power-budget pass for Bramble: what Battlegrounds charges for stats and text.

Reads the card libraries built by build_bg_library.py (and build_galaxy_library.py
when its output exists) and writes analysis tables to
docs/research/battlegrounds/analysis/ as CSV and JSON. The findings are written up
in docs/research/battlegrounds/power-analysis.md; the methodology built on them is
docs/design/power-budget.md.

Standard library only. Run from anywhere:

    python -I tools/research/power_budget.py            # full run (about a minute)
    python -I tools/research/power_budget.py --quick    # smaller combat simulation
    python -I tools/research/power_budget.py --no-sim   # card statistics only

Analyses
  1. Per-tier stat distributions (current pool; every minion ever in the pool).
  2. Fitted stat curve (attack+health against tier) and outliers.
  3. Attack share (attack / (attack+health)) by tier and tribe.
  4. Text classification into keywords and effect categories (per-card audit file).
  5. Stat "cost" of each feature: OLS and Huber regressions of stat ratio
     (stats / tier median) on features, plus tier-matched grouped differences.
  6. Golden versus normal multipliers (stats and numbers in text).
  7. Gold-to-stats exchange rate from Tavern buff spells.
  8. Power creep: per-build tier means from the per-build snapshots in
     tools/research/.cache/slim (if present), stat-change events, and a
     first-seen cohort comparison from minions.json (always available).
  9. Once Upon a Galaxy characters: stats by rarity and keyword (if the Galaxy
     library exists).
 10. A toy headless combat simulation comparing a 7-wide Battlegrounds row with
     Bramble's fixed-slot staggered 4-3 board: per-slot exposure, marginal win-rate
     value of +Attack, +Health, Divine Shield and Taunt by slot, neighbour counts
     for "in front of / behind" text, placement and empty-slot value.
     It is a calibration aid, not a balance verdict: vanilla units, no effects.
"""
from __future__ import annotations

import argparse
import csv
import glob
import json
import math
import os
import random
import re
import statistics
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BG_DATA = REPO / "docs" / "research" / "battlegrounds" / "data"
OUT = REPO / "docs" / "research" / "battlegrounds" / "analysis"
SLIM = REPO / "tools" / "research" / ".cache" / "slim"
GALAXY_CARDS = REPO / "docs" / "research" / "galaxy" / "data" / "cards.json"

TIERS = [1, 2, 3, 4, 5, 6]          # T7 is tiny and odd; reported but not fitted
ALL_TIERS = [1, 2, 3, 4, 5, 6, 7]
SUMMARY: dict = {}


# --------------------------------------------------------------------------- io

def load(name: str) -> dict:
    with open(BG_DATA / name, encoding="utf-8") as f:
        return json.load(f)


def write_csv(name: str, rows: list[dict], fields: list[str] | None = None) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    if fields is None:
        fields = []
        for r in rows:
            for k in r:
                if k not in fields:
                    fields.append(k)
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: fmt(v) for k, v in r.items()})


def write_json(name: str, obj) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, ensure_ascii=False, default=fmt)


def fmt(v):
    if isinstance(v, float):
        return round(v, 4)
    if isinstance(v, (list, tuple)):
        return ";".join(str(fmt(x)) for x in v)
    return v


# ------------------------------------------------------------------------ stats

def pct(vals: list[float], q: float) -> float:
    s = sorted(vals)
    if not s:
        return float("nan")
    k = (len(s) - 1) * q
    lo, hi = math.floor(k), math.ceil(k)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def describe(vals: list[float]) -> dict:
    if not vals:
        return {"n": 0}
    return {
        "n": len(vals),
        "mean": statistics.fmean(vals),
        "median": statistics.median(vals),
        "sd": statistics.stdev(vals) if len(vals) > 1 else 0.0,
        "min": min(vals),
        "p25": pct(vals, 0.25),
        "p75": pct(vals, 0.75),
        "max": max(vals),
    }


def mad(vals: list[float]) -> float:
    m = statistics.median(vals)
    return statistics.median([abs(v - m) for v in vals])


def invert(m: list[list[float]]) -> list[list[float]]:
    """Gauss-Jordan inverse with partial pivoting."""
    n = len(m)
    a = [row[:] + [1.0 if i == j else 0.0 for j in range(n)] for i, row in enumerate(m)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(a[r][c]))
        if abs(a[p][c]) < 1e-12:
            raise ValueError("singular matrix")
        a[c], a[p] = a[p], a[c]
        piv = a[c][c]
        a[c] = [v / piv for v in a[c]]
        for r in range(n):
            if r != c and a[r][c] != 0.0:
                f = a[r][c]
                a[r] = [vr - f * vc for vr, vc in zip(a[r], a[c])]
    return [row[n:] for row in a]


def wls(X: list[list[float]], y: list[float], w: list[float] | None = None, ridge: float = 1e-6):
    """Weighted least squares. Returns beta, standard errors, R^2, residuals."""
    n, k = len(X), len(X[0])
    w = w or [1.0] * n
    xtx = [[0.0] * k for _ in range(k)]
    xty = [0.0] * k
    for xi, yi, wi in zip(X, y, w):
        for a in range(k):
            va = xi[a] * wi
            if va == 0.0:
                continue
            xty[a] += va * yi
            row = xtx[a]
            for b in range(k):
                row[b] += va * xi[b]
    for a in range(1, k):
        xtx[a][a] += ridge
    inv = invert(xtx)
    beta = [sum(inv[a][b] * xty[b] for b in range(k)) for a in range(k)]
    resid = [yi - sum(b * x for b, x in zip(beta, xi)) for xi, yi in zip(X, y)]
    sw = sum(w)
    dof = max(1, n - k)
    sigma2 = sum(wi * r * r for wi, r in zip(w, resid)) / dof
    se = [math.sqrt(max(0.0, inv[a][a] * sigma2)) for a in range(k)]
    ybar = sum(wi * yi for wi, yi in zip(w, y)) / sw
    sst = sum(wi * (yi - ybar) ** 2 for wi, yi in zip(w, y))
    sse = sum(wi * r * r for wi, r in zip(w, resid))
    r2 = 1 - sse / sst if sst else 0.0
    return beta, se, r2, resid


def huber(X, y, k=1.345, iters=30):
    """Huber M-estimator by iteratively reweighted least squares."""
    w = [1.0] * len(y)
    beta, se, r2, resid = wls(X, y, w)
    for _ in range(iters):
        s = (mad(resid) / 0.6745) or 1e-9
        w = [1.0 if abs(r / s) <= k else k / abs(r / s) for r in resid]
        nb, se, r2, resid = wls(X, y, w)
        if max(abs(a - b) for a, b in zip(nb, beta)) < 1e-7:
            beta = nb
            break
        beta = nb
    return beta, se, r2, resid


# -------------------------------------------------------------- classification

TRIBE_WORDS = r"(beasts?|demons?|dragons?|elementals?|mechs?|murlocs?|naga|pirates?|quilboars?|undead|aberrations?)"

# Each feature: (group, description, test(card, lowered text) -> bool).
# "keyword" = static keyword; "trigger" = when the effect fires; "effect" = what it does;
# "condition" = what the text depends on. Patterns are crude on purpose and auditable
# in card_features.csv.
def _kw(card, *names):
    return any(n in card["keywords"] for n in names)


def _sentences(t):
    return [s for s in re.split(r"[.!]\s*", t) if s]


FEATURES = [
    ("taunt", "keyword", "Taunt", lambda c, t: _kw(c, "Taunt")),
    ("divine_shield", "keyword", "Divine Shield", lambda c, t: _kw(c, "Divine Shield")),
    ("reborn", "keyword", "Reborn", lambda c, t: _kw(c, "Reborn")),
    ("windfury", "keyword", "Windfury or Mega-Windfury", lambda c, t: _kw(c, "Windfury") or "windfury" in t.split(".")[0] and not re.search(r"give|gain|have", t.split(".")[0])),
    ("venomous", "keyword", "Venomous or Poisonous", lambda c, t: _kw(c, "Venomous", "Poisonous")),
    ("stealth", "keyword", "Stealth", lambda c, t: _kw(c, "Stealth")),
    ("magnetic", "keyword", "Magnetic", lambda c, t: _kw(c, "Magnetic")),
    ("cleave", "keyword", "Cleave: also damages the minions next to the target", lambda c, t: bool(re.search(r"also damages? the (minions|enemies) next to", t))),
    ("battlecry", "trigger", "Battlecry", lambda c, t: _kw(c, "Battlecry") or t.startswith("battlecry")),
    ("deathrattle_summon", "trigger", "Deathrattle that summons", lambda c, t: (_kw(c, "Deathrattle") or "deathrattle:" in t) and bool(re.search(r"deathrattle:[^.]*summon", t))),
    ("deathrattle_other", "trigger", "Deathrattle that does not summon", lambda c, t: (_kw(c, "Deathrattle") or "deathrattle:" in t) and not re.search(r"deathrattle:[^.]*summon", t)),
    ("start_of_combat", "trigger", "Start of Combat", lambda c, t: _kw(c, "Start of Combat") or "start of combat" in t),
    ("avenge", "trigger", "Avenge (X)", lambda c, t: _kw(c, "Avenge") or "avenge (" in t),
    ("rally", "trigger", "Rally (when this attacks)", lambda c, t: _kw(c, "Rally") or t.startswith("rally") or " rally:" in t),
    ("on_attack_or_damage", "trigger", "Other in-combat trigger (after/whenever attacks, takes damage, dies, is summoned)", lambda c, t: bool(re.search(r"(after|whenever|when)[^.]*(attacks|takes damage|deals damage|dies|is summoned|loses divine shield|you summon)", t))),
    ("end_of_turn", "trigger", "End of turn", lambda c, t: _kw(c, "End of Turn") or "end of your turn" in t),
    ("start_of_turn", "trigger", "Start of turn", lambda c, t: "start of your turn" in t),
    ("on_play_or_buy", "trigger", "Recruit-phase trigger (after you play/buy/sell/refresh/cast)", lambda c, t: bool(re.search(r"(after|whenever|when) you (play|buy|sell|refresh|cast|spend|gain)", t))),
    ("spellcraft", "trigger", "Spellcraft", lambda c, t: _kw(c, "Spellcraft") or t.startswith("spellcraft")),
    ("activate", "trigger", "Activate (N)", lambda c, t: "activate (" in t),
    ("choose_one", "trigger", "Choose One", lambda c, t: _kw(c, "Choose One") or "choose one" in t),
    ("aura", "effect", "Aura / static effect on others", lambda c, t: _kw(c, "Aura") or bool(re.search(r"\byour (other )?\w+ have \+|\bhave \+\d", t))),
    ("economy", "effect", "Economy: gold, coins, free or cheaper refreshes and buys", lambda c, t: bool(re.search(r"\bgold\b|tavern coin|free refresh|refreshes? (each turn )?cost|costs? \(\d+\) less|maximum gold|cost health instead", t))),
    ("shop_buff", "effect", "Buffs minions in the Tavern", lambda c, t: any("in the tavern" in s and re.search(r"\+\d", s) for s in _sentences(t))),
    ("permanent_scaling", "effect", "Scales permanently or 'this game' (improves over turns)", lambda c, t: bool(re.search(r"permanent|this game|improves? |improved by|\(improves", t))),
    ("spell_gen", "effect", "Generates Tavern spells / Blood Gems / named spell cards", lambda c, t: bool(re.search(r"\b(get|gets|discover|add)s?\b[^.]*\b(spells?|blood gems?|fortify|bount(y|ies)|corrosion|conflagration|butchering|golden touch|pointy arrows?|gem day|fodder|fishbait)\b", t)) and "tavern coin" not in t),
    ("card_gen", "effect", "Generates minions to hand (get/discover a minion)", lambda c, t: bool(re.search(r"\b(get|gets|discover)\b[^.]*\b(minions?|tier \d|cop(y|ies)|chromadrake|" + TRIBE_WORDS + r")\b", t))),
    ("summon_in_combat", "effect", "Summons units in combat (not via Deathrattle)", lambda c, t: bool(re.search(r"summon", t)) and not re.search(r"deathrattle:[^.]*summon", t) and not re.search(r"whenever you summon|after you summon|you summon", t)),
    ("buff_others", "effect", "Gives other minions stats", lambda c, t: any(re.search(r"\bgive[s]?\b[^.]*\+\d", s) and "in the tavern" not in s for s in _sentences(t))),
    ("self_growth", "effect", "Gains stats itself", lambda c, t: bool(re.search(r"\bgains? \+\d|this gains|gain stats|keeps? [^.]*stats", t))),
    ("damage_effect", "effect", "Direct damage or destroy", lambda c, t: bool(re.search(r"\bdeal[s]? (\d+ )?(excess )?damage|destroy|set [^.]*health to", t))),
    ("multiplier", "effect", "Doubles other triggers (Brann-style)", lambda c, t: bool(re.search(r"(trigger|cast)s? (twice|an extra time)|an extra time|trigger twice", t))),
    ("golden_ref", "effect", "References Golden / triples", lambda c, t: bool(re.search(r"\bgolden\b|triple", t))),
    ("drawback", "effect", "Drawback: destroys itself, loses stats, hurts your hero, helps the opponent, forced targeting", lambda c, t: bool(re.search(r"destroy (it|this)|\blose \d|lose \+?\d|damage to your hero|for your opponent|can't attack", t))),
    ("targeting", "effect", "Chooses its own target ('always attacks the ...', 'immediately attacks')", lambda c, t: bool(re.search(r"always attacks|immediately attacks|attacks? the (enemy|highest|lowest)", t))),
    ("positional", "condition", "Position text: adjacent, next to, left-most, right-most", lambda c, t: bool(re.search(r"adjacent|next to|left-most|right-most|leftmost|rightmost|neighbo", t))),
    ("tribe_dependent", "condition", "Text names a tribe (synergy dependency)", lambda c, t: bool(re.search(r"\b" + TRIBE_WORDS + r"\b", t))),
    ("counter_condition", "condition", "Has a counter or threshold ('(N left!)', 'once this', 'every N')", lambda c, t: bool(re.search(r"left!\)|once this|every \d|\(\d+ ", t))),
]
FEATURE_NAMES = [f[0] for f in FEATURES]
FEATURE_GROUP = {f[0]: f[1] for f in FEATURES}
FEATURE_DESC = {f[0]: f[2] for f in FEATURES}
RECRUIT_FEATURES = {"battlecry", "end_of_turn", "start_of_turn", "on_play_or_buy", "spellcraft", "activate",
                    "choose_one", "economy", "shop_buff", "spell_gen", "card_gen", "magnetic"}
COMBAT_FEATURES = {"deathrattle_summon", "deathrattle_other", "start_of_combat", "avenge", "rally",
                   "on_attack_or_damage", "cleave", "summon_in_combat", "damage_effect"}
STATIC_KEYWORDS = {"taunt", "divine_shield", "reborn", "windfury", "venomous", "stealth"}


def classify(card: dict) -> dict:
    t = (card.get("text") or "").lower().replace("\n", " ")
    t = re.sub(r"\s+", " ", t).strip()
    return {name: bool(test(card, t)) for name, _, _, test in FEATURES}


def timing_class(f: dict) -> str:
    rec = any(f[k] for k in RECRUIT_FEATURES)
    com = any(f[k] for k in COMBAT_FEATURES)
    if rec and com:
        return "recruit+combat"
    if rec:
        return "recruit-phase only"
    if com:
        return "combat only"
    if any(f[k] for k in STATIC_KEYWORDS) and not any(f[k] for k in FEATURE_NAMES if k not in STATIC_KEYWORDS):
        return "static keywords only"
    if not any(f.values()):
        return "no classified text"
    return "other text"


# ------------------------------------------------------------- card analyses

def stats_of(c):
    return c["attack"] + c["health"]


def tier_tables(samples: dict[str, list[dict]]):
    rows = []
    for label, cards in samples.items():
        for t in ALL_TIERS:
            cs = [c for c in cards if c["tier"] == t]
            for field, fn in (("attack", lambda c: c["attack"]), ("health", lambda c: c["health"]),
                              ("stats", stats_of), ("attack_share", lambda c: c["attack"] / stats_of(c) if stats_of(c) else 0.5)):
                d = describe([fn(c) for c in cs])
                rows.append({"sample": label, "tier": t, "measure": field, **d})
    write_csv("tier_stats.csv", rows, ["sample", "tier", "measure", "n", "mean", "median", "sd", "min", "p25", "p75", "max"])
    return rows


def stat_curve(samples):
    out = {}
    outlier_rows = []
    for label, cards in samples.items():
        pts = [(c["tier"], stats_of(c)) for c in cards if c["tier"] in TIERS and stats_of(c) > 0]
        X = [[1.0, t] for t, _ in pts]
        y = [s for _, s in pts]
        (a, b), (sa, sb), r2, _ = wls(X, y)
        (la, lb), (sla, slb), lr2, _ = wls(X, [math.log(s) for s in y])
        # quadratic for curvature check
        (qa, qb, qc), _, qr2, _ = wls([[1.0, t, t * t] for t, _ in pts], y)
        med = {t: statistics.median([s for tt, s in pts if tt == t]) for t in TIERS}
        mean = {t: statistics.fmean([s for tt, s in pts if tt == t]) for t in TIERS}
        sse_lin = sum((s - (a + b * t)) ** 2 for t, s in pts)
        sse_exp = sum((s - math.exp(la + lb * t)) ** 2 for t, s in pts)
        steps = {f"{t}->{t + 1}": med[t + 1] - med[t] for t in TIERS[:-1]}
        out[label] = {
            "n": len(pts),
            "linear": {"intercept": a, "slope": b, "se_slope": sb, "r2": r2, "sse": sse_lin},
            "exponential": {"S1": math.exp(la + lb), "growth_per_tier": math.exp(lb), "r2_log": lr2, "sse": sse_exp},
            "quadratic": {"a": qa, "b": qb, "c": qc, "r2": qr2},
            "tier_median": med,
            "tier_mean": mean,
            "median_step": steps,
            "mean_over_tier_ratio": {t: mean[t] / t for t in TIERS},
        }
        # robust per-tier outliers
        for t in TIERS:
            cs = [c for c in cards if c["tier"] == t]
            vals = [stats_of(c) for c in cs]
            m, s = statistics.median(vals), 1.4826 * mad(vals) or 1.0
            for c in cs:
                z = (stats_of(c) - m) / s
                if abs(z) >= 2.5:
                    outlier_rows.append({"sample": label, "tier": t, "name": c["name"], "attack": c["attack"],
                                         "health": c["health"], "stats": stats_of(c), "tier_median": m,
                                         "robust_z": z, "in_current_pool": c["in_current_pool"], "text": c["text"]})
        t7 = [stats_of(c) for c in cards if c["tier"] == 7]
        out[label]["tier7_note"] = describe(t7)
    write_json("stat_curve.json", out)
    outlier_rows.sort(key=lambda r: (r["sample"], -abs(r["robust_z"])))
    write_csv("stat_outliers.csv", outlier_rows)
    return out


def attack_share(samples):
    rows = []
    for label, cards in samples.items():
        tribes = sorted({tr for c in cards for tr in (c["tribes"] or ["(none)"])})
        for tr in tribes + ["ALL"]:
            for t in ALL_TIERS + ["all"]:
                cs = [c for c in cards if (tr == "ALL" or tr in (c["tribes"] or ["(none)"]))
                      and (t == "all" or c["tier"] == t) and stats_of(c) > 0]
                if not cs:
                    continue
                sh = [c["attack"] / stats_of(c) for c in cs]
                rows.append({"sample": label, "tribe": tr, "tier": t, "n": len(cs),
                             "mean_attack_share": statistics.fmean(sh), "median_attack_share": statistics.median(sh),
                             "mean_stats": statistics.fmean([stats_of(c) for c in cs])})
    write_csv("attack_share.csv", rows)
    return rows


def feature_costs(samples, feats_by_id):
    """Regress stat ratio (stats / tier median) on features."""
    rows, models = [], {}
    for label, cards in samples.items():
        cs = [c for c in cards if c["tier"] in TIERS and stats_of(c) > 0]
        med = {t: statistics.median([stats_of(c) for c in cs if c["tier"] == t]) for t in TIERS}
        names = [n for n in FEATURE_NAMES if sum(feats_by_id[c["dbfId"]][n] for c in cs) >= 5]
        X, y, ya = [], [], []
        for c in cs:
            f = feats_by_id[c["dbfId"]]
            X.append([1.0] + [1.0 if f[n] else 0.0 for n in names])
            y.append(stats_of(c) / med[c["tier"]])
        beta, se, r2, resid = wls(X, y)
        hb, hse, hr2, _ = huber(X, y)
        # absolute-stat model with tier dummies (coefficients in flat stat points)
        Xa = []
        for c in cs:
            f = feats_by_id[c["dbfId"]]
            Xa.append([1.0] + [1.0 if c["tier"] == t else 0.0 for t in TIERS[1:]] + [1.0 if f[n] else 0.0 for n in names])
            ya.append(stats_of(c))
        ab, ase, ar2, _ = wls(Xa, ya)
        nt = len(TIERS) - 1
        models[label] = {"n": len(cs), "features": names, "r2_ratio_ols": r2, "r2_ratio_huber": hr2,
                         "r2_absolute": ar2, "intercept_ratio": beta[0], "intercept_ratio_huber": hb[0],
                         "tier_median": med}
        for i, n in enumerate(names):
            with_f = [c for c in cs if feats_by_id[c["dbfId"]][n]]
            # tier-matched grouped difference
            diffs, wts = [], []
            for t in TIERS:
                a_ = [stats_of(c) / med[t] for c in with_f if c["tier"] == t]
                b_ = [stats_of(c) / med[t] for c in cs if c["tier"] == t and not feats_by_id[c["dbfId"]][n]]
                if a_ and b_:
                    diffs.append(statistics.fmean(a_) - statistics.fmean(b_))
                    wts.append(len(a_))
            grouped = sum(d * w for d, w in zip(diffs, wts)) / sum(wts) if wts else float("nan")
            co = beta[i + 1]
            rows.append({
                "sample": label, "feature": n, "group": FEATURE_GROUP[n], "n_with": len(with_f),
                "share_of_sample": len(with_f) / len(cs),
                "ols_ratio_coef": co, "ols_se": se[i + 1], "ols_t": co / se[i + 1] if se[i + 1] else 0.0,
                "huber_ratio_coef": hb[i + 1],
                "grouped_tier_matched_diff": grouped,
                "abs_model_sp": ab[1 + nt + i], "abs_model_se": ase[1 + nt + i],
                "implied_sp_T1": co * med[1], "implied_sp_T3": co * med[3], "implied_sp_T6": co * med[6],
                "mean_tier_with": statistics.fmean([c["tier"] for c in with_f]),
                "description": FEATURE_DESC[n],
            })
    write_csv("feature_costs.csv", rows)
    write_json("feature_models.json", models)
    return rows, models


def complexity_tax(samples, feats_by_id):
    rows = []
    for label, cards in samples.items():
        cs = [c for c in cards if c["tier"] in TIERS and stats_of(c) > 0]
        med = {t: statistics.median([stats_of(c) for c in cs if c["tier"] == t]) for t in TIERS}
        by_n, by_class = defaultdict(list), defaultdict(list)
        for c in cs:
            f = feats_by_id[c["dbfId"]]
            k = sum(1 for n in FEATURE_NAMES if f[n] and FEATURE_GROUP[n] != "condition")
            by_n[min(k, 4)].append(stats_of(c) / med[c["tier"]])
            by_class[timing_class(f)].append(stats_of(c) / med[c["tier"]])
        for k in sorted(by_n):
            rows.append({"sample": label, "split": "feature_count", "value": f"{k}{'+' if k == 4 else ''}",
                         **describe(by_n[k])})
        for k in sorted(by_class):
            rows.append({"sample": label, "split": "timing_class", "value": k, **describe(by_class[k])})
    write_csv("stat_ratio_by_complexity.csv", rows,
              ["sample", "split", "value", "n", "mean", "median", "sd", "min", "p25", "p75", "max"])
    return rows


NUM_RE = re.compile(r"(?<![\w(])\+?(\d+)(?![\w)])")


def golden(samples):
    out = {}
    for label, cards in samples.items():
        ratios, kinds = [], Counter()
        num_ratio = Counter()
        exceptions = []
        for c in cards:
            ga, gh = c.get("golden_attack"), c.get("golden_health")
            if ga is None or gh is None or stats_of(c) == 0:
                continue
            r = (ga + gh) / stats_of(c)
            ratios.append(r)
            if ga == 2 * c["attack"] and gh == 2 * c["health"]:
                kinds["exactly_double"] += 1
            else:
                kinds["other"] += 1
                exceptions.append(f"{c['name']} {c['attack']}/{c['health']} -> {ga}/{gh}")
            n1 = [int(x) for x in NUM_RE.findall(c.get("text") or "")]
            n2 = [int(x) for x in NUM_RE.findall(c.get("golden_text") or "")]
            if n1 and len(n1) == len(n2):
                for a, b in zip(n1, n2):
                    if a == 0:
                        continue
                    q = b / a
                    num_ratio["x2" if q == 2 else "x1" if q == 1 else "x3+" if q >= 3 else "other"] += 1
            elif c.get("text") and c.get("golden_text") and c["text"] != c["golden_text"]:
                num_ratio["reworded (trigger twice, etc.)"] += 1
        out[label] = {"stat_ratio": describe(ratios), "stat_kinds": dict(kinds),
                      "text_number_scaling": dict(num_ratio), "stat_exceptions": exceptions[:40]}
    write_json("golden.json", out)
    return out


SPELL_SINGLE = re.compile(r"give (?:a|another|a friendly|your left-most|a random friendly) minion \+(\d+)/\+(\d+)|give (?:a|a friendly) minion \+(\d+) (attack|health)")
SPELL_TEAM = re.compile(r"give (your|four random friendly|four friendly|three friendly|two friendly) minions \+(\d+)/\+(\d+)|give (four|three) (?:random )?friendly minions \+(\d+) (attack|health)")


def spells_gold_to_stats(spells):
    rows = []
    for s in spells:
        if not s.get("ever_in_pool_sampled") or not s.get("cost"):
            continue
        t = (s.get("text") or "").lower()
        mult = 2 if "twice" in t else 1
        m = SPELL_SINGLE.search(t)
        kind, sp, targets = None, 0, 1
        if m:
            kind = "single"
            sp = int(m.group(1)) + int(m.group(2)) if m.group(1) else int(m.group(3))
            if "your left-most" in t:
                kind = "single"
        else:
            m = SPELL_TEAM.search(t)
            if m:
                kind = "team"
                if m.group(1):
                    who = m.group(1)
                    sp = int(m.group(2)) + int(m.group(3))
                else:
                    who = m.group(4)
                    sp = int(m.group(5))
                targets = {"your": 7, "four random friendly": 4, "four friendly": 4, "three friendly": 3,
                           "two friendly": 2, "four": 4, "three": 3}[who]
        if not kind:
            continue
        cond = bool(re.search(r"\bif\b|repeat|choose one|this game|next turn|start of combat", t))
        total = sp * mult * targets
        rows.append({"name": s["name"], "tier": s["tier"], "cost": s["cost"], "kind": kind,
                     "stats_per_target": sp * mult, "targets_assumed": targets, "total_stats": total,
                     "stats_per_gold": total / s["cost"], "per_target_per_gold": sp * mult / s["cost"],
                     "conditional_or_extra": cond, "in_current_pool": s.get("in_current_pool"), "text": s["text"]})
    rows.sort(key=lambda r: (r["kind"], r["tier"], r["cost"]))
    write_csv("spell_gold_to_stats.csv", rows)
    agg = []
    for kind in ("single", "team"):
        for t in ALL_TIERS:
            v = [r["per_target_per_gold"] for r in rows if r["kind"] == kind and r["tier"] == t and not r["conditional_or_extra"]]
            if v:
                agg.append({"kind": kind, "tier": t, "n_unconditional": len(v),
                            "median_stats_per_target_per_gold": statistics.median(v),
                            "mean_stats_per_target_per_gold": statistics.fmean(v)})
    write_csv("spell_gold_to_stats_by_tier.csv", agg)
    return rows, agg


# ----------------------------------------------------------------- creep

KW_ONLY_WORDS = {"taunt", "divine", "shield", "reborn", "windfury", "mega-windfury", "venomous", "poisonous",
                 "stealth", "magnetic", "rush", "charge", "cleave"}


SCALING_RE = re.compile(r"permanent|this game|improve|end of your turn|start of your turn|in the tavern|for the rest of")


def strip_html(t):
    t = re.sub(r"<[^>]+>", "", t or "")
    t = re.sub(r"\[x\]|\$|#|\{\d\}", "", t)
    return re.sub(r"\s+", " ", t).strip()


def creep_from_snapshots(current_median):
    files = sorted(glob.glob(str(SLIM / "*.json")), key=lambda f: int(os.path.basename(f)[:-5]))
    if not files:
        return None
    build_dates = {b["build"]: b for b in load("builds.json")["sampled_builds"]}
    rows, changes = [], []
    prev = None
    yearly = defaultdict(lambda: defaultdict(list))
    for f in files:
        with open(f, encoding="utf-8") as fh:
            snap = json.load(fh)
        b = snap["build"]
        info = build_dates.get(b, {})
        date = info.get("date", "")
        pool = {int(k): v for k, v in snap["pool"].items()}
        for t in ALL_TIERS:
            cs = [p for p in pool.values() if p["techLevel"] == t]
            if not cs:
                continue
            st = [p["attack"] + p["health"] for p in cs]
            kwo = 0
            for p in cs:
                words = set(re.findall(r"[a-z\-]+", strip_html(p.get("text")).lower()))
                if words <= KW_ONLY_WORDS:
                    kwo += 1
            scal = sum(1 for p in cs if SCALING_RE.search(strip_html(p.get("text")).lower()))
            ratio = [s / current_median[t] for s in st] if t in current_median else []
            rows.append({"build": b, "date": date, "version": info.get("version", ""), "era": snap.get("era"),
                         "tier": t, "n": len(cs), "mean_stats": statistics.fmean(st),
                         "median_stats": statistics.median(st), "mean_attack": statistics.fmean([p["attack"] for p in cs]),
                         "mean_health": statistics.fmean([p["health"] for p in cs]),
                         "vanilla_or_keyword_only": kwo, "share_scaling_text": scal / len(cs),
                         "mean_ratio_to_current_median": statistics.fmean(ratio) if ratio else ""})
            if date and ratio:
                yearly[date[:4]][t].extend(st)
                yearly[date[:4]]["scaling"].extend([1 if SCALING_RE.search(strip_html(p.get("text")).lower()) else 0 for p in cs])
        if prev is not None:
            for k, p in pool.items():
                q = prev[1].get(k)
                if q and (q["attack"], q["health"], q["techLevel"]) != (p["attack"], p["health"], p["techLevel"]):
                    d_stats = (p["attack"] + p["health"]) - (q["attack"] + q["health"])
                    changes.append({"from_build": prev[0], "to_build": b, "to_date": date, "name": p["name"],
                                    "old": f"T{q['techLevel']} {q['attack']}/{q['health']}",
                                    "new": f"T{p['techLevel']} {p['attack']}/{p['health']}",
                                    "tier_change": p["techLevel"] - q["techLevel"], "stat_change": d_stats,
                                    "text_changed": strip_html(p.get("text")) != strip_html(q.get("text"))})
        prev = (b, pool)
    write_csv("creep_by_build.csv", rows)
    write_csv("stat_changes.csv", changes)
    yrows = []
    for y in sorted(yearly):
        for t in sorted(k for k in yearly[y] if k != "scaling"):
            v = yearly[y][t]
            yrows.append({"year": y, "tier": t, "minion_build_samples": len(v), "mean_stats": statistics.fmean(v),
                          "median_stats": statistics.median(v)})
        v = yearly[y]["scaling"]
        yrows.append({"year": y, "tier": "share_of_pool_with_scaling_text", "minion_build_samples": len(v),
                      "mean_stats": statistics.fmean(v), "median_stats": ""})
    write_csv("creep_by_year.csv", yrows)
    # summary of change events
    ev = Counter()
    for c in changes:
        if c["tier_change"] > 0:
            ev["tier up (nerf)"] += 1
        elif c["tier_change"] < 0:
            ev["tier down (buff)"] += 1
        elif c["stat_change"] > 0:
            ev["stats up"] += 1
        elif c["stat_change"] < 0:
            ev["stats down"] += 1
        else:
            ev["stat shape only (same total)"] += 1
    sizes = Counter(abs(c["stat_change"]) for c in changes if c["tier_change"] == 0 and c["stat_change"] != 0)
    return {"builds": len(files), "change_events": dict(ev), "stat_change_sizes": dict(sorted(sizes.items())),
            "first_build": rows[0]["build"], "last_build": rows[-1]["build"]}


def creep_cohorts(all_cards, med_all):
    rows = []
    groups = defaultdict(list)
    for c in all_cards:
        if c["tier"] not in TIERS or stats_of(c) == 0:
            continue
        y = (c.get("lineage_first_seen_date") or c.get("first_seen_date") or "")[:4]
        groups[y].append(stats_of(c) / med_all[c["tier"]])
    for y in sorted(groups):
        rows.append({"first_seen_year": y, **describe(groups[y])})
    write_csv("creep_by_first_seen_cohort.csv", rows, ["first_seen_year", "n", "mean", "median", "sd", "min", "p25", "p75", "max"])
    return rows


# ----------------------------------------------------------------- Galaxy

GAL_RARITY = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret Rare"]


def galaxy():
    if not GALAXY_CARDS.exists():
        return {"status": "TODO: docs/research/galaxy/data/cards.json not found; rerun after build_galaxy_library.py"}
    with open(GALAXY_CARDS, encoding="utf-8") as f:
        d = json.load(f)
    chars = [c for c in d["cards"] if c.get("type") == "character" and not c.get("token")
             and c.get("status") == "current" and c.get("attack") is not None and c.get("health") is not None]
    rows = []
    med = {}
    for r in GAL_RARITY:
        cs = [c for c in chars if c.get("rarity") == r]
        if not cs:
            continue
        st = [c["attack"] + c["health"] for c in cs]
        med[r] = statistics.median(st)
        rows.append({"rarity": r, "shop_turn": {"Common": 1, "Uncommon": 3, "Rare": 5, "Epic": 7, "Legendary": 9}.get(r, ""),
                     **{f"stats_{k}": v for k, v in describe(st).items()},
                     "mean_attack_share": statistics.fmean([c["attack"] / max(1, c["attack"] + c["health"]) for c in cs])})
    write_csv("galaxy_stats_by_rarity.csv", rows)
    kw_rows = []
    kws = sorted({k for c in chars for k in c.get("keywords", [])})
    pos_pat = {"in_front_of": r"in front of", "behind": r"behind", "front_row": r"front row",
               "back_row": r"back row", "adjacent": r"adjacent|next to|neighbo", "across": r"across from",
               "slot": r"\bslot"}
    for k in kws + list(pos_pat):
        if k in pos_pat:
            has = lambda c, p=pos_pat[k]: bool(re.search(p, (c.get("text") or "").lower()))
        else:
            has = lambda c, k=k: k in c.get("keywords", [])
        diffs, wts, n = [], [], 0
        for r in med:
            a_ = [(c["attack"] + c["health"]) / med[r] for c in chars if c.get("rarity") == r and has(c)]
            b_ = [(c["attack"] + c["health"]) / med[r] for c in chars if c.get("rarity") == r and not has(c)]
            n += len(a_)
            if a_ and b_:
                diffs.append(statistics.fmean(a_) - statistics.fmean(b_))
                wts.append(len(a_))
        if n >= 3 and wts:
            kw_rows.append({"feature": k, "kind": "position text" if k in pos_pat else "keyword", "n_with": n,
                            "grouped_rarity_matched_diff": sum(x * w for x, w in zip(diffs, wts)) / sum(wts)})
    kw_rows.sort(key=lambda r: r["grouped_rarity_matched_diff"])
    write_csv("galaxy_feature_diffs.csv", kw_rows)
    # Support costing: static "Support -- +X/+Y" (or +X Attack / +X Health) auras on the
    # two front characters a back slot sits between. "Each fight" supports are permanent
    # growth, not auras, and are listed separately.
    sup_rows = []
    for c in chars:
        t = (c.get("text") or "").replace("—", "--")
        m = re.search(r"Support[-:\s]*\s*(Each fight, give (?:the )?characters in front of me )?\+(\d+)(?:/\+(\d+)| (Attack|Health))", t)
        if not m or c.get("rarity") not in med:
            continue
        per = int(m.group(2)) + int(m.group(3)) if m.group(3) else int(m.group(2))
        body = c["attack"] + c["health"]
        paid = med[c["rarity"]] - body
        sup_rows.append({"name": c["name"], "rarity": c["rarity"], "body": f"{c['attack']}/{c['health']}",
                         "body_stats": body, "rarity_median": med[c["rarity"]], "body_ratio": body / med[c["rarity"]],
                         "kind": "each fight (permanent growth)" if m.group(1) else "static aura",
                         "per_target": per, "nominal_aura_two_targets": 2 * per,
                         "stats_paid_vs_median": paid,
                         "aura_per_stat_paid": (2 * per / paid) if paid > 0 else "",
                         "other_text": len(re.sub(r"Support[^/]*", "", t).strip(" /")) > 0, "text": c["text"]})
    sup_rows.sort(key=lambda r: (GAL_RARITY.index(r["rarity"]), r["name"]))
    write_csv("galaxy_support_costing.csv", sup_rows)
    return {"status": "ok", "characters": len(chars), "rarity_median_stats": med, "features": kw_rows,
            "support_cards_costed": len(sup_rows)}


# --------------------------------------------------------- toy combat sim
#
# Unit = [attack, health, taunt, divine_shield]. Board = 7 slots (None = empty).
# Slots 0-3 are the front row F1-F4, 4-6 the back row B1-B3. The Battlegrounds
# layout uses the same 7 slots as one row (no targeting restriction).
# Rules (Battlegrounds baseline): side with more units attacks first, else coin
# flip; sides alternate single attacks; each side attacks with the next living
# unit after its last attacker in slot order (skipping 0-attack units); the
# attacker hits a random eligible enemy (Taunt first); damage is simultaneous;
# Divine Shield absorbs one hit. Bramble: back row can't be targeted while any
# front unit lives. No effects, no summons, nobody moves.

BEHIND = {0: (4,), 1: (4, 5), 2: (5, 6), 3: (6,)}   # front slot -> back slots behind it
IN_FRONT = {4: (0, 1), 5: (1, 2), 6: (2, 3)}         # back slot -> front slots in front of it


def combat(A, B, rows, rng, track=None, fx=None):
    """One fight. Returns 1 / 0.5 / 0 for side A. fx (side A only) can hold
    'aura_atk': {src_slot: (target_slots, bonus)} -- while src lives, targets have +bonus Attack;
    'front_death_gain': {back_slot: (atk, hp)} -- when a unit in front of back_slot dies, it gains this."""
    sides = [[u[:] if u else None for u in A], [u[:] if u else None for u in B]]
    aura = (fx or {}).get("aura_atk") or {}
    fdg = (fx or {}).get("front_death_gain") or {}

    def bonus(side, j):
        if side or not aura:
            return 0
        b = 0
        for src, (tg, v) in aura.items():
            s = sides[0][src]
            if j in tg and s and s[1] > 0:
                b += v
        return b
    ptr = [-1, -1]
    alive = [sum(1 for u in s if u and u[1] > 0) for s in sides]
    if alive[0] > alive[1]:
        turn = 0
    elif alive[1] > alive[0]:
        turn = 1
    else:
        turn = 0 if rng.random() < 0.5 else 1
    stalled = 0
    for _ in range(300):
        if alive[0] == 0 or alive[1] == 0:
            break
        att, dfn = sides[turn], sides[1 - turn]
        idx = -1
        p = ptr[turn]
        for k in range(1, 8):
            j = (p + k) % 7
            u = att[j]
            if u and u[1] > 0 and u[0] > 0:
                idx = j
                break
        if idx < 0:
            stalled += 1
            if stalled >= 2:
                break
            turn = 1 - turn
            continue
        stalled = 0
        ptr[turn] = idx
        if rows:
            cand = [j for j in range(4) if dfn[j] and dfn[j][1] > 0] or [j for j in range(4, 7) if dfn[j] and dfn[j][1] > 0]
        else:
            cand = [j for j in range(7) if dfn[j] and dfn[j][1] > 0]
        taunts = [j for j in cand if dfn[j][2]]
        if taunts:
            cand = taunts
        tj = cand[int(rng.random() * len(cand))]
        a, d = att[idx], dfn[tj]
        if track is not None:
            track["attacks"][turn][idx] += 1
            track["attacked"][1 - turn][tj] += 1
            if turn == 0 and rows:
                if idx >= 4:
                    track["front_alive_at_back_attack"].append(sum(1 for f in IN_FRONT[idx] if att[f] and att[f][1] > 0))
                else:
                    track["back_alive_at_front_attack"].append(sum(1 for b in BEHIND[idx] if att[b] and att[b][1] > 0))
        ad, dd = a[0] + bonus(turn, idx), d[0] + bonus(1 - turn, tj)
        for unit, dmg in ((d, ad), (a, dd)):
            if dmg > 0:
                if unit[3]:
                    unit[3] = False
                else:
                    unit[1] -= dmg
        for side_i, unit, j in ((1 - turn, d, tj), (turn, a, idx)):
            if unit[1] <= 0 and len(unit) == 4:
                unit.append(True)          # mark dead once
                alive[side_i] -= 1
                if side_i == 0 and rows and j < 4:
                    if track is not None:
                        track["behind_alive_at_front_death"].append(sum(1 for b in BEHIND[j] if sides[0][b] and sides[0][b][1] > 0))
                    for b in BEHIND[j]:
                        g = fdg.get(b)
                        u = sides[0][b]
                        if g and u and u[1] > 0:
                            u[0] += g[0]
                            u[1] += g[1]
        turn = 1 - turn
    if track is not None:
        for s in (0, 1):
            for j in range(7):
                u = sides[s][j]
                if u and u[1] > 0:
                    track["survived"][s][j] += 1
    if alive[0] > 0 and alive[1] == 0:
        return 1.0
    if alive[1] > 0 and alive[0] == 0:
        return 0.0
    return 0.5


def tier_pairs(cards, tier):
    return [(c["attack"], c["health"]) for c in cards if c["tier"] == tier and c["attack"] > 0 and c["health"] > 0]


def random_board(rng, pairs, n=7):
    units = [[a, h, False, False] for a, h in (pairs[int(rng.random() * len(pairs))] for _ in range(n))]
    return units + [None] * (7 - n)


def place_sorted(units, mode):
    """Front = the 4 highest-Health units (mode 'tank_front') or the 4 lowest ('glass_front')."""
    us = sorted([u for u in units if u], key=lambda u: (u[1], -u[0]), reverse=(mode == "tank_front"))
    front, back = us[:4], us[4:]
    return front + back + [None] * (7 - len(front) - len(back))


def run_sim(current_cards, trials, seed=20261027):
    t0 = time.time()
    results, exposure, neighbours, placement, gaps, positional = [], [], {}, [], [], []
    mods = {"+2 attack": lambda u: u.__setitem__(0, u[0] + 2), "+2 health": lambda u: u.__setitem__(1, u[1] + 2),
            "divine shield": lambda u: u.__setitem__(3, True), "taunt": lambda u: u.__setitem__(2, True)}
    for tier in (2, 5):
        pairs = tier_pairs(current_cards, tier)
        for layout, rows in (("hsbg_7_wide", False), ("bramble_4_3", True)):
            base, boards = [], []
            track = {"attacks": [[0] * 7, [0] * 7], "attacked": [[0] * 7, [0] * 7], "survived": [[0] * 7, [0] * 7],
                     "front_alive_at_back_attack": [], "back_alive_at_front_attack": [], "behind_alive_at_front_death": []}
            for i in range(trials):
                rb = random.Random(seed * 7 + i)
                A, B = random_board(rb, pairs), random_board(rb, pairs)
                boards.append((A, B))
                base.append(combat(A, B, rows, random.Random(seed + i), track))
            for j in range(7):
                exposure.append({"tier": tier, "layout": layout, "slot": slot_name(j, rows),
                                 "attacks_made_per_fight": track["attacks"][0][j] / trials,
                                 "times_attacked_per_fight": track["attacked"][0][j] / trials,
                                 "survival_rate": track["survived"][0][j] / trials})
            if rows:
                neighbours[f"tier{tier}"] = {
                    "front_alive_when_back_unit_attacks": dist(track["front_alive_at_back_attack"]),
                    "back_alive_when_front_unit_attacks": dist(track["back_alive_at_front_attack"]),
                    "back_alive_when_front_unit_dies": dist(track["behind_alive_at_front_death"]),
                    "front_deaths_with_a_unit_behind_per_fight": sum(1 for x in track["behind_alive_at_front_death"] if x > 0) / trials,
                    "in_front_dies_triggers_per_fight_whole_back_row": sum(track["behind_alive_at_front_death"]) / trials,
                }
            mean_base = statistics.fmean(base)
            per_sp = []
            layout_rows = []
            for mname, mfn in mods.items():
                for j in range(7):
                    diffs = []
                    for i, (A, B) in enumerate(boards):
                        A2 = [u[:] if u else None for u in A]
                        mfn(A2[j])
                        diffs.append(combat(A2, B, rows, random.Random(seed + i)) - base[i])
                    m = statistics.fmean(diffs)
                    se = statistics.stdev(diffs) / math.sqrt(len(diffs))
                    r = {"tier": tier, "layout": layout, "slot": slot_name(j, rows), "modifier": mname,
                         "delta_win_rate": m, "se": se, "baseline_win_rate": mean_base}
                    layout_rows.append(r)
                    if mname in ("+2 attack", "+2 health"):
                        per_sp.append(m / 2)
            unit = statistics.fmean(per_sp)
            for r in layout_rows:
                pts = 2 if r["modifier"] in ("+2 attack", "+2 health") else 1
                r["win_rate_per_stat_point_layout_avg"] = unit
                r["stat_point_equivalent"] = r["delta_win_rate"] / unit if unit else ""
                r["sp_equiv_per_point"] = (r["delta_win_rate"] / unit) / pts if unit and pts == 2 else ""
            results.extend(layout_rows)
            # position-based effects, costed in stat-point equivalents of this layout
            tests = []
            if rows:
                for j in (4, 5, 6):
                    tests.append((slot_name(j, rows), "support aura: +2 Attack to the units in front of this",
                                  {"aura_atk": {j: (IN_FRONT[j], 2)}}, 2 * len(IN_FRONT[j])))
                    tests.append((slot_name(j, rows), "when a unit in front of this dies, gain +2/+2",
                                  {"front_death_gain": {j: (2, 2)}}, None))
                for j in range(4):
                    tests.append((slot_name(j, rows), "aura: +2 Attack to the units behind this",
                                  {"aura_atk": {j: (BEHIND[j], 2)}}, 2 * len(BEHIND[j])))
            else:
                for j in range(7):
                    adj = tuple(x for x in (j - 1, j + 1) if 0 <= x < 7)
                    tests.append((slot_name(j, rows), "adjacent aura: +2 Attack to neighbours (Dire Wolf style)",
                                  {"aura_atk": {j: (adj, 2)}}, 2 * len(adj)))
            for sname, label, fx, nominal in tests:
                diffs = [combat(A, B, rows, random.Random(seed + i), fx=fx) - base[i] for i, (A, B) in enumerate(boards)]
                m = statistics.fmean(diffs)
                spe = m / unit if unit else 0.0
                positional.append({"tier": tier, "layout": layout, "slot": sname, "effect": label,
                                   "delta_win_rate": m, "se": statistics.stdev(diffs) / math.sqrt(len(diffs)),
                                   "stat_point_equivalent": spe, "nominal_stat_points": nominal if nominal else "",
                                   "realisation": spe / nominal if nominal else ""})
            # placement decision value (rows only matter for Bramble, kept for both as a control)
            for mode in ("tank_front", "glass_front"):
                diffs = []
                for i, (A, B) in enumerate(boards):
                    diffs.append(combat(place_sorted(A, mode), B, rows, random.Random(seed + i)) - base[i])
                placement.append({"tier": tier, "layout": layout, "placement": mode + " vs random",
                                  "delta_win_rate": statistics.fmean(diffs),
                                  "se": statistics.stdev(diffs) / math.sqrt(len(diffs))})
            # empty-slot cost: remove the unit in slot j (6 units vs 7)
            if rows:
                for j in range(7):
                    diffs = []
                    for i, (A, B) in enumerate(boards):
                        A2 = [u[:] if u else None for u in A]
                        A2[j] = None
                        diffs.append(combat(A2, B, rows, random.Random(seed + i)) - base[i])
                    gaps.append({"tier": tier, "layout": layout, "empty_slot": slot_name(j, rows),
                                 "delta_win_rate": statistics.fmean(diffs),
                                 "se": statistics.stdev(diffs) / math.sqrt(len(diffs))})
    write_csv("sim_marginal_values.csv", results)
    write_csv("sim_slot_exposure.csv", exposure)
    write_csv("sim_placement.csv", placement)
    write_csv("sim_empty_slot.csv", gaps)
    write_csv("sim_positional_effects.csv", positional)
    write_json("sim_neighbours.json", {"trials": trials, "seed": seed, "neighbours": neighbours})
    return {"trials_per_cell": trials, "seconds": round(time.time() - t0, 1)}


def slot_name(j, rows):
    if not rows:
        return f"P{j + 1}"
    return f"F{j + 1}" if j < 4 else f"B{j - 3}"


def dist(vals):
    if not vals:
        return {}
    c = Counter(vals)
    n = len(vals)
    return {"mean": statistics.fmean(vals), **{f"p{k}": c[k] / n for k in sorted(c)}}


# ------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-sim", action="store_true", help="skip the combat simulation")
    ap.add_argument("--quick", action="store_true", help="small simulation (600 trials per cell)")
    ap.add_argument("--trials", type=int, default=6000, help="simulation trials per cell (default 6000)")
    args = ap.parse_args()

    minions = load("minions.json")
    meta = minions["meta"]
    cards = minions["cards"]
    current = [c for c in cards if c["in_current_pool"]]
    allhist = [c for c in cards if c["lineage_primary"]]
    samples = {"current": current, "all_history": allhist}
    feats = {c["dbfId"]: classify(c) for c in cards}

    print(f"minions: {len(cards)} rows, current {len(current)}, lineage-primary {len(allhist)}")
    tier_tables(samples)
    curve = stat_curve(samples)
    attack_share(samples)

    audit = []
    for c in sorted(current + [c for c in allhist if not c["in_current_pool"]], key=lambda c: (not c["in_current_pool"], c["tier"], c["name"])):
        f = feats[c["dbfId"]]
        audit.append({"name": c["name"], "tier": c["tier"], "attack": c["attack"], "health": c["health"],
                      "stats": stats_of(c), "in_current_pool": c["in_current_pool"], "tribes": c["tribes"],
                      "timing_class": timing_class(f), "features": [n for n in FEATURE_NAMES if f[n]], "text": c["text"]})
    write_csv("card_features.csv", audit)
    fc, models = feature_costs(samples, feats)
    complexity_tax(samples, feats)
    gold = golden(samples)
    spells, spell_agg = spells_gold_to_stats(load("spells.json")["cards"])

    med_cur = curve["current"]["tier_median"]
    med_all = curve["all_history"]["tier_median"]
    creep = creep_from_snapshots(med_cur)
    if creep is None:
        creep = {"status": "TODO: tools/research/.cache/slim not found; run build_bg_library.py to rebuild snapshots"}
    creep_cohorts(allhist, med_all)
    gal = galaxy()

    sim = {"status": "skipped"}
    if not args.no_sim:
        trials = 600 if args.quick else args.trials
        print(f"simulating ({trials} trials per cell)...")
        sim = run_sim(current, trials)

    feature_counts = Counter(timing_class(feats[c["dbfId"]]) for c in current)
    SUMMARY.update({
        "source": {"build": meta["latest_build"], "version": meta["latest_version"], "date": meta["latest_date"]},
        "counts": {"current": len(current), "all_history_lineages": len(allhist)},
        "curve": {k: {"linear_slope": v["linear"]["slope"], "linear_intercept": v["linear"]["intercept"],
                      "linear_r2": v["linear"]["r2"], "exp_growth_per_tier": v["exponential"]["growth_per_tier"],
                      "tier_median": v["tier_median"]} for k, v in curve.items()},
        "timing_classes_current": dict(feature_counts),
        "golden": {k: v["stat_kinds"] for k, v in gold.items()},
        "creep": creep,
        "galaxy": {k: v for k, v in gal.items() if k != "features"},
        "sim": sim,
        "battlegrounds_rules_doc": "present" if (REPO / "docs/research/battlegrounds/rules.md").exists() else "TODO: rules.md not written yet",
    })
    write_json("summary.json", SUMMARY)
    print(json.dumps(SUMMARY, indent=1, default=fmt)[:3000])
    print(f"wrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
