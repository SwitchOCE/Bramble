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
    python -I tools/research/power_budget.py --rows     # small rows run (v1 engine; a few minutes), prints only
    python -I tools/research/power_budget.py --rows --full   # rows study at the committed tables' sizes (~30 min
                                                              # on half the cores); the only run that writes rows_*.csv
    python -I tools/research/power_budget.py --rows --quick  # smoke test, prints only

The default, --quick and --no-sim runs cover analyses 1-10 only; the rows study (11)
runs only with --rows, and only --rows --full writes the rows_*.csv tables, so the
committed full-run tables are never overwritten by a smaller run.

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
 11. The rows study (docs/design/positioning-sim.md): a v1 combat engine that follows
     rulebook 8.x-9.x (summons, Deathrattles, Reborn, attack pointer, row targeting,
     Taunt within the attackable row, random effects ignoring rows), 11 prototype
     position cards, placement searches on matched boards, a one-row baseline on the
     same boards, and card pricing. Writes rows_*.csv.
     Tests: python -I tools/research/test_power_budget_sim.py
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


# ------------------------------------------------ rows study: combat engine v1
#
# A fuller (still toy) Bramble combat engine for the rows study, written up in
# docs/design/positioning-sim.md and tested by tools/research/test_power_budget_sim.py.
# Rules followed (rulebook.md):
#   8.2.1 in front of / behind     8.2.6 across from     8.4.1-8.4.6 summon placement
#   9.2.1 more units attacks first 9.3.2 Start of Combat, random side first, reading order
#   9.3.5 Start of Combat deaths resolve before the next Start of Combat effect
#   9.4.5 attack pointer and flags 9.4.8 summons below the pointer wait, at or above it don't
#   9.5.1 back-row protection      9.5.4 Taunt within the attackable row
#   9.5.6 random effects ignore rows and Taunt
#   9.6.1 "whenever this attacks" before damage; if attacker or defender is gone, no damage
#   9.6.3 deaths are checked after each damage event (each ping)
#   9.7.1-9.7.2 dying units leave their slots first; then "when ... dies" triggers,
#         Deathrattles, "after ... dies" triggers, Reborn; repeat for new deaths
#   9.7.3 active side's deaths first, reading order    9.8.2-9.8.3 Reborn
#   9.9 end of combat, 9.10.1 200-attack limit (tie)
# Not modelled: Windfury, Stealth, Venomous, Cleave, Avenge, hero powers, spells.
# The older `combat` above is kept unchanged so the v0 tables stay reproducible.
#
# Two geometries share the engine:
#   "rows" - Bramble's staggered 4-3 board.
#   "line" - a Battlegrounds-style baseline on the same 7 slots: one row, every enemy
#            can be attacked, "in front of / behind" become "adjacent" (left and right),
#            summons go to the nearest empty slot (a tie goes right). Placement on a line
#            board is packed: n units use slots 1..n (Battlegrounds has no gaps).

FRONT = (0, 1, 2, 3)
BACK = (4, 5, 6)
SLOT_X = (0.0, 1.0, 2.0, 3.0, 0.5, 1.5, 2.5)


def summon_order(src: int) -> tuple:
    """Rulebook 8.4.2: empty slots tried nearest first, same row first, a tie goes right."""
    same, other = (FRONT, BACK) if src < 4 else (BACK, FRONT)
    key = lambda j: (abs(SLOT_X[j] - SLOT_X[src]), -SLOT_X[j])
    return tuple(sorted((j for j in same if j != src), key=key)) + tuple(sorted(other, key=key))


def line_order(src: int) -> tuple:
    return tuple(sorted((j for j in range(7) if j != src), key=lambda j: (abs(j - src), -j)))


SUMMON_ORDER = {j: summon_order(j) for j in range(7)}
DEATH_ORDER = {j: (j,) + SUMMON_ORDER[j] for j in range(7)}   # 8.4.1: own slot first


def _geometry(rows: bool) -> dict:
    if rows:
        behind = {j: BEHIND.get(j, ()) for j in range(7)}
        infront = {j: IN_FRONT.get(j, ()) for j in range(7)}
        death = DEATH_ORDER
    else:
        nb = {j: tuple(k for k in (j - 1, j + 1) if 0 <= k < 7) for j in range(7)}
        behind, infront = nb, nb
        death = {j: (j,) + line_order(j) for j in range(7)}
    watch = {j: tuple(b for b in range(7) if j in infront[b]) for j in range(7)}
    return {"rows": rows, "behind": behind, "infront": infront, "watch": watch, "death": death}


GEOM = {"rows": _geometry(True), "line": _geometry(False)}


def card(name, atk, hp, tier=0, kind="plain", home=None, taunt=False, ds=False, reborn=False,
         dr=(), fx=None, text=""):
    """A card spec. dr: tuple of Deathrattles; fx: one position effect (kind, *params)."""
    return {"name": name, "atk": atk, "hp": hp, "tier": tier, "kind": kind, "home": home,
            "taunt": taunt, "ds": ds, "reborn": reborn, "dr": tuple(dr), "fx": fx, "text": text}


class Unit:
    __slots__ = ("c", "atk", "hp", "taunt", "ds", "reborn", "flag", "fxk", "uses")

    def __init__(self, c):
        self.c = c
        self.atk, self.hp = c["atk"], c["hp"]
        self.taunt, self.ds, self.reborn = c["taunt"], c["ds"], c["reborn"]
        self.flag = False
        fx = c["fx"]
        self.fxk = fx[0] if fx else None
        self.uses = fx[-1] if fx and fx[0] == "after_front_death_summon" else 0


class Fight:
    """One combat between boards A (side 0) and B (side 1): lists of 7 card specs or None.

    mode is "rows" (Bramble) or "line" (Battlegrounds-style baseline, see above).
    trace, if a list, receives ("soc_first", side), ("soc_hit", side, target_slot),
    ("attack", side, slot, target_slot), ("ping", side, target_slot), ("dies", side, slot)
    and ("summon", side, slot, name) events."""

    def __init__(self, A, B, rng, trace=None, mode="rows"):
        g = GEOM[mode]
        self.rows, self.behind, self.infront = g["rows"], g["behind"], g["infront"]
        self.watch, self.death = g["watch"], g["death"]
        self.rng = rng
        self.S = [[Unit(c) if c else None for c in A], [Unit(c) if c else None for c in B]]
        self.P = [-1, -1]
        self.trace = trace
        self.attacks = 0
        for s in (0, 1):
            self.recruit_buffs(s)

    def recruit_buffs(self, s):
        """Permanent buffs already earned in the Recruit Phase (9.1.1). A unit with
        ('eot_front_buff', atk, hp, turns) has given the units now in front of it
        `turns` End of Turn buffs. Approximation: the layout was the same on those turns."""
        row = self.S[s]
        for b in range(7):
            u = row[b]
            if u is not None and u.fxk == "eot_front_buff":
                _, da, dh, k = u.c["fx"]
                for j in self.infront[b]:
                    v = row[j]
                    if v is not None:
                        v.atk += k * da
                        v.hp += k * dh

    # -- helpers
    def eff_atk(self, s, j):
        row = self.S[s]
        a = row[j].atk
        for b in self.watch[j]:
            v = row[b]
            if v is not None and v.fxk == "aura_front_atk" and v.hp > 0:
                a += v.c["fx"][1]
        return a

    def can_attack(self, s):
        return [j for j in range(7) if self.S[s][j] is not None and self.eff_atk(s, j) > 0]

    def pick(self, s):
        """Rulebook 9.4.5 steps 1-3: lowest unflagged unit that can attack; reset the cycle if none."""
        can = self.can_attack(s)
        if not can:
            return None
        row = self.S[s]
        for j in can:
            if not row[j].flag:
                return j
        for u in row:
            if u is not None:
                u.flag = False
        self.P[s] = -1
        return can[0]

    def place(self, s, unit, order):
        for j in order:
            if self.S[s][j] is None:
                self.S[s][j] = unit
                unit.flag = j < self.P[s]          # 9.4.8
                if self.trace is not None:
                    self.trace.append(("summon", s, j, unit.c["name"]))
                return j
        return None                                 # 8.4.5 / 8.4.6: no room, the summon is lost

    @staticmethod
    def hit(u, dmg):
        if dmg <= 0:
            return
        if u.ds:
            u.ds = False
        else:
            u.hp -= dmg

    def ping(self, s, dmg):
        """Damage a random enemy of side s, from either row (9.5.6)."""
        d = self.S[1 - s]
        cand = [j for j in range(7) if d[j] is not None and d[j].hp > 0]
        if not cand:
            return
        tj = cand[int(self.rng.random() * len(cand))]
        if self.trace is not None:
            self.trace.append(("ping", s, tj))
        self.hit(d[tj], dmg)

    # -- phases
    def start_of_combat(self):
        first = 0 if self.rng.random() < 0.5 else 1
        if self.trace is not None:
            self.trace.append(("soc_first", first))
        for s in (first, 1 - first):
            row = self.S[s]
            for j in range(7):
                u = row[j]
                if u is None or u.fxk is None or u.hp <= 0:
                    continue
                fx, k = u.c["fx"], u.fxk
                if k == "soc_behind_atk":
                    for b in self.behind[j]:
                        if row[b] is not None:
                            row[b].atk += fx[1]
                elif k == "soc_lone":
                    if (not self.rows or j < 4) and all(row[b] is None for b in self.behind[j]):
                        u.atk += fx[1]
                        u.hp += fx[2]
                elif k == "soc_alone_front":
                    if self.rows and j < 4 and all(row[f] is None for f in FRONT if f != j):
                        u.atk += fx[1]
                        u.hp += fx[2]
                elif k == "soc_across":                    # 8.2.6: same slot label
                    t = self.S[1 - s][j]
                    if t is not None:
                        if self.trace is not None:
                            self.trace.append(("soc_hit", s, j))
                        self.hit(t, fx[1])
                        self.resolve_deaths(s)             # 9.3.5

    def attack(self, s, i):
        row, d = self.S[s], self.S[1 - s]
        self.P[s] = i
        for j in range(i + 1):
            if row[j] is not None:
                row[j].flag = True
        a = row[i]
        if self.rows:
            cand = [j for j in FRONT if d[j] is not None] or [j for j in BACK if d[j] is not None]
        else:
            cand = [j for j in range(7) if d[j] is not None]
        taunts = [j for j in cand if d[j].taunt]
        if taunts:
            cand = taunts
        tj = cand[int(self.rng.random() * len(cand))]
        t = d[tj]
        if self.trace is not None:
            self.trace.append(("attack", s, i, tj))
        # 9.6.1 step 2: "whenever this attacks" effects
        if a.fxk == "attack_buff_behind":
            for b in self.behind[i]:
                v = row[b]
                if v is not None:
                    v.atk += a.c["fx"][1]
                    v.hp += a.c["fx"][2]
        pinged = False
        for b in self.watch[i]:
            v = row[b]
            if v is not None and v.fxk == "front_attack_ping" and v.hp > 0:
                self.ping(s, v.c["fx"][1])
                self.resolve_deaths(s)                     # 9.6.3: after each damage event
                pinged = True
        if pinged and (row[i] is not a or d[tj] is not t):
            return                                         # 9.6.1: no damage exchange
        ad, td = self.eff_atk(s, i), self.eff_atk(1 - s, tj)
        self.hit(t, ad)
        self.hit(a, td)
        self.resolve_deaths(s)

    def resolve_deaths(self, active):
        S = self.S
        while True:
            dying = []
            for s in (active, 1 - active):             # 9.7.3: active side first, reading order
                row = S[s]
                for j in range(7):
                    u = row[j]
                    if u is not None and u.hp <= 0:
                        dying.append((s, j, u))
                        row[j] = None                  # 9.7.1: leave the slot first
            if not dying:
                return
            for s, j, u in dying:                      # step 1: "when ... dies"
                for b in self.watch[j]:
                    v = S[s][b]
                    if v is not None and v.fxk == "front_death_gain" and v.hp > 0:
                        v.atk += v.c["fx"][1]
                        v.hp += v.c["fx"][2]
            for s, j, u in dying:                      # step 2: Deathrattles
                if self.trace is not None:
                    self.trace.append(("dies", s, j))
                for eff in u.c["dr"]:
                    k = eff[0]
                    if k == "summon":
                        for _ in range(eff[1]):
                            self.place(s, Unit(eff[2]), self.death[j])
                    elif k == "ping":
                        self.ping(s, eff[1])
                    elif k == "buff_behind":
                        for b in self.behind[j]:
                            v = S[s][b]
                            if v is not None and v.hp > 0:
                                v.atk += eff[1]
                                v.hp += eff[2]
            for s, j, u in dying:                      # step 3: "after ... dies"
                for b in self.watch[j]:
                    v = S[s][b]
                    if (v is not None and v.fxk == "after_front_death_summon" and v.hp > 0
                            and v.uses > 0 and S[s][j] is None):
                        v.uses -= 1
                        self.place(s, Unit(v.c["fx"][1]), (j,))     # 8.4.6 named slot
            for s, j, u in dying:                      # step 4: Reborn
                if u.reborn:
                    nu = Unit(u.c)
                    nu.hp, nu.reborn = 1, False
                    self.place(s, nu, self.death[j])                 # 9.8.3

    def run(self):
        """Returns 1 / 0.5 / 0 for side A."""
        S = self.S
        n0 = sum(1 for u in S[0] if u is not None)
        n1 = sum(1 for u in S[1] if u is not None)
        turn = 0 if n0 > n1 else 1 if n1 > n0 else (0 if self.rng.random() < 0.5 else 1)
        self.start_of_combat()
        while self.attacks < 200:
            if not any(S[0]) or not any(S[1]):
                break
            i = self.pick(turn)
            if i is None:
                if not self.can_attack(1 - turn):
                    break
                turn = 1 - turn
                continue
            self.attack(turn, i)
            self.attacks += 1
            turn = 1 - turn
        a0, a1 = any(S[0]), any(S[1])
        return 1.0 if a0 and not a1 else 0.0 if a1 and not a0 else 0.5


