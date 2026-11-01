#!/usr/bin/env python3
"""Bramble power-budget model: immediate power versus scaling and economy, over time.

Answers the owner's question (owner note 2026-10-27f): "How many turns would it
take for the scaling card to realistically catch up and be better than the
immediate power card? At what level of econ?"

Standard library only. Re-run after changing any number in ASSUMPTIONS:

    python -I tools/research/budget_model.py

Writes CSV and JSON tables to docs/research/budget-model/. The write-up for the
owner is docs/design/power-budget-review.md; every number in it comes from a
table written here.

How the model works (short version; the review doc has the long one)
  1. A deterministic one-player economy and board simulation, turn by turn:
     income, carry-over, tier upgrades with the per-turn discount, buying units
     (3 gold, sell for 1), replacing the weakest unit when the board is full,
     and spending gold that has no better use on refreshes. Units are plain
     stat lumps worth V(tier) stat points (SP). Run under four economy levels
     and under Bramble rules (carry-over, escalating refresh) or HSBG rules.
  2. "Two worlds" comparison: the same game, except on turn a the player buys
     card X (a scaling or economy card) instead of a plain unit of the same
     tier. The difference in board SP per fight is the card's value over time.
     Hold time comes from the simulation (the card leaves when it is the
     weakest unit and a better buy exists), or is forced to the H(t)
     placeholder from power-budget.md.
  3. SP differences are converted to expected hero damage with a proxy:
     win-rate change per SP (from the toy combat sim) times the damage of a
     loss (HSBG formula: winner's tier + surviving units' tiers, capped by
     turn). It is a proxy, not a measurement.
  4. Sensitivity: every assumption marked in the table below is pushed low and
     high and the headline answers are recomputed.

Outputs (docs/research/budget-model/)
  economy_timeline.csv  turn-by-turn gold, tier, buys, board SP per economy level and rule set (a)
  tier_reach.csv        turn each tier is reached (a)
  hp_weights.csv        hero-damage proxy: win-rate slope, damage of a loss, HP per SP per fight
  closed_form.csv       crossover fights implied by the method's own formula
  scaling_grid.csv      every tier x purchase turn x scaling archetype x pricing x hold mode (b)
  scaling_headline.csv  the grid, filtered to the main archetypes (b)
  traces.csv            per-turn curves for five worked cases (b, c)
  hold_time.csv         H(t) placeholders against simulated holds (d)
  econ_cards.csv        economy cards against a plain unit, Bramble and HSBG rules (c)
  carry_over.csv        value of the same economy card with and without carry-over (c)
  econ_break_even.csv   body at which an economy card breaks even, and the charge rate it implies (c)
  gold_value.csv        measured value of one extra gold by the turn it arrives (c)
  break_even_rates.csv  scaling charge rate that breaks even by turn 10/12/15 (pricing)
  scaling_rate_caps.csv largest per-turn growth a 1/1 body can carry and still break even (pricing)
  horizon_pricing_check.csv  a proposed fix to the formula, tested (pricing)
  pace_scenarios.csv    headline cases with a faster-scaling lobby (e)
  sensitivity.csv       tornado table: each assumption low/high against six headline metrics (e)
  real_cards.csv        ten current HSBG pairs at printed stats (f)
  assumptions.json, summary.json

This is a model, not a simulation of real games: there are no opponents' cards,
no triples, no tribes, no shop randomness. Its job is to make the trade-offs
visible and to say which assumptions matter.
"""
from __future__ import annotations

import copy
import csv
import json
import math
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "docs" / "research" / "budget-model"

# =============================================================================
# ASSUMPTIONS  --  change a number here and re-run.
# Tags: [rule] rulebook value; [data] from the HSBG/Galaxy analysis;
#       [method] from power-budget.md v0; [judgement] my call, to be tested.
# =============================================================================
A = {
    # ---- Budget curve (power-budget.md section 2) ----------------------------
    "V": {1: 5, 2: 7, 3: 8, 4: 10, 5: 12, 6: 14},      # [method] SP of a plain unit by tier
    "H": {1: 3, 2: 3, 3: 4, 4: 4, 5: 5, 6: 5},          # [method][judgement] H(t) hold-time placeholders, fights
    "MIN_BODY": 2,                                       # [judgement] smallest legal body (a 1/1)

    # ---- Economy rules (rulebook chapter 4) ----------------------------------
    "INCOME_START": 3, "INCOME_STEP": 1, "INCOME_MAX": 10,   # [rule] 4.1.1
    "UNIT_COST": 3,                                      # [rule] 4.2.1
    "SELL_BOUGHT": 1,                                    # [rule] 4.3.3 (Created sells for 0; not modelled: all units here are Bought)
    "UPGRADE_BASE": {2: 5, 3: 7, 4: 8, 5: 11, 6: 11},    # [rule] 4.6.2
    "UPGRADE_DISCOUNT": 1,                               # [rule] 4.6.3, from turn 2
    "REFRESH_THRESHOLDS": (10, 20),                      # [rule] 4.4.3: refreshes 1-10 cost 1, 11-20 cost 2, 21+ cost 3
    "REFRESH_COSTS": (1, 2, 3),
    "BOARD_SLOTS": 7,                                    # [rule] 8.1.2 (4 front + 3 back)
    "MAX_TIER": 6,
    "HORIZON": 15,                                       # [judgement] last turn modelled; most HSBG games are decided by turn 12-16

    # ---- Player policy (how the scripted player spends gold) -----------------
    # Upgrade when affordable AND (it leaves >= LEVEL_KEEP gold for a buy, OR
    # LEVEL_WAIT turns of discount have built up since the last upgrade, OR it is
    # the first upgrade). Under HSBG rules with no econ this reproduces the
    # standard curve: tier 2 on turn 2, 3 on 4, 4 on 6, 5 on 8, 6 on 10.
    "LEVEL_KEEP": 3,                                     # [judgement]
    "LEVEL_WAIT": 2,                                     # [judgement]
    "REPLACE_MIN_GAIN": 2,                               # [judgement] on a full board, buy only if the new unit beats the weakest by >= this many SP
    "KEEP_LOOKAHEAD": 2,                                 # [judgement] the player values a scaling/econ unit at its value in this many turns when deciding what to sell
    "SINK_SP_PER_REFRESH": 1.0,                          # [judgement] permanent board SP gained per refresh when gold has no better use
                                                         # (better picks, triple pieces, spells). HSBG buff spells give 4-6 SP per gold [data], but only when offered.
    # Comparisons are averaged over these policy variants: offsets to
    # (LEVEL_KEEP, LEVEL_WAIT, REPLACE_MIN_GAIN). The first is the base policy.
    "POLICY_ENSEMBLE": [(0, 0, 0), (-1, 0, 0), (1, 0, 0), (0, -1, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)],  # [judgement]
    "BANK_UNTIL_MAX_TIER": True,                         # [judgement] with carry-over, leftover gold is banked toward the next upgrade until tier 6, then spent on refreshes

    # ---- Economy levels: extra gold per turn on top of income [judgement] ----
    # (turn_from, extra_gold) steps; the body cost of the engines that produce
    # this gold is not modelled in the timeline (it is in the economy-card table).
    "ECON_LEVELS": {
        "no_econ":    [],
        "standard":   [(2, 0.5)],                        # occasional coins and one-off battlecries: +1 every other turn
        "econ_heavy": [(3, 1), (5, 2)],                  # one engine from turn 3, a second from turn 5
        "high_roll":  [(2, 2), (4, 3), (6, 4)],          # several engines or an economy hero
    },
    "REFERENCE_ECON": "standard",                        # lobby reference board and the "design target" economy

    # ---- Hero-damage proxy (power-budget.md section 8 sim; rulebook 10.1) ----
    "WR_SLOPE_K": 2.0,                                   # [data][judgement] win-rate gain per SP ~= K / board SP. Toy sim: 0.046 at T2 (42 SP boards) and 0.028 at T5 (74 SP) -> K 1.9-2.1
    "WR_SLOPE_CAP": 0.15,                                # [judgement] cap for tiny early boards
    "WR_DELTA_CAP": 0.5,                                 # [judgement] largest win-rate change one card can make in one fight
    "SURVIVORS_ON_LOSS": 2,                              # [judgement] enemy units left alive when you lose
    "DAMAGE_CAP": [(1, 5), (4, 10), (8, 15)],            # [rule] 10.1.4 (turn_from, cap); removed at top 4 (not modelled)
    "GENERIC_GROWTH_PER_TURN": 0.0,                      # [judgement] lobby pace: SP per unit per turn that boards gain from everyone else's scaling text and buffs.
                                                         # 0 = printed-stats world. ~2.5 brings turn-12 boards to ~250 SP, closer to modern HSBG.
                                                         # Added as a board-level pool in both worlds, so it lowers the value of one SP; it does not change who is replaced.

    # ---- Pricing (power-budget.md section 3.2 and 4) --------------------------
    "SCALING_CHARGE": 1.0,                               # [method] per-turn scaling charged at 100% of s*(H+1)/2
    "ECON_CHARGE": 0.5,                                  # [method] economy charged at 50% of its gold value
    "CARRY_FACTOR": 1.1,                                 # [method] value of gold with carry-over relative to HSBG
    "HSBG_LIKE_BODY": 0.9,                               # [data] HSBG scaling cards carry ~0.86-1.0 x the tier median; modelled as 0.9 x V(t)
    "PRICING_TRIGGERS_PER_TURN": None,                   # recruit-trigger cards: the designer's expected qualifying plays per turn (None = measured from the reference economy)
    "RECRUIT_SHARE": 0.5,                                # [judgement] share of your buys that qualify ("after you play a Demon") in a committed build
}

