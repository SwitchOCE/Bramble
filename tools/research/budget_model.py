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

Economy bounding (a separate run; write-up docs/design/economy-bounding.md):

    python -I tools/research/budget_model.py bound                      (about 2 minutes on 8 worker processes)
    python -I tools/research/budget_model.py bound check r=0.3 b=0.1 hnet=0.5 a=4   (one card's rates, a few seconds)

  One long Recruit Phase with no timer (rulebook 3.1.2). A player with a bank of gold and an engine package buys what
  is worth buying and refreshes until it can't pay. Compares paid-refresh price schedules (BOUND_SCHEDULES) across
  engine packages (BOUND_PACKAGES); assumptions are in the B block.
  bound_schedules.csv    price of each paid refresh; gold for N shops; shops from G gold
  bound_packages.csv     package x schedule x bank x policy: shops (p10/median/p90), effect refreshes, gold, units, SP,
                         SP per gold, actions, minutes, unbounded share, loop index at the target length and at the top price
  bound_summary.csv      the packages table pivoted: median (p90) shops by schedule, shops added over no engine, gold, units, SP
  bound_floor.csv        normal turns (10-14 gold) against banked turns: shops added by each engine, now and recommended
  bound_tiers.csv        the lines whose pieces exist below tier 6, at Tavern tiers 3, 4 and 6
  bound_sweeps.csv       pure refresher: shops against r (gold back per gold), b (free shops per shop), engine net gold
                         per shop, and a (free refreshes at the start of the turn)
  bound_limits.csv       the largest r, b and net gold per shop that keep a turn within 20 or 30 shops
  bound_window.csv       the smallest rate that gives 20 shops on a normal turn against the largest that keeps banked turns in bounds
  bound_econ_recheck.csv economy-card break-even (B5) with the original late-gold sink against a flat per-gold sink (B6)

Checks for power-budget.md v1 (print only, write nothing; single process):

    python -I tools/research/budget_model.py checks scaling 0 1 2.5     scaling charge below the cap, and its pace dependence
    python -I tools/research/budget_model.py checks econ 1.8 2.0 2.2 2.5 3.0   gold on a unit against the late sink
    python -I tools/research/budget_model.py checks reach               tier reach of income boards at the gold caps

This is a model, not a simulation of real games: there are no opponents' cards,
no triples, no tribes, no shop randomness. Its job is to make the trade-offs
visible and to say which assumptions matter.
"""
from __future__ import annotations

import copy
import csv
import json
import math
import random
import sys
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
    "SINK_SP_PER_GOLD": None,                            # [judgement] if set, leftover gold at tier 6 buys this many SP per gold (Tavern spells and units,
                                                         # not escalated) instead of SINK_SP_PER_REFRESH per refresh. None = the original model.
                                                         # The bounding model measures 1.7-2.0 SP per gold for a no-engine player (bound_packages.csv, policy "power").
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

# =============================================================================
# ASSUMPTIONS (economy bounding)  --  one long Recruit Phase with no timer.
# Run only this part with:  python -I tools/research/budget_model.py bound
# Quick check of one card or rate:  python -I tools/research/budget_model.py bound check r=0.3 b=0.1 hnet=0.5 a=4
# Write-up: docs/design/economy-bounding.md. Outputs: bound_*.csv.
# The player has a full board and a bank of gold. It buys what its policy says is worth buying, then
# refreshes (effect refreshes first, then free ones, then paid), until it can't pay and has nothing free left.
# =============================================================================
B = {
    "SEED": 7,                       # each cell seeds its own generator from SEED and the cell's names, so results don't depend on run order
    "RUNS": 400,                     # [judgement] Monte Carlo turns per cell
    "WORKERS": 8,                    # processes for the package runs; CLAUDE.md allows up to half the cores (12 of 24) without asking
    "CAP_SHOPS": 1000,               # [judgement] a turn that reaches this many shops counts as unbounded
    "BANKS": (10, 12, 14, 20, 30, 60),  # gold at the start of the long turn
    "REAL_BANKS": (10, 12, 14),      # [data] economy_timeline.csv: at tier 6 the main model's player spends 10 (standard), 12 (econ_heavy)
                                     # or 14 (high_roll) gold a turn and banks 0-1. These are the turns a player actually has.
                                     # 20 = one saved turn, or income plus a strong generator; 30 and 60 = banked turns (4.1.2, no cap) [judgement]
    "TARGET_SHOPS": (20, 30),        # owner, 2 Nov: the strongest engines see "about 20-30 shops" in a turn (target deferred later that day)
    "LEN_PAID": 30,                  # Lambda for turn length is taken at the price of this paid refresh (the target length), not the top price
    "LIMIT_P90": 45,                 # [judgement] proposed 90th-percentile limit at a 30-gold bank

    # ---- The shop (rulebook 6.1.1, 4.2.1, 4.3.3) -------------------------------
    "UNIT_COST": 3,                  # [rule] 4.2.1
    "SELL_BOUGHT": 1,                # [rule] 4.3.3
    "SELL_CREATED": 0,               # [rule] 4.3.3 (HSBG: 1). Packages may override with sell_created=1 to show the HSBG leak.
    # Unit slots and pool shares by Tavern tier. Tier 6 [data]: economy-engines.md appendix. Tiers 3 and 4 [data]: the tier-6
    # value times the ratio of the card's share at tier <= 3 or <= 4 to its share at tier <= 6, from minions.json / spells.json
    # (current pool, rulebook 5.1.2 copy counts, averaged over the 5-tribe lobbies that hold the card's tribe).
    # Refreshing Anomaly is tier 4, so the tier-3 free-source share is Sly Infiltrator alone. H_TRIBE = slots x one tribe's share.
    "TIER_SHOPS": {
        6: dict(UNIT_SLOTS=6, H_TRIBE=1.18, Q_FREE_SRC=0.0138, Q_LEAF=0.0111, Q_NAMED_T2=0.0088),
        4: dict(UNIT_SLOTS=5, H_TRIBE=0.91, Q_FREE_SRC=0.0186, Q_LEAF=0.0159, Q_NAMED_T2=0.0120),
        3: dict(UNIT_SLOTS=4, H_TRIBE=0.76, Q_FREE_SRC=0.0145, Q_LEAF=0.0299, Q_NAMED_T2=0.0175),
    },
    "Q_CG_SLOT": 0.0052,             # [data] Coast Guard (tier 5, 9 copies) per unit slot in a lobby with Pirates (~1,743 copies)
    "Q_CG_IN_PIRATES": 0.031,        # [data] its share of a Pirate-only shop: 9 of 292 Pirate copies (current Pirate pool; [judgement] for its own era)

    # ---- What a late shop is worth to a full tier-6 board ----------------------
    "P_BUFF_SPELL": 0.42,            # [data] 31 of the 73 current Tavern spells are stat buffs (spells.json, by card, not copy-weighted)
    "BUFF_SPELL_COST": 2,            # [data] median cost of those 31 spells
    "SPELL_SP_PER_GOLD": 5.0,        # [data][judgement] single-target buffs 4-6 SP per gold; team buffs 1.5-2.25 per target per gold
                                     # (analysis/spell_gold_to_stats_by_tier.csv). 5 is a middle value for a 7-unit board.
    "P_USEFUL_UNIT": 0.25,           # [judgement] chance a shop holds one unit worth buying for a full tier-6 board (upgrade, triple piece, synergy)
    "USEFUL_UNIT_SP": 4.0,           # [judgement] SP it adds. With P_USEFUL_UNIT this is 1 SP per shop, the same as A["SINK_SP_PER_REFRESH"].
    "CREATED_UNIT_SP": 3.0,          # [judgement] SP of a random generated unit to a full board: it rarely beats the weakest unit, sometimes completes a triple
    "BOUNTY_SP": {"Healthy": 16, "Hostile": 16, "Selfish": 12},  # [data] spells.json: four minions +4 Health / +4 Attack; left-most +6/+6
    "BOUNTY_GOLD": {"Wealthy": 2},   # [data] "Gain 2 Gold."
    # Friendly Bounty makes one Created unit. The pick among the five is uniform [judgement: HSBG weights undocumented].

    # ---- Clicks and time (player experience) -----------------------------------
    # Actions counted: a refresh click; buy, play and sell of each bought unit; buy and cast of each spell; one cast per Bounty
    # (Privateer's extra casts are automatic); play and sell of each Created unit, which is how a player clears a 10-card hand
    # (rulebook 7.1.1; 4.3.7 says units in hand can't be sold, so a spare board slot is the only way out).
    "SEC_PER_SHOP": 4.0,             # [judgement] reading a refilled shop of 7 cards
    "SEC_PER_ACTION": 1.5,           # [judgement] one drag or click
}

# Paid-refresh price schedules. steps: (paid refreshes already made this turn, price from then on).
# tail: None (price stays at the last step), ("add", start, every, amount) or ("double", start, every).
# "start" is the number of paid refreshes already made when the first increase applies (30 = the 31st refresh).
# Not the same as the R3 loop model's schedules (economy-engines.md appendix): R3's "Bstep" adds 1 every 10 from the first
# refresh. This model supersedes R3's.
BOUND_SCHEDULES = [
    ("bg_flat1",         "HSBG reference: always 1",                       [(0, 1)], None),
    ("s123_10_20",       "Bramble now: 1/2/3 at 10/20",                    [(0, 1), (10, 2), (20, 3)], None),
    ("s12345_10_40",     "1/2/3/4/5 at 10/20/30/40",                       [(0, 1), (10, 2), (20, 3), (30, 4), (40, 5)], None),
    ("s123_5_10",        "1/2/3 at 5/10",                                  [(0, 1), (5, 2), (10, 3)], None),
    ("s12345_5_20",      "1/2/3/4/5 at 5/10/15/20",                        [(0, 1), (5, 2), (10, 3), (15, 4), (20, 5)], None),
    ("s123_plus1_nocap", "1/2/3 at 10/20, then +1 every 5 from the 31st, no cap", [(0, 1), (10, 2), (20, 3)], ("add", 30, 5, 1)),
    ("s123_plus1_from26", "1/2/3 at 10/20, then +1 every 5 from the 26th, no cap", [(0, 1), (10, 2), (20, 3)], ("add", 25, 5, 1)),
    ("s123_plus2_from26", "1/2/3 at 10/20, then +2 every 5 from the 26th, no cap", [(0, 1), (10, 2), (20, 3)], ("add", 25, 5, 2)),
    ("s123_double",      "1/2/3 at 10/20, then doubles every 5 from the 31st", [(0, 1), (10, 2), (20, 3)], ("double", 30, 5)),
    ("owner_15_plus1_5", "Owner 2 Nov: 1 for refreshes 1-15, then +1 every 5 (2 at 16-20, 3 at 21-25, ...), no cap",
                         [(0, 1)], ("add", 15, 5, 1)),
    ("s12345_plus1_10",  "1/2/3/4/5 at 10/20/30/40, then +1 every 10 from the 51st, no cap",
                         [(0, 1), (10, 2), (20, 3), (30, 4), (40, 5)], ("add", 50, 10, 1)),
]
BOUND_RECOMMENDED = "s123_plus1_nocap"

# Engine packages. Classes ("player"):
#   no engine; average (plain engine cards); strong (the strongest plausible board: see BOARD RULE); ceiling (legal but rare:
#   breaks the board rule); anomaly (a lobby-wide modifier from the library, with or without engines); library (another legal
#   line from the library or a past pool); bramble (a hypothetical Bramble card shape); stress (one rule or one card away).
# BOARD RULE [judgement, proposed]: at most one golden plus one plain copy of any tier-5 or tier-6 card (4 of its 7-9 copies),
#   one retrigger (golden Brann counts as one), the hero's power, one anomaly, one trinket.
#
# Components (any mix):
#   spend=[...]   "after you spend N gold": kind "bounty" (Sky Admiral Rogers), "card" (Fleet Admiral Tethys), "stats"
#                 (Gunpowder Courier), "gold" (abstract gold back), "free" (gain `per` free Refreshes). copies = how many such
#                 cards, per = Bounties/cards/refreshes per trigger, mult = casts per Bounty (Proud Privateer).
#   tribe=dict(h, refund, free_on_play, absent_free, smart)
#                 tribe units in the shop (h per shop, a key into TIER_SHOPS or a number). The player buys them: refund = gold per
#                 tribe unit bought (Cap'n Hoggarr); free_on_play = free Refreshes per tribe unit played (Recycling Sticker);
#                 absent_free = refreshes are free while the shop has no tribe unit (Pigeon Lord). smart = buy only when it costs
#                 no more than the next paid refresh (otherwise always buy, as the Hoggarr lines did in revision 1).
#   free_src=dict(q, F, mult, set)   a shop unit (share q per slot) whose Battlecry gives F free refreshes, times mult (Brann).
#                 set=True: "set, don't add" (proposed G5): the grant sets the free count to F instead of adding F x mult.
#   leaf=dict(q, F, mult, set)       a shop spell (share q of the spell slot) giving F free refreshes, cast mult times.
#   coin_src=dict(q, gold, mult)     a shop unit giving gold on Battlecry, times mult.
#   buy_refresh=True, unit_cost=2, no_paid=True   Golganneth's Tempest: units cost 2, no Refresh action, the shop refreshes
#                 itself after each buy (an effect refresh: free and uncounted, rulebook 4.4.6).
#   conc=dict(q, q_in)              Coast Guard: "When you sell this, Refresh the Tavern with Pirates, then steal one." q per slot
#                 in a normal shop, q_in per slot in a Pirate-only shop. The refresh is an effect refresh.
#   board=dict(r, b, hnet)          a designer's own rates for a card on the board: gold back per gold spent, free shops per shop,
#                 gold per shop. Use this (or `bound check`) for a mechanic none of the kinds above covers.
#   start_free=a                    free refreshes at the start of the turn (an additive engine: a fixed number, not a rate)
# Card text from docs/research/battlegrounds/data/*.json; the packages are [judgement].
BOUND_PACKAGES = [
    dict(name="none", player="no engine", label="No engine: buys spells and useful units, refreshes until broke"),
    dict(name="avg_pirates", player="average",
         label="Plain Rogers + plain Privateer (Bounties cast twice)",
         spend=[dict(kind="bounty", N=9, copies=1, per=1, mult=2)]),
    dict(name="avg_mixed", player="average",
         label="Plain Tethys + plain Gunpowder Courier (4 Pirates) + Refreshing Anomaly, no Brann",
         spend=[dict(kind="card", N=10, copies=1, per=1), dict(kind="stats", N=5, copies=1, sp=16)],
         free_src=dict(q="Q_FREE_SRC", F=2, mult=1)),
    dict(name="avg_spendfree", player="bramble",
         label="Plain 'After you spend 5 Gold, gain a free Refresh' (a Bramble shape, no such BG card)",
         spend=[dict(kind="free", N=5, copies=1, per=1)]),
    dict(name="strong_rogers", player="strong",
         label="Golden Rogers + golden Privateer (Bounties cast 3 times)",
         spend=[dict(kind="bounty", N=9, copies=1, per=2, mult=3)]),
    dict(name="strong_rogers_hoggarr", player="strong",
         label="Golden Rogers + golden Privateer + Hoggarr hero (+1 gold per Pirate bought)",
         spend=[dict(kind="bounty", N=9, copies=1, per=2, mult=3)], tribe=dict(h="H_TRIBE", refund=1)),
    dict(name="strong_brann", player="strong",
         label="Refreshing Anomaly / Sly Infiltrator + golden Brann (x3) + Leaf cast twice",
         free_src=dict(q="Q_FREE_SRC", F=2, mult=3), leaf=dict(q="Q_LEAF", F=2, mult=2)),
    dict(name="strong_brann_set", player="strong",
         label="strong_brann under 'set, don't add' (G5): each grant sets the free count to 2",
         free_src=dict(q="Q_FREE_SRC", F=2, mult=3, set=True), leaf=dict(q="Q_LEAF", F=2, mult=2, set=True)),
    dict(name="strong_scaler", player="strong",
         label="Golden Gunpowder Courier (+6/+2 to 5 Pirates) + golden Tethys",
         spend=[dict(kind="stats", N=5, copies=1, sp=40), dict(kind="card", N=10, copies=1, per=2)]),
    dict(name="strong_coin", player="strong",
         label="Shell Collector (Battlecry: Tavern Coin) + golden Brann (x3)",
         coin_src=dict(q="Q_NAMED_T2", gold=1, mult=3)),
    dict(name="strong_spendfree", player="bramble",
         label="Golden 'After you spend 5 Gold, gain 2 free Refreshes' (rulebook 7.3.5: numbers double, thresholds don't)",
         spend=[dict(kind="free", N=5, copies=1, per=2)]),
    dict(name="strong_sticker", player="library",
         label="Recycling Sticker ('After you play an Elemental, gain a free Refresh'), buys Elementals when cheaper than a paid refresh",
         tribe=dict(h="H_TRIBE", refund=0, free_on_play=1, smart=True)),
    dict(name="strong_pigeon_rogers", player="library",
         label="Pigeon Lord (refreshes free while the shop has no Pirate) + golden Rogers + golden Privateer; buys out Pirates",
         spend=[dict(kind="bounty", N=9, copies=1, per=2, mult=3)], tribe=dict(h="H_TRIBE", refund=0, absent_free=True, smart=True)),
    dict(name="b035_free_src", player="bramble",
         label="A free-refresh unit at the G7 limit: 'gain 2 free Refreshes' at 2.92% of slots, b = 0.35 gross, adding",
         free_src=dict(q=0.35 / 12, F=2, mult=1)),
    dict(name="bramble_additive8", player="bramble",
         label="'Start of turn: gain 4 free Refreshes', golden (8): an additive engine, a fixed count per turn",
         start_free=8),
    # "ceiling": the best legal board, which needs six Rogers copies of a pool of 7 (rulebook 5.1.2): rare [judgement]
    dict(name="ceiling_2rogers", player="ceiling",
         label="Two golden Rogers + golden Privateer (Bounties cast 3 times)",
         spend=[dict(kind="bounty", N=9, copies=2, per=2, mult=3)]),
    dict(name="ceiling_2rogers_hoggarr", player="ceiling",
         label="Two golden Rogers + golden Privateer + Hoggarr hero (+1 gold per Pirate bought)",
         spend=[dict(kind="bounty", N=9, copies=2, per=2, mult=3)], tribe=dict(h="H_TRIBE", refund=1)),
    dict(name="golganneth_none", player="anomaly",
         label="Golganneth's Tempest anomaly, no engine (units cost 2; the shop refreshes itself after each buy)",
         buy_refresh=True, unit_cost=2, no_paid=True),
    dict(name="golganneth_hoggarr", player="anomaly",
         label="Golganneth's Tempest + Hoggarr hero (+1 per Pirate bought)",
         buy_refresh=True, unit_cost=2, no_paid=True, tribe=dict(h="H_TRIBE", refund=1)),
    dict(name="golganneth_hoggarr_rogers", player="anomaly",
         label="Golganneth's Tempest + Hoggarr hero + golden Rogers + golden Privateer",
         buy_refresh=True, unit_cost=2, no_paid=True, tribe=dict(h="H_TRIBE", refund=1),
         spend=[dict(kind="bounty", N=9, copies=1, per=2, mult=3)]),
    dict(name="coastguard_hoggarr_rogers", player="library",
         label="Coast Guard in pool (2024-25) + Hoggarr hero + golden Rogers + golden Privateer; Coast Guard rebought and sold",
         spend=[dict(kind="bounty", N=9, copies=1, per=2, mult=3)], tribe=dict(h="H_TRIBE", refund=1),
         conc=dict(q="Q_CG_SLOT", q_in="Q_CG_IN_PIRATES")),
    dict(name="stress_sticker_refund", player="stress",
         label="Recycling Sticker + a Hoggarr for Elementals (+1 gold per Elemental bought)",
         tribe=dict(h="H_TRIBE", refund=1, free_on_play=1, smart=True)),
    dict(name="stress_brann_x4", player="stress",
         label="strong_brann with golden Brann read as x4 (rulebook 7.3.5 open)",
         free_src=dict(q="Q_FREE_SRC", F=2, mult=4), leaf=dict(q="Q_LEAF", F=2, mult=2)),
    dict(name="stress_rogers_hoggarr_bgsell", player="stress",
         label="ceiling_2rogers_hoggarr with HSBG sell values (Created units sell for 1)",
         spend=[dict(kind="bounty", N=9, copies=2, per=2, mult=3)], tribe=dict(h="H_TRIBE", refund=1), sell_created=1),
    dict(name="stress_hoggarr_concentrated", player="stress",
         label="Golden + plain Hoggarr (+3 per Pirate), every shop all Pirates, each shop paid for as a refresh",
         tribe=dict(h=6, refund=3)),
    dict(name="stress_common_free_src", player="stress",
         label="A common free-refresh unit (3% of slots, 'gain 2 free Refreshes') + golden Brann (x3)",
         free_src=dict(q=0.03, F=2, mult=3)),
]
# Run at Tavern tiers 3, 4 and 6 (bound_tiers.csv): lines whose pieces exist below tier 6. Golden Brann is tier 5, so these use
# no retrigger, or Brann's Blessing (tier-4 spell: "Your Battlecries trigger twice until next turn") read as active all turn.
BOUND_TIER_PACKAGES = [
    dict(name="none", player="no engine", label="No engine"),
    dict(name="t_free", player="average", label="Refreshing Anomaly / Sly Infiltrator + Leaf, no retrigger",
         free_src=dict(q="Q_FREE_SRC", F=2, mult=1), leaf=dict(q="Q_LEAF", F=2, mult=1)),
    dict(name="t_free_blessing", player="strong", label="Same, Battlecries x2 (Brann's Blessing)",
         free_src=dict(q="Q_FREE_SRC", F=2, mult=2), leaf=dict(q="Q_LEAF", F=2, mult=1)),
    dict(name="t_coin", player="average", label="Shell Collector, no retrigger", coin_src=dict(q="Q_NAMED_T2", gold=1, mult=1)),
    dict(name="strong_sticker", player="library", label="Recycling Sticker, buys Elementals when cheaper than a paid refresh",
         tribe=dict(h="H_TRIBE", refund=0, free_on_play=1, smart=True)),
    dict(name="stress_sticker_refund", player="stress", label="Recycling Sticker + a Hoggarr for Elementals",
         tribe=dict(h="H_TRIBE", refund=1, free_on_play=1, smart=True)),
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
        elif A.get("SINK_SP_PER_GOLD") is not None:
            sink += gold * A["SINK_SP_PER_GOLD"]  # spells and units at a flat price: every leftover gold is used
            gold = 0
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


# =============================================================================
# Economy bounding: one long Recruit Phase with no timer (assumptions in B)
# =============================================================================
def bound_price(steps, tail, n):
    """Price of the next paid refresh after n paid refreshes this turn."""
    p = steps[0][1]
    for start, price in steps:
        if n >= start:
            p = price
    if tail and n >= tail[1]:
        k = 1 + (n - tail[1]) // tail[2]
        if tail[0] == "add":
            p = steps[-1][1] + tail[3] * k
        elif tail[0] == "double":
            p = steps[-1][1] * 2 ** min(k, 40)
    return p


def top_price(steps, tail):
    return math.inf if tail else steps[-1][1]


def len_price(steps, tail):
    """The price that applies at the target length: the LEN_PAID-th paid refresh."""
    return bound_price(steps, tail, B["LEN_PAID"] - 1)


def _shop(tier=6):
    return B["TIER_SHOPS"][tier]


def _bq(v, sh=None):
    """A package share given as a key into the tier's shop table, or as a number."""
    if not isinstance(v, str):
        return v
    sh = sh or _shop()
    return sh[v] if v in sh else B[v]


def pure_turn(steps, tail, G, r=0.0, b=0.0, hnet=0.0, a=0):
    """Expected-value turn for a pure refresher: no buys except what hnet stands for.
    r = gold back per gold spent on refreshes; b = free shops per shop; hnet = net gold per shop;
    a = free refreshes at the start of the turn (an additive engine)."""
    cap = B["CAP_SHOPS"]
    g, paid, free, shops, spent = float(G), 0, float(a), 0, 0.0
    while shops < cap:
        if free >= 1 - 1e-9:
            free -= 1
        else:
            p = bound_price(steps, tail, paid)
            if g < p - 1e-9:
                break
            g += p * (r - 1)
            spent += p
            paid += 1
        shops += 1
        free += b
        g += hnet
    return dict(shops=shops, paid=paid, free=shops - paid, spent=round(spent, 2), unbounded=shops >= cap)


def package_rates(pkg, tier=6, p=3.0, spend_free=True):
    """r, b and engine net gold per shop from a package's text (expected values) at refresh price p.
    A spend counter that grants free refreshes ("after you spend N gold, gain a free Refresh") gives per/N free shops per gold,
    so p*per/N per paid refresh: its share of free shops, (f + s) / (1 + s), rises with the price. Those free shops can't
    pay for themselves, so spend_free=False leaves them out (the finiteness check)."""
    sh = _shop(tier)
    slots = sh["UNIT_SLOTS"]
    sell_c = pkg.get("sell_created", B["SELL_CREATED"])
    cost, sell = pkg.get("unit_cost", B["UNIT_COST"]), B["SELL_BOUGHT"]
    r = s_free = 0.0
    for e in pkg.get("spend", []):
        if e["kind"] == "bounty":
            r += e["copies"] * e["per"] * e["mult"] * (0.2 * B["BOUNTY_GOLD"]["Wealthy"] + 0.2 * sell_c) / e["N"]
        elif e["kind"] == "card":
            r += e["copies"] * e["per"] * sell_c / e["N"]
        elif e["kind"] == "gold":
            r += e["copies"] * e["gold"] / e["N"]
        elif e["kind"] == "free":
            s_free += e["copies"] * e["per"] / e["N"]
    bd = pkg.get("board", {})
    r += bd.get("r", 0.0)
    f, hnet = bd.get("b", 0.0), bd.get("hnet", 0.0)
    if "free_src" in pkg:
        fs = pkg["free_src"]
        F = fs["F"] if fs.get("set") else fs["F"] * fs["mult"]
        f += slots * _bq(fs["q"], sh) * F
        hnet += slots * _bq(fs["q"], sh) * (sell - cost + cost * r)
    if "leaf" in pkg:
        ls = pkg["leaf"]
        F = ls["F"] if ls.get("set") else ls["F"] * ls["mult"]
        f += _bq(ls["q"], sh) * F
        hnet += _bq(ls["q"], sh) * (-1 + r)
    if "coin_src" in pkg:
        c = pkg["coin_src"]
        hnet += slots * _bq(c["q"], sh) * (c["gold"] * c["mult"] + sell - cost + cost * r)
    if "tribe" in pkg:
        t = pkg["tribe"]
        h = _bq(t["h"], sh)
        per_unit = t.get("refund", 0) + sell - cost + cost * r
        if pkg.get("buy_refresh"):
            # one buy per shop: a tribe unit when the shop has one, otherwise any unit
            p_tribe = 1 - (1 - h / slots) ** slots
            hnet += p_tribe * t.get("refund", 0)
        else:
            f += h * t.get("free_on_play", 0) + (1.0 if t.get("absent_free") else 0.0)
            hnet += h * per_unit
    if pkg.get("buy_refresh"):
        # Golganneth's Tempest: each shop costs one buy (cost) and gives back sell + spend returns + any refund
        hnet += sell - cost + cost * r
        return r, 0.0, hnet, cost
    s = s_free * p if spend_free else 0.0
    b = (f + s) / (1 + s)
    return r, b, hnet, p


def loop_index(r, b, hnet, p):
    """Loop index Lambda = 1 - (net gold lost per shop) / p, at refresh price p. Expected shops per gold = 1 / (p (1 - Lambda)),
    and the turn is finite (in expectation) iff Lambda < 1.
    For b < 1 this is 1 - (1-r)(1-b) + hnet/p: per paid refresh the player pays p(1-r) and gets 1/(1-b) shops, each worth hnet.
    For b >= 1 no shop needs paying for, so the turn ends only if the engine's own pieces cost gold (hnet < 0): 1 + hnet/p.
    Taken at the price of the target length (len_price) it measures turn length. Taken at the top price it measures finiteness;
    with no cap on the price, hnet/p -> 0 there, so a refund loop is always finite but can still be long."""
    if r >= 1:
        return math.inf
    if b >= 1:
        return math.inf if hnet >= 0 else 1 + hnet / p
    if p == math.inf:
        return 1 - (1 - r) * (1 - b)
    return 1 - (1 - r) * (1 - b) + hnet / p


def package_lambdas(pkg, steps, tail, tier=6):
    """(r, b, hnet, Lambda at the target-length price, Lambda at the top price) for a package under a schedule."""
    if pkg.get("buy_refresh"):
        # the buy is the shop's price, and hnet already nets it (and its spend returns): Lambda = 1 + hnet / cost
        r, b, hnet, p = package_rates(pkg, tier)
        lam = 1 + hnet / p
        return r, b, hnet, lam, lam
    pl, pt = len_price(steps, tail), top_price(steps, tail)
    r, b, hnet, _ = package_rates(pkg, tier, pl)
    lam_len = loop_index(r, b, hnet, pl)
    r2, b2, h2, _ = package_rates(pkg, tier, pl, spend_free=False)
    lam_top = loop_index(r2, b2, h2, pt if pt != math.inf else math.inf)
    if pt == math.inf and b2 >= 1:
        lam_top = loop_index(r2, b2, h2, pl)  # price doesn't matter once every shop is free
    return r, b, hnet, lam_len, lam_top


def mc_turn(steps, tail, G, pkg, rng, policy="power", tier=6):
    """One long Recruit Phase, Monte Carlo. Returns a dict of totals.
    policy "power": buys every positive-value card (buff spells, useful units, engine pieces).
    policy "loop": buys engine pieces only and puts all other gold into refreshes (the longest turn)."""
    sh = _shop(tier)
    slots = sh["UNIT_SLOTS"]
    cap = B["CAP_SHOPS"]
    cost, sell = pkg.get("unit_cost", B["UNIT_COST"]), B["SELL_BOUGHT"]
    sell_c = pkg.get("sell_created", B["SELL_CREATED"])
    st = dict(g=float(G), spent=0.0, returned=0.0, bought=0, created=0, sp=0.0, actions=0)
    engines = [(e, [0.0] * e["copies"]) for e in pkg.get("spend", [])]
    bounty_kinds = ("Friendly", "Healthy", "Hostile", "Selfish", "Wealthy")
    bd = pkg.get("board", {})
    ctr = dict(paid=0, free=float(pkg.get("start_free", 0)), frac=0.0)
    pending = []  # queued effect refreshes (rulebook 4.4.6: free, uncounted), by shop kind
    no_paid = pkg.get("no_paid", False)

    def gain(x):
        st["g"] += x
        st["returned"] += x

    def created(n):
        st["actions"] += 2 * n  # play it to a spare slot and sell it, to keep the 10-card hand clear
        if sell_c > 0:
            gain(n * sell_c)  # HSBG: generated units are sold for gold
        else:
            st["created"] += n
            st["sp"] += n * B["CREATED_UNIT_SP"]

    def trigger(e):
        if e["kind"] == "bounty":
            for _ in range(e["per"]):
                st["actions"] += 1  # cast it; Privateer's extra casts are automatic
                k = bounty_kinds[rng.randrange(5)]
                for _ in range(e["mult"]):
                    if k == "Friendly":
                        created(1)
                    elif k == "Wealthy":
                        gain(B["BOUNTY_GOLD"]["Wealthy"])
                    else:
                        st["sp"] += B["BOUNTY_SP"][k]
        elif e["kind"] == "card":
            created(e["per"])
        elif e["kind"] == "stats":
            st["sp"] += e["sp"]
        elif e["kind"] == "gold":
            gain(e["gold"])
        elif e["kind"] == "free":
            ctr["free"] += e["per"]

    def pay(x):
        st["g"] -= x
        st["spent"] += x
        if bd.get("r"):
            gain(x * bd["r"])
        for e, counters in engines:
            for i in range(len(counters)):
                counters[i] += x
                while counters[i] >= e["N"] - 1e-9:
                    counters[i] -= e["N"]
                    trigger(e)

    def grant(spec):
        if spec.get("set"):
            ctr["free"] = max(ctr["free"], spec["F"])  # proposed G5: a grant sets the count, a retrigger re-sets it
        else:
            ctr["free"] += spec["F"] * spec["mult"]

    def next_price():
        return math.inf if no_paid else bound_price(steps, tail, ctr["paid"])

    def buy_unit():
        pay(cost)
        st["bought"] += 1
        st["actions"] += 3  # buy, play, sell (it, or the unit it replaces)
        gain(sell)

    fs, ls, cs, tr, cg = pkg.get("free_src"), pkg.get("leaf"), pkg.get("coin_src"), pkg.get("tribe"), pkg.get("conc")
    q_free = _bq(fs["q"], sh) if fs else 0.0
    q_coin = _bq(cs["q"], sh) if cs else 0.0
    q_tribe = (_bq(tr["h"], sh) / slots) if tr else 0.0
    q_leaf = _bq(ls["q"], sh) if ls else 0.0
    q_cg = _bq(cg["q"], sh) if cg else 0.0
    q_cg_in = _bq(cg["q_in"], sh) if cg else 0.0

    def buy_tribe():
        buy_unit()
        gain(tr.get("refund", 0))
        if tr.get("free_on_play"):
            ctr["free"] += tr["free_on_play"]

    def worth_tribe(k=1):
        """smart buying: k tribe units are worth buying for their refresh if they cost no more than the next paid refresh"""
        if not tr.get("smart"):
            return True
        net = k * (cost - sell - tr.get("refund", 0))
        return net <= 0 or net <= next_price()

    def visit_shop(kind="normal"):
        """Buy what the policy wants from one shop. Returns True if tribe units are left in it (Pigeon Lord)."""
        x = rng.random()  # the spell slot
        if x < q_leaf:
            if st["g"] >= 1:
                pay(1)
                st["actions"] += 2
                grant(ls)
        elif x < q_leaf + B["P_BUFF_SPELL"] and policy == "power":
            c = B["BUFF_SPELL_COST"]
            if st["g"] >= c:
                pay(c)
                st["actions"] += 2
                st["sp"] += c * B["SPELL_SP_PER_GOLD"]
        n_tribe = n_cg = 0
        for _ in range(slots):
            x = rng.random()
            if kind == "tribe_only":
                if x < q_cg_in:
                    n_cg += 1
                else:
                    n_tribe += 1
                continue
            if x < q_free:
                if st["g"] >= cost:
                    buy_unit()
                    grant(fs)
            elif x < q_free + q_coin:
                if st["g"] >= cost:
                    buy_unit()
                    gain(cs["gold"] * cs["mult"])
            elif x < q_free + q_coin + q_tribe:
                n_tribe += 1
            elif x < q_free + q_coin + q_tribe + q_cg:
                n_cg += 1
        left = False
        if tr and n_tribe:
            if tr.get("absent_free"):
                if worth_tribe(n_tribe) and st["g"] >= n_tribe * cost:
                    for _ in range(n_tribe):
                        buy_tribe()
                else:
                    left = True
            else:
                for _ in range(n_tribe):
                    if st["g"] >= cost and worth_tribe():
                        buy_tribe()
        for _ in range(n_cg):  # Coast Guard: bought last, because selling it refreshes the shop
            if st["g"] >= cost:
                buy_tribe()  # it is a Pirate: the refund applies, then it is sold
                pending.append("tribe_only")
                if rng.random() < q_cg_in:  # the stolen Pirate is another Coast Guard (Created: sells for 0, still refreshes)
                    st["actions"] += 2
                    pending.append("tribe_only")
                else:
                    created(1)
        if rng.random() < B["P_USEFUL_UNIT"] and st["g"] >= cost and policy == "power":
            buy_unit()
            st["sp"] += B["USEFUL_UNIT_SP"]
        return left

    paid = free_used = effect = shops = 0
    tribe_left = False if pkg.get("buy_refresh") else visit_shop()  # the opening shop (not counted)
    while shops < cap:
        kind = "normal"
        if pending:
            kind = pending.pop()
            effect += 1
        elif pkg.get("buy_refresh"):
            # Golganneth's Tempest: one buy, then the shop refreshes itself
            has_tribe = tr is not None and any(rng.random() < q_tribe for _ in range(slots))
            spell = rng.random() < B["P_BUFF_SPELL"]
            if has_tribe and st["g"] >= cost:
                buy_tribe()
            elif policy == "power" and spell and st["g"] >= B["BUFF_SPELL_COST"]:
                pay(B["BUFF_SPELL_COST"])
                st["actions"] += 2
                st["sp"] += B["BUFF_SPELL_COST"] * B["SPELL_SP_PER_GOLD"]
            elif st["g"] >= cost:
                buy_unit()
                if policy == "power" and rng.random() < B["P_USEFUL_UNIT"]:
                    st["sp"] += B["USEFUL_UNIT_SP"]
            else:
                break
            effect += 1
        elif ctr["free"] >= 1 - 1e-9:
            ctr["free"] -= 1
            free_used += 1
            st["actions"] += 1
        elif tr and tr.get("absent_free") and not tribe_left:
            free_used += 1  # Pigeon Lord: the shop has none of the type, so this refresh is free
            st["actions"] += 1
        else:
            p = next_price()
            if st["g"] < p:
                break
            pay(p)
            paid += 1
            ctr["paid"] = paid
            st["actions"] += 1
        shops += 1
        if bd.get("b"):
            ctr["frac"] += bd["b"]
            while ctr["frac"] >= 1:
                ctr["frac"] -= 1
                ctr["free"] += 1
        if bd.get("hnet"):
            if bd["hnet"] > 0:
                gain(bd["hnet"])
            else:
                st["g"] += bd["hnet"]
                st["spent"] -= bd["hnet"]
        if not pkg.get("buy_refresh"):
            tribe_left = visit_shop(kind)
    minutes = ((shops + 1) * B["SEC_PER_SHOP"] + st["actions"] * B["SEC_PER_ACTION"]) / 60
    return dict(shops=shops, paid=paid, free=free_used, effect=effect, spent=st["spent"], returned=st["returned"],
                bought=st["bought"], created=st["created"], sp=st["sp"], gold_left=st["g"], actions=st["actions"],
                minutes=minutes, unbounded=shops >= cap)


def _pct(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(q * len(xs)))]


