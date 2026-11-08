# Pass 2: Bog folk fix

9 Nov 2026, a cloud designer, on `ideation/c-pass2-bog`. Method: the triage skill; format: `briefs/pass2-design.md`. No power budget; a reviewer costs this. No game code changed: hypotheses were tested in the real engine with temporary patches, since reverted and kept as [`evidence/pass2-bog/prototype.patch`](../evidence/pass2-bog/prototype.patch) (diagnostic, behind environment flags).

**Result.** Bog stays at 16 cards, 3/3/3/3/2/2, with two sub-routes. The fix is one rule change (Bitter hits first) and two cards redesigned in place: Bridge Toad (T1) and Tiddy Mun (T5). On corrected, fair fixtures, Bog high wins **43.3%** of same-roll fights and Bog low **34.2%**. Before the fix, Bog high won 0.0% and Bog low 0.3%. Each figure is 1,000 fights against the other five boards of the same roll, at 100 seeds with sides swapped.

## 1. Symptom

R9 round robin (`evidence/pass2-build.md`): Bog high wins 0/1,000 against the other highs, Bog low 3/1,000. Before pass 2, `benchmark-boards.md` had Bog 5th at R9 and R12 and 4th–5th at R6: it has been bottom-two in every round of evidence. The diagnosis found no engine bug.

## 2. Hypotheses and what the engine showed

Each test is the R9 round robin with one thing changed (25–100 seeds). Numbers are Bog's same-roll win rate.

| # | Level | Hypothesis | Would show if true | Test | Result | Verdict |
|---|---|---|---|---|---|---|
| H1 | Card | Bog bodies are too small | Bog's printed stats are below the field per tier | Mean printed A+H per tier, shop pool | Bog 4.3/5.0/6.3/7.7/9.5/13.0; field 3.0–4.7, 4.0–6.0, 5.0–7.3, 7.3–9.0, 9.0–11.5, 10–14. Attack share 0.35 (Oozes 0.33, Hunters 0.40) | **Ruled out.** Bodies are par |
| H2 | System (Mire itself) | Bog's text does nothing | Stripping all Bog text doesn't change results | Strip every Bog unit's mechanics | 0.0 → 0.0 (high), 0.3 → 0.0 (low) | **Kept, sharper.** With +2/+2 on each Bog unit the text is worth **+57 points** (31.6% stripped, 89.2% with text). Every Mire payoff fires when a wall is attacked, so it pays only if the wall *survives* |
| H3 | Rule timing | Bitter after damage is too late | Applying Bitter before the hit moves Bog | Bitter at declaration | Original fixture: 0.0 → 0.8. Fair fixture: **12.1 → 52.0** (25 seeds; 51.0 at 100, §6) | **Kept, main cause.** A multiplier: worthless while walls die to the first hit, decisive once they survive it |
| H4 | Card (Tiddy) | Tiddy wastes its gains on dead walls | Gaining before the hit moves Bog | Tiddy's gain before damage, several sizes | +1/+1 first, twice a fight: 72.4. +1/+1 first, once: 55.2. +2 Health first, twice: 49.2 (25 seeds), 43.3 (100 seeds, final) | **Kept.** Size is the reviewer's dial |
| H5 | Journey | No growth below T4, so a low roll has nothing to scale | Bog low is the only low with printed bodies only | Fixture read; a growing T1 | Every other low has a growth layer (Takes, Pym, Rings, Supper, Pinches); Bog low has none. A growing Bridge Toad: 7.6 → 32.8 | **Kept** |
| H6 | Measurement (fixtures) | Bog's fixtures are less generous than the others' | Bog is short of finds the others got | Fixture audit; give Bog the same finds | Bog high has **one Supper; all five other highs have two**. Bog low has two weak neutral fillers (Scarecrow 0/4, Wobbly 1/4), while Hunters low and Birds low got a Charcoal Burner. Fixtures alone: high 0.0 → 12.1, low 0.3 → 3.8 | **Kept, not enough alone** |
| H7 | Competition | The Committee is an outlier that alone beats Bog | Bog wins with the Committee removed | Committee text stripped | Bog high 0.0 → 19.4, but only by beating Hedgerow (97%). Still 0% against the other four | **Ruled out for Bog**; real for Hedgerow (§3) |
| H8 | Rule (Mire wait) | Walls suicide by attacking after they wait | Making mirers hold until their enemy dies moves Bog | "Mirers don't attack while their Mired enemy lives" | Alone: 0.0 → 0.0. With Bitter first, fair fixture: 52 → 58 | **Ruled out**; the once-a-fight wait stays |
| H9 | Measurement (bench) | The 0% is a cliff, not a gulf | Small stat shifts flip whole matchups | ±1/+1 on every unit of a board | Bog high +1/+1: 0 → 11; +2/+2: 0 → 89. Hunters high −1/−1: 50 → 18. Hedgerow low −1/−1: 78 → 48 | **Kept as a caveat.** Fixed boards are threshold tests: 0% meant "just under", and one Supper is worth 30–40 points on any board |