# Archetypes swept in the scaling grid. s = SP gained per trigger.
SCALING_ARCHETYPES = [
    # name,                kind,          s,  freq (triggers per combat or share), label
    ("eot_+1health",      "self_turn",    1, None, "End of turn: gain +1 Health (+1 SP/turn)"),
    ("eot_+1/+1",         "self_turn",    2, None, "End of turn: gain +1/+1 (+2 SP/turn)"),
    ("eot_+2/+2",         "self_turn",    4, None, "End of turn: gain +2/+2 (+4 SP/turn)"),
    ("combat_+1/+1_x0.5", "self_combat",  2, 0.5, "Combat trigger, +1/+1 permanently, 0.5 triggers/fight"),
    ("combat_+1/+1_x1",   "self_combat",  2, 1.0, "Combat trigger, +1/+1 permanently, 1 trigger/fight"),
    ("combat_+1/+1_x2",   "self_combat",  2, 2.0, "Combat trigger, +1/+1 permanently, 2 triggers/fight"),
    ("play_+1/+1",        "recruit",      2, None, "After you play a <Tribe>, gain +1/+1 (share RECRUIT_SHARE of buys)"),
    ("eot_other_+1/+1",   "other_turn",   2, None, "End of turn: give another unit +1/+1 (buff stays on the target)"),
]

ECON_ARCHETYPES = [
    # name,            kind,             gold, tiers, label
    ("bc_gold_1",     "gold_once",      1, (1, 2), "Battlecry: gain 1 gold"),
    ("sot_gold_1",    "gold_per_turn",  1, (1, 2, 3, 4), "Start of turn: gain 1 gold"),
    ("sot_gold_2",    "gold_per_turn",  2, (4, 5), "Start of turn: gain 2 gold"),
]

# Real HSBG pairs (current pool, minions.json build 255790). Stats are printed
# stats; effect parameters are my reading of the text [judgement].
REAL_PAIRS = [
    # (id, tier, scaling card, a/h, kind, s, freq/gold, immediate card, a/h, note)
    ("lullabot", 1, "Lullabot", (2, 2), "self_turn", 1, None, "Scarlet Survivor", (3, 3), "Magnetic ignored"),
    ("wrath_weaver", 1, "Wrath Weaver", (1, 3), "recruit", 4, None, "Scarlet Survivor", (3, 3), "+2/+2 per Demon played; 1 hero damage per trigger not counted"),
    ("southsea_busker", 1, "Southsea Busker", (3, 1), "gold_once", 0, 1, "Scarlet Survivor", (3, 3), "1 gold next turn"),
    ("shell_collector", 2, "Shell Collector", (4, 3), "gold_once", 0, 1, "Tarecgosa", (4, 4), "Tavern Coin = 1 gold"),
    ("surfing_sylvar", 2, "Surfing Sylvar", (1, 2), "other_turn", 1.6, None, "Tarecgosa", (4, 4), "+1 Attack to ~1.6 adjacent units per turn"),
    ("devout_hellcaller", 3, "Devout Hellcaller", (4, 4), "self_combat", 4, 1.5, "Greedy Conniver", (7, 7), "+2/+2 after another Demon deals damage; ~1.5 Demon hits/fight assumed"),
    ("accord_o_tron", 3, "Accord-o-Tron", (3, 3), "gold_per_turn", 0, 1, "Greedy Conniver", (7, 7), "Magnetic ignored"),
    ("parasitic_fleshling", 4, "Parasitic Fleshling", (4, 6), "other_turn", 4, None, "Zesty Shaker", (6, 7), "+2/+2 to left-most each turn; discards ignored"),
    ("flaming_enforcer", 4, "Flaming Enforcer", (4, 5), "consume", 0.7, None, "Zesty Shaker", (6, 7), "consumes the highest-Health shop unit: ~0.7 x V(your tier) per turn"),
    ("gearfin", 4, "Gearfin", (6, 5), "gold_per_turn", 0, 2, "Zesty Shaker", (6, 7), "two 1-cost Tavern spells per turn treated as 2 gold"),
]

TURNS = None  # set from HORIZON


# =============================================================================
# Helpers
# =============================================================================
def income(t):
    return min(A["INCOME_START"] + A["INCOME_STEP"] * (t - 1), A["INCOME_MAX"])


def extra_gold(level, t):
    """Extra gold on turn t; fractional rates are paid as whole gold on a fixed cadence."""
    rate = 0.0
    for start, g in A["ECON_LEVELS"][level]:
        if t >= start:
            rate = g
    if rate == int(rate):
        return int(rate)
    # pay the fractional part as cumulative floor (0.5 -> 0,1,0,1...)
    start = A["ECON_LEVELS"][level][0][0]
    k = t - start + 1
    return int(math.floor(rate * k + 1e-9) - math.floor(rate * (k - 1) + 1e-9))


def damage_cap(t):
    cap = None
    for start, c in A["DAMAGE_CAP"]:
        if t >= start:
            cap = c
    return cap