def _sched(name):
    return next(s for s in BOUND_SCHEDULES if s[0] == name)


def bound_cell(args):
    """One package x schedule x bank x policy x tier cell: RUNS Monte Carlo turns. Top level so worker processes can run it."""
    pkg, sched, G, policy, tier = args
    name, label, steps, tail = sched
    rng = random.Random(f"{B['SEED']}|{pkg['name']}|{name}|{G}|{policy}|{tier}")
    r, b, hnet, lam_len, lam_top = package_lambdas(pkg, steps, tail, tier)
    res = []
    for i in range(B["RUNS"]):
        res.append(mc_turn(steps, tail, G, pkg, rng, policy, tier))
        if i == 19 and all(x["unbounded"] for x in res):
            break  # every run so far hit the cap: call it unbounded and move on
    n = len(res)
    shops = [x["shops"] for x in res]
    mean = lambda k: round(sum(x[k] for x in res) / n, 1)
    spent = sum(x["spent"] for x in res) / n
    fmt = lambda v: "inf" if v == math.inf else round(v, 3)
    return dict(
        package=pkg["name"], player=pkg["player"], schedule=name, tier=tier, bank=G, policy=policy,
        shops_p10=_pct(shops, 0.1), shops_median=_pct(shops, 0.5), shops_p90=_pct(shops, 0.9),
        paid_median=_pct([x["paid"] for x in res], 0.5), free_median=_pct([x["free"] for x in res], 0.5),
        effect_median=_pct([x["effect"] for x in res], 0.5),
        gold_spent_mean=round(spent, 1), gold_returned_mean=mean("returned"),
        units_bought_mean=mean("bought"), units_created_mean=mean("created"),
        sp_gained_mean=mean("sp"), sp_per_gold=round(sum(x["sp"] for x in res) / n / spent, 2) if spent else 0.0,
        actions_mean=mean("actions"), minutes_median=round(_pct([x["minutes"] for x in res], 0.5), 1),
        minutes_p90=round(_pct([x["minutes"] for x in res], 0.9), 1),
        share_unbounded=round(sum(x["unbounded"] for x in res) / n, 3), runs=n,
        r=round(r, 3), b=round(b, 3), engine_net_gold_per_shop=round(hnet, 3),
        loop_index=fmt(lam_len), loop_index_top=fmt(lam_top), label=pkg["label"])


