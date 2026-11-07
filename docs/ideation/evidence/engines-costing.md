# Engines package: costing review

- **1. Last Blow:** in budget (game length about neutral). Change: credit the side whose blow emptied the last board, not the last attacker.
- **2. The Last Four:** over (the duel becomes one fight). Change: lift the cap at four left, but bring it back for the final duel, as 10.1.4a does now.
- **3a. Stand Behind Me (formation):** in budget (10.5 SP at most, against 10). No change.
- **3b. Bread from the Back (formation):** over (12 SP against 10, +20%; the band is ±15%). Change: cap at +2/+2.
- **4. Hand-me-down:** in budget, but the code goes further than the text. Change: one sale feeds one play, as the text says. Keep rounding up.
- **5. Harvest Supper at tier 3:** in budget (13.25 SP against 15). No change.
- **Death-Watch Beetle:** under (its text only pays late, on a tier-3 body). Change: tier 5, 3/7.
- **The Bellman:** under (its text is worth about 0 SP in a fight). Change: 4/6 body.
- **The Heir Apparent:** well over (+12–15 SP of text, charged 2). Change: 2/4 body, and cap the extra half at +3/+3.

## Notes

**Formation.** Each spell gets 2 gold × S(t) = 10 SP.
- Stand Behind Me: on a one-tribe board, 2 × (3 × 0.75 + 3) = 10.5. On a ~65%-kin committed board, about 7.6; with no kin, 0. Today it gives 3.5, or 7 for kin.
- Bread from the Back: aimed at B2, both front units touch 4 units, so a one-tribe board gives 12. Capped at +2/+2 the ceiling is 8, the same as today's kin case.

**Hand-me-down.** `recruit_rules.gd` adds up every sale this turn onto the next play. Most of the extra stats from scaling units arrive after turn 12, so c(t) holds.

**Heir Apparent.** A typical round-10 carry holds 25–30 permanent SP. Its golden can't double "all".

**Last Blow.** A tie costs each side the toll t today. Under Last Blow the loser takes min(12, tier + t) and the striker takes nothing.
- Lobby damage per wipe changes by +4 at round 9, +1 at round 12 and −4 at round 15.
- Wipes are 11% of late fights, so length barely moves.
- The prototype credits `last_attack_side`, so a death trigger or Bitter that finishes the wipe still credits the attacker.

**The Last Four.** A loss goes from 12 to 14–19 (+35%). In the duel (~14 Health each) one loss is usually lethal, so the leader's 64% falls toward a coin flip. It also reverses 10.1.4a ("the cap remains through the final duel").

**Bellman.** Under the Last Four its extra damage is mostly overkill. The budget can't yet price hero damage; this is an open class.

**Death-Watch Beetle.** It wins about 5.5% of late fights it would lose (≈3 SP at tiers 5–6). A tier-3 7-SP body costs about 7 SP of slot by then.

`cards-now.md` is stale (Stand Behind Me +1/+2, Supper 4 gold); I used the JSON.