def refreshes_for(gold, carry):
    """Spend gold on refreshes at escalating cost (Bramble) or 1 each (HSBG).
    Returns (refreshes, gold spent)."""
    if not carry:  # HSBG: every refresh costs 1
        return gold, gold
    t1, t2 = A["REFRESH_THRESHOLDS"]
    c1, c2, c3 = A["REFRESH_COSTS"]
    n = spent = 0
    while True:
        cost = c1 if n < t1 else (c2 if n < t2 else c3)
        if spent + cost > gold:
            break
        spent += cost
        n += 1
    return n, spent


def V(t):
    return A["V"][t]


def G(t):
    return A["V"][t] / 2.0  # [method] value of 1 gold in SP


# =============================================================================
# The simulation
# =============================================================================
class Unit:
    __slots__ = ("value", "tier", "tracked", "kind", "s", "freq", "gold", "bought", "born")

    def __init__(self, value, tier, bought, tracked=False, kind="plain", s=0.0, freq=None, gold=0):
        self.value = float(value)
        self.tier = tier
        self.tracked = tracked
        self.kind = kind
        self.s = s
        self.freq = freq
        self.gold = gold
        self.bought = bought
        self.born = bought


def keep_value(u, tier):
    """What the player thinks a unit is worth when choosing what to sell."""
    v = u.value
    L = A["KEEP_LOOKAHEAD"]
    if u.kind == "self_turn":
        v += u.s * L
    elif u.kind == "self_combat":
        v += u.s * u.freq * L
    elif u.kind == "recruit":
        v += u.s * A["RECRUIT_SHARE"] * 1.5 * L
    elif u.kind == "consume":
        v += u.s * V(tier) * L
    elif u.kind == "other_turn":
        v += u.s * L  # its buffs land elsewhere
    elif u.kind == "gold_per_turn":
        v += G(tier) * u.gold * L
    return v


def simulate(level, carry=True, tracked=None, hold_mode="endo"):
    """One player's game. tracked = dict(turn, tier, body, kind, s, freq, gold).
    hold_mode: 'endo' (the policy decides when to sell it), 'fixed' (sold after
    H(tier) fights), 'card' (never sold: the card's own curve).
    Returns a list of per-turn dicts."""
    gold = 0
    tier = 1
    cost = A["UPGRADE_BASE"][2]
    since = 99
    units: list[Unit] = []
    sink = 0.0
    rows = []
    tr_unit = None
    tr_bought_turn = None
    tr_done = False
    pending_gold = 0  # "gain gold next turn"
    for T in range(1, A["HORIZON"] + 1):
        inc = income(T)
        ext = extra_gold(level, T)
        tr_gold = pending_gold
        pending_gold = 0
        if tr_unit is not None and tr_unit in units and tr_unit.kind == "gold_per_turn" and T > tr_bought_turn:
            tr_gold += tr_unit.gold
        bonus = A.get("_BONUS")
        if bonus and bonus[0] == T:
            ext += bonus[1]
        gold = (gold if carry else 0) + inc + ext + tr_gold
        if T >= 2:
            cost = max(0, cost - A["UPGRADE_DISCOUNT"])
        since += 1
        # forced sale in fixed-hold mode
        if (tr_unit is not None and hold_mode == "fixed" and tr_unit in units
                and T - tr_bought_turn >= A["H"][tracked["tier"]]):
            units.remove(tr_unit)
            gold += A["SELL_BOUGHT"]
        # --- upgrade
        upgrade_spend = 0
        while tier < A["MAX_TIER"] and gold >= cost and (
                gold - cost >= A["LEVEL_KEEP"] or since >= A["LEVEL_WAIT"] or tier == 1):
            gold -= cost
            upgrade_spend += cost
            tier += 1
            since = 0
            cost = A["UPGRADE_BASE"].get(tier + 1, 0)
        # --- tracked purchase
        buys = sells = 0
        plays_after_tracked = 0
        if tracked and not tr_done and T >= tracked["turn"] and gold >= A["UNIT_COST"] and tier >= tracked["tier"]:
            gold -= A["UNIT_COST"]
            buys += 1
            tr_unit = Unit(tracked["body"], tracked["tier"], T, True, tracked["kind"],
                           tracked.get("s", 0), tracked.get("freq"), tracked.get("gold", 0))
            tr_bought_turn = T
            tr_done = True
            if len(units) >= A["BOARD_SLOTS"]:
                cand = [u for u in units]
                w = min(cand, key=lambda u: keep_value(u, tier))
                units.remove(w)
                gold += A["SELL_BOUGHT"]
                sells += 1
            units.append(tr_unit)
            if tr_unit.kind == "gold_once":
                gold += tr_unit.gold  # Battlecry gold, counted as available this turn (a Coin; Busker's 'next turn' differs by one turn)
        # --- ordinary buys
        while gold >= A["UNIT_COST"]:
            new_val = V(tier)
            if len(units) < A["BOARD_SLOTS"]:
                gold -= A["UNIT_COST"]
                units.append(Unit(new_val, tier, T))
                buys += 1
            else:
                protected = (hold_mode in ("fixed", "card"))
                # the tracked card is never sold on the turn it is bought
                cand = [u for u in units if not (u.tracked and (protected or T == tr_bought_turn))]
                if not cand:
                    break
                w = min(cand, key=lambda u: keep_value(u, tier))
                if new_val >= keep_value(w, tier) + A["REPLACE_MIN_GAIN"]:
                    gold -= A["UNIT_COST"]
                    units.remove(w)
                    gold += A["SELL_BOUGHT"]
                    units.append(Unit(new_val, tier, T))
                    buys += 1
                    sells += 1
                else:
                    break
            if tr_unit is not None and tr_unit in units and T >= tr_bought_turn:
                plays_after_tracked += 1
        # --- leftover gold
        refreshes = 0
        if carry and A["BANK_UNTIL_MAX_TIER"] and tier < A["MAX_TIER"]:
            pass  # bank it
        else:
            refreshes, spent = refreshes_for(gold, carry)
            sink += refreshes * A["SINK_SP_PER_REFRESH"]
            gold -= spent
            if not carry:
                gold = 0
        # --- end of turn: growth
        # lobby pace: buffs from the rest of the game's text, as a board-level pool (same in both worlds)
        sink += A["GENERIC_GROWTH_PER_TURN"] * len(units)
        if tr_unit is not None and tr_unit in units:
            k = tr_unit.kind
            if k == "self_turn":
                tr_unit.value += tr_unit.s
            elif k == "recruit":
                plays = plays_after_tracked if T == tr_bought_turn else buys
                tr_unit.value += tr_unit.s * A["RECRUIT_SHARE"] * plays
            elif k == "consume":
                tr_unit.value += tr_unit.s * V(tier)
            elif k == "other_turn":
                others = [u for u in units if not u.tracked]
                if others:
                    max(others, key=lambda u: u.value).value += tr_unit.s
        # --- combat snapshot
        board_sp = sum(u.value for u in units) + sink
        n = len(units)
        avg_tier = (sum(u.tier for u in units) / n) if n else 0
        held = tr_unit is not None and tr_unit in units
        rows.append(dict(turn=T, income=inc, extra=ext + tr_gold, tier=tier, upgrade_spend=upgrade_spend,
                         buys=buys, sells=sells, refreshes=refreshes, banked=gold if carry else 0,
                         units=n, board_sp=round(board_sp, 3), sink_sp=round(sink, 3),
                         avg_unit_tier=round(avg_tier, 3), tracked_held=held,
                         tracked_value=round(tr_unit.value, 3) if held else None))
        # --- after combat: combat-trigger growth
        if held and tr_unit.kind == "self_combat":
            tr_unit.value += tr_unit.s * tr_unit.freq
    return rows


def reach_turns(rows):
    out = {}
    for r in rows:
        out.setdefault(r["tier"], r["turn"])
    for t in range(1, A["MAX_TIER"] + 1):
        if t not in out:
            lower = [out[x] for x in out if x > t]
            out[t] = min(lower) if lower else None
    return out


# =============================================================================
# Hero-damage weights
# =============================================================================
def weights(ref_rows):
    """w(T) = expected hero HP per SP per fight = win-rate slope x damage of a loss."""
    w = {}
    for r in ref_rows:
        T = r["turn"]
        slope = min(A["WR_SLOPE_CAP"], A["WR_SLOPE_K"] / max(r["board_sp"], 1e-9))
        dmg = min(damage_cap(T), r["tier"] + A["SURVIVORS_ON_LOSS"] * r["avg_unit_tier"])
        w[T] = dict(slope=slope, dmg=dmg, w=slope * dmg)
    return w


# =============================================================================
# Pricing
# =============================================================================
def pricing_triggers_per_turn():
    if A["PRICING_TRIGGERS_PER_TURN"] is not None:
        return A["PRICING_TRIGGERS_PER_TURN"]
    rows = simulate(A["REFERENCE_ECON"])
    b = [r["buys"] for r in rows if 3 <= r["turn"] <= 10]
    return sum(b) / len(b)


def s_eff(kind, s, freq, tier):
    """Expected SP per turn, as the designer would estimate it."""
    if kind == "self_turn" or kind == "other_turn":
        return s
    if kind == "self_combat":
        return s * freq
    if kind == "recruit":
        return s * A["RECRUIT_SHARE"] * pricing_triggers_per_turn()
    if kind == "consume":
        return s * V(tier)
    return 0.0


def priced_body(kind, s, freq, tier, scheme, rate=None, gold=0, turn=None):
    v = V(tier)
    H = A["H"][tier]
    if scheme.startswith("horizon"):
        # proposed alternative: replace H(t) by the fights left until the target turn
        H = max(1, int(scheme[7:]) - turn + 1)
        scheme = "budget"
    if scheme == "free":
        b = v
    elif scheme == "hsbg_like":
        b = A["HSBG_LIKE_BODY"] * v
    elif scheme.startswith("budget"):
        r = A["SCALING_CHARGE"] if rate is None else rate
        if kind in ("gold_once", "gold_per_turn"):
            total_gold = gold if kind == "gold_once" else gold * H
            r = A["ECON_CHARGE"] if rate is None else rate
            b = v - r * total_gold * G(tier) * A["CARRY_FACTOR"]
        else:
            se = s_eff(kind, s, freq, tier)
            per_fight = se * (H + 1) / 2.0
            tail = 0.5 * se * H if kind == "other_turn" else 0.0  # [method] half the tail
            b = v - r * (per_fight + tail)
    else:
        raise ValueError(scheme)
    return max(A["MIN_BODY"], b), b  # (clamped, raw)


# =============================================================================
# Two-worlds comparison
# =============================================================================
def compare(level, tier, turn, kind, s, freq, body, gold=0, carry=True, hold_mode="endo",
            imm_body=None, w=None):
    imm = dict(turn=turn, tier=tier, body=V(tier) if imm_body is None else imm_body, kind="plain")
    card = dict(turn=turn, tier=tier, body=body, kind=kind, s=s, freq=freq, gold=gold)
    # Average over an ensemble of player policies: one greedy policy makes lumpy,
    # knife-edge decisions (one extra gold can shift a whole upgrade), so each
    # comparison is the mean over POLICY_ENSEMBLE variants.
    runs = []
    saved = {k: A[k] for k in ("LEVEL_KEEP", "LEVEL_WAIT", "REPLACE_MIN_GAIN")}
    for keep, wait, gain in A["POLICY_ENSEMBLE"]:
        A["LEVEL_KEEP"], A["LEVEL_WAIT"], A["REPLACE_MIN_GAIN"] = (saved["LEVEL_KEEP"] + keep,
                                                                  saved["LEVEL_WAIT"] + wait,
                                                                  saved["REPLACE_MIN_GAIN"] + gain)
        runs.append((simulate(level, carry, imm, hold_mode), simulate(level, carry, card, hold_mode)))
    A.update(saved)
    ra, rb = runs[0]
    H = A["HORIZON"]
    n_runs = len(runs)
    diffs = {T: sum(q[T - 1]["board_sp"] - p[T - 1]["board_sp"] for p, q in runs) / n_runs
             for T in range(1, H + 1)}
    spread15 = [sum(q[T - 1]["board_sp"] - p[T - 1]["board_sp"] for T in range(1, H + 1)) for p, q in runs]
    own = {}
    for r, q in zip(ra, rb):
        if r["tracked_held"] or q["tracked_held"]:
            own[r["turn"]] = ((q["tracked_value"] or 0) - (r["tracked_value"] or 0))
    a_turn = next((r["turn"] for r in rb if r["tracked_held"]), None)
    # crossovers use the base policy only, so a purchase delayed in one variant does not blur them
    base_diffs = {p["turn"]: q["board_sp"] - p["board_sp"] for p, q in zip(ra, rb)}

    def hp(T, d):
        dwr = max(-A["WR_DELTA_CAP"], min(A["WR_DELTA_CAP"], d * w[T]["slope"]))
        return dwr * w[T]["dmg"]

    def first_cross(series):
        """First turn from which the per-fight difference stays >= 0 to the horizon."""
        last_neg = None
        for T in range(a_turn or 1, H + 1):
            if series.get(T, 0) < -1e-9:
                last_neg = T
        if last_neg is None:
            return a_turn
        return last_neg + 1 if last_neg < H else None

    def first_cum_cross(series, weight=None):
        """First turn from which the cumulative difference stays >= 0 to the horizon."""
        c = 0.0
        last_neg = None
        for T in range(a_turn or 1, H + 1):
            c += hp(T, series.get(T, 0)) if weight else series.get(T, 0)
            if c < -1e-9:
                last_neg = T
        if last_neg is None:
            return a_turn
        return last_neg + 1 if last_neg < H else None

    def cum_until(series, X, weight=None):
        return sum((hp(T, series.get(T, 0)) if weight else series.get(T, 0))
                   for T in range(a_turn or 1, min(X, H) + 1))

    hold_a = round(sum(sum(1 for r in p if r["tracked_held"]) for p, q in runs) / n_runs, 1)
    hold_b = round(sum(sum(1 for r in q if r["tracked_held"]) for p, q in runs) / n_runs, 1)
    tempo_hp = sum(min(0.0, hp(T, d)) for T, d in diffs.items()) if w else None
    gain_hp = sum(max(0.0, hp(T, d)) for T, d in diffs.items()) if w else None
    res = dict(acquired=a_turn, hold_immediate=hold_a, hold_card=hold_b,
               cross_current=first_cross(base_diffs), cross_cum=first_cum_cross(base_diffs),
               cross_cum_hp=first_cum_cross(base_diffs, w) if w else None,
               tempo_cost_hp=round(tempo_hp, 3) if w else None,
               gain_hp=round(gain_hp, 3) if w else None,
               policy_spread_sp_t15=f"{min(spread15):.0f}..{max(spread15):.0f}")
    for X in (8, 10, 12, 15):
        res[f"surplus_sp_t{X}"] = round(cum_until(diffs, X), 2)
        if w:
            res[f"surplus_hp_t{X}"] = round(cum_until(diffs, X, w), 3)
    res["_diffs"] = diffs
    res["_own"] = own
    res["_ra"] = ra
    res["_rb"] = rb
    return res