def _run_cells(cells):
    if B["WORKERS"] > 1:
        import multiprocessing
        with multiprocessing.Pool(B["WORKERS"]) as pool:
            return pool.map(bound_cell, cells, chunksize=4)
    return [bound_cell(c) for c in cells]


def bound_schedule_table():
    rows = []
    for name, label, steps, tail in BOUND_SCHEDULES:
        prices = [bound_price(steps, tail, n) for n in range(60)]
        cum = [sum(prices[:k]) for k in range(61)]
        row = dict(schedule=name, label=label, top_price=top_price(steps, tail), price_at_target=len_price(steps, tail),
                   prices_1_to_50=" ".join(str(p) for p in prices[:50]))
        for k in (10, 15, 20, 25, 30, 40, 50):
            row[f"gold_for_{k}_shops"] = cum[k]
        for G in (10, 12, 14, 20, 30, 40, 60, 100):
            row[f"shops_from_{G}"] = pure_turn(steps, tail, G)["shops"]
        rows.append(row)
    write_csv("bound_schedules.csv", rows)
    return rows


def _search(steps, tail, G, param, ok, hi, step):
    """Largest value of param (from 0 up in steps) for which ok(shops) still holds; None if it fails at 0."""
    best, v = None, 0.0
    while v <= hi + 1e-9:
        if ok(pure_turn(steps, tail, G, **{param: v})["shops"]):
            best = round(v, 2)
        else:
            break
        v += step
    return best