def fight(A, B, seed, mode="rows"):
    return Fight(A, B, random.Random(seed), mode=mode).run()


# ------------------------------------------------ rows study: cards
#
# Prototype position cards for the owner to judge (written up in positioning-sim.md).
# Bodies priced with power-budget.md v0 before the run; the study then measures them.
# METHOD_TEXT is the v0 method's price for each card's text, in SP (body + text = price).

SPORE = card("Spore", 1, 1, kind="token")
SAPLING = card("Sapling", 2, 2, kind="token")

POSITION_CARDS = [
    card("Lantern Moth", 1, 3, 1, "position", "back", fx=("aura_front_atk", 1),
         text="The units in front of this have +1 Attack."),
    card("Drummer Hare", 2, 2, 2, "position", "front", fx=("attack_buff_behind", 1, 1),
         text="Whenever this attacks, give the units behind this +1/+1."),
    card("Martyr Hedgehog", 2, 3, 2, "position", "front", dr=(("buff_behind", 1, 1),),
         text="Deathrattle: Give the units behind this +1/+1."),
    card("Lone Stag", 2, 1, 2, "position", "front", fx=("soc_lone", 3, 3),
         text="Start of Combat: If this is in the front row with no unit behind it, gain +3/+3."),
    card("Hearthguard Badger", 3, 3, 3, "position", "front", fx=("soc_behind_atk", 2),
         text="Start of Combat: Give the units behind this +2 Attack."),
    card("Vigil Vole", 2, 3, 3, "position", "back", fx=("front_death_gain", 1, 1),
         text="When a unit in front of this dies, gain +1/+1."),
    card("Spotter Rook", 2, 5, 3, "position", "back", fx=("front_attack_ping", 1),
         text="Whenever a unit in front of this attacks, deal 1 damage to a random enemy."),
    card("Sapling Keeper", 1, 3, 4, "position", "back", fx=("after_front_death_summon", SAPLING, 2),
         text="After a unit in front of this dies, summon a 2/2 Sapling into its slot. (Twice per combat.)"),
    # added in revision 2: a Taunt/Divine Shield front (the fortress risk, rulebook 8.3.2),
    # Recruit Phase position text, and "across from" (8.2.6) reaching the enemy back row.
    card("Shellback Tortoise", 1, 3, 3, "position", "front", taunt=True, ds=True, fx=("soc_alone_front", 0, 3),
         text="Taunt. Divine Shield. Start of Combat: If this is your only front-row unit, gain +3 Health."),
    card("Nest Robin", 1, 2, 2, "position", "back", fx=("eot_front_buff", 0, 1, 2),
         text="End of Turn: Give the units in front of this +1 Health permanently."),
    card("Acorn Slinger", 2, 2, 2, "position", "back", fx=("soc_across", 3),
         text="Start of Combat: Deal 3 damage to the enemy unit across from this."),
]

SUMMON_CARDS = [
    card("Puffball Ooze", 2, 3, 3, "summon", dr=(("summon", 2, SPORE),),
         text="Deathrattle: Summon two 1/1 Spores."),
    card("Fern Hare", 3, 3, 3, "summon", reborn=True, text="Reborn."),
    card("Rot Toad", 3, 2, 3, "summon", dr=(("ping", 3),),
         text="Deathrattle: Deal 3 damage to a random enemy."),
]

# Revision 1 suggested these reprices (1 Health off each); revision 2 measures them.
REPRICES = [dict(c, name=f"{c['name']} {c['atk']}/{c['hp'] - 1}", hp=c["hp"] - 1)
            for c in POSITION_CARDS + SUMMON_CARDS
            if c["name"] in ("Lantern Moth", "Martyr Hedgehog", "Vigil Vole", "Fern Hare")]

METHOD_TEXT = {"Lantern Moth": 0.95, "Drummer Hare": 2.6, "Martyr Hedgehog": 2.5, "Lone Stag": 4.2,
               "Hearthguard Badger": 2.0, "Vigil Vole": 2.7, "Spotter Rook": 1.1, "Sapling Keeper": 6.25,
               "Shellback Tortoise": 3.6, "Nest Robin": 4.0, "Acorn Slinger": 2.4,
               "Puffball Ooze": 3.2, "Fern Hare": 1.6, "Rot Toad": 3.0}
# Owner's tolerance (2 Nov): +/-15% plain cards, +/-25% economy, scaling and engine cards.
# [judgement] Only Nest Robin (per-turn scaling) is put in the 25% group here.
TOLERANCE = {"Nest Robin": 25}

V_T = {1: 5, 2: 7, 3: 8, 4: 10, 5: 12, 6: 14}       # power-budget.md section 2


def vanilla(tier, extra=0):
    v = V_T[tier]
    a = int(0.45 * v + 0.5)
    return card(f"Vanilla T{tier}", a + extra, v - a + extra, tier)


def body_only(c):
    """The card's body with all text and keywords removed (the textless control)."""
    return dict(c, name=c["name"] + " (body)", fx=None, dr=(), reborn=False, taunt=False, ds=False,
                kind="body", text="")


def golden_card(c):
    """Rulebook golden rule: 2x body, 2x effect sizes, thresholds and counts unchanged."""
    g = dict(c)
    g["name"] = "Golden " + c["name"]
    g["atk"], g["hp"] = 2 * c["atk"], 2 * c["hp"]
    fx = c["fx"]
    if fx:
        k = fx[0]
        if k == "after_front_death_summon":
            g["fx"] = (k, golden_card(fx[1]), fx[2])
        elif k == "eot_front_buff":
            g["fx"] = (k, 2 * fx[1], 2 * fx[2], fx[3])
        else:
            g["fx"] = (k,) + tuple(2 * x for x in fx[1:])
    dr = []
    for e in c["dr"]:
        if e[0] == "summon":
            dr.append(("summon", e[1], golden_card(e[2])))
        else:
            dr.append((e[0],) + tuple(2 * x for x in e[1:]))
    g["dr"] = tuple(dr)
    return g


# ------------------------------------------------ rows study: placement
#
# A placement is a tuple of 7 entries: the index of the unit in that slot, or -1.

def board_of(units, pl):
    return [units[k] if k >= 0 else None for k in pl]


def random_placement(rng, n, allowed=None):
    slots = rng.sample(tuple(allowed) if allowed is not None else range(7), n)
    pl = [-1] * 7
    for k, j in enumerate(slots):
        pl[j] = k
    return tuple(pl)


def naive_placement(rng, n):
    """Front first, in reading order, units in random order: a player who ignores the rows."""
    order = list(range(n))
    rng.shuffle(order)
    return tuple(order + [-1] * (7 - n))


def _fxk(u):
    return u["fx"][0] if u["fx"] else None


def heuristic_placement(units, rest="attack", version=2, reserved=()):
    """A written rule of thumb a player could follow without thinking about the opponent.

    Both versions: back-row cards in B2, B1, B3; front position cards in F2, F3, F1, F4
    (two units behind); Lone Stag in F1 with B1 left empty; other units by highest Attack
    (rest="attack") or highest Health (rest="health", the v0 'tank_front' idea).
    version=1 ("front first"): the other units fill F1-F4, then B2, B1, B3.
    version=2 ("at most 3 in front"): on boards of 6 units or fewer, at most 3 units go in
    front; the rest go in the back, first behind your front position cards.
    reserved: slots the rule must leave empty (used when a measured card sits there)."""
    pl = [-1] * 7
    n = len(units)
    reserved = set(reserved)
    idx = range(n)
    lone = [k for k in idx if _fxk(units[k]) == "soc_lone"]
    back = [k for k in idx if units[k]["home"] == "back"]
    front = [k for k in idx if units[k]["home"] == "front" and k not in lone]
    key = (lambda k: (-units[k]["atk"], -units[k]["hp"])) if rest == "attack" else \
        (lambda k: (-units[k]["hp"], -units[k]["atk"]))
    others = sorted((k for k in idx if k not in lone and k not in back and k not in front), key=key)

    def free(order):
        return [j for j in order if pl[j] < 0 and j not in reserved]

    def anywhere():
        return free(range(7)) or [j for j in range(7) if pl[j] < 0]

    for k in lone:
        f = free((0, 3))
        if f:
            pl[f[0]] = k
            reserved.add(4 if f[0] == 0 else 6)
        else:
            front.append(k)
    for k in back:
        f = free((5, 4, 6))
        if f:
            pl[f[0]] = k
        else:
            front.append(k)
    for k in front:
        f = free((1, 2, 0, 3, 5, 4, 6)) or anywhere()
        pl[f[0]] = k
    if version == 1:
        for k in others:
            f = free((0, 1, 2, 3, 5, 4, 6)) or anywhere()
            pl[f[0]] = k
        return tuple(pl)
    cap = 4 if n >= 7 else min(3, n)

    def back_pref():
        score = {b: sum(1 for f in FRONT if pl[f] >= 0 and units[pl[f]]["home"] == "front" and b in BEHIND[f])
                 for b in BACK}
        return sorted(BACK, key=lambda b: (-score[b], (5, 4, 6).index(b)))
    for k in others:
        nfront = sum(1 for j in FRONT if pl[j] >= 0)
        f = free(FRONT) if nfront < cap else []
        f = f or free(back_pref()) or free(FRONT) or anywhere()
        pl[f[0]] = k
    return tuple(pl)


def heuristic_line(units):
    """Rule of thumb for the one-row baseline (packed, slots 1..n). Attack-triggered
    adjacency cards (Drummer Hare, Spotter Rook) early with two neighbours (slots 2-4);
    other position cards late with two neighbours (slots n-1, n-2, n-3, then n); other
    units fill the rest left to right, highest Attack first. Picked after seeing where the
    one-row search puts the cards, as the rows rule was [judgement]."""
    n = len(units)
    pl = [-1] * 7
    early = [k for k in range(n) if units[k]["kind"] == "position"
             and _fxk(units[k]) in ("attack_buff_behind", "front_attack_ping")]
    late = [k for k in range(n) if units[k]["kind"] == "position" and k not in early]
    others = sorted((k for k in range(n) if units[k]["kind"] != "position"),
                    key=lambda k: (-units[k]["atk"], -units[k]["hp"]))

    def put(k, order):
        f = [j for j in order if 0 <= j < n and pl[j] < 0] or [j for j in range(n) if pl[j] < 0]
        pl[f[0]] = k
    for k in early:
        put(k, (1, 2, 3))
    for k in late:
        put(k, (n - 2, n - 3, n - 4, n - 1))
    for k in others:
        put(k, range(n))
    return tuple(pl)


def win_rate(units, pl, opps, seeds, mode="rows"):
    A = board_of(units, pl)
    return statistics.fmean(fight(A, B, s, mode) for B, s in zip(opps, seeds))


def canon(units, pl):
    """Placement key that treats units with the same card and stats as identical."""
    return tuple((units[k]["name"], units[k]["atk"], units[k]["hp"]) if k >= 0 else None for k in pl)


def climb(units, start, opps, seeds, mode="rows", allowed=None, max_iter=8):
    """Steepest-ascent hill climb over swaps of two slots (a swap with an empty slot is a move).
    A noisy local search scored on a finite opponent sample: not a proven optimum."""
    allowed = tuple(allowed) if allowed is not None else tuple(range(7))
    cur, cur_v = start, win_rate(units, start, opps, seeds, mode)
    seen = {canon(units, cur): cur_v}
    for _ in range(max_iter):
        best, best_v = None, cur_v
        for ai, a in enumerate(allowed):
            for b in allowed[ai + 1:]:
                if cur[a] == cur[b] == -1:
                    continue
                nxt = list(cur)
                nxt[a], nxt[b] = nxt[b], nxt[a]
                nxt = tuple(nxt)
                key = canon(units, nxt)
                if key == canon(units, cur):
                    continue
                v = seen.get(key)
                if v is None:
                    v = seen[key] = win_rate(units, nxt, opps, seeds, mode)
                if v > best_v + 1e-9:
                    best, best_v = nxt, v
        if best is None:
            break
        cur, cur_v = best, best_v
    return cur, cur_v


# ------------------------------------------------ rows study: experiments

CONDITIONS = ("plain", "summons", "position", "position+summons")


def make_units(rng, pairs, n, cond, gold=False):
    """Matched boards: one draw of 7 plain units, 3 position cards and 2 summon cards, then
    each condition swaps cards in for the first plain units, so conditions share everything else.
    position-body: the two position cards' bodies and homes with their text removed."""
    plain = [card("Plain", *pairs[int(rng.random() * len(pairs))], kind="plain") for _ in range(7)]
    pos = rng.sample(POSITION_CARDS, 3)
    summ = rng.sample(SUMMON_CARDS, 2)
    if gold:
        pos, summ = [golden_card(c) for c in pos], [golden_card(c) for c in summ]
    swap = {"plain": [], "summons": summ, "position": pos[:2], "position+summons": pos[:2] + summ[:1],
            "position-body": [body_only(c) for c in pos[:2]], "position3": pos}[cond]
    units = swap + plain[len(swap):]
    return units[:n]