# =============================================================================
# Output helpers
# =============================================================================
def write_csv(name, rows, fields=None):
    OUT.mkdir(parents=True, exist_ok=True)
    rows = [{k: v for k, v in r.items() if not k.startswith("_")} for r in rows]
    if not rows:
        return
    fields = fields or list(rows[0].keys())
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        wr.writeheader()
        for r in rows:
            wr.writerow(r)


def write_json(name, obj):
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, default=str)


# =============================================================================
# Analyses
# =============================================================================
def economy_tables():
    timeline, reach = [], []
    for rules, carry in (("bramble", True), ("hsbg", False)):
        for level in A["ECON_LEVELS"]:
            rows = simulate(level, carry)
            for r in rows:
                timeline.append(dict(rules=rules, econ=level, **{k: v for k, v in r.items()
                                                                  if not k.startswith("tracked")}))
            rt = reach_turns(rows)
            reach.append(dict(rules=rules, econ=level, **{f"tier{t}": rt.get(t) for t in range(2, 7)},
                              board_sp_t8=next(r["board_sp"] for r in rows if r["turn"] == 8),
                              board_sp_t12=next(r["board_sp"] for r in rows if r["turn"] == 12),
                              full_board_turn=next((r["turn"] for r in rows if r["units"] >= A["BOARD_SLOTS"]), None)))
    write_csv("economy_timeline.csv", timeline)
    write_csv("tier_reach.csv", reach)
    return reach


def weight_table(w):
    write_csv("hp_weights.csv", [dict(turn=T, **{k: round(v, 4) for k, v in d.items()}) for T, d in w.items()])


def scaling_grid(w):
    """(b): every tier x acquisition turn x archetype x pricing x econ level."""
    rows = []
    for level in A["ECON_LEVELS"]:
        rt = reach_turns(simulate(level))
        for tier in range(1, 7):
            base_turn = rt[tier]
            if base_turn is None:
                continue
            for a in sorted({base_turn, base_turn + 1, base_turn + 2}):
                if a > A["HORIZON"] - 2:
                    continue
                for name, kind, s, freq, label in SCALING_ARCHETYPES:
                    for scheme in ("budget100", "hsbg_like", "free"):
                        body, raw = priced_body(kind, s, freq, tier, scheme)
                        for mode in ("card", "fixed", "endo"):
                            r = compare(level, tier, a, kind, s, freq, body, hold_mode=mode, w=w)
                            rows.append(dict(econ=level, tier=tier, turn_planned=a, archetype=name,
                                             pricing=scheme, hold_mode=mode, body=round(body, 2),
                                             body_raw=round(raw, 2), immediate=V(tier),
                                             H=A["H"][tier], **r))
    write_csv("scaling_grid.csv", rows)
    return rows


def headline(grid):
    """Pick the cells the review leads with."""
    keep = [r for r in grid if r["pricing"] in ("budget100", "hsbg_like")]
    out = []
    for r in keep:
        if r["turn_planned"] != r["acquired"]:
            pass
        out.append(r)
    sel = [r for r in out if r["archetype"] in ("eot_+1health", "eot_+1/+1", "eot_+2/+2", "combat_+1/+1_x1", "play_+1/+1")]
    write_csv("scaling_headline.csv", sel, fields=[
        "econ", "tier", "turn_planned", "acquired", "archetype", "pricing", "hold_mode", "body", "body_raw",
        "immediate", "H", "hold_immediate", "hold_card", "cross_current", "cross_cum", "cross_cum_hp",
        "tempo_cost_hp", "gain_hp", "surplus_sp_t8", "surplus_sp_t10", "surplus_sp_t12", "surplus_sp_t15",
        "surplus_hp_t8", "surplus_hp_t10", "surplus_hp_t12", "surplus_hp_t15"])
    return sel


def traces(w):
    """Per-turn traces for the owner's worked example and a few others."""
    cases = [
        ("T2 +1/+1 per turn, turn 3, budget100", "standard", 2, 3, "self_turn", 2, None, "budget100"),
        ("T2 +1/+1 per turn, turn 3, hsbg_like", "standard", 2, 3, "self_turn", 2, None, "hsbg_like"),
        ("T1 +1 Health per turn, turn 1, budget100", "standard", 1, 1, "self_turn", 1, None, "budget100"),
        ("T4 +2/+2 per turn, turn 6, budget100", "standard", 4, 6, "self_turn", 4, None, "budget100"),
        ("T3 +1 gold per turn, turn 4, budget50", "standard", 3, 4, "gold_per_turn", 0, None, "budget"),
    ]
    rows = []
    for label, level, tier, a, kind, s, freq, scheme in cases:
        gold = 1 if kind.startswith("gold") else 0
        body, _ = priced_body(kind, s, freq, tier, scheme, gold=gold)
        for mode in ("card", "endo"):
            r = compare(level, tier, a, kind, s, freq, body, gold=gold, hold_mode=mode, w=w)
            for qa, qb in zip(r["_ra"], r["_rb"]):
                T = qa["turn"]
                rows.append(dict(case=label, hold_mode=mode, turn=T, tier_player=qb["tier"],
                                 immediate_value=qa["tracked_value"], card_value=qb["tracked_value"],
                                 board_sp_immediate=qa["board_sp"], board_sp_card=qb["board_sp"],
                                 board_diff=round(qb["board_sp"] - qa["board_sp"], 3),
                                 hp_weight=round(w[T]["w"], 4),
                                 hp_diff=round(max(-A["WR_DELTA_CAP"], min(A["WR_DELTA_CAP"], (qb["board_sp"] - qa["board_sp"]) * w[T]["slope"])) * w[T]["dmg"], 4)))
    write_csv("traces.csv", rows)


def closed_form():
    """Card-only crossover in fights, for a scaling unit priced at rate r of s*(H+1)/2:
    current crossover k_c = r*(H+1)/2, cumulative k_cum = r*(H+1) - 1 (fights, counting the
    acquisition fight as 1). Inverse: r = (k_cum + 1)/(H + 1)."""
    rows = []
    for tier in range(1, 7):
        H = A["H"][tier]
        for r in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5):
            rows.append(dict(tier=tier, H=H, rate=r, cross_current_fight=round(r * (H + 1) / 2, 2),
                             cross_cum_fight=round(r * (H + 1) - 1, 2)))
        for k in (2, 3, 4, 5, 6):
            rows.append(dict(tier=tier, H=H, rate=round((k + 1) / (H + 1), 3), cross_current_fight=None,
                             cross_cum_fight=k, note="rate for target cumulative crossover"))
    write_csv("closed_form.csv", rows, fields=["tier", "H", "rate", "cross_current_fight", "cross_cum_fight", "note"])