def _search_min(steps, tail, G, param, ok, hi, step):
    """Smallest value of param for which ok(shops) holds; None if none up to hi."""
    v = 0.0
    while v <= hi + 1e-9:
        if ok(pure_turn(steps, tail, G, **{param: v})["shops"]):
            return round(v, 2)
        v += step
    return None


SEARCH = (("r", 0.99, 0.01), ("b", 0.99, 0.01), ("hnet", 8.0, 0.05), ("a", 60, 1))


def bound_sweeps():
    """Pure-refresher sweeps of r, b, engine net gold per shop and start-of-turn free refreshes, by schedule and bank."""
    rows = []
    grids = dict(r=[round(0.05 * i, 2) for i in range(20)] + [0.97, 1.0, 1.05, 1.1, 1.2, 1.3, 1.5],
                 b=[round(0.05 * i, 2) for i in range(20)] + [0.97, 1.0],
                 hnet=[round(0.25 * i, 2) for i in range(25)],
                 a=list(range(0, 21, 2)))
    for name, label, steps, tail in BOUND_SCHEDULES:
        for G in B["BANKS"]:
            for param, grid in grids.items():
                for v in grid:
                    res = pure_turn(steps, tail, G, **{param: v})
                    rows.append(dict(schedule=name, bank=G, param=param, value=v, shops=res["shops"],
                                     paid=res["paid"], free=res["free"], gold_spent=res["spent"],
                                     unbounded=res["unbounded"]))
    write_csv("bound_sweeps.csv", rows)
    # largest r, b and hnet that keep the pure refresher at or under each target
    lim = []
    for name, label, steps, tail in BOUND_SCHEDULES:
        for G in (10, 12, 20, 30):
            base = pure_turn(steps, tail, G)["shops"]
            row = dict(schedule=name, bank=G, shops_no_engine=base)
            for T in B["TARGET_SHOPS"]:
                for param, hi, step in SEARCH[:3]:
                    best = _search(steps, tail, G, param, lambda s: s <= T, hi, step)
                    row[f"max_{param}_for_{T}"] = best if best is not None else "bank alone exceeds"
            row["finite_if"] = ("r<1, b<1, hnet<%s" % top_price(steps, tail)) if not tail else "r<1, b<1 (any hnet: the price has no cap)"
            lim.append(row)
    write_csv("bound_limits.csv", lim)
    return rows, lim