**Root cause.** Every piece of Bog text pays off when a wall is attacked, but its R9 walls (6–9 Health) die to one 5–7 Attack hit, and Bitter, the only defence that could stop that, lands after the damage. So the whole Mire package is worth nothing until the walls survive. The bench shows this: Bog's text is worth +57 points with +2/+2 on every unit, and 0 at the fixtures. One fewer Supper than every other high, and printed-only bodies on the low roll, kept Bog just under that threshold.

**Process cause.** `pass2-b.md`'s Bog boards assumed "Bitter takes 2–3 off each attacker" before it hits; the build (and the reminder, "After an enemy attacks this") put it after damage. No step compared the timing designed with the timing built, and the fixtures weren't checked for parity (Supper counts, growth layers). **Process fix:** (1) the rulebook states the timing of every defensive keyword, and designers' board maths cites it; (2) before a benchmark runs, check its fixtures for parity: the same count of Suppers and neutral T4s per roll, and a growth layer listed per board; (3) report each board's sensitivity to +1/+1 next to its win rate. The same cause may apply to Bristle, Shell and Hunker, and the Birds low fixture is generous.

## 3. The Standing Committee across all tribes

**4/5 at T5.** "Start of Combat: give units touching this +2 Attack, or +3 if all 7 touch." A full board gets **+21 Attack**. That's more team Attack than any T6: Squire Lollop gives +14/+14 to all seven. On the bench, Hedgerow high wins 42.8% with it and **0.6%** without it. With a flat +2 it wins 22.2%, and with +1 (or +2 if all 7 touch) 22.8%. **It's an outlier, and Hedgerow's high roll is a one-card board.** It isn't Bog's cause (H7), so I don't redesign it. For Hedgerow: cut the full bonus to +2 (+14, matching Squire) and move the stats into Hedgerow's other T4–T5 pieces, since weakening it alone drops Hedgerow to fifth.

## 4. The fix

### Rule: Bitter hits first (BRAMBLE ideation, replaces the timing in `engine.md` and the reminder)

**Rule.** When an enemy attacks a unit with Bitter, the enemy loses that much Attack *before* the damage. The loss lasts the fight, stacks with lent Bitter, applies only to the leading attacker, and stops at 1 Attack, as now. Once per enemy (Prima Donna) still means once per enemy. It applies to every attack, including counters and pounces, because it's checked when the attack is declared.

**Reminder (14 words):** "When an enemy attacks this, it first loses this much Attack, down to 1."

- **Role and window:** Bog's defence from R1 to the end. It's what makes a wall's primary job (holding a stuck enemy and outliving its first hit) actually happen. Warty Nan, Madame Bufo, the Natterjack Chorus, the Prima Donna and the Peat King's Peatlings carry it.
- **Competitors:** Bristle (pricks after the hit) and Shell (blocks one hit). Bitter-first shrinks every hit from that enemy, the first included, and never kills. One rule fixes five cards.
- **Journey:** at T1, Warty Nan (1/3, Bitter 1, lends Bitter 1) turns a 3-Attack T1 hit into 1–2, so a 1/3 wall lives through two hits. At T5 the Prima Donna's Bitter 3 takes Urchin from 7 to 4 before it hits, so its hit plus Bristle is 6, not 9, and she lives.
- **Great buy:** R5, Warty Nan between Bufo and Peat Cutter: each enemy front unit hits for 3 less from its first swing. **Bad buy:** a back-row Bitter unit while the front row stands.
- **Variations:** (1) Bitter halves the first hit, then shrinks after, as now: two effects. (2) Bitter only against Mired attackers: tighter to Mire, but Nan loses it without a partner.
- **Engine:** move `CombatLanes.bitter` from `CombatReactions.before_deaths` to the start of `CombatReactions.attack`, before `_perform_attack`. The prototype does exactly this. The 9.9.2 Last Blow note ("Bitter... cannot cause a wipe") stays true.

### Bridge Toad (T1, Bog folk), redesigned

**1/3.** "**Mire.** After its Mired enemy attacks this: gain +1/+1 permanently. Once a fight."
*Golden 2/6:* "**Mire.** After its Mired enemy attacks this: gain +2/+2 permanently. Once a fight."
*Details:* "It gains even if the hit kills it."
*Was:* "Mire. If this Mires the enemy with the most Attack and it attacks this, get 1 gold next turn." (0.16 gold per starting copy-fight in the pass 2 soak, under a third of the Peat Cutter's 0.59).

- **Role and window:** the Wrestling Match's T1 grower, R1–R9. It's the first Bog card that makes a later board bigger, so a low roll has something to scale. Its job is to hold the enemy across and get bigger from being hit, and the Mire lock means it *is* hit, every fight.
- **Competitors at T1:** Little Nip 2/3 (Take: +1/+1 permanently), Pill Bug 1/4, Wee Wobbly 1/4, Young Brock 1/3. Nip needs a kill; the Toad only needs to be attacked, which Mire guarantees. Same growth as Nip, a surer trigger; it passes Pill Bug once the growth adds up.
- **Journey:** beside Warty Nan it takes 1–2 a hit and grows every fight; by R6 a 3/5 beside Bufo and Gideon, later fed by Tiddy. Wrestling Match, and Tongues' T1 Mire source.
- **Great buy:** R1–R2 on an empty board. It's the only Bog T1 that still matters at R9.
- **Bad buy:** R8+ as a fresh 1/3. It has no time left to grow, so buy Gideon or a T4 instead.
- **Variations:** (1) add **Bitter 1**: low 34 → 38%, but 15 words and Nan's job. (2) "+0/+2 permanently, twice a fight": a pure wall, which doesn't threaten anything but feeds Tiddy's Health plan.
- **Engine:** small: Tiddy's after-attacked script narrowed to itself, once a fight. The prototype modelled only banked gains, not the in-fight one, so it slightly understates the Toad.

### Tiddy Mun (T5, Bog folk), changed

**3/6.** "When a Mired enemy attacks one of your units: first, that unit gains +2 Health permanently. Twice a fight."
*Golden 6/12:* "When a Mired enemy attacks one of your units: first, that unit gains +4 Health permanently. Twice a fight."
*Was:* "After a Mired enemy attacks one of your units: that unit gains +1/+1 permanently. Twice a fight."

- **Why it changed:** in the three logged R9 fights, five of Tiddy's six gains went to walls that had just died (`pass2-bog-diagnosis.md`). Its job, keeping walls standing, never happened. Gaining Health before the hit fixes that, and "first" matches Bitter's timing.
- **Role and window:** the Wrestling Match's T5 payoff, R8–R13: the bog water rises and the walls get taller. Bufo goes from 8 to 10 Health before Sorrel's Bitter-shrunk 5-Attack hit. Over a few fights, the walls outgrow R10+ carries.
- **Competitors at T5:** Grizel 5/6, Lady Belladonna 4/8, Mother Goose 4/7, Reel-Mistress 4/7, the Prima Donna 2/8. The smallest body; it earns the slot with +4 lasting Health a fight on the walls being hit, keeping the Prima Donna and Gideon alive for their text.
- **Journey:** makes every T1–T4 mirer a long-term investment, the Toad included, and keeps walls alive long enough for the Peat King's Peatlings and the Lantern Man's count.
- **Great buy:** R8 with the Prima Donna and two mirers: four Health on the two walls taking the first hits.
- **Bad buy:** a Tongues board with one mirer. Only one unit is attacked by a Mired enemy, so Tiddy is a 3/6.
- **Variations:** (1) +1/+1 first, twice a fight: Bog high 72.4%, too strong on the bench. (2) +1/+1 first, once a fight: 55.2%, with a smaller payoff.
- **Engine:** small. The trigger moves from `after_attacked` to the attack's declaration, next to Bitter. The prototype puts it right after Bitter.

### Unchanged, and why

Nan, Bufo, the Chorus, the Prima Donna and the Peat King gain through Bitter first. The Peat Cutter earns 0.59 a fight, so it does its job. Gideon needed no Bitter: his counter fires more as neighbours survive. The Tongues cards are unchanged: they spend patches, and the problem was patches that didn't hold. The Mire wait stays (H8).

## 5. Corrected fixtures

The same income, climbs and tier timing as `pass2-boards.md`. The full JSON is [`evidence/pass2-bog/corrected-boards.json`](../evidence/pass2-bog/corrected-boards.json); the other ten boards are unchanged.

**Bog high (tier 5, 86 stats; was 72).** **Two Suppers**, like all five other highs. Tiddy's R8 gift to Bufo and Gideon is +0/+2, under the new text.
```
F1 Madame Bufo 3/8   F2 Gideon 4/10   F3 The Prima Donna 4/10   F4 Young Pretender 5/4
       B1 Signor Ranocchio 8/9   B2 Tiddy Mun 5/8   B3 Vaulting Hopkin 5/3
```
Economy: 62 base; seven units (21), climbs (24), two Suppers (6) = 51. Other highs: Hedgerow 72 (+21 Committee Attack), Hunters 88, Fairies 98, Oozes 79 plus Belly bodies, Birds 65 plus away Birds.

**Bog low (tier 4, 45 stats; was 35).** Madame Bufo (a T2 Bog unit, as findable as a Scarecrow) replaces the Turnip Scarecrow. Charcoal Burner, the neutral T4 that Hunters low and Birds low both found, replaces Wee Wobbly. Bridge Toad has two banked gains (Little Nip in Hunters low has two Takes).
```
F1 Bridge Toad 3/5   F2 The Peat Cutter 2/4   F3 The Natterjack Chorus 3/4   F4 Madame Bufo 1/4
       B1 Young Pretender 3/2   B2 Spitfire Sal 1/3   B3 Charcoal Burner 4/6
```
Economy: 62 base; seven units (21), delayed climbs (13) = 34. Other lows: 39–58 stats. All four enemy front slots are Mired; Sal deals 2 to each.

## 6. Results (R9, same roll, 100 seeds × sides swapped)

| Board | Published | Fair fixtures, old cards | Fair + Bitter first + Toad | **Fair + full fix** | Full fix, original fixtures |
|---|---:|---:|---:|---:|---:|
| Bog high | 0.0 | 12.1 | 51.0 | **43.3** | 3.5 |
| Bog low | 0.3 | 3.8 | 34.2 | **34.2** | 6.5 |

With the full fix, Bog high beats Birds 85%, Hunters 44%, Oozes 36%, Hedgerow 32% and Fairies 20%. Bog low beats Oozes 80%, Fairies 68% and Hunters 22%, and loses every fight to Hedgerow low (Dozey 10/16) and Birds low (94% against all lows, already flagged as generous). The other highs end at Oozes 79.3, Fairies 75.7, Hunters 41.2, Hedgerow 35.0 and Birds 25.5. Bog moves from last to third on the high roll and fourth on the low. All 13,200 fights ended `board_empty`: 0 ties, 0 attack-limit stops, 0 trigger-limit stops.

**The last column:** on the original fixtures, one Supper short, the fix leaves Bog at 3.5%: the H9 cliff. The claim is competitiveness on fixtures as generous as the others', not immunity to a stingy one.

## 7. Bog journey

| Stage | Wrestling Match (walls, Bitter, growth) | Tongues Across the Water (Snap the stuck carry) | Why not skip it |
|---|---|---|---|
| T1, R1–3 | **Bridge Toad** 1/3 (grows), Warty Nan 1/3 (Bitter, lends) | Young Pretender 3/2 | With Bitter first, Nan's 1 is a third of a T1 hit. The Toad is the first card that's still on the board at R9 |
| T2, R2–5 | Madame Bufo 1/4, Peat Cutter 2/4 (gold) | Vaulting Hopkin 3/1 | Bufo's Bitter 2 now lands before the hit. The Cutter pays about 0.6 a fight |
| T3, R4–6 | Gideon 2/6, Natterjack Chorus 3/4 | Spitfire Sal 1/3 | The Chorus spreads Mire and Bitter. Gideon counters, because his neighbours live |
| T4, R6–8 | Jenny Greenteeth 3/5 | His Highness 3/5, Signor Ranocchio 3/4 | Jenny's −2 Attack stacks with a neighbour's Bitter. Ranocchio grows |
| T5, R8–10 | **Tiddy Mun** 3/6 (Health first), Prima Donna 2/8 | Prima Donna (three patches) | Tiddy makes walls outlast a carry. The Prima Donna triples the patches |
| T6, R10+ | Peat King 5/9 | The Lantern Man 4/8 | Two finishers, one per route |

Early cards feed later ones: Toad and Nan make a wall Tiddy keeps growing, and every surviving wall keeps a patch for the Lantern Man. The shop decides the lean: Nan or Tiddy towards walls, Ranocchio or Sal towards tongues.

## 8. Limits and calls for the reviewer

- **R12 isn't benched.** Permanent Health on walls plus Bitter-first could produce slow walls late. Watch Bog's R12 rate and the fight length in the soak.
- **Bitter-first is the largest lever** (12 → 51 on its own). If costing calls it too strong, cut Prima Donna's Bitter from 3 to 2 before touching the rule.
- **The Committee** (§3) is a separate Hedgerow item. If it's nerfed, Bog high against Hedgerow rises from 32%.
- **Birds low** (94% against lows) still decides one fifth of Bog low's rate.
- The prototype patch is a diagnostic with environment flags, not an implementation. The build should follow the engine notes above and add directed tests: Bitter before Bristle; Tiddy's gain before a lethal hit; the Toad growing once when killed.

**Reproduce:** apply `evidence/pass2-bog/prototype.patch`, run `godot --headless --import` once, and copy `tools/sim/pass2_boards.gd` with `INPUT` read from an environment variable. Then run it on `corrected-boards.json` with `BITTER_FIRST=1 TIDDY_FIRST=1 TIDDY_A=0 TIDDY_H=2 TIDDY_LIMIT=2`, and with Bridge Toad's mechanics set to Mire only (its banked gains are in the fixture), `repetitions=100 seed=92100`. Revert afterwards.