def rule_for(mode):
    return heuristic_line if mode == "line" else heuristic_placement


def allowed_for(mode, n):
    return tuple(range(n)) if mode == "line" else tuple(range(7))


def opponent_pool(pairs, n, cond, gold, count, seed, mode="rows"):
    """Same condition as the board; half placed by the fair rule of thumb, half at random."""
    rng = random.Random(seed)
    out = []
    for _ in range(count):
        us = make_units(rng, pairs, n, cond, gold)
        pl = rule_for(mode)(us) if rng.random() < 0.5 else random_placement(rng, n, allowed_for(mode, n))
        out.append(board_of(us, pl))
    return out


def field_pool(pairs, n, gold, count, seed, mode="rows"):
    """The common rule field: one opponent pool per (band, size, geometry), conditions mixed,
    every board placed by the rule of thumb. Win rates against it are comparable across conditions."""
    rng = random.Random(seed)
    out = []
    for _ in range(count):
        cond = CONDITIONS[int(rng.random() * 4)]
        us = make_units(rng, pairs, n, cond, gold)
        out.append(board_of(us, rule_for(mode)(us)))
    return out


_POOLS: dict = {}


def _cell_pools(cell):
    if cell not in _POOLS:
        band, cond, n, gold, mode, cs, pairs, sizes = cell
        _POOLS[cell] = (opponent_pool(pairs, n, cond, gold, sizes[0], cs + 1, mode),
                        opponent_pool(pairs, n, cond, gold, sizes[1], cs + 2, mode),
                        opponent_pool(pairs, n, cond, gold, sizes[2], cs + 3, mode),
                        field_pool(pairs, n, gold, sizes[3], cs + 4, mode))
    return _POOLS[cell]


def _split_cov(xs, ys):
    mx, my = statistics.fmean(xs), statistics.fmean(ys)
    return sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / (len(xs) - 1)


def _label(u):
    return u["name"] if u["kind"] != "plain" else f"{u['atk']}/{u['hp']}"


def placement_job(job):
    """One matched board in one cell: random, naive, rule-of-thumb and searched placements."""
    cell, b, k_random, starts = job
    band, cond, n, gold, mode, cs, pairs, sizes = cell
    train, test, ends_pool, field = _cell_pools(cell)
    allowed = allowed_for(mode, n)
    rng = random.Random(cs * 1009 + b)
    units = make_units(rng, pairs, n, cond, gold)

    def seeds(off, k):
        return [cs * 7 + off + i for i in range(k)]
    tr_s, te_s, en_s, fi_s = seeds(100000, len(train)), seeds(200000, len(test)), seeds(300000, len(ends_pool)), \
        seeds(400000, len(field))

    def wr(pl, opps, ss):
        return win_rate(units, pl, opps, ss, mode)
    # random placements: test win rate, split-half on training opponents, +1/+1 slope
    half = len(train) // 2
    r_test, h1, h2, slope, r_pls = [], [], [], [], []
    for _ in range(k_random):
        pl = random_placement(rng, n, allowed)
        r_pls.append(pl)
        r_test.append(wr(pl, test, te_s))
        A = board_of(units, pl)
        res = [fight(A, B, s, mode) for B, s in zip(train, tr_s)]
        h1.append(statistics.fmean(res[:half]))
        h2.append(statistics.fmean(res[half:]))
        k = int(rng.random() * n)
        up = list(units)
        up[k] = dict(units[k], atk=units[k]["atk"] + 1, hp=units[k]["hp"] + 1)
        slope.append((win_rate(up, pl, test, te_s, mode) - r_test[-1]) / 2)
    rule = rule_for(mode)(units)
    rule1 = heuristic_placement(units, version=1) if mode == "rows" else rule
    fixed = [rule] + ([rule1] if mode == "rows" else [])
    starts_pl = fixed + [random_placement(rng, n, allowed) for _ in range(starts - len(fixed))]
    ends = [climb(units, s, train, tr_s, mode, allowed) for s in starts_pl]
    smart = max(ends, key=lambda e: e[1])[0]
    # re-score the climb ends on a large separate pool (variety measure)
    res_e, cache = [], {}
    for e in ends:
        key = canon(units, e[0])
        if key not in cache:
            A = board_of(units, e[0])
            cache[key] = [fight(A, B, s, mode) for B, s in zip(ends_pool, en_s)]
        res_e.append(cache[key])
    big = [statistics.fmean(r) for r in res_e]
    sig, max_d = False, 0.0
    for x in range(len(res_e)):
        for y in range(x + 1, len(res_e)):
            d = [p - q for p, q in zip(res_e[x], res_e[y])]
            m = statistics.fmean(d)
            se = statistics.stdev(d) / math.sqrt(len(d)) if any(d) else 0.0
            max_d = max(max_d, abs(m))
            if se > 0 and abs(m) > 2 * se:
                sig = True
    keys = set(cache)
    splits = {tuple(sorted(_label(units[k]) + str(units[k]["atk"]) + "/" + str(units[k]["hp"])
                           for k in e[0][:4] if k >= 0)) for e in ends}
    naive = statistics.fmean(wr(naive_placement(rng, n), test, te_s) for _ in range(3)) \
        if (n < 7 and mode == "rows") else ""
    row = {"band": band, "geometry": mode, "condition": cond, "units": n, "board": b,
           "wr_random": statistics.fmean(r_test), "wr_naive": naive,
           "wr_rule": wr(rule, test, te_s), "wr_rule_v1": wr(rule1, test, te_s),
           "wr_rule_tank": wr(heuristic_placement(units, "health", version=1), test, te_s) if mode == "rows" else "",
           "wr_smart": wr(smart, test, te_s), "train_smart": max(e[1] for e in ends),
           "wr_climb_ends_big_pool": [round(x, 4) for x in big], "climb_ends_max_diff": max_d,
           "climb_ends_differ_significantly": sig,
           "split_half_cov": _split_cov(h1, h2), "sp_slope": statistics.fmean(slope),
           "distinct_climb_ends": len(keys), "distinct_front_sets": len(splits),
           "smart_equals_rule": canon(units, smart) == canon(units, rule),
           "smart_front_units": sum(1 for j in FRONT if smart[j] >= 0) if mode == "rows" else "",
           "field_random": statistics.fmean(wr(pl, field, fi_s) for pl in r_pls[:3]),
           "field_rule": wr(rule, field, fi_s), "field_rule_v1": wr(rule1, field, fi_s),
           "field_smart": wr(smart, field, fi_s),
           "board_units": ";".join(_label(u) for u in units),
           "smart_layout": ";".join(slot_name(j, mode == "rows") + "=" + _label(units[k])
                                    for j, k in enumerate(smart) if k >= 0)}
    pos_slots = []
    if mode == "rows":
        for j, k in enumerate(smart):
            if k >= 0 and units[k]["kind"] == "position":
                pos_slots.append((units[k]["name"].replace("Golden ", ""), slot_name(j, True),
                                  _gap_note(units, smart, j)))
    row["position_card_slots"] = pos_slots
    return row