def bound_window():
    """Floor against ceiling, pure refresher. For each schedule and rate: the smallest rate that gives 20 shops on a normal
    tier-6 turn (REAL_BANKS), against the largest that keeps a 30-gold bank at 30 shops and a 60-gold bank at 45.
    The window is open when one rate does both."""
    rows = []
    for name, label, steps, tail in BOUND_SCHEDULES:
        for param, hi, step in SEARCH:
            row = dict(schedule=name, param=param)
            for G in B["REAL_BANKS"]:
                row[f"min_for_20_at_{G}"] = _search_min(steps, tail, G, param, lambda s: s >= 20, hi, step)
            row["max_for_30_at_30"] = _search(steps, tail, 30, param, lambda s: s <= 30, hi, step)
            row["max_for_45_at_60"] = _search(steps, tail, 60, param, lambda s: s <= 45, hi, step)
            fl = row["min_for_20_at_12"]
            cs = [c for c in (row["max_for_30_at_30"], row["max_for_45_at_60"]) if c is not None]
            row["window_at_12"] = ("open" if fl is not None and cs and fl <= min(cs) and len(cs) == 2 else "closed")
            if fl is not None:
                row["shops_at_30_with_floor_rate"] = pure_turn(steps, tail, 30, **{param: fl})["shops"]
                row["shops_at_60_with_floor_rate"] = pure_turn(steps, tail, 60, **{param: fl})["shops"]
            rows.append(row)
    write_csv("bound_window.csv", rows)
    return rows


