# Balance pass on `dev` (8f55bcca), 18 Nov 2026: the agent's full report

Written by an Opus agent working on its own. The owner asked for "a balance pass on the cards and a small balance pass bounded, and present me with some findings ... I want to see how will they align with my own thoughts, because I'm trying to triangulate what agents can find." The agent was told not to use the owner's past balance opinions as evidence (it skipped `docs/design/owner-ideas-log.md` and `docs/design/sources/`), to make no changes, and to stay within about 90 minutes. Its full transcript is `balance-agent-transcript.jsonl` in this folder (Claude Code JSONL: one JSON event per line; the agent's tool calls and results are in it). Its probe scripts are `tribe_lobby.gd` and `duel.gd` in this folder; they ran from `res://tools/checks/` in a throwaway checkout of `origin/dev`.

The report, verbatim:

---

## Bramble balance pass on `dev` (8f55bcca)

No changes made to any branch. Probe scripts kept in scratchpad (`tribe_lobby.gd`, `duel.gd`); worktree removed.

### 1. Top findings

1. **Pigeons are far ahead of the field.** 455 tribe-locked 8-bot lobbies: Pigeon avg place 3.2, top-4 72%, win 32%; 60–66% fight win vs other tribes at every stage. Median board stats ~2× everyone from round 4 (85 vs 44–58) and ~3× by round 14 (1058 vs 285–561). Engine is slot buffs: they survive sell/tier-up, so they never waste, and bots get them free. Confidence high. Direction: smaller or conditional Pigeon slot growth, starting with #2.

2. **Colour Sergeant (P3) out-produces its tier.** Full front row = +3/+3 on 4 slots = 24 permanent stats/turn; tier guide's T3 cumulative target is ~9. Two Sergeants stack; Sergeant Major (T6) makes it 48. Strongest card in lobby lift (+15 pts over Pigeon baseline). Confidence high. Direction: one row slot per turn, or move it to T4–5.

3. **The Colonel (P6): uncapped Reserve.** Fixed Pigeon board vs Briar board, 100–200 fights each: empty hand 0%, 1 unit in hand 0%, 2 → 84%, 3–6 → 100%. Each hand unit is a full extra body that also takes its slot buff, and gold pools, so stocking the hand is cheap. Confidence high (bots never exploit it, so lobby numbers understate it). Direction: one Reserve per fight or a hard cap.

4. **Gleaner (L3): 5 damage per friendly death, unlimited.** Locust boards lose many units per fight (Hoppers, Molt). Same Locust board vs Briars: 0 Gleaners 0%, 1 → 49%, 2 → 99%. Eighth Plague (L5) is the same at smaller scale: turned 0% into 76%. Confidence high for Gleaner, medium for Plague. Direction: per-fight cap like Padre's "(8 a fight)".

5. **Mice are the weakest tribe.** Avg place 6.2, top-4 17%, win 1%; 23–28% mid-game fight win. Printed stats run 70–80% of the tier median and their scaling is Attack-only. A hand-built board with sensible placement still lost to Briars 1–197 of 200. Confidence medium-high. Direction: more Health on bodies or Health in slot buffs. **`night/ambush` weakens their main tools** (Master of Engines, Spoon Catapult, Toothpick Ballista), so it would widen the gap unless compensated.

6. **Locusts fall off late.** 54–66% fight win through round 9, then 36% (r10–12) and 16% (r13+). Top-4 68% but win 3%. T5–6 bodies average 15–17 stats vs median 18–22; Tide is Attack-only; Gleaner's damage stays flat while enemy Health grows. Confidence medium. Direction: Health or scaling on late cards.

7. **Badger Fury supports underperform.** Against the Briar board, a Badger board with Marshal of the Red Mist won 83%, with Old Brock in that slot 91%; leaving front slots empty to raise Outnumbered made it worse (45%). Master-at-Arms (B4, 5/9 giving +1 Fury) has the worst Badger lobby lift; Dame of the Old Sett and Marshal also sit below baseline. Confidence medium. Direction: bigger Fury numbers or better bodies; Master-at-Arms is close to a dead card.

8. **Briars dominate late, and their power is the Compost.** 68–74% fight win from round 10; win rate 21%. Same Briar board: empty Compost loses 0–100%, Compost of 6 wins 100–0, because Root and Grow both draw on it. Confidence medium. Direction: watch Compost fill rate from Bury (Old Mother Midden doubles it).

9. **Gold-generating cards are weak because gold isn't scarce.** Relic Seeker, Shrew Cutpurse, Hedge Layer. Bots refreshing up to 8 times a turn still end rounds 12–14 with 7–26 unspent gold, so +1 gold is worth about one refresh. Confidence low-medium. Direction: pay out in something other than gold.

10. **Interaction to watch: Granary Glutton.** It eats every Locust you sell, unlimited, and the sold unit's death effect still fires: selling Famine-caller this way gives Tide +2. Hoppers from Horde-runner, doubled by Mother of Thousands, are free food. Limited only by shop luck. Confidence low (not tested).

### 2. Tribe ranking (strongest first)

1. **Pigeon**: skill-free, permanent slot buffs plus the Colonel (high).
2. **Briar**: weak mid-game, then dominant once the Compost fills (medium).
3. **Locust**: wins the early and middle game, rarely wins whole games (medium).
4. **Badger**: slow start (35% of early fights), solid mid-game, Fury supports don't pay off (medium-low).
5. **Mouse**: small bodies, Attack-only scaling, worst at every stage after round 3 (medium-high).

### 3. What I couldn't judge

- **The bots are naive.** They're tribe-locked, buy greedily, place by simple rules. They never sell on purpose to feed the Compost or a Glutton, never stock the hand for the Colonel, never plan around Outnumbered. Strategy-aware bots, or a small league of scripted strategies per tribe, would settle it.
- **The power check reads ×1 for Thorns and Gleaner.** Its symmetric 10/10 boards hide these effects, so it can't price them.
- **Golden ceilings and eat loops** need targeted recruit-phase sims.
- **The constructed boards and their buffs are my own guesses.** The near all-or-nothing results show how much one card swings a fight, not exact win rates.

### 4. Method

- **Read:** the bramble-design skill, the tier guide, the rulebook (economy, board, combat, damage), SHARED-RULES.md, all `units.json` and `display.json`, the relevant mechanic scripts, power-check.md.
- **Lobbies:** wrote `tribe_lobby.gd`: 8-bot lobbies where each bot buys only its own tribe; Squires and "in front of this" cards go in the back row. 455 games in 5 parallel processes: `godot --headless -s res://tools/checks/tribe_lobby.gd -- games=100 first_seed=1000|1100|…`. Measured placement, fight win rate by stage, head-to-head, board stats by round, and each card's lift (board presence vs win, against its tribe in the same round).
- **Constructed fights:** wrote `duel.gd`: 100–200 seeded fights per matchup through the real fight engine, with slot buffs, Tide, Compost and hand set by hand.
- **Power check:** ran `power_check.gd` from `night/power` on `badger_lance` (×2), `locust_glean`, `locust_plague`, `thorn_thorns` (all ×1, a blind spot of the tool) and `mouse_pile_on` (×2.5).
- **Skipped:** `soak.sh` and `records.sh` (they check rules and records, not balance).