def _gap_note(units, pl, j):
    if j < 4:
        behind = [b for b in BEHIND[j] if pl[b] >= 0]
        return f"{len(behind)} behind"
    return f"{sum(1 for f in IN_FRONT[j] if pl[f] >= 0)} in front"


def fit_layout(c, others, j):
    """Small boards: the other units placed to suit the card in slot j. Behind-text cards get
    their units behind them; Shellback Tortoise gets the others behind it (the fortress);
    in-front-text cards get their front slots filled; Lone Stag keeps its slot behind empty."""
    k = _fxk(c) or (c["dr"][0][0] if c["dr"] else None)
    first, skip = (), set()
    if k == "soc_alone_front":
        first = (4, 5, 6) if j < 4 else ()
    elif k == "soc_lone":
        skip = set(BEHIND.get(j, ()))
    elif c["home"] == "front":
        first = BEHIND.get(j, ())
    elif c["home"] == "back":
        first = IN_FRONT.get(j, ())
    order = [s for s in tuple(first) + (0, 1, 2, 3, 5, 4, 6) if s != j and s not in skip]
    order = list(dict.fromkeys(order)) + [s for s in skip if s != j]
    pl = [-1] * 7
    for k_, s in zip(sorted(range(len(others)), key=lambda q: (-others[q]["atk"], -others[q]["hp"])), order):
        pl[s] = k_
    return tuple(pl)


def card_value_job(job):
    """One card in one slot: the card, its textless body and a vanilla unit of its tier in the
    same slot, plus a vanilla +1/+1 against a vanilla for the SP slope. Paired fights.
    n=7: full board; n=6: one gap; n<=4: a small early board of the card's own tier, with
    the other units placed by the rule of thumb (layout "rule") or to suit the card ("fit")."""
    (c, n, j, gap, pairs, trials, seed, layout) = job
    tier = c["tier"]
    small = n <= 4
    ref = vanilla(tier)
    lo, hi = (vanilla(tier), vanilla(tier, 1)) if small else (vanilla(3), vanilla(3, 1))
    body = body_only(c)
    rng = random.Random(seed)
    d_card, d_body, d_text, d_slope = [], [], [], []
    for i in range(trials):
        if small:
            others = [card("Plain", *pairs[int(rng.random() * len(pairs))]) for _ in range(n - 1)]
            pl = fit_layout(c, others, j) if layout == "fit" else heuristic_placement(others, reserved={j})
            A = board_of(others, pl)
            ous = [card("Plain", *pairs[int(rng.random() * len(pairs))]) for _ in range(n)]
            B = board_of(ous, heuristic_placement(ous) if rng.random() < 0.5 else random_placement(rng, n))
        else:
            slots = [k for k in range(7) if k != j and k != gap]
            rest = [card("Plain", *pairs[int(rng.random() * len(pairs))]) for _ in slots]
            rng.shuffle(rest)
            A = [None] * 7
            for k, u in zip(slots, rest):
                A[k] = u
            ous = make_units(rng, pairs, 7, "plain")
            B = board_of(ous, heuristic_placement(ous) if rng.random() < 0.5 else random_placement(rng, 7))
        s = seed * 13 + i
        res = []
        for u in (c, body, ref, hi, lo):
            A[j] = u
            res.append(fight(A, B, s))
        d_card.append(res[0] - res[2])
        d_body.append(res[1] - res[2])
        d_text.append(res[0] - res[1])
        d_slope.append((res[3] - res[4]) / 2)
    return {"card": c["name"], "tier": tier, "units": n, "slot": slot_name(j, True),
            "empty_slot": slot_name(gap, True) if gap is not None else "", "layout": layout,
            "delta_vs_vanilla": statistics.fmean(d_card), "se": statistics.stdev(d_card) / math.sqrt(trials),
            "body_delta_vs_vanilla": statistics.fmean(d_body), "text_delta": statistics.fmean(d_text),
            "se_text": statistics.stdev(d_text) / math.sqrt(trials), "slope_per_sp": statistics.fmean(d_slope)}


def engine_check(pairs, trials, seed):
    """v0 `combat` against v1 `Fight` on the same vanilla 6-vs-7 boards (separate dice)."""
    out = []
    for mode, rows in (("rows", True), ("line", False)):
        d, w0, w1 = [], [], []
        for i in range(trials):
            rb = random.Random(seed * 7 + i)
            A, B = random_board(rb, pairs, 6), random_board(rb, pairs, 7)
            conv = lambda X: [card("Plain", u[0], u[1]) if u else None for u in X]
            r0 = combat(A, B, rows, random.Random(seed + i))
            r1 = fight(conv(A), conv(B), seed + 10 ** 6 + i, mode)
            w0.append(r0)
            w1.append(r1)
            d.append(r1 - r0)
        out.append({"geometry": mode, "boards": trials, "tier": 3, "v0_win_rate": statistics.fmean(w0),
                    "v1_win_rate": statistics.fmean(w1), "difference": statistics.fmean(d),
                    "se_difference": statistics.stdev(d) / math.sqrt(trials)})
    return out


# The sizes the committed rows_*.csv tables were made with (about 16 minutes on 24 cores).
# The defaults below are roughly a tenth of the work, with wider error bars.
ROWS_FULL = {"boards": 150, "train": 160, "test": 500, "ends_pool": 2000, "field": 400, "k_random": 10,
             "card_trials": 1500, "small_trials": 800}