def break_even(w):
    """(implications) Which scaling-charge rate makes a card exactly break even in expected
    hero HP by turn X, with realistic (endogenous) hold, at each econ level?"""
    rows = []
    for level in A["ECON_LEVELS"]:
        rt = reach_turns(simulate(level))
        for tier in (1, 2, 3, 4, 5):
            a = rt[tier]
            if a is None or a > A["HORIZON"] - 3:
                continue
            for name, kind, s, freq, label in SCALING_ARCHETYPES:
                if kind not in ("self_turn", "self_combat"):
                    continue
                for X in (10, 12, 15):
                    def f(rate):
                        body, _ = priced_body(kind, s, freq, tier, "budget", rate=rate)
                        return compare(level, tier, a, kind, s, freq, body, hold_mode="endo", w=w)[f"surplus_hp_t{X}"]
                    lo, hi = 0.0, 4.0
                    flo, fhi = f(lo), f(hi)
                    if flo < 0:
                        rate = "never (even free)"
                    elif fhi > 0:
                        rate = ">4 (body hits the 1/1 floor first)"
                    else:
                        for _ in range(30):
                            mid = (lo + hi) / 2
                            if f(mid) > 0:
                                lo = mid
                            else:
                                hi = mid
                        rate = round((lo + hi) / 2, 2)
                    body_at_100, raw = priced_body(kind, s, freq, tier, "budget100")
                    rows.append(dict(econ=level, tier=tier, turn_planned=a, archetype=name, by_turn=X,
                                     break_even_rate=rate, body_at_100=round(body_at_100, 2),
                                     body_raw_at_100=round(raw, 2)))
    write_csv("break_even_rates.csv", rows)
    return rows


def hold_table(w):
    """(d) Hold time: placeholders versus the simulation."""
    rows = []
    for level in A["ECON_LEVELS"]:
        rt = reach_turns(simulate(level))
        for tier in range(1, 7):
            a = rt[tier]
            if a is None:
                continue
            for off in (0, 2):
                if a + off > A["HORIZON"] - 1:
                    continue
                plain = compare(level, tier, a + off, "plain", 0, None, V(tier), hold_mode="endo", w=w)
                row = dict(econ=level, tier=tier, acquired=plain["acquired"], H_placeholder=A["H"][tier],
                           hold_plain_sim=plain["hold_immediate"],
                           censored=plain["acquired"] + plain["hold_immediate"] - 1 >= A["HORIZON"])
                for name, kind, s, freq, label in SCALING_ARCHETYPES[:3] + SCALING_ARCHETYPES[4:5]:
                    body, _ = priced_body(kind, s, freq, tier, "budget100")
                    r = compare(level, tier, a + off, kind, s, freq, body, hold_mode="endo", w=w)
                    card = compare(level, tier, a + off, kind, s, freq, body, hold_mode="card", w=w)
                    row[f"hold_{name}"] = r["hold_card"]
                    row[f"crosscum_{name}"] = card["cross_cum"]
                    row[f"replaced_before_cross_{name}"] = (
                        card["cross_cum"] is None or card["cross_cum"] > (r["acquired"] + r["hold_card"] - 1))
                rows.append(row)
    write_csv("hold_time.csv", rows)
    return rows


def econ_cards(w):
    """(c) Economy cards versus a plain unit, Bramble rules versus HSBG rules."""
    rows = []
    for level in A["ECON_LEVELS"]:
        for rules, carry in (("bramble", True), ("hsbg", False)):
            rt = reach_turns(simulate(level, carry))
            for name, kind, gold, tiers, label in ECON_ARCHETYPES:
                for tier in tiers:
                    a0 = rt[tier]
                    if a0 is None:
                        continue
                    for a in sorted({a0, a0 + 2}):
                        if a > A["HORIZON"] - 2:
                            continue
                        for scheme in ("budget", "hsbg_like", "free"):
                            body, raw = priced_body(kind, 0, None, tier, scheme, gold=gold)
                            r = compare(level, tier, a, kind, 0, None, body, gold=gold, carry=carry,
                                        hold_mode="endo", w=w)
                            rows.append(dict(econ=level, rules=rules, card=name, tier=tier, turn_planned=a,
                                             pricing=scheme, body=round(body, 2), body_raw=round(raw, 2),
                                             immediate=V(tier), **r))
    write_csv("econ_cards.csv", rows)
    # carry-over factor: value under Bramble / value under HSBG, same card, free body
    cf = []
    for level in A["ECON_LEVELS"]:
        for name, kind, gold, tiers, label in ECON_ARCHETYPES:
            for tier in tiers:
                b = [r for r in rows if r["econ"] == level and r["card"] == name and r["tier"] == tier
                     and r["pricing"] == "free" and r["rules"] == "bramble"]
                h = [r for r in rows if r["econ"] == level and r["card"] == name and r["tier"] == tier
                     and r["pricing"] == "free" and r["rules"] == "hsbg"]
                if not b or not h:
                    continue
                b, h = b[0], h[0]
                for X in (10, 15):
                    vb, vh = b[f"surplus_sp_t{X}"], h[f"surplus_sp_t{X}"]
                    cf.append(dict(econ=level, card=name, tier=tier, acquired_bramble=b["acquired"],
                                   acquired_hsbg=h["acquired"], by_turn=X, value_sp_bramble=vb,
                                   value_sp_hsbg=vh, carry_factor=round(vb / vh, 2) if vh > 0.05 else None,
                                   value_hp_bramble=b[f"surplus_hp_t{X}"], value_hp_hsbg=h[f"surplus_hp_t{X}"]))
    write_csv("carry_over.csv", cf)
    return rows, cf


def econ_break_even(w):
    """Body (SP) at which an economy card exactly breaks even with a plain V(t) unit in
    expected hero HP by turn X (realistic hold, standard rules), and the economy charge
    rate that body implies under the method's formula."""
    rows = []
    for level in A["ECON_LEVELS"]:
        rt = reach_turns(simulate(level))
        for name, kind, gold, tiers, label in ECON_ARCHETYPES:
            for tier in tiers:
                a = rt[tier]
                if a is None or a > A["HORIZON"] - 3:
                    continue
                for X in (10, 12, 15):
                    def f(body):
                        return compare(level, tier, a, kind, 0, None, body, gold=gold, hold_mode="endo", w=w)[f"surplus_hp_t{X}"]
                    lo, hi = 0.0, float(V(tier))
                    if f(hi) < 0:
                        be = "above V(t): not worth a plain unit even at full body"
                        implied = None
                    elif f(lo) > 0:
                        be = 0.0
                        implied = None
                    else:
                        for _ in range(16):
                            mid = (lo + hi) / 2
                            if f(mid) > 0:
                                hi = mid
                            else:
                                lo = mid
                        be = round((lo + hi) / 2, 2)
                        H = A["H"][tier]
                        total_gold = gold if kind == "gold_once" else gold * H
                        implied = round((V(tier) - be) / (total_gold * G(tier) * A["CARRY_FACTOR"]), 2)
                    body_m, raw_m = priced_body(kind, 0, None, tier, "budget", gold=gold)
                    rows.append(dict(econ=level, card=name, tier=tier, turn_planned=a, by_turn=X,
                                     break_even_body=be, plain_body=V(tier), method_body_raw=round(raw_m, 2),
                                     implied_econ_charge=implied))
    write_csv("econ_break_even.csv", rows)
    return rows


