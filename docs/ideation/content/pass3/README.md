# Pass 3 tribe designs (9 Nov 2026, on paper)

Track C of the scale rework (`../../plan-scale-rework.md`, step 1). These are paper designs: nothing here is built yet.

**How they were made.** Each tribe had a panel:
- three independent designers, each with an angle (engine, carry, wild);
- a breaker who tried to break all three;
- a synthesis that built on the strongest design and took the best parts of the others.

No designer saw a price table. Each was briefed with:
- the target shape;
- the condition/payoff/enabler frame;
- the tribe's identity.

A cross-tribe critic then read all six on one scale. Panel drafts, breakers and their models are in `../../evidence/pass3-panels/`. The workflow script is `bramble-pass3-design-wf_c0f75f84-f7b.js` in the session's workflow scripts.

| File | What it holds |
|---|---|
| `<tribe>-pass3.md` | The synthesis: cards, rules text, lines, harness line JSON, open sim questions |
| `<tribe>-pass3-model.py` and `.out.txt` | The panel's paper model and its output (no Godot) |
| `cross-tribe.md` | Do the six feel different; sizes on one scale; overlaps; answers; splash; neutrals; pool rules |
| `../../evidence/reference-curves.md` | The one target table every model and the harness use |

## Amendments adopted from the cross-tribe critique

These override the six syntheses wherever they disagree. Each wave's build spec applies them, and reasons are in `cross-tribe.md` (section numbers below).

1. **One target table.** Every model and the harness use `reference-curves.md`.
   - Fairies and Oozes were sized to Battlegrounds' September 2025 mean, so they run 1.7–2.2× the others from R12 (§2).
   - They start resized:
     - **Fairies:** the Fetch twin at half. Cluricaun moving to tier-ups (amendment 7) does the rest: it grows twice on the Ring line instead of three times. *Corrected after the wave 1 review: "g = ¼" here was the old turn-timer period, and it no longer applies once Cluricaun grows on tier-ups.*
     - **Oozes:** Stone Soup r = 1/12, Elder at a quarter.
   - These are dials. The harness sets them after step 2 picks the era. If a steeper era wins, the other four go up instead.
2. **Tribe words** on seven splashable payoffs (§5): His Highness and the Prince, Tiddy Mun, Cradle Fetch, Hob, Dr Urchin, Old Isegrim, Old Brock.
3. **Any-row answers:** only Hasty, the Lantern Man and Old Isegrim. Belladonna aims across (§4.2).
4. **Start of Combat order:** biggest-enemy effects resolve after both sides' other Start of Combat effects. Biggest-enemy effects see units inside Bellies (§4.3).
5. **Growth from the enemy** (§3.1):
   - Hunters own permanent growth from kills, and Bog owns growth from bites.
   - Jack Daw becomes fight-only after a harness check.
   - Hasty keeps its gain.
6. **One permanent-gain queue:** Hunters' Takes and Bog's Soak land at the next Start of Turn, shown as a pending badge.
7. **Clocks** (§3.2):
   - Hedgerow owns the turn timer.
   - Cluricaun grows on tier-ups: *"After you Tier up: if every slot has a Ring, your Rings grow +1/+1."* Golden is +2/+2. The step is a dial.
8. **Half damage:** Tom Tit uses Damage Reduction 50%. Hunker stays "when attacked" (§3.3).
9. **Names:** the Toll-Bard becomes the Lane-Bard (§3.5).
10. **Early game:** One Swallow's trips last 1 turn (§6).
11. **Loop guards:**
    - Pack joins never cleave.
    - Extra triggers never repeat a doubling or move a countdown, whatever doubler causes them.
12. **Neutrals** (§8):
    - keep 9;
    - rewrite Ballooning Spider, Charcoal Burner and Whirligig Beetle, and make Pipistrelle Echo scale with spells;
    - add Shieldbug (a Shield holder) and Click Beetle (a "When played" doubler);
    - no neutral any-row answer, no Cold Iron and no neutral full-board aura;
    - Track B's End of Turn doubler, defender, cleaver and economy cards stay as sweep levers only;
    - the 38 prototype bodies retire when wave 2 lands.
13. **Async counts "across" answers as aimed.** The harness adds a scouted-attacker orientation (§4.1).

## Read the numbers as paper

The models count differently:
- Fairies count the Fetch twin.
- Oozes count units inside Bellies.
- Birds don't count the sky.

None runs the real engine. The figures say where to start the dials, not whether a tribe is good. The harness and play decide that, with fun first: a tribe passes on reward moments and decisions, inside a wide guardrail band (`../../plan-scale-rework.md`, step 3).

## What happens next

Plan v3 (`../../plan-scale-rework.md`):
- Wave 1 (Birds and Fairies) is built and merges first.
- Wave 2 (the pool rules, then Bog and Hunters, then Oozes, Hedgerow and the neutrals) follows, with dials in two presets.
- The full pool is measured, then played at checkpoint 1.
- **First harness tests:** `cross-tribe.md` §10 lists what the harness checks first on the new content.