def run_rows_study(current_cards, boards=40, train=80, test=250, ends_pool=600, field=200, k_random=6,
                   starts=3, card_trials=400, small_trials=250, workers=None, seed=20261102, write=True):
    """The rows study (task S2). Writes rows_*.csv to the analysis folder when write is True."""
    from concurrent.futures import ProcessPoolExecutor
    t0 = time.time()
    pairs = {t: tier_pairs(current_cards, t) for t in (1, 2, 3, 4, 5)}
    sizes = (train, test, ends_pool, field)
    spec = [("T3", "rows", n, False, c) for n, cs_ in ((7, CONDITIONS + ("position-body", "position3")),
                                                       (5, CONDITIONS + ("position-body",))) for c in cs_]
    spec += [("T5 golden", "rows", 7, True, c) for c in CONDITIONS]
    spec += [("T3", "line", n, False, c) for n in (7, 5) for c in CONDITIONS]
    cells, jobs = [], []
    for band, mode, n, gold, cond in spec:
        cs = seed + 1000 * (n + (50 if gold else 0))          # same boards across conditions and geometries
        cell = (band, cond, n, gold, mode, cs, tuple(pairs[5 if gold else 3]), sizes)
        cells.append(cell)
        jobs += [(cell, b, k_random, starts) for b in range(boards)]
    cjobs = []
    for ci, c in enumerate(POSITION_CARDS + SUMMON_CARDS + REPRICES):
        for j in range(7):
            cjobs.append((c, 7, j, None, pairs[3], card_trials, seed + 31 * ci + j, ""))
            for n in (3, 4):
                for lay in ("rule", "fit"):
                    cjobs.append((c, n, j, None, pairs[c["tier"]], small_trials,
                                  seed + 31 * ci + j + 100 * n + 9000, lay))
            if c in REPRICES:
                continue
            for g in range(7):
                if g != j:
                    cjobs.append((c, 6, j, g, pairs[3], card_trials // 2, seed + 31 * ci + 7 * j + g + 5000, ""))
    if workers is None:                                       # owner's rule: use at most half the CPU
        workers = max(1, (os.cpu_count() or 2) // 2)
    with ProcessPoolExecutor(max_workers=workers) as ex:
        crows = list(ex.map(card_value_job, cjobs, chunksize=2))
        rows = list(ex.map(placement_job, jobs, chunksize=2))
    check = engine_check(pairs[3], 6000, seed + 77)
    out = {}
    # ---- placement summary
    summ, slots = [], []
    for band, cond, n, gold, mode, *_ in cells:
        rs = [r for r in rows if r["band"] == band and r["condition"] == cond and r["units"] == n
              and r["geometry"] == mode]
        sp = statistics.fmean(r["sp_slope"] for r in rs)

        def gain(a, b):
            d = [r[a] - r[b] for r in rs]
            return statistics.fmean(d), statistics.stdev(d) / math.sqrt(len(d))
        g_sr, se_sr = gain("wr_smart", "wr_random")
        g_hr, se_hr = gain("wr_rule", "wr_random")
        g_sh, se_sh = gain("wr_smart", "wr_rule")
        g_sh1, _ = gain("wr_smart", "wr_rule_v1")
        g_fs, se_fs = gain("field_smart", "field_random")
        g_fh, _ = gain("field_smart", "field_rule")
        cov = statistics.fmean(r["split_half_cov"] for r in rs)
        row = {"band": band, "geometry": mode, "condition": cond, "units": n, "boards": len(rs),
               "wr_random": statistics.fmean(r["wr_random"] for r in rs),
               "wr_rule_v1": statistics.fmean(r["wr_rule_v1"] for r in rs),
               "wr_rule": statistics.fmean(r["wr_rule"] for r in rs),
               "wr_smart": statistics.fmean(r["wr_smart"] for r in rs),
               "train_minus_test_smart_pp": 100 * statistics.fmean(r["train_smart"] - r["wr_smart"] for r in rs),
               "smart_minus_random_pp": 100 * g_sr, "se_pp": 100 * se_sr,
               "rule_minus_random_pp": 100 * g_hr, "se_pp_rule": 100 * se_hr,
               "smart_minus_rule_pp": 100 * g_sh, "se_pp_sr": 100 * se_sh,
               "smart_minus_rule_v1_pp": 100 * g_sh1,
               "rule_share_of_gain": g_hr / g_sr if g_sr > 0.005 else "",
               "win_rate_per_sp_pp": 100 * sp,
               "smart_minus_random_sp": g_sr / sp if sp else "",
               "rule_minus_random_sp": g_hr / sp if sp else "",
               "smart_minus_rule_sp": g_sh / sp if sp else "",
               "share_rule_ties_or_beats_smart": sum(1 for r in rs if r["wr_rule"] >= r["wr_smart"]) / len(rs),
               "share_smart_beats_rule_by_5pp": sum(1 for r in rs if r["wr_smart"] - r["wr_rule"] > 0.05) / len(rs),
               "true_sd_across_random_placements_pp": 100 * math.sqrt(max(0.0, cov)),
               "share_boards_climbs_agree_exactly": sum(1 for r in rs if r["distinct_climb_ends"] == 1) / len(rs),
               "share_boards_climbs_agree_on_front_set": sum(1 for r in rs if r["distinct_front_sets"] == 1) / len(rs),
               "mean_max_diff_climb_ends_big_pool_pp": 100 * statistics.fmean(r["climb_ends_max_diff"] for r in rs),
               "share_boards_climb_ends_differ_significantly":
                   sum(1 for r in rs if r["climb_ends_differ_significantly"]) / len(rs),
               "share_smart_equals_rule": sum(1 for r in rs if r["smart_equals_rule"]) / len(rs),
               "field_random": statistics.fmean(r["field_random"] for r in rs),
               "field_rule_v1": statistics.fmean(r["field_rule_v1"] for r in rs),
               "field_rule": statistics.fmean(r["field_rule"] for r in rs),
               "field_smart": statistics.fmean(r["field_smart"] for r in rs),
               "field_smart_minus_random_pp": 100 * g_fs, "field_se_pp": 100 * se_fs,
               "field_smart_minus_rule_pp": 100 * g_fh}
        if mode == "rows":
            fc = Counter(r["smart_front_units"] for r in rs)
            for k in (1, 2, 3, 4):
                row[f"smart_front_{k}"] = fc[k] / len(rs)
            if n < 7:
                row["naive_minus_random_pp"] = 100 * gain("wr_naive", "wr_random")[0]
        summ.append(row)
        cnt = defaultdict(Counter)
        for r in rs:
            for name, sl, note in r["position_card_slots"]:
                cnt[name][(sl, note)] += 1
        for name in sorted(cnt):
            tot = sum(cnt[name].values())
            for (sl, note), k in cnt[name].most_common():
                slots.append({"band": band, "condition": cond, "units": n, "card": name, "smart_slot": sl,
                              "neighbours": note, "boards": k, "share": k / tot})
    # ---- rows against the one-row baseline, matched boards
    vs = []
    for r in summ:
        if r["geometry"] != "rows":
            continue
        ln = next((x for x in summ if x["geometry"] == "line" and x["band"] == r["band"]
                   and x["condition"] == r["condition"] and x["units"] == r["units"]), None)
        if ln is None:
            continue
        vs.append({"band": r["band"], "condition": r["condition"], "units": r["units"],
                   "rows_smart_minus_random_sp": r["smart_minus_random_sp"],
                   "line_smart_minus_random_sp": ln["smart_minus_random_sp"],
                   "rows_extra_placement_value_sp": r["smart_minus_random_sp"] - ln["smart_minus_random_sp"],
                   "rows_best_minus_random_sp": max(r["smart_minus_random_sp"], r["rule_minus_random_sp"]),
                   "line_best_minus_random_sp": max(ln["smart_minus_random_sp"], ln["rule_minus_random_sp"]),
                   "rows_smart_minus_rule_sp": r["smart_minus_rule_sp"],
                   "line_smart_minus_rule_sp": ln["smart_minus_rule_sp"],
                   "rows_true_sd_pp": r["true_sd_across_random_placements_pp"],
                   "line_true_sd_pp": ln["true_sd_across_random_placements_pp"],
                   "rows_smart_minus_random_pp": r["smart_minus_random_pp"],
                   "line_smart_minus_random_pp": ln["smart_minus_random_pp"],
                   "rows_pp_per_sp": r["win_rate_per_sp_pp"], "line_pp_per_sp": ln["win_rate_per_sp_pp"]})
    # ---- card value summary
    slope = {}
    for r in crows:
        slope.setdefault((r["units"], r["tier"] if r["units"] <= 4 else 0), []).append(r["slope_per_sp"])
    slope = {k: statistics.fmean(v) for k, v in slope.items()}
    for r in crows:
        sl = slope[(r["units"], r["tier"] if r["units"] <= 4 else 0)]
        v = V_T[r["tier"]]
        r["sp_equivalent"] = v + r["delta_vs_vanilla"] / sl
        r["body_sp"] = v + r["body_delta_vs_vanilla"] / sl
        r["text_sp"] = r["text_delta"] / sl
    csum = []
    for c in POSITION_CARDS + SUMMON_CARDS + REPRICES:
        base = c["name"].split(" ")[0] + " " + c["name"].split(" ")[1] if c in REPRICES else c["name"]
        v = V_T[c["tier"]]
        by = {n: [r for r in crows if r["card"] == c["name"] and r["units"] == n] for n in (7, 6, 4, 3)}
        r7 = by[7]
        best7, worst7 = max(r7, key=lambda r: r["sp_equivalent"]), min(r7, key=lambda r: r["sp_equivalent"])
        mean7 = statistics.fmean(r["sp_equivalent"] for r in r7)
        tol = TOLERANCE.get(base, 15)
        row = {"card": c["name"], "tier": c["tier"], "kind": c["kind"], "home": c["home"] or "",
               "body": f"{c['atk']}/{c['hp']}", "V_t": v, "text": c["text"],
               "method_text_sp": METHOD_TEXT.get(base, ""),
               "method_price_sp": c["atk"] + c["hp"] + METHOD_TEXT.get(base, 0),
               "tolerance_pct": tol,
               "sp_full_best": best7["sp_equivalent"], "best_slot_full": best7["slot"],
               "body_sp_at_best": best7["body_sp"], "text_sp_at_best": best7["text_sp"],
               "text_sp_mean_over_slots": statistics.fmean(r["text_sp"] for r in r7),
               "sp_full_mean": mean7, "sp_full_worst": worst7["sp_equivalent"], "worst_slot_full": worst7["slot"],
               "slot_gap_sp_full": best7["sp_equivalent"] - worst7["sp_equivalent"],
               "error_full_best_pct": 100 * (best7["sp_equivalent"] / v - 1),
               "error_full_mean_pct": 100 * (mean7 / v - 1),
               "within_tolerance_best": abs(best7["sp_equivalent"] / v - 1) * 100 <= tol,
               "se_sp": statistics.fmean(r["se"] for r in r7) / slope[(7, 0)]}
        if by[6]:
            best6 = max(by[6], key=lambda r: r["sp_equivalent"])
            row.update({"sp_6_best": best6["sp_equivalent"], "best_6": best6["slot"] + " gap " + best6["empty_slot"],
                        "error_6_best_pct": 100 * (best6["sp_equivalent"] / v - 1)})
        for n in (4, 3):
            bn = max(by[n], key=lambda r: r["sp_equivalent"])
            row.update({f"sp_{n}_best": bn["sp_equivalent"], f"best_{n}": bn["slot"] + " " + bn["layout"],
                        f"text_sp_{n}_best": bn["text_sp"],
                        f"error_{n}_best_pct": 100 * (bn["sp_equivalent"] / v - 1)})
        csum.append(row)
    meta = {"boards_per_cell": boards, "train_opponents": train, "test_opponents": test,
            "climb_end_rescore_opponents": ends_pool, "rule_field_opponents": field,
            "random_placements": k_random, "climb_starts": starts, "card_trials": card_trials,
            "small_board_trials": small_trials, "seed": seed,
            "slope_per_sp_card_runs": {f"{k[0]} units" + (f" T{k[1]}" if k[1] else ""): v for k, v in slope.items()},
            "seconds": round(time.time() - t0, 1)}
    out = {"meta": meta, "summary": summ, "rows_vs_line": vs, "cards": csum, "engine_check": check}
    if write:
        write_csv("rows_placement_boards.csv", [{k: v for k, v in r.items() if k != "position_card_slots"} for r in rows])
        write_csv("rows_placement_summary.csv", summ)
        write_csv("rows_position_card_slots.csv", slots)
        write_csv("rows_vs_line.csv", vs)
        write_csv("rows_card_slots.csv", crows)
        write_csv("rows_card_summary.csv", csum)
        write_csv("rows_engine_check.csv", check)
        with open(OUT / "rows_run.csv", "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["key", "value"])
            for k, v in meta.items():
                w.writerow([k, fmt(v) if not isinstance(v, dict) else json.dumps({str(a): round(b, 5) for a, b in v.items()})])
    return out


# ------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-sim", action="store_true", help="skip the combat simulation")
    ap.add_argument("--quick", action="store_true", help="small simulation (600 trials per cell)")
    ap.add_argument("--trials", type=int, default=6000, help="simulation trials per cell (default 6000)")
    ap.add_argument("--rows", action="store_true",
                    help="run only the rows study (v1 engine); prints results, writes nothing without --full")
    ap.add_argument("--full", action="store_true",
                    help="rows study at the committed tables' sizes (about 10x the default work); writes rows_*.csv")
    args = ap.parse_args()

    if args.rows:
        cur = [c for c in load("minions.json")["cards"] if c["in_current_pool"]]
        if args.quick:
            kw = {"boards": 6, "train": 40, "test": 100, "ends_pool": 200, "field": 100, "card_trials": 100,
                  "small_trials": 60, "write": False}
        else:
            kw = dict(ROWS_FULL) if args.full else {"write": False}
        print(f"rows study: {kw}")
        res = run_rows_study(cur, **kw)
        print(json.dumps(res["meta"], default=fmt))
        for r in res["summary"]:
            print(r["band"], r["geometry"], r["condition"], r["units"],
                  "smart-random %.1f pp, smart-rule %.1f pp" % (r["smart_minus_random_pp"], r["smart_minus_rule_pp"]))
        print(f"wrote {OUT}/rows_*.csv" if kw.get("write", True) else "small run: nothing written (use --full to write)")
        return 0

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