def rate_caps(w):
    """Largest per-turn scaling rate s (SP per turn) that a card can carry at each tier and
    still only break even with a plain V(t) unit by turn X, given (a) the smallest legal
    body or (b) the body the 100% method would give it. Above the cap, no body is small
    enough: the text alone is over budget."""
    rows = []
    for level in A["ECON_LEVELS"]:
        rt = reach_turns(simulate(level))
        for tier in range(1, 6):
            a = rt[tier]
            if a is None or a > A["HORIZON"] - 3:
                continue
            for kind, freq in (("self_turn", None), ("self_combat", 1.0)):
                for X in (10, 12, 15):
                    def f(sv):
                        return compare(level, tier, a, kind, sv, freq, A["MIN_BODY"], hold_mode="endo", w=w)[f"surplus_hp_t{X}"]
                    lo, hi = 0.0, 8.0
                    if f(hi) < 0:
                        cap = ">8"
                    else:
                        for _ in range(16):
                            mid = (lo + hi) / 2
                            if f(mid) > 0:
                                hi = mid
                            else:
                                lo = mid
                        cap = round((lo + hi) / 2, 2)
                    rows.append(dict(econ=level, tier=tier, turn_planned=a, kind=kind, by_turn=X,
                                     max_sp_per_turn_on_min_body=cap))
    write_csv("scaling_rate_caps.csv", rows)
    return rows


def gold_value():
    """Measured value of one extra gold, by the turn it arrives: cumulative board SP-fights
    to the horizon, against the method's G(t) x H(t) (a body worth V(t)/2 per gold, held H fights)."""
    global A
    rows = []
    base_A = copy.deepcopy(A)
    for level in A["ECON_LEVELS"]:
        for rules, carry in (("bramble", True), ("hsbg", False)):
            base_runs = []
            for keep, wait, gain in A["POLICY_ENSEMBLE"]:
                A["LEVEL_KEEP"] = base_A["LEVEL_KEEP"] + keep
                A["LEVEL_WAIT"] = base_A["LEVEL_WAIT"] + wait
                A["REPLACE_MIN_GAIN"] = base_A["REPLACE_MIN_GAIN"] + gain
                base_runs.append(simulate(level, carry))
            A = copy.deepcopy(base_A)
            rt = reach_turns(base_runs[0])
            for T in range(1, A["HORIZON"]):
                tot = 0.0
                for i, (keep, wait, gain) in enumerate(A["POLICY_ENSEMBLE"]):
                    A["LEVEL_KEEP"] = base_A["LEVEL_KEEP"] + keep
                    A["LEVEL_WAIT"] = base_A["LEVEL_WAIT"] + wait
                    A["REPLACE_MIN_GAIN"] = base_A["REPLACE_MIN_GAIN"] + gain
                    A["_BONUS"] = (T, 1)
                    r = simulate(level, carry)
                    A.pop("_BONUS")
                    tot += sum(q["board_sp"] - p["board_sp"] for p, q in zip(base_runs[i], r))
                A = copy.deepcopy(base_A)
                tier_T = base_runs[0][T - 1]["tier"]
                rows.append(dict(econ=level, rules=rules, turn=T, player_tier=tier_T,
                                 sp_fights_per_gold=round(tot / len(A["POLICY_ENSEMBLE"]), 2),
                                 method_G_x_H=G(tier_T) * A["H"][tier_T]))
    A = base_A
    write_csv("gold_value.csv", rows)
    return rows


def horizon_check(w):
    """Proposed fix: charge scaling at 100% of s*(F+1)/2 where F = fights from purchase to a
    target turn (10, 12 or 15) instead of H(t). If the formula is right, the HP surplus by the
    target turn should be near 0."""
    rows = []
    for level in ("no_econ", "standard", "econ_heavy"):
        rt = reach_turns(simulate(level))
        for tier in range(1, 6):
            for off in (0, 2):
                a = rt[tier] + off
                for name, kind, s, freq, label in SCALING_ARCHETYPES:
                    if kind not in ("self_turn", "self_combat"):
                        continue
                    for X in (10, 12, 15):
                        if a > X - 1:
                            continue
                        body, raw = priced_body(kind, s, freq, tier, f"horizon{X}", turn=a)
                        r = compare(level, tier, a, kind, s, freq, body, hold_mode="endo", w=w)
                        b100, _ = priced_body(kind, s, freq, tier, "budget100")
                        r100 = compare(level, tier, a, kind, s, freq, b100, hold_mode="endo", w=w)
                        rows.append(dict(econ=level, tier=tier, acquired=r["acquired"], archetype=name, target_turn=X,
                                         body_horizon=round(body, 2), body_raw_horizon=round(raw, 2),
                                         surplus_hp_at_target_horizon=r[f"surplus_hp_t{X}"],
                                         body_100=round(b100, 2), surplus_hp_at_target_100=r100[f"surplus_hp_t{X}"]))
    write_csv("horizon_pricing_check.csv", rows)
    return rows


def real_cards(w):
    """(f) Real HSBG pairs at printed stats, against the real immediate partner and against V(t)."""
    global A
    rows = []
    base_A = copy.deepcopy(A)
    for growth in (0.0, 2.5):
        A = copy.deepcopy(base_A)
        A["GENERIC_GROWTH_PER_TURN"] = growth
        ww = weights(simulate(A["REFERENCE_ECON"]))
        for pid, tier, sname, (sa, sh), kind, s, fg, iname, (ia, ih), note in REAL_PAIRS:
            for level in ("no_econ", "standard", "econ_heavy"):
                rt = reach_turns(simulate(level))
                a = rt[tier]
                freq = fg if kind == "self_combat" else None
                gold = fg if kind.startswith("gold") else 0
                for partner, ib in ((f"{iname} {ia}/{ih}", ia + ih), (f"plain V({tier})", V(tier))):
                    r = compare(level, tier, a, kind, s, freq, sa + sh, gold=gold, hold_mode="endo",
                                imm_body=ib, w=ww)
                    # Wrath Weaver: 1 damage to your own hero per trigger
                    self_dmg = {}
                    if pid == "wrath_weaver":
                        for X in (10, 12, 15):
                            v = next((q["tracked_value"] for q in reversed(r["_rb"][:X]) if q["tracked_value"] is not None), sa + sh)
                            self_dmg[X] = round((v - (sa + sh)) / s, 2)
                    body_m, raw_m = priced_body(kind, s, freq, tier, "budget" if kind.startswith("gold") else "budget100", gold=gold)
                    row = dict(pair=pid, tier=tier, scaling_card=f"{sname} {sa}/{sh}", versus=partner,
                               lobby_growth=growth, econ=level, method_body_for_this_text=round(raw_m, 2),
                               printed_body=sa + sh, note=note, **r)
                    for X in (10, 12, 15):
                        row[f"self_damage_t{X}"] = self_dmg.get(X, 0)
                        row[f"net_hp_t{X}"] = round(r[f"surplus_hp_t{X}"] - self_dmg.get(X, 0), 2)
                    rows.append(row)
    A = base_A
    write_csv("real_cards.csv", rows)
    return rows