def bound_packages():
    cells = [(pkg, sched, G, policy, 6) for pkg in BOUND_PACKAGES for sched in BOUND_SCHEDULES
             for G in B["BANKS"] for policy in ("power", "loop")]
    rows = _run_cells(cells)
    write_csv("bound_packages.csv", rows)
    return rows


def bound_tiers():
    """The lines whose pieces exist below tier 6, at Tavern tiers 3, 4 and 6 (shop size and pool shares change)."""
    scheds = [_sched("s123_10_20"), _sched(BOUND_RECOMMENDED)]
    cells = [(pkg, sched, G, policy, tier) for pkg in BOUND_TIER_PACKAGES for sched in scheds
             for tier in (3, 4, 6) for G in (10, 20, 30) for policy in ("power", "loop")]
    rows = _run_cells(cells)
    write_csv("bound_tiers.csv", rows)
    return rows


def bound_floor(pk):
    """Normal turns (REAL_BANKS) and banked turns, Bramble now and the recommended schedule: does the engine add shops?"""
    idx = {(r["package"], r["policy"], r["bank"], r["schedule"]): r for r in pk}
    rows = []
    for pkg in BOUND_PACKAGES:
        for policy in ("power", "loop"):
            for G in B["BANKS"]:
                row = dict(package=pkg["name"], player=pkg["player"], policy=policy, bank=G,
                           normal_turn=G in B["REAL_BANKS"])
                for sname in ("s123_10_20", BOUND_RECOMMENDED):
                    r, base = idx[(pkg["name"], policy, G, sname)], idx[("none", policy, G, sname)]
                    row[f"{sname}_shops_median"] = r["shops_median"]
                    row[f"{sname}_shops_p90"] = r["shops_p90"]
                    row[f"{sname}_added_over_no_engine"] = r["shops_median"] - base["shops_median"]
                    row[f"{sname}_sp"] = r["sp_gained_mean"]
                    row[f"{sname}_minutes_median"] = r["minutes_median"]
                row["reaches_20_now"] = row["s123_10_20_shops_median"] >= 20
                rows.append(row)
    write_csv("bound_floor.csv", rows)
    return rows


def bound_econ_recheck():
    """B5 check: the economy-card break-even of econ_break_even(), standard econ, by turn 12,
    with the late-gold sink of the original model against a flat per-gold sink (Tavern spells)."""
    global A
    base_A = copy.deepcopy(A)
    rows = []
    settings = [("original: 1 SP per refresh", None), ("flat 1.0 SP per gold", 1.0),
                ("flat 1.6 SP per gold (marginal: no engine, banks 30 to 60)", 1.6),
                ("flat 1.8 SP per gold (bounding model, no engine)", 1.8), ("flat 3.0 SP per gold", 3.0)]
    for label, rate in settings:
        A = copy.deepcopy(base_A)
        A["SINK_SP_PER_GOLD"] = rate
        level = A["REFERENCE_ECON"]
        w = weights(simulate(level))
        rt = reach_turns(simulate(level))
        for name, kind, gold, tiers, _ in ECON_ARCHETYPES:
            for tier in tiers:
                a = rt[tier]
                if a is None or a > A["HORIZON"] - 3:
                    continue
                f = lambda body: compare(level, tier, a, kind, 0, None, body, gold=gold, hold_mode="endo", w=w)["surplus_hp_t12"]
                lo, hi = 0.0, float(V(tier))
                if f(hi) < 0:
                    be, implied = "above V(t)", None
                elif f(lo) > 0:
                    be, implied = 0.0, None
                else:
                    for _ in range(16):
                        mid = (lo + hi) / 2
                        lo, hi = (lo, mid) if f(mid) > 0 else (mid, hi)
                    be = round((lo + hi) / 2, 2)
                    total_gold = gold if kind == "gold_once" else gold * A["H"][tier]
                    implied = round((V(tier) - be) / (total_gold * G(tier) * A["CARRY_FACTOR"]), 2)
                body_m, raw_m = priced_body(kind, 0, None, tier, "budget", gold=gold)
                rows.append(dict(late_sink=label, econ=level, card=name, tier=tier, turn_bought=a,
                                 break_even_body_t12=be, plain_body=V(tier), method_body_raw=round(raw_m, 2),
                                 implied_econ_charge=implied))
    A = base_A
    write_csv("bound_econ_recheck.csv", rows)
    return rows


def bound_summary(pk):
    """One row per package x policy x bank: median and p90 shops under every schedule ("U" = some runs hit
    CAP_SHOPS), plus shops added over the no-engine player and gold, units, SP, SP per gold and minutes under each schedule."""
    idx = {(r["package"], r["policy"], r["bank"], r["schedule"]): r for r in pk}
    rows = []
    for pkg in BOUND_PACKAGES:
        for policy in ("power", "loop"):
            for G in B["BANKS"]:
                row = dict(package=pkg["name"], player=pkg["player"], policy=policy, bank=G)
                for name, _, _, _ in BOUND_SCHEDULES:
                    r = idx[(pkg["name"], policy, G, name)]
                    base = idx[("none", policy, G, name)]
                    u = "U" if r["share_unbounded"] > 0 else ""
                    row[f"{name}_shops"] = f"{r['shops_median']} ({r['shops_p90']}){u}"
                    row[f"{name}_added"] = r["shops_median"] - base["shops_median"]
                    row[f"{name}_gold"] = r["gold_spent_mean"]
                    row[f"{name}_units"] = round(r["units_bought_mean"] + r["units_created_mean"], 1)
                    row[f"{name}_sp"] = r["sp_gained_mean"]
                    row[f"{name}_sp_per_gold"] = r["sp_per_gold"]
                    row[f"{name}_minutes"] = f"{r['minutes_median']} ({r['minutes_p90']})"
                row["loop_index_now"] = idx[(pkg["name"], policy, G, "s123_10_20")]["loop_index"]
                row["loop_index_recommended"] = idx[(pkg["name"], policy, G, BOUND_RECOMMENDED)]["loop_index"]
                row["loop_index_top_recommended"] = idx[(pkg["name"], policy, G, BOUND_RECOMMENDED)]["loop_index_top"]
                rows.append(row)
    write_csv("bound_summary.csv", rows)
    return rows


def bound_check(argv):
    """python -I tools/research/budget_model.py bound check r=0.3 b=0.1 hnet=0.5 a=4
    A designer's quick check: one card's rates as a board engine, against Bramble now and the recommended schedule."""
    kv = dict(a.split("=", 1) for a in argv)
    board = {k: float(kv[k]) for k in ("r", "b", "hnet") if k in kv}
    pkg = dict(name="check", player="check", label="bound check " + " ".join(argv), board=board,
               start_free=int(float(kv.get("a", 0))))
    B["RUNS"] = 200
    print("rates", board, "start-of-turn free refreshes", pkg["start_free"])
    for sname in ("s123_10_20", BOUND_RECOMMENDED):
        sched = _sched(sname)
        for policy in ("loop", "power"):
            line = []
            for G in B["BANKS"]:
                c = bound_cell((pkg, sched, G, policy, 6))
                n = bound_cell((dict(name="none", player="", label=""), sched, G, policy, 6))
                line.append(f"{G}g: {c['shops_median']} ({c['shops_p90']}) vs {n['shops_median']}")
            print(f"  {sname:18s} {policy:5s} Lambda {c['loop_index']}  " + " | ".join(line))
    print("  target [judgement]: at 30 gold, median <= 30 and p90 <=", B["LIMIT_P90"], "for the strongest plausible board")


