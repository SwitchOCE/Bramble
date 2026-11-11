# Which breaker method finds multi-piece engines? (11 Nov 2026)

Owner's idea: ask the breaker "what pieces would make this card break?" and have it look for them, instead of judging the card and listing obvious combos. Tested on 9 Battlegrounds cards with known answers, three methods × two models, one run each.

**Clean data (after the owner caught a leak).** A first round gave agents the full card library with first/last-seen dates, which let them infer a card was pulled fast; it was stopped. The clean round gave each card a snapshot of the pool at its date (minions, heroes and hero powers, buddies, tavern spells, trinkets and anomalies where they existed), with no dates, no patch notes, no repo and no web. Limits: other cards carry their latest wording; models may remember history from training.

Cards. Known broken (owner's memory and Blizzard's actions): Arcane Behemoth, Banana Slamma (2023 "double its stats"), Tidemistress Athissa (2022, with Stormscale Siren), Chronormu, Shadowy Construct (Teron's buddy, June 2024: "Deathrattle: give this minion's maximum stats to another friendly minion"; with Archlich Kel'Thuzad, Drakkari, Titus), Nathanos Blightcaller (Sylvanas's buddy, March 2023). Controls: Stone Age Slab, Flaming Enforcer, Brann.

Methods. A: judge on best play and list combos. B: work backwards (name the pieces that would break it, search the snapshot for them by mechanic, then judge). C: B plus a turn-by-turn best-case game.

B = called BROKEN; ~ = found the runaway engine but called it power fantasy; - = missed.

| | Behemoth | Slamma | Athissa | Chronormu | Construct | Nathanos | Controls wrongly BROKEN |
|---|---|---|---|---|---|---|---|
| Fable A | - | - | - | B | ~ (Kel'Thuzad, linear) | ~ | Slab only under one anomaly |
| **Fable B** | - | **B** | - | **B** | ~ (full loop, ×1.7/turn) | **B** | Slab "narrow" (Jandice re-buy) |
| Fable C | - | - | - | ~ | ~ (full loop) | ~ | Slab via Jandice or Bribe |
| Sonnet A | - | - | - | - | - (found Kel'Thuzad, called it fine) | - | Enforcer |
| Sonnet B | - | - | - | - | - | B | none |
| Sonnet C | - | B | - | - | - | B | Enforcer |

Findings:
1. **The model matters more than the method.** Fable found the Kel'Thuzad engine in every method; Sonnet in one, and judged it fine. Sonnet twice called a control broken.
2. **Working backwards (B) is the best method on Fable:** 3 of 6 called broken, Shadowy Construct's self-feeding loop found, no plain control wrongly broken.
3. **The verdict is the weak step.** Fable C found the Construct, Nathanos and Chronormu loops and still called them power fantasy: the turn-by-turn estimate made slow exponentials (×1.5 to ×1.7 a turn) look modest. A loop the breaker has found should be judged by the hard rule, not by the breaker's feel.
4. **Nobody found Behemoth's copy loop** (Discover copies, make one Golden, sell Behemoths into each other). Athissa was judged linear by all; its real problem was pace, not a loop.
5. **Stone Age Slab with a re-buy** (Jandice's swap, Anomalous Bribe) came up in three Fable runs. Unverified; may be a real exploit rather than a false alarm.

One run per cell, so treat single cells as noisy.

## Guide round: method B plus a field guide to combo shapes (11 Nov)

Same clean snapshots and cards. The brief added `combo-shapes-guide.md`: eight shapes (self-reference, cross-feed, phase shift, trigger stack, copy supply, reset, duplication, free fuel), the roles a piece can play, and "a loop that grows by a share of itself each turn with no cap is BROKEN, however modest it looks". One run each, plus Opus on plain B as a baseline.

| | Behemoth | Slamma | Athissa | Chronormu | Construct | Nathanos | Controls flagged |
|---|---|---|---|---|---|---|---|
| Opus B (no guide) | - | B | - | ~ | ~ (Kel'Thuzad) | B | Slab |
| Fable + guide | - | - | - | B | **B** (Kel'Thuzad) | B | Slab |
| Sonnet + guide | - | B | - | B (Varden) | - | B | Slab, Brann |
| **Opus + guide** | **B** (Mutanus sells a Behemoth onto a copy) | ~ (in-combat only) | - | B (Mutanus) | **B** (Kel'Thuzad) | B | Slab, Brann, Enforcer |

Findings:
1. **The guide fixes the verdict step.** Found loops are now called BROKEN instead of "power fantasy", on every model. Sonnet goes from 1–2 to 3; Opus from 2 to 4.
2. **Opus + guide is the first run to find Behemoth's loop**, and the only one to find both Construct and Behemoth. But the guide's copy-supply shape was written knowing Behemoth's answer, so this needs a held-out card set before it counts.
3. **Slamma's break is in-combat** (×2 per summon, reset after the fight). Runs that call it power fantasy are following the hard rule, which covers growth across turns only; the in-combat burst is the rule's known gap (see `bg-test.md`).
4. **The controls aren't clean.** Checked against the snapshot texts, all three flagged lines work as written: Jandice swaps the carrier into the Tavern and the Slab doubles it on re-buy (×2/turn); Kelp Keeper (1 gold) triggers Shell Collector twice under Brann for 2 coins, a net +1 gold per use with no limit; Jandice plus Flaming Portrait makes the Enforcer's meal feed its neighbours, one of which is eaten next turn. Whether these happened in live play is unverified. Pool A's hero powers and trinkets make the controls breakable; a fair control set needs cards whose pool has no swap or re-buy effects, or the flags must be checked case by case.
5. **Blame is still loose.** Sonnet blamed Brann for the Kelp loop; the rule says to pin a loop on the card that closes it (Kelp Keeper here).

One run per cell. Next fair check: a held-out set of known-broken and known-healthy cards the guide wasn't written around.

## Small balance-watch check, Opus only (11 Nov)

The owner asked for the smallest version that flags cards with the potential to break, so data and replays can look at them, rather than precision at high cost; Opus only. A 420-word brief (`balance-watch-brief.md`; the guide round's was 940): work backwards, eight one-line questions instead of the field guide, and three flags: BROKEN (only the egregious kind), WATCH, CLEAR. Two Opus runs on the same clean snapshots.

| | Behemoth | Slamma | Athissa | Chronormu | Construct | Nathanos | Slab | Enforcer | Brann |
|---|---|---|---|---|---|---|---|---|---|
| Run 1 | W | W (in-fight) | C | W | W | W | W | W | **B** (Kelp gold loop, pinned on Kelp Keeper) |
| Run 2 | W | W (in-fight) | C | W | W | W | W | W | **B** (same) |

- Every known loop card flagged, both runs, with the same flags. Athissa is CLEAR in both; its real problem was pace, which this check doesn't look for.
- Cost per run: about 128k tokens and 5.7 minutes, against 166k and 9.5 minutes for Opus with the full guide.
- BROKEN went only to the Kelp Keeper gold loop (unlimited within a turn). Slab was held at WATCH because its pieces are rare.
- Not yet known: how often it flags healthy cards. Only Athissa came back CLEAR, and the controls turned out to have real lines in their pools. The 24-card set in `bg-test.md` is the check for that.

### False-flag check: 31 tier 4+ cards (11 Nov)

Same brief and clean snapshots, three Opus runs of about ten cards each. 19 cards that lasted a long time in the pool (a stand-in for healthy, not proof) and 12 that Blizzard removed or nerfed.

| | WATCH | BROKEN | CLEAR |
|---|---|---|---|
| Long-lived (19) | 7: Slab, Enforcer, Living Prison (Jandice swap); Futurefin (Mutanus); Brann (Kelp Keeper gold); Poet (Myrmidon Sticker); Stalwart Kodo (in-fight copies) | 0 | 12: Drakkari, Utility Drone, Choral, Kalecgos, Ur'zul, Courier, Champion of Sargeras, Tichondrius, Felfire Conjurer, Showy Cyclist, Groundbreaker, Felboar |
| Removed or nerfed (12) | 5: Slamma, Chronormu, Behemoth, Ball of Minions, Famished Felbat | 0 | 7: Myrmidon, Garr, Upbeat Duo, Kel'Thuzad, Athissa, Rascal, Extortionist |

- BROKEN was never given in 31 cards, so the tier is as strict as asked. (Brann's gold loop was BROKEN in the two earlier runs and WATCH here, because the pool doesn't say whether Activate can be used again.)
- The removed cards whose problem was a loop (Slamma, Chronormu, Behemoth) are all flagged. The CLEAR ones were removed for other reasons, such as pace (Athissa) or tuning, or for rotation.
- About a third of long-lived cards get WATCH, and 5 of those 7 run through one enabler (Jandice's swap, Mutanus's sell, Kelp Keeper). Listing a flag under the enabler, with the cards beneath it, would cut what the owner reads.
- Runs also flagged loops outside their list without being asked (Private Investigator gold, Titanic Guardian pairs, Mutanus with Windfall Tornado).
- Cost: 134k to 187k tokens and 5 to 9 minutes per batch of ten (the batch with four older pools was the dearest).

## Two-pass check: catching what has to go (11 Nov)

Owner: "nothing being flagged as broken is a problem... We want to catch stuff that's unhealthy and needs to be removed... watch cards need to then be caught and removed when on a second check. And I need to have confidence this process will do that."

The BROKEN bar above asked for cheap, common pieces, so it excused exactly the rare loops Battlegrounds removed. New bar: the line works as written and grows about ×1.3 a turn or more, or without limit in a turn or a fight; rarity, cost, periods and piece count don't excuse it. A second fresh Opus check takes every WATCH card: it checks each step in the code, looks for a substitute where one fails, settles the open question, scripts six turns, and decides BROKEN or KEEP. Briefs: `balance-watch-brief.md`, `second-check-brief.md`.

| Set | First check | Second check | Final |
|---|---|---|---|
| Bramble, 18 cards (10 must catch, 8 must keep), two runs of 9 | 18/18 right; no WATCH | (not needed) | 18/18 |
| Bramble second-check test: 4 WATCH lines written for the test (Redbreast's Fly South keyword, Golden Egg re-egging, Cuckoo, Lollop) | – | Redbreast KEEP (never flies in code), Golden Egg KEEP (egged mark blocks it), Cuckoo BROKEN, Lollop BROKEN at 4+ copies (one copy ×1.07) | 4/4 |
| Battlegrounds known-broken: Slamma (2023), Chronormu, Behemoth, Shadowy Construct, Nathanos | Chronormu, Behemoth, Nathanos BROKEN; Slamma, Construct WATCH | Slamma BROKEN (Drek'Thar prints no limit: ×2 per summon in a fight); Construct BROKEN (golden Graverobber supplies the second copy; ×1.27–1.78 a turn in 4,000 sims) | 5/5 |
| Battlegrounds staples: Brann, Drakkari, Kalecgos, Champion of Sargeras, Utility Drone, Stone Age Slab, Flaming Enforcer | 5 CLEAR; Slab and Enforcer BROKEN through Jandice's swap (plus Zar'jira for Enforcer) | – | 5/7; both flags name the Jandice enabler, and both lines work as written |

- Every loop card that had to go ends BROKEN. The Fly South homecoming rule was found unprompted in three runs (×1.36 a turn from a tier 1 Bird; ×1.58 with One Swallow).
- The checks also turned up code mismatches: Redbreast and Cuckoo carry the Fly South keyword but can't fly; Lollop's code shares the biggest unit's stats where the text says "its"; Mallow and Dozey JSON say ×2 where preset B says ×3.
- Fix made after the run: a loop with no cap but slower than ×1.3 a turn is WATCH, not CLEAR, so a slow loop (one Lollop at ×1.07) always gets the second check instead of passing silently.
- Cost: first check 133k–165k tokens and 6–8 minutes per batch of 6–9 cards; second check 85k–112k tokens and 3–5 minutes.
- Limits: one run per batch. The Bramble answer key was known to me when writing the brief's examples (Treasurer, Lollop, Aspic and Soup are in the guidance, not in the brief). The Battlegrounds staples' Jandice flags are unverified against live play.