# ---- Sensitivity -------------------------------------------------------------
def headline_metrics():
    ref = simulate(A["REFERENCE_ECON"])
    w = weights(ref)
    rt = reach_turns(ref)
    # M1/M2: T2 +1/+1 per turn bought turn 3, priced at 100%, standard econ, realistic hold
    body, _ = priced_body("self_turn", 2, None, 2, "budget100")
    card = compare(A["REFERENCE_ECON"], 2, 3, "self_turn", 2, None, body, hold_mode="card", w=w)
    endo = compare(A["REFERENCE_ECON"], 2, 3, "self_turn", 2, None, body, hold_mode="endo", w=w)
    # M3: T4 +2/+2 per turn at the tier-4 turn
    b4, _ = priced_body("self_turn", 4, None, 4, "budget100")
    e4 = compare(A["REFERENCE_ECON"], 4, rt[4], "self_turn", 4, None, b4, hold_mode="endo", w=w)
    # M4: T3 +1 gold per turn econ card
    bg, _ = priced_body("gold_per_turn", 0, None, 3, "budget", gold=1)
    eg = compare(A["REFERENCE_ECON"], 3, rt[3], "gold_per_turn", 0, None, bg, gold=1, hold_mode="endo", w=w)
    return {
        "T2 +1/+1/turn: cumulative crossover turn (SP)": card["cross_cum"],
        "T2 +1/+1/turn: HP surplus by turn 10": endo["surplus_hp_t10"],
        "T2 +1/+1/turn: hold (fights)": endo["hold_card"],
        "T4 +2/+2/turn: HP surplus by turn 12": e4["surplus_hp_t12"],
        "T3 +1 gold/turn: HP surplus by turn 12": eg["surplus_hp_t12"],
        "T3 +1 gold/turn: HP payback turn": eg["cross_cum_hp"],
    }


SENSITIVITY = [
    # name, path, low, high
    ("V(t) curve x0.85 / x1.15", "V", "scale0.85", "scale1.15"),
    ("H(t) placeholders -1 / +1", "H", "add-1", "add+1"),
    ("Scaling charge rate 0.5 / 1.5", "SCALING_CHARGE", 0.5, 1.5),
    ("Economy charge rate 0.25 / 1.0", "ECON_CHARGE", 0.25, 1.0),
    ("Replace-min-gain 0 / 4 SP", "REPLACE_MIN_GAIN", 0, 4),
    ("Keep lookahead 0 / 4 turns", "KEEP_LOOKAHEAD", 0, 4),
    ("Refresh sink 0 / 3 SP per refresh", "SINK_SP_PER_REFRESH", 0.0, 3.0),
    ("Generic unit growth 0 / 2.5 SP per turn (HSBG-like lobby)", "GENERIC_GROWTH_PER_TURN", 0.0, 2.5),
    ("Win-rate slope K 1.5 / 2.5", "WR_SLOPE_K", 1.5, 2.5),
    ("Survivors on loss 1 / 3", "SURVIVORS_ON_LOSS", 1, 3),
    ("Reference econ no_econ / econ_heavy", "REFERENCE_ECON", "no_econ", "econ_heavy"),
    ("Level policy greedy / patient", "LEVEL_KEEP", "greedy", "patient"),
    ("Bank until tier 6 off / on", "BANK_UNTIL_MAX_TIER", False, True),
]


def apply_change(path, val):
    if path == "V":
        f = float(val[5:])
        A["V"] = {t: round(v * f, 2) for t, v in A["V"].items()}
    elif path == "H":
        d = int(val[3:])
        A["H"] = {t: max(1, v + d) for t, v in A["H"].items()}
    elif path == "LEVEL_KEEP":
        if val == "greedy":
            A["LEVEL_KEEP"], A["LEVEL_WAIT"] = 0, 0
        else:
            A["LEVEL_KEEP"], A["LEVEL_WAIT"] = 6, 3
    else:
        A[path] = val


def sensitivity():
    global A
    base_A = copy.deepcopy(A)
    base = headline_metrics()
    rows = []
    for name, path, lo, hi in SENSITIVITY:
        res = {}
        for side, val in (("low", lo), ("high", hi)):
            A = copy.deepcopy(base_A)
            apply_change(path, val)
            res[side] = headline_metrics()
            A = copy.deepcopy(base_A)
        for m, b in base.items():
            l, h = res["low"][m], res["high"][m]
            num = [x for x in (l, h, b) if isinstance(x, (int, float))]
            swing = (max(num) - min(num)) if len(num) == 3 else None
            rows.append(dict(assumption=name, metric=m, base=b, low=l, high=h,
                             swing=round(swing, 3) if swing is not None else "n/a (no crossover)"))
    A = base_A
    # tornado ordering per metric
    rows.sort(key=lambda r: (r["metric"], -(r["swing"] if isinstance(r["swing"], (int, float)) else 1e9)))
    write_csv("sensitivity.csv", rows)
    return base, rows


def pace_scenarios():
    """How the answers change if the rest of the lobby scales (GENERIC_GROWTH_PER_TURN)."""
    global A
    base_A = copy.deepcopy(A)
    rows = []
    cases = [("eot_+1health", "self_turn", 1, None, 1), ("eot_+1/+1", "self_turn", 2, None, 2),
             ("eot_+1/+1", "self_turn", 2, None, 4), ("eot_+2/+2", "self_turn", 4, None, 4),
             ("combat_+1/+1_x1", "self_combat", 2, 1.0, 3), ("sot_gold_1", "gold_per_turn", 0, None, 3)]
    for g in (0.0, 1.0, 2.5):
        A = copy.deepcopy(base_A)
        A["GENERIC_GROWTH_PER_TURN"] = g
        ref = simulate(A["REFERENCE_ECON"])
        w = weights(ref)
        rt = reach_turns(ref)
        for name, kind, s, freq, tier in cases:
            gold = 1 if kind.startswith("gold") else 0
            for scheme in (("budget",) if gold else ("budget100", "hsbg_like")):
                body, _ = priced_body(kind, s, freq, tier, scheme, gold=gold)
                a = rt[tier] + (1 if tier == 2 else 0)
                r = compare(A["REFERENCE_ECON"], tier, a, kind, s, freq, body, gold=gold, hold_mode="endo", w=w)
                rows.append(dict(generic_growth=g, archetype=name, tier=tier, pricing=scheme, body=round(body, 2),
                                 acquired=r["acquired"], hold_card=r["hold_card"], hold_immediate=r["hold_immediate"],
                                 cross_cum_hp=r["cross_cum_hp"], surplus_hp_t10=r["surplus_hp_t10"],
                                 surplus_hp_t12=r["surplus_hp_t12"], surplus_hp_t15=r["surplus_hp_t15"],
                                 board_sp_t12_ref=next(q["board_sp"] for q in ref if q["turn"] == 12)))
    A = base_A
    write_csv("pace_scenarios.csv", rows)
    return rows


def main():
    reach = economy_tables()
    ref = simulate(A["REFERENCE_ECON"])
    w = weights(ref)
    weight_table(w)
    closed_form()
    grid = scaling_grid(w)
    head = headline(grid)
    traces(w)
    holds = hold_table(w)
    econ, cf = econ_cards(w)
    ebe = econ_break_even(w)
    caps = rate_caps(w)
    hz = horizon_check(w)
    gv = gold_value()
    real = real_cards(w)
    be = break_even(w)
    base, sens = sensitivity()
    pace = pace_scenarios()
    write_json("assumptions.json", {k: (v if not isinstance(v, dict) else {str(a): b for a, b in v.items()})
                                    for k, v in A.items()})
    write_json("summary.json", dict(
        tier_reach=reach, pricing_triggers_per_turn=round(pricing_triggers_per_turn(), 3),
        headline_metrics=base,
        scaling_archetypes=[dict(name=n, kind=k, s=s, freq=f, label=l) for n, k, s, f, l in SCALING_ARCHETYPES],
        econ_archetypes=[dict(name=n, kind=k, gold=g, tiers=t, label=l) for n, k, g, t, l in ECON_ARCHETYPES],
        outputs=sorted(p.name for p in OUT.iterdir())))
    print("wrote", len(list(OUT.iterdir())), "files to", OUT)
    for k, v in base.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