# =============================================================================
# Checks for power-budget.md v1: break-even sweeps that print and write nothing
# =============================================================================
def _bisect_body(f, lo, hi, n=18):
    """Body at which f (surplus HP by turn 12) changes sign, f falling as the body shrinks."""
    for _ in range(n):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if f(mid) > 0 else (mid, hi)
    return (lo + hi) / 2


def checks_scaling(growths):
    """Scaling charge per SP below the growth cap (power-budget.md 3.2, B1) and its lobby-pace dependence (B3).
    For each lobby pace (GENERIC_GROWTH_PER_TURN), kind and tier: the break-even body and charge c = (V - body) / s."""
    global A
    base_A = copy.deepcopy(A)
    ss = (0.25, 0.5, 1.0, 1.5, 2.0, 3.0)
    charges = {}
    for growth in growths:
        A = copy.deepcopy(base_A)
        A["GENERIC_GROWTH_PER_TURN"] = growth
        level = "standard"
        w = weights(simulate(level))
        rt = reach_turns(simulate(level))
        for kind, freq in (("self_turn", None), ("self_combat", 1.0)):
            for tier in range(1, 6):
                a = rt[tier]
                out = []
                for s in ss:
                    f = lambda body: compare(level, tier, a, kind, s, freq, body, hold_mode="endo", w=w)["surplus_hp_t12"]
                    v = float(V(tier))
                    if f(0.0) > 0:
                        out.append(f"s{s}:beats")
                        continue
                    if f(v) < 0:
                        out.append(f"s{s}:belowV")
                        continue
                    be = _bisect_body(f, 0.0, v)
                    charges[(growth, kind, tier, s)] = (v - be) / s
                    out.append(f"s{s}:be{be:.2f}/c{(v - be) / s:.2f}")
                print(f"g{growth} {kind} T{tier} turn{a}: " + " ".join(out))
    A = base_A
    if len(growths) > 1:
        g0 = growths[0]
        print(f"pace: change in c against growth {g0}")
        for growth in growths[1:]:
            for kind in ("self_turn", "self_combat"):
                for tier in range(1, 6):
                    cells = []
                    for s in ss:
                        c0, c1 = charges.get((g0, kind, tier, s)), charges.get((growth, kind, tier, s))
                        cells.append(f"s{s}:{100 * (c1 - c0) / c0:+.1f}%" if c0 and c1 else f"s{s}:-")
                    print(f"  g{growth} {kind} T{tier}: " + " ".join(cells))


def checks_econ(sinks):
    """Gold on a unit against the late sink (power-budget.md 4.1): break-even body and price (SP = V - body)
    for one-off and recurring gold of 1 and 2 at Tiers 1-6, standard econ, by turn 12, at each SINK_SP_PER_GOLD."""
    global A
    base_A = copy.deepcopy(A)
    for rate in sinks:
        A = copy.deepcopy(base_A)
        A["SINK_SP_PER_GOLD"] = rate
        level = "standard"
        w = weights(simulate(level))
        rt = reach_turns(simulate(level))
        cells = []
        for kind, gold in (("gold_once", 1), ("gold_once", 2), ("gold_per_turn", 1), ("gold_per_turn", 2)):
            for tier in range(1, 7):
                a = rt[tier]
                if a is None or a > A["HORIZON"] - 3:
                    continue
                v = float(V(tier))
                f = lambda body: compare(level, tier, a, kind, 0, None, body, gold=gold, hold_mode="endo", w=w)["surplus_hp_t12"]
                if f(v) < 0:
                    cells.append(f"{kind[5:]}{gold}T{tier}=belowplain")
                    continue
                if f(0.0) > 0:
                    cells.append(f"{kind[5:]}{gold}T{tier}=beats")
                    continue
                be = _bisect_body(f, 0.0, v)
                cells.append(f"{kind[5:]}{gold}T{tier}=be{be:.2f}/sp{v - be:.2f}")
        print(f"sink {rate}: " + "  ".join(cells))
    A = base_A


CHECK_REACH_LEVELS = {  # (turn_from, extra_gold) steps, as A["ECON_LEVELS"]; power-budget.md B2
    "standard": [(2, 0.5)],
    "high_roll": [(2, 2), (4, 3), (6, 4)],
    "v1_caps_one_T3_unit": [(2, 0.5), (4, 1.5)],
    "v1_caps_two_T3_units": [(2, 0.5), (4, 2.5)],
    "v1_caps_two_T3_then_T5x2": [(2, 0.5), (4, 2.5), (8, 4.5)],
    "v1r2_full_income_board": [(2, 0.5), (4, 2.5), (6, 3.5), (8, 6.5)],
    "bounding6_caps_T2_T3_T4": [(2, 0.5), (3, 1.5), (4, 2.5), (6, 4.5)],
}


def checks_reach():
    """Turn each tier is reached by income boards at the gold caps (power-budget.md B2). Extra gold only, no body cost."""
    global A
    base_A = copy.deepcopy(A)
    for name, steps in CHECK_REACH_LEVELS.items():
        A = copy.deepcopy(base_A)
        A["ECON_LEVELS"][name] = steps
        rt = reach_turns(simulate(name))
        print(name, steps, {t: rt[t] for t in range(2, 7)})
    A = base_A


def checks_main(argv):
    """python -I tools/research/budget_model.py checks scaling [growth ...] | econ <sink ...> | reach
    Prints only; writes nothing. Single process, a few seconds to a few minutes."""
    mode, args = (argv[0] if argv else ""), [float(x) for x in argv[1:]]
    if mode == "scaling":
        checks_scaling(args or [0.0, 1.0])
    elif mode == "econ":
        checks_econ(args or [1.8, 2.0, 2.2, 2.5, 3.0])
    elif mode == "reach":
        checks_reach()
    else:
        print(checks_main.__doc__)


def bound_main():
    sched = bound_schedule_table()
    bound_econ_recheck()
    sweeps, lim = bound_sweeps()
    bound_window()
    pk = bound_packages()
    bound_summary(pk)
    bound_floor(pk)
    bound_tiers()
    print("wrote bound_schedules, bound_econ_recheck, bound_sweeps, bound_limits, bound_window, bound_packages,"
          " bound_summary, bound_floor, bound_tiers (.csv) to", OUT)
    for r in sched:
        print(f"  {r['schedule']:18s} shops from 10/12/20/30/60 gold: "
              f"{r['shops_from_10']}/{r['shops_from_12']}/{r['shops_from_20']}/{r['shops_from_30']}/{r['shops_from_60']}")
    for r in pk:
        if r["schedule"] == BOUND_RECOMMENDED and r["bank"] in (12, 30):
            print(f"  {r['package'] + '/' + r['policy']:34s} recommended, bank {r['bank']:2d}: median {r['shops_median']} "
                  f"p90 {r['shops_p90']} SP {r['sp_gained_mean']} unbounded {r['share_unbounded']} "
                  f"Lambda {r['loop_index']} / top {r['loop_index_top']}")


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
    if sys.argv[1:2] == ["bound"]:
        if sys.argv[2:3] == ["check"]:
            bound_check(sys.argv[3:])
        else:
            bound_main()
    elif sys.argv[1:2] == ["checks"]:
        checks_main(sys.argv[2:])
    else:
        main()
