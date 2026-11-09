# Quilboar reference port (test-only), budgeted on paper

**Preset conflict, settled both ways.** The task asks for preset A (52 / 150 / 500 / 1,700 at R6 / R9 / R12 / R15). `docs/ideation/DECISIONS.md` (9 Nov, note 09h) says instead: "The Quilboar reference port is budgeted at B, not A." This spec does A, as asked. It also gives B (the default) and C, each one dial away from the preset before it (§2.3, curves in §6). Use whichever the orchestrator confirms.

**Test-only.**
- Every card here is a reference set for A/B harness runs, with ids `qb_*` behind a `reference_quilboar` pool flag.
- The Battlegrounds names are working names only.
- None of it goes into the release pool or into any branch headed for `main`.

**Paper only.** No Godot was run. The model is a scripted-arrival paper model like the other pass 3 models:
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/qport/qmodel.py`
- drivers `abl2.py`, `dials.py` and `presets.py` in the same folder.

## What I could and could not access

**Could not:**
- Video: I watched none.
- Transcripts: `bobs-ledger-transcripts/comp_transcripts.json` holds only YouTube ids for the Choose One guide (`pSFnITXBal8`, `3ebRlvd1rKI`, `IzEAFMUvG3g`) and says the caption text is deliberately not kept. I did not fetch the captions.
- HSReplay comp pages: they returned 403.

**Could** (all saved under `scratchpad/refs/`, untrusted, nothing executed):
- **Firestone** comp strategies and final-board stats:
  - `quilboar_choose_one` (power B), `quilboar_felboar_spam` (S, hard), `quilboar_gem_spam` (C);
  - slyders' tips (17 Oct 2026);
  - 40 Choose One final boards.
- **bobs-ledger** `comps.json`:
  - guide text rewritten from HSReplay comp pages (scrape of 23 Sep 2026);
  - a recorded 1st-place Felboar game (20 Oct).
- **bgbuddy.**
- **Blizzard patch notes** 36.4, 36.4.2 and 37.0.2.
- **Local data:**
  - `docs/research/battlegrounds/data/minions.csv` and `spells.json` (37.0.0, with the 37.0.2 changes applied by hand);
  - `fundamentals/web/perfect_combats.jsonl` (9 perfect-game Quilboar winners).

---

## 1. The tribe in one paragraph

**Identity and engine.** Quilboar are Battlegrounds' Blood Gem tribe. Their cards make 0-cost +1/+1 spells (Blood Gems). Uniquely, they also raise what every future gem gives: "Your Blood Gems give an extra +1/+1 this game". The most played line in the 37.0 pool is **Choose One**:
- Gem Rat (End of Turn: a Gem Day) and Bramble Tunneler (Rally: a random Choose One card) generate Choose One cards.
- Turbo Hogrider turns each such card into 2 gems on every Quilboar.
- Sanguine Refiner and Champion, Fearless Foodie and Gem Day itself raise gem size each turn and each fight.

**How good players play it.**
- **Early (turns 1–5):** they play tempo with whatever is strong. Quilboar are only 35–45% of perfect-game winners' boards, and tier 1–2 Quilboar appear in no comp's core. Geomancer, Roadboar and Crater Miner are taken for banked gems.
- **Pivot:** they commit on "Gem Rat/Bramble Tunneler + Turbo Hogrider" (bobs-ledger). slyders on Firestone: "Generate some economy and gem boost early with Bramble Tunneler, When you find Turbo Hogrider, Cycle all Choose One card". The Quilboar share then climbs to 54%, 66% and 79% on turns 6, 7 and 8.
- **Mid:** they level to tier 6 for Hogrider and scale gems "through Gem rat or Sanguine Refiner".
- **Endgame:** they cycle every decent Choose One card in the shop. The guide's only skips are Intrepid Botanist and Time Management.
  - Final boards hold Hogrider (40 of 40 Firestone boards; 100% of perfect games), Tunneler (39/40; 86%), Gem Rat (20/40; 58%) and Refiner (15/40; 47%).
  - The board is wide: the biggest unit is 26–30% of it, against 34% across BG.
  - A last Gem Confiscation goes on a carry.

**Other lines:**
- Felboar shop-buff, which needs Demons, Balinda and Brann;
- Gems from hand (Hot-Air Surveyor + Roogug + Geomant);
- Gem Barrage.

Over 36.x–37.0, Blizzard's notes moved Quilboar from the weakest tribe to one they called too strong. Then 37.0.2 cut Refiner from +1/+2 to +1/+1 and moved Surveyor to tier 5.

The reference ports **Choose One**: it is the most-played commit, and it needs no Demons or Balinda.

---

## Trivariate scaling

### The three axes and the time terms

The gain a turn is a product of three factors, and the board is their running total:

`G(t) = C(t) × A(t) × S(t)`  and  `Board(T) = bodies + Σ_{t≤T} G(t)`

| Axis | What it is | Quilboar sources |
|---|---|---|
| **C, count** | How many gems, or gem-producing Choose One cards, arrive each turn | Gem Rat's Gem Day (one a turn per Rat); Tunneler cards (per fight); shop cycling (about one Choose One unit per 4.5 gold); printed gems (Geomancer 2, Miner 2, Foodie 4, Sly 3, Roadboar 1 a fight) |
| **A, applications** | How many units each source lands on, or how many times it is cast | Hogrider (each Choose One card goes onto every Quilboar, so A ≈ 5–6); Brigand and Bonker (all units); Roogug (chains); Surveyor and Balinda (cast again); Drakkari (End of Turn twice) |
| **S, size** | Gem size, a player-wide number that applies to every future gem (not to old ones) | Gem Day, Foodie, Refiner (per fight), Champion (Battlecry and Deathrattle) |

**Time terms.**
- S grows by steps each turn (Gem Rat) and each fight (Refiner, Champion's death), so it is roughly linear in t, with a slope equal to the number of size engines owned.
- C is also roughly linear in t, because generators are bought over time.
- A saturates at the board size (7).

**Acceleration terms.**
- **The slopes step up with each engine bought:** a second Rat, a second Refiner, a golden Tunneler.
- **The axes are coupled:**
  - Gem Day is both a size step and a Choose One card, so one card moves S and, through Hogrider, A·C.
  - Thorned Trailblazer makes one card do both modes.
  - Tunneler's cards are themselves Choose One cards.

**Result: polynomial growth, not exponential.**
- With C and S linear in t and A saturating, G is about quadratic and the board about cubic.
- Measured effective degree from R11 to R15: 2.9–4.1 at BG numbers, and 2.0–2.9 at preset A, depending on where the clock starts.
- Our proportional tribes add a share of their own board (`G = r × Board`), so they grow as `(1 + r)^t`.
- The Quilboar curve is front-loaded at the commit card: Hogrider turns C into C × A in one step. Then its growth a round decays.
  - At BG numbers: ×5.76 at R11, then ×2.77, ×1.91, ×1.53, ×1.41, ×1.34.
  - At preset A: ×1.91 at R12, then ×1.50, ×1.42, ×1.33, ×1.33.
  - A ×1.5-a-round proportional tribe therefore catches up from about R16.

### Each axis switched off (typical line, board stats)

How each axis is switched off:
- **Count flat:** one Gem Day a turn from one Rat, plus printed gems on bought units. No Tunneler cards, no cycling, no second Rat, no Roadboar gems.
- **Apps off:** Hogrider and Brigand gems land on one unit (the carry).
- **Size off:** gems stay +1/+1 all game.
- **Time off:** no per-fight growth (Refiner, Champion deaths, Tunneler and Roadboar Rallies).

Count flat and time off match at R6 and R9 because Roadboar is the only per-fight source before R9.

**At BG 37.0.2 numbers, on Bramble's economy:**

| Typical line | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| Full | 54 (1.04× A) | 236 (1.57) | 6,604 (13.2) | 27,220 (16.0) |
| Count flat | 43 | 194 | 1,318 (÷5.0) | 2,452 (÷11.1) |
| Apps off | 54 | 236 | 1,763 (÷3.7) | 6,410 (÷4.2) |
| **Size off** | 52 | 125 | **517 (1.03× A, ÷12.8)** | **1,199 (0.71× A, ÷22.7)** |
| Time off | 43 | 194 | 1,506 (÷4.4) | 4,699 (÷5.8) |
| All three axes off | 43 | 123 | 178 (÷37) | 179 (÷152) |

**At the preset A port (§2):**

| Typical line | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| Full | 53 (1.02× A) | 158 (1.05) | 716 (1.43) | 2,035 (1.20) |
| Count flat | 43 | 159 | 364 (÷2.0) | 440 (÷4.6) |
| Apps off | 53 | 158 | 425 (÷1.7) | 889 (÷2.3) |
| Size off | 52 | 117 | 218 (÷3.3) | 344 (÷5.9) |
| Time off | 43 | 159 | 415 (÷1.7) | 850 (÷2.4) |
| All three axes off | 43 | 123 | 170 (÷4.2) | 161 (÷12.6) |

**Headline.** With gem size frozen, BG's Quilboar already sits on preset A at R12 (517 against 500). The size axis alone is ×13 at R12 and ×23 at R15. That is the owner's "extra scaling multiplier". The port keeps all three axes and the same order of leverage (size > count > time ≈ applications), only smaller.

### Why BG numbers "obliterate" our designs

At BG 37.0.2 numbers, the typical Quilboar line is:
- 6.7–14.5× every pass 3 line at R12, and 7.4–17.6× at R15;
- only 1.0–2.1× at R9.

So the owner's expectation holds, from Hogrider (R11) on.

Two things multiply:
1. **BG's own scale.** BG's median board at R12 is 2,598, which is 5.2× preset A. The model's typical line at BG numbers (6,604) sits near BG's perfect-game winners (7,598) and at 2.5× BG's median.
2. **The size axis puts Quilboar on BG's scale in the first place.** It is one global number, raised by several cards each turn and each fight, and fed by the same cards that drive count (Gem Day).

None of our six tribes has all three of those properties. Our panels deliberately avoided "tribe numbers". Fairies' Ring size is the only one, and it is raised mostly on tier-ups.

### The pass 3 tribes by axis, and how each fares against the port

The ratios below are each tribe line's figure from `cross-tribe.md` §2 (× typical, read as × preset A), divided by the Quilboar typical line at A (1.02 / 1.05 / 1.43 / 1.20). Fairies and Oozes figures are pre-resize, that is, at design size, which is what preset B now uses.

| Tribe | Count | Repetition | Size | Axes | Growth | Line ÷ Quilboar at R6 / R9 / R12 / R15 | Prediction |
|---|---|---|---|---|---|---|---|
| **Birds** | Rate-limited: one doubling per Bird per 2 rounds; Stork recalls per 6 gold | Thin: Redbreast 1/8, Cuckoo 1/10 to every Bird | Self-proportional (×2 own stats), no tribe number | 2 + thin | Exponential, ~×1.5/round | A: 0.77 / 0.90 / 0.86 / 0.83. D: 0.68 / 0.72 / 0.66 / 0.76 | 10–25% behind to R15. Overtakes about R17 if ×1.5 holds. Whistlers (across the biggest enemy) are worth less against a wide board |
| **Fairies** | Ring count (gold and sales: Annis, Nan, Sally, Queen) | Fetch twin; Monarch's Midsummer doubles every 3rd End of Turn | Ring size: additive and retroactive; grows on tier-ups (Cluricaun) and Lob/Silky thanks | 3 | Product (count × size) times a ×2 clock | Ring: 0.86 / 0.89 / 1.30 / 1.49. Court: 0.94 / 1.34 / 1.38 / 1.74 (design size) | The closest analogue (its own doc says "Similar to Blood Gems"). At design size it leads from R12. Resized, about 0.8× at R12 and level by R15 |
| **Bog** | Bites (Mire patches) | Tiddy funnel (half the Toll to neighbours); frog doubles neighbours every 3rd kiss | Borrowed from the enemy: a quarter of the biter's Attack; Soak keeps +1/+1 per Attack | 3, size from the enemy | Tracks the field | Court: 0.92 / 0.76 / 0.83 / 1.20. Swamp: 0.97 / 0.77 / 0.64 / 0.83 | Behind R9–R13, during Quilboar's hump. Court is ahead by R15. Head to head it does better than the totals say, because gemmed Quilboar attackers feed its bites |
| **Hunters** | Takes per fight | Little: the Glutton sends half of each Take to the carry; the Laird doubles shares; Pelts a quarter. Concentrates rather than spreads | Enemy-proportional: half the quarry's stats | 2 + thin | Tracks the field | A: 1.02 / 1.10 / 0.73 / 0.93. B: 1.04 / 1.09 / 0.84 / 1.18 | Level R6–R9, behind at R12, level or ahead by R15. Gains most from eating Quilboar's R12 hump, though a wide board (biggest unit about 0.33) limits each Take |
| **Oozes** | Meals a turn (Digest, Nell, Slice; bought with gold) | Elder gives half of each meal to the family; Aspic +50% | Self-proportional: Stone Soup puts r × the biggest Ooze on every shop unit | 3, compounding size | Exponential, ×1.56/round | B: 1.41 / 1.44 / 1.17 / 1.81. Pot Luck: 1.21 / 1.32 / 1.29 / 1.33 (design size) | The only real trivariate peer, and its size axis compounds. Level at R12 after the resize (r = 1/12), clearly ahead from R15 |
| **Hedgerow** | Hayward: +1/+1 per gold cashed, to all Hedgerow this game (a Quilboar-like count × applications counter); Supper food | Lollop a tenth to the Line; Committee a fifth of the smallest to all; Mallow doubles the runt | Dozey doubles every 3 turns in his slot (×1.26/round); food fed before he wakes is doubled with him | 3, mostly slow | A slow exponential plus one additive counter | Supper: 1.27 / 1.21 / 0.87 / 1.16. Parish: 0.85 / 0.84 / 0.70 / 1.30 | Ahead R6–R9, behind at R12, ahead at R15 |
| **Quilboar (port)** | Gem Days, Tunneler cards, cycling | Hogrider fan-out, Brigand, Bonker, Roogug, Surveyor | Gem size: additive, global, not retroactive | 3, additive | Polynomial (degree 2–3), front-loaded | 1 | Peaks relative to everyone at R11–R13, then is caught by the proportional tribes |

**What the reference teaches.**
- Trivariate additive scaling gives Quilboar a timing identity: strongest relative to others just after the commit, weaker late.
- Within it, the size axis is the strongest dial.
- The acceleration comes from coupling: one card that moves two axes. Limiting coupling is a gentler guardrail than limiting any one axis.

---

## 2. Every card, tier by tier

**Scale factor and why.**
- **Kept ×1, at BG 37.0.2:** bodies, tiers, the base gem (+1/+1) and every gem count. With BG numbers on Bramble's economy, the typical line is 54 at R6 (1.04× A). So the early game is already on target, and a uniform factor would starve R6.
- **All the excess is growth, so only growth is cut:**
  1. Every gem-size step ×½.
  2. Tunneler and Refiner trigger once a fight.
  3. Hogrider at A plays 1 gem on your other Quilboar per 2 Choose One cards.
  4. Brigand ÷3.
- **Effective factor:** ÷9.2 on the R12 board (6,604 → 716) and ÷13.4 at R15.
- **Why halves rather than whole numbers:** no combination of integer-only changes reached the band (the best was about 2.85× A at R12).
- **Why the rate limits:** "once a fight" and "every 2nd card" are the integer way to write ½ of a 1-count effect. The counter copies Felboar's "(3 left!)" pattern.

Text conventions:
- Bramble text is written for preset A.
- Battlecry → "When played"; Deathrattle → "When this dies"; Rally → "When this attacks".
- Gems played during a fight last that fight only, unless the text says otherwise (as in BG).
- **Changed** marks a number or rate change.

### 2.1 Units

| T | BG working name | BG stats | BG text (37.0.2) | Bramble id | Bramble T, stats | Bramble text (preset A) | Golden |
|---|---|---|---|---|---|---|---|
| 1 | Razorfen Geomancer | 2/1 | Battlecry: Get 2 Blood Gems. | `qb_razorfen_geomancer` | 1, 2/1 | When played: get 2 Blood Gems. | 4/2; 4 gems |
| 1 | Tusked Camper | 2/3 | Rally: This plays a Blood Gem on itself. | `qb_tusked_camper` | 1, 2/3 | When this attacks: play a Blood Gem on it. | 2 gems |
| 2 | Crater Miner | 2/2 | Choose One – Get 2 Blood Gems; or Get a Gem Day. | `qb_crater_miner` | 2, 2/2 | Choose one: get 2 Blood Gems; or get a Gem Day. | 4 gems; or 2 Gem Days |
| 2 | Prodigious Tusker | 2/5 | Whenever another friendly minion attacks, this plays a Blood Gem on it. | `qb_prodigious_tusker` | 2, 2/5 | When another of your units attacks: play a Blood Gem on it. | 2 gems |
| 2 | Roadboar | 2/4 | Rally: Get a Blood Gem. | `qb_roadboar` | 2, 2/4 | When this attacks: get a Blood Gem. | 2 gems |
| 3 | Fearless Foodie | 2/4 | Choose One – Your Blood Gems give an extra +1/+1 this game; or Get 4 Blood Gems. | `qb_fearless_foodie` | 3, 2/4 | **Changed:** Choose one: your Blood Gems give an extra **+½/+½** this game; or get 4 Blood Gems. | +1/+1; or 8 gems |
| 3 | Gem Rat | 4/4 | At the end of your turn, get a Gem Day. | `qb_gem_rat` | 3, 4/4 | End of Turn: get a Gem Day. | 2 Gem Days |
| 3 | Mangled Bandit | 3/3 | Activate (0): Discard a card to get 3 Blood Gems. | `qb_mangled_bandit` | 3, 3/3 | Activate (0 gold): discard a card to get 3 Blood Gems. | 6 gems |
| 3 | Sly Infiltrator | 4/5 | Choose One – Gain 2 free Refreshes; or Get 3 Blood Gems. | `qb_sly_infiltrator` | 3, 4/5 | Choose one: 2 free refreshes; or get 3 Blood Gems. | 4 refreshes; or 6 gems |
| 3 | Thorned Trailblazer | 4/5 | One Choose One card each turn has both effects combined. | `qb_thorned_trailblazer` | 3, 4/5 | One Choose One card each turn has both effects. (1 left!) | Two cards |
| 3 | Trench Fighter | 3/3 | At the end of your turn, get a Gem Confiscation. | `qb_trench_fighter` | 3, 3/3 | End of Turn: get a Gem Confiscation. | 2 |
| 4 | Bonker | 2/7 | Windfury. Rally: This plays a Blood Gem on all your other minions. | `qb_bonker` | 4, 2/7 | Attacks twice. When this attacks: play a Blood Gem on each of your other units. | 2 gems |
| 4 | Bramble Tunneler | 3/6 | Rally: Get a random Choose One card. | `qb_bramble_tunneler` | 4, 3/6 | **Changed:** **Once a fight,** when this attacks: get a random Choose One card. | 2 cards |
| 4 | Geomagus Roogug | 4/6 | Divine Shield. Whenever a Blood Gem is played on this, this plays a Blood Gem on a different friendly minion. | `qb_geomagus_roogug` | 4, 4/6 | Shield. When a Blood Gem is played on this: play a Blood Gem on another of your units (random). | 2 gems |
| 4 | Razorfen Flapper | 5/3 | Battlecry and Deathrattle: Get a Blood Gem Barrage. | `qb_razorfen_flapper` | 4, 5/3 | When played, and when this dies: get a Blood Gem Barrage. | 2 |
| 4 | Snare Trapper | 4/4 | Choose One – Get a random Quilboar; or Increase your maximum Gold by 1. | `qb_snare_trapper` | 4, 4/4 | Choose one: get a random Quilboar; or +1 maximum Gold (4.1.4). | 2; or +2 |
| 5 | Hot-Air Surveyor (T4 before 37.0.2) | 3/7 | Blood Gems played from your hand cast an extra time. | `qb_hot_air_surveyor` | 5, 3/7 | Blood Gems you play from your hand cast an extra time. | 2 extra |
| 5 | Felboar (Demon, Quilboar) | 2/6 | After you cast 3 spells, consume a minion in the Tavern to gain its stats. | `qb_felboar` | 5, 2/6 | Quilboar only. After you cast 3 spells: eat a unit in the shop and gain its stats. (3 left!) | Double stats |
| 5 | Razorfen Vineweaver | 4/4 | Rally: This plays 4 permanent Blood Gems on itself. | `qb_razorfen_vineweaver` | 5, 4/4 | When this attacks: play 4 Blood Gems on it that last beyond this fight. | 8 gems |
| 5 | Sanguine Refiner | 3/8 | Rally: Your Blood Gems give an extra +1/+1 this game. | `qb_sanguine_refiner` | 5, 3/8 | **Changed:** **Once a fight,** when this attacks: your Blood Gems give an extra **+½/+½** this game. | +1/+1 |
| 6 | Sanguine Champion | 9/4 | Battlecry and Deathrattle: Your Blood Gems give an extra +2/+1 this game. | `qb_sanguine_champion` | 6, 9/4 | **Changed:** When played, and when this dies: your Blood Gems give an extra **+1/+½** this game. | +2/+1 |
| 6 | Turbo Hogrider | 6/8 | After you play a Choose One card, this plays 2 Blood Gems on all your Quilboar. | `qb_turbo_hogrider` | 6, 6/8 | **Changed:** After you play **2** Choose One cards: play **a** Blood Gem on each of your **other** Quilboar. (2 left!) | After each Choose One card |
| 6 | Veteran Brigand | 8/8 | Choose One – This plays 3 Blood Gems on all your minions; or cast Blood Gem Barrage 3 times. | `qb_veteran_brigand` | 6, 8/8 | **Changed:** Choose one: play **a** Blood Gem on each of your units; or cast Blood Gem Barrage **once**. | 2 gems; or twice |
| 6 | Victorious Geomant | 10/10 | Activate (2): Get 6 Blood Gems. Cast any that don't fit on your left-most minion. | `qb_victorious_geomant` | 6, 10/10 | Activate (2 gold): get 6 Blood Gems. Any that don't fit in your hand are played on your first unit (reading order). | 12 gems |

**Left out:**
- Duos-only cards (Generous Geomancer, Loyal Mobster);
- tier 7 (Jailbird Juggernaut);
- trinkets such as Jar o' Gems (Bramble has none).

### 2.2 Tokens

| BG working name | BG cost and text | Bramble id | Bramble (preset A) |
|---|---|---|---|
| Blood Gem | 0: +1/+1 | `qb_blood_gem` | Spell, 0 gold, aimed at one of your units: it gets **+[gem size]** (starts at +1/+1). |
| Gem Day | Choose One – your Blood Gems give an extra +1 Attack this game; or +1 Health | `qb_gem_day` | **Changed:** Choose one: your Blood Gems give an extra **+½ Attack** this game; or **+½ Health**. Spell, 0 gold (BG's cost isn't in our local data; the model assumes 0, so check it). It counts as a Choose One card. |
| Gem Confiscation | 1: This plays 3 Blood Gems on a minion. It steals all Blood Gems from its neighbors. | `qb_gem_confiscation` | 1 gold, aimed: play 3 Blood Gems on a unit. It takes all Blood Gem stats from the units **beside** it. |
| Blood Gem Barrage | 1: After the Tavern is Refreshed this game, give its minions +2/+2 worth of Blood Gems. | `qb_blood_gem_barrage` | **Changed (brought in line with Brigand):** 1 gold: for the rest of the game, after your shop is refreshed, play 2 Blood Gems on each shop unit. This reads "+2/+2 worth" as 2 gems at your current gem size; check it against BG behaviour. |

**Halves rule (A and B).**
- Gem size is shown with halves, like Ring size (8.5.4).
- A batch of gems on one unit adds up before rounding down.
- The unit keeps any leftover half as a pip, and two pips make +1.
- The model assumes no rounding loss.
- Rejected alternative: "base +2/+2 and half the counts", because it doubles every 1-gem card.

### 2.3 Dials by preset

| Dial | BG 37.0.2 (test switch "uncut") | A (fallback) | **B (default)** | C |
|---|---|---|---|---|
| Gem-size steps (Gem Day, Foodie, Refiner, Champion) | full | ½ | ½ | full |
| Hogrider | 2 gems on all your Quilboar, after each card | 1 gem on other Quilboar, after every 2nd card | 1 gem on other Quilboar, after each card (the 36.4 text) | as B |
| Tunneler, Refiner | every Rally | once a fight | once a fight | once a fight |
| Brigand | 3 gems; Barrage ×3 | 1; ×1 | 1; ×1 | 1; ×1 |
| Typical line, R6 / R9 / R12 / R15 | 54 / 236 / 6,604 / 27,220 | 53 / 158 / 716 / 2,035 | 53 / 158 / 998 / 3,136 | 54 / 200 / 1,731 / 5,804 |
| R12 against its target | 13.2× A | 1.43× A | 1.11× B (900) | 0.96× C (1,800) |

- B and C reach their targets by raising rates, not bodies, as the plan requires.
- At C every size step is a whole number, so there are no halves.

Dial file, in the style of `rates.json`:

```json
"quilboar_ref": {
  "A": {"gem_size_step": 0.5, "hogrider_every": 2, "hogrider_gems": 1, "hogrider_targets": "other_quilboar", "tunneler_per_fight": 1, "refiner_per_fight": 1, "brigand_gems": 1, "brigand_barrage_casts": 1},
  "B": {"gem_size_step": 0.5, "hogrider_every": 1, "hogrider_gems": 1, "hogrider_targets": "other_quilboar", "tunneler_per_fight": 1, "refiner_per_fight": 1, "brigand_gems": 1, "brigand_barrage_casts": 1},
  "C": {"gem_size_step": 1.0, "hogrider_every": 1, "hogrider_gems": 1, "hogrider_targets": "other_quilboar", "tunneler_per_fight": 1, "refiner_per_fight": 1, "brigand_gems": 1, "brigand_barrage_casts": 1},
  "uncut": {"gem_size_step": 1.0, "hogrider_every": 1, "hogrider_gems": 2, "hogrider_targets": "all_quilboar", "tunneler_per_fight": null, "refiner_per_fight": null, "brigand_gems": 3, "brigand_barrage_casts": 3}
}
```

**Each lever restored to its BG value, one at a time, from A** (typical line, R12 / R15):

| Lever restored | R12 | R15 |
|---|---|---|
| Size steps full | 1,213 | 3,727 |
| Hogrider at the 36.4 text | 998 | 3,136 |
| Hogrider at the 37.0.2 text | 1,799 | 6,372 |
| Tunneler every Rally | 1,004 | 3,325 |
| Refiner every Rally | 832 | 2,465 |
| Brigand 3 gems | 878 | 2,790 |
| No shop cycling | 587 | 1,108 |

---

## 3. Mechanic mapping

| BG mechanic | Bramble equivalent | Existing or new |
|---|---|---|
| Blood Gem (0-cost +1/+1 spell) | `kind: spell`, `aim: unit` (friendly), effect `gem {count: 1}`. Played from hand it is a cast and fires `on_spell_cast` | Spell kind exists; `gem` is **new** |
| "Your Blood Gems give an extra +X/+Y this game" | Player stat `gem_size` (attack, health, in halves; starts 1/1), changed by effect `gem_size_add`. Not retroactive | **New**; Ring size (8.5.4) is the display precedent |
| "This plays N Blood Gems on X" (played by a unit) | `gem {count, target}` using existing selectors (self, all, other_tribe, random_other, beside). **Not a cast:** it fires no `on_spell_cast`, as in BG | **New** effect, existing selectors |
| Gems during a fight | Fight-only unless `permanent: true` (Vineweaver). In the recruit phase they are permanent | **New** flag |
| Choose One | Card field `modes: [effects, effects]`, tag `choose_one`, trigger `on_choose_one_played` (after the chosen mode resolves). Hogrider at A adds the counter `every: 2` | **New**; "every Nth" counters exist (Monarch, frog) |
| Thorned Trailblazer | `rule` query `choose_one_both`, with a per-turn count shown as "(1 left!)" | **New** query |
| Rally / Battlecry / Deathrattle / End of Turn | `on_attack` / `on_play` / `on_death` / `end_of_turn` | Existing |
| Windfury (Bonker) | Repeat attack (9.4.11) | Existing rule |
| Divine Shield (Roogug) | Shield | Existing |
| Activate (Bandit 0, Geomant 2) | Extend `activated` from heroes to units, with a gold cost and BG's use limit | **New** for units |
| Discard (Bandit) | A cost step: pick a card in hand to remove | **New** |
| Random Choose One card (Tunneler) | `add_card {random: {tag: choose_one}}`. Pool: qb_ Choose One units at or below your tier (Miner, Foodie, Sly, Trapper, Brigand). Marked Created, so it sells for 0 (4.3.3) | `add_card` exists; the filter is **new** |
| Random Quilboar (Trapper) | `add_card {random: {tribe: quilboar}}`, Created | As above |
| "+1 maximum Gold" | `rule` on the income ceiling (4.1.4) | Existing rule; check that the query name is `income` |
| Free Refreshes (Sly) | `free_refresh` | Existing |
| Barrage ("after the Tavern is refreshed this game") | `on_refresh` + selector `shop` + `gem`, on a **player-scoped** listener that stacks (no unit holds it). Reuse Stone Soup's shop-buff path | Trigger and selector exist; player scope is **new** |
| Felboar ("after 3 spells, consume a Tavern minion") | `on_spell_cast` counter of 3 → eat a shop unit for its stats. Reuse the Oozes' meal effect if its schema fits, else **new** `consume_shop` | Partly existing |
| "Whenever a Blood Gem is played on this" (Roogug) | **New** trigger `on_gem_received`. Loop guard: a gem played by a Roogug trigger can't trigger a Roogug again in the same chain (README amendment 11's spirit) | **New** |
| Surveyor ("cast an extra time") | `rule` query `hand_gem_extra_casts` (+1, golden +2). Each extra cast counts as a cast, so it fires `on_spell_cast`; check that this matches BG | **New** |
| Confiscation's steal | A per-unit gem ledger (stats received from gems), plus `steal_gems {from: beside}` | **New** |
| Quilboar tribe | Tribe `quilboar` (test-only). The Harvest Supper bonus (+1/+1, up to +3/+3) applies | Existing |

### Exemptions that keep the port faithful

- **Hero and spell scaling** (flat gains become X% of the recipient's stats, switched on in both presets): Blood Gems, Gem Day and Confiscation must be `scaling_exempt`. Otherwise +1/+1 turns into a share of the unit's stats, the size axis becomes proportional, and it is no longer Quilboar.
- **Shy thanks** (12.1.7): gems must not thank Shy units (`thanks_shy: false`; precedent: the Hunters' Pelt). Otherwise 30 gems a turn would pay 60 gold.

### Cross-tribe hazards for the harness to report

| Card | What it does with gems |
|---|---|
| Pipistrelle Echo | A Balinda-like card: gems aimed at it also hit the units beside it, so ×3 applications on hand gems |
| Moss Ooze | Echoes gem stats into its Belly, so a double count |
| Cricket Busker | 1 gold a turn; harmless |
| Prince Restored | Makes Confiscation or Barrage free |
| Click Beetle (When-played doubler) | Repeats Geomancer's gems and Champion's When-played size. It does **not** repeat a Choose One, because Choose One isn't a When-played effect, as with Brann in BG |
| `scale_doubler` (the End of Turn doubler) | Works as Drakkari: doubles Gem Rat and Trench Fighter |

### Position words on the 4-front / 3-back board

- **"Neighbors", "adjacent", "left/right"** map to Bramble's **beside**: same row, left and right. Bramble's "neighbour" (beside plus in front and behind, up to 4) is not used: it would make Confiscation up to 2× stronger than BG. A carry in F2, F3 or B2 has two units beside it; in F1, F4, B1 or B3 it has one.
- **"Left-most"** (Geomant's overflow) maps to the **first unit in reading order**: F1, else the next filled slot. This keeps BG's link between left-most and first to attack.
- **"Attacks first":** no Quilboar card says it. What matters is how often a Rally unit attacks. Bramble attacks in reading order (F1…B3).
  - A back-row Rally unit attacks later in each cycle but lives longer (back-row protection).
  - The model assumes 1.5 attacks a fight up to R8 and 2 after.
  - "Attacks immediately" (9.4.12) isn't needed.
- **"All your minions"** maps to all your units (up to 7). **"A different friendly minion"** maps to a random other unit.

---

## 4. Neutrals and early flex

Kept minimal. The port adds **no** new neutral cards for the reference line.

| BG card | Role in the real lines | Port |
|---|---|---|
| Drakkari Enchanter (T5 1/5, End of Turn effects trigger twice) | A Choose One add-on (Firestone): doubles Gem Rat's Gem Day and Trench Fighter's Confiscation | Use Bramble's existing End of Turn doubler sweep lever (`scale_doubler`). Under amendment 11, Gem Day is not a doubling, so it does repeat. No new card |
| Brann Bronzebeard (T5 2/4, Battlecries trigger twice) | Felboar line | Click Beetle, once it lands. Doesn't repeat a Choose One |
| Balinda Stonehearth (T6 6/6, spells on friendly minions cast twice) | Felboar and Gems-from-hand lines | Not ported for the reference line. Optional `qb_balinda` (T6 6/6: "Spells you aim at your units cast twice"), behind the same test flag, only for `quilboar_gems_from_hand`. Default off |
| A Dragon Rally add-on in the Choose One guide (BG36_243 in the guide's list) | Choose One add-on | Not ported |

**Early flex.** BG winners' boards before turn 6 are 55–65% non-Quilboar. The common picks are tier 1–2 tempo and economy units: Busker, Laureate, Cord Puller and Risen Rider in our data. The harness lobby already offers Bramble's own pool, so the bot flexes there by role:
- economy: `one_swallow`, `money_spider`;
- Shield holder: Shieldbug, once built;
- body that summons on death: `earwig_mother`;
- sticky front-liners: Bog's tier 1–2 mirers.

The policy in §5 picks them by stats and the tribe weight. No BG neutral port is needed.

---

## 5. Harness line policies

Birds shape plus the loader fields (`priority`, `climb_schedule`, `save_threshold`, `save_until`, `engine`, `priority_weight`, `tribe_weight`, `commit_round`, `engine_pieces`). The loader formats need checking against `tools/sim/line_profiles.committed.json` on `ideation/harness`.

```json
{
  "quilboar_choose_one": {
    "tribe": "quilboar",
    "test_only": true,
    "pool_flag": "reference_quilboar",
    "engine_flag": true,
    "engine": true,
    "engine_pieces": ["qb_turbo_hogrider", "qb_bramble_tunneler", "qb_gem_rat", "qb_sanguine_refiner"],
    "commit_round": 6,
    "commit_rule": "Before R6, flex. From R6, or earlier on the turn Gem Rat or Bramble Tunneler is on board, the tribe weight applies to every buy (guides: 'Gem Rat/Bramble Tunneler + Turbo Hogrider').",
    "priority_weight": 14,
    "tribe_weight": 4,
    "buy_priority_by_tier": {
      "T1": ["qb_razorfen_geomancer", "qb_tusked_camper"],
      "T2": ["qb_roadboar", "qb_crater_miner", "qb_prodigious_tusker"],
      "T3": ["qb_gem_rat", "qb_trench_fighter", "qb_thorned_trailblazer", "qb_fearless_foodie", "qb_sly_infiltrator", "qb_mangled_bandit"],
      "T4": ["qb_bramble_tunneler", "qb_snare_trapper", "qb_geomagus_roogug", "qb_bonker", "qb_razorfen_flapper"],
      "T5": ["qb_sanguine_refiner", "qb_razorfen_vineweaver", "qb_hot_air_surveyor"],
      "T6": ["qb_turbo_hogrider", "qb_sanguine_champion", "qb_veteran_brigand", "qb_victorious_geomant"]
    },
    "buy_priority": ["qb_turbo_hogrider", "qb_bramble_tunneler", "qb_gem_rat", "qb_sanguine_refiner", "qb_thorned_trailblazer",
                     "qb_trench_fighter", "qb_sanguine_champion", "qb_fearless_foodie", "qb_snare_trapper", "qb_sly_infiltrator",
                     "qb_crater_miner", "qb_veteran_brigand", "qb_roadboar", "qb_razorfen_geomancer", "qb_geomagus_roogug",
                     "qb_bonker", "qb_razorfen_vineweaver", "qb_prodigious_tusker", "qb_tusked_camper", "qb_mangled_bandit",
                     "qb_razorfen_flapper", "qb_hot_air_surveyor", "qb_victorious_geomant"],
    "priority": "same as buy_priority",
    "max_copies": {"qb_bramble_tunneler": 3, "qb_gem_rat": 2, "qb_turbo_hogrider": 2, "qb_sanguine_refiner": 2, "default": 1,
                   "triple": "buy a third copy only when it makes a golden; Tunneler first"},
    "climb": {"T2": 2, "T3": 4, "T4": 6, "T5": 9, "T6": 11},
    "climb_schedule": {"2": 2, "3": 4, "4": 6, "5": 9, "6": 11},
    "harvest_supper_rounds": [7, 9, 11],
    "save_threshold": 0,
    "save_until": null,
    "save_rule": "Spend out every turn. The one save: on the turn before a scheduled tier-up, keep what next turn's discounted tier cost needs beyond next turn's income. Shop cycling spends only what that reserve leaves.",
    "flex_policy": {
      "until_round": 6,
      "pick": "the best unit in the shop by stats per gold, any tribe; tribe_weight 4 for qb_ cards",
      "always_take_if_offered": ["qb_razorfen_geomancer", "qb_roadboar", "qb_crater_miner", "qb_gem_rat"],
      "max_flex_kept": 2,
      "sell_first": "flex units, as soon as a Quilboar needs the slot"
    },
    "choose_one_policy": {
      "qb_gem_day": "the lower of Attack and Health (keeps the gem even)",
      "qb_crater_miner": "2 gems before R9 and before Hogrider; Gem Day after",
      "qb_fearless_foodie": "4 gems before R9 and before Hogrider; the size mode after",
      "qb_sly_infiltrator": "3 gems; take the 2 refreshes instead while cycling when the shop holds no Choose One unit",
      "qb_snare_trapper": "+1 maximum Gold",
      "qb_veteran_brigand": "the gem mode",
      "trailblazer_both": "Foodie first, then Crater Miner, then Gem Day",
      "order": "with Hogrider on board, play Gem Days first, then Tunneler cards, then cycled units"
    },
    "gem_policy": {
      "hand_gems": "half on the carry, half spread over the other keepers; never on a unit sold this turn",
      "carry": "qb_gem_rat, else the biggest keeper",
      "gem_confiscation": "on the carry, in the slot with the most gemmed units beside it"
    },
    "cycle_policy": {
      "from_round": 8,
      "min_tier": 3,
      "requires": "qb_turbo_hogrider or qb_bramble_tunneler on board",
      "rule": "keep one slot open; buy every Choose One unit the shop shows (Miner, Foodie, Sly, Trapper, Brigand), play it, sell it; refresh to look while spare gold is 4.5 or more; at most 4 a turn; the last one played stays in the open slot and fights",
      "tunneler_cards": "play, then sell for 0 (Created)"
    },
    "keeper_cap": {"R1": 7, "engine_out": 6},
    "sell_rank": ["flex", "qb_crater_miner", "qb_snare_trapper", "qb_fearless_foodie", "qb_sly_infiltrator", "qb_tusked_camper",
                  "qb_prodigious_tusker", "qb_razorfen_geomancer", "qb_roadboar", "qb_mangled_bandit", "qb_bonker",
                  "qb_razorfen_flapper", "qb_geomagus_roogug", "qb_trench_fighter", "qb_thorned_trailblazer", "qb_gem_rat",
                  "qb_razorfen_vineweaver", "qb_hot_air_surveyor", "qb_felboar", "qb_veteran_brigand", "qb_victorious_geomant",
                  "qb_sanguine_champion", "qb_sanguine_refiner", "qb_bramble_tunneler", "qb_turbo_hogrider"],
    "placement": "back row: the carry in B2, Bramble Tunneler and Sanguine Refiner in B1 and B3 (they attack and survive, so they Rally more); front row: Sanguine Champion (its death raises gem size), Turbo Hogrider, Snare Trapper, the cycle slot, Trench Fighter"
  },
  "quilboar_gems_from_hand": {
    "tribe": "quilboar",
    "test_only": true,
    "pool_flag": "reference_quilboar",
    "engine_flag": false,
    "note": "Second BG line, not modelled; a check run only. Turn on qb_balinda only for this line.",
    "engine_pieces": ["qb_hot_air_surveyor", "qb_geomagus_roogug", "qb_sanguine_refiner", "qb_victorious_geomant"],
    "commit_round": 7,
    "buy_priority": ["qb_hot_air_surveyor", "qb_sanguine_refiner", "qb_geomagus_roogug", "qb_victorious_geomant", "qb_mangled_bandit",
                     "qb_sanguine_champion", "qb_bramble_tunneler", "qb_fearless_foodie", "qb_razorfen_geomancer", "qb_roadboar"],
    "climb": {"T2": 2, "T3": 4, "T4": 6, "T5": 9, "T6": 11},
    "harvest_supper_rounds": [7, 9, 11],
    "save_threshold": 0,
    "gem_policy": "play every hand gem on Roogug while it lives (each one chains to another unit); Geomant every turn; the carry first in reading order for Geomant's overflow",
    "placement": "the carry in F1; Roogug in the back row"
  }
}
```

**Bot needs.**
- The Choose One mode choices.
- The cycle loop: buy, play, sell, refresh, with one open slot.
- Hand-gem placement and the Confiscation target.
- Tunneler cards played and sold for 0.

Without these, Quilboar looks weak for the wrong reason. Shop cycling alone is worth ×1.8 at R15.

---

## 6. Paper curve against preset A

### Three lines at preset A

Board stats (× preset A; biggest unit's share of the board):

| Line | R6 | R9 | R12 | R15 | Growth a round, R8–R14 |
|---|---|---|---|---|---|
| **Typical** | 53 (1.02; 0.30) | 158 (1.05; 0.41) | 716 (1.43; 0.37) | 2,035 (1.20; 0.32) | ×1.56 |
| Strong | 66 (1.27) | 189 (1.26) | 897 (1.79; 0.32) | 2,929 (1.72; 0.30) | ×1.57 |
| Low roll | 60 (1.15) | 142 (0.95) | 285 (0.57; 0.46) | 1,198 (0.70) | ×1.40 |

How the lines differ:
- **Typical:**
  - climbs to T2 at R2, T3 R4, T4 R6, T5 R9, T6 R11;
  - Gem Rat at R5, Trench Fighter R6, Tunneler R7, Refiner R9, a second Tunneler R10, Hogrider R11, Champion R13, golden Tunneler R14.
- **Strong:**
  - climbs on time (T5 at R8, T6 at R10);
  - two Rats, a golden Tunneler at R11, a second Hogrider at R12, two Refiners.
- **Low roll:**
  - climbs late (T4 at R7, T5 R10, T6 R12);
  - one Tunneler, no Refiner, Hogrider not until R13.

The typical line's gem size is 1½/1 at R6, 3/2½ at R9, 7/6½ at R12 and 13/13 at R15. It plays 3–7 Choose One cards a turn once the engine runs.

### Typical line round by round, preset A

| Round | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|
| Board | 103 | 105 | 158 | 240 | 375 | 716 | 1,075 | 1,527 | 2,035 | 2,705 |
| × preset A | 1.39 | 1.00 | 1.05 | 1.07 | 1.12 | 1.43 | 1.43 | 1.35 | 1.20 | 1.06 |
| Growth | | ×1.02 (saving for T5) | ×1.50 | ×1.52 | ×1.56 | ×1.91 (Hogrider) | ×1.50 | ×1.42 | ×1.33 | ×1.33 |

R12 is Hogrider's step. No uniform cut removes the hump; only Hogrider's own dial does, and B's text makes it bigger. The relative strength falls back after R13, which is the polynomial shape.

### Typical line's board at preset A (attack/health)

| Round | Units |
|---|---|
| R6 | Geomancer 9/7, Gem Rat 5/5, Roadboar 3/5, flex 4/4, Crater Miner 3/3, Trench Fighter 3/3 |
| R9 | Gem Rat 35/29, Trailblazer 7/7, Tunneler 6/8, Refiner 4/9, Trench Fighter 6/6, Foodie 3/5, Crater Miner 2/2 |
| R12 | Gem Rat 139/129, Tunneler 51/51, Refiner 49/52, Tunneler 48/49, Foodie 33/34, Hogrider 18/20, Trapper 8/7 |
| R15 | Gem Rat 332/320, golden Tunneler 277/274, Refiner 190/190, Champion 150/142, Hogrider 58/59, Trapper 10/10 |

The board is wide, with the biggest unit at 0.31–0.37, as in BG (0.26–0.30 for Quilboar, 0.34 across BG). Hogrider stays small because it never gems itself.

### At B and C, and BG uncut, for comparison

| Preset | Line | R6 | R9 | R12 | R15 | Growth a round, R8–R14 |
|---|---|---|---|---|---|---|
| B | Typical | 53 | 158 | 998 | 3,136 | ×1.67 |
| B | Strong | 66 | 189 | 1,427 | 4,945 | ×1.70 |
| B | Low roll | 60 | 142 | 285 | 1,708 | ×1.47 |
| C | Typical | 54 | 200 | 1,731 | 5,804 | ×1.81 |
| C | Strong | 72 | 244 | 2,501 | 9,221 | ×1.82 |
| C | Low roll | 60 | 156 | 408 | 3,072 | ×1.60 |
| BG 37.0.2 | Typical | 54 | 236 | 6,604 | 27,220 | ×2.28 |
| BG 37.0.2 | Strong | 72 | 274 | 9,400 | 43,250 | ×2.27 |
| BG 37.0.2 | Low roll | 60 | 159 | 513 | 8,926 | ×1.93 |

- **BG checks on the uncut model:**
  - The typical line at R13–R14 is 12.6k–19.3k, against BG Quilboar perfect-game finals (median 28,831) and Choose One final boards (44,467).
  - BG's Quilboar winners by turn (n = 9) are 18 / 32 / 52 / 83 / 144 / 229 on turns 3–8. The model starts below them (54 at R6), because winners flex strong early units.
- **Checkpoint criterion 2 (×1.3 a round, R8–R14):** every line at every preset passes on paper.
- **Spread between strong and low roll at R12:** 3.1× at A, 5.0× at B, 6.1× at C. This is the cost of one commit card.

### Read the numbers as paper

- **Arrivals are scripted, not shopped.** The "typical" line is a well-played commit. At BG numbers it sits near perfect-game winners, so expect the harness median for Quilboar below it, as for the other pass 3 models.
- **The model leaves out or simplifies:**
  - rounding loss from halves (it assumes no loss);
  - Crater Miner's late Gem Day as another Choose One card (it undercounts);
  - Confiscation's steal (it treats it as zero-sum);
  - Barrage, Felboar, Bonker, Tusker, Roogug and Surveyor (the typical line doesn't use them).
- **Combat is assumed,** not simulated: 1.5–2 Rally attacks a fight, Champion dying in half the fights, and 4.5 gold per cycled Choose One unit with at most 4 a turn. The Rally count alone moves R15 between 1,712 and 2,444.

### First harness checks

1. **The R12 hump:** does Hogrider's step show in lobbies, and does it decide fights before they start (a cut trigger)?
2. **Head to head, Quilboar against each tribe at R9 / R12 / R15:** the §Trivariate predictions, especially Hunters and Bog borrowing from the gemmed board, and Oozes overtaking from R15.
3. **The line spread** (strong against low roll) and how often the line never finds Hogrider.
4. **The cross-tribe hazards:** how much Pipistrelle Echo, Moss Ooze, the End of Turn doubler and Click Beetle add on Quilboar boards.
5. **The uncut switch** reproduces "obliterate" (about 7–18× every tribe line from R12): proof that the port is faithful and that the cuts do the work.