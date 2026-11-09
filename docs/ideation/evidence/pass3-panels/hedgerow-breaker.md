# Hedgerow pass 3: the breaker's critique

9 Nov 2026. The adversarial critic for the Hedgerow panel (Track C, `docs/ideation/plan-scale-rework.md`). The panel has one design, `hedgerow-engine.md` (the Long Sleep, a light pass).

What I read:
- the owner's notes 09a, 09c, 09d and 08e;
- `fundamentals.md` §1 and §3, and the plan;
- rulebook §3.4, 4, 5.1, 6.1, 7, 8–9 and 12.1;
- the wording guide;
- the other tribes' pass 3 designs, to look for overlaps.

What I ran:
- the designer's model, probed with the lines a real player would take;
- a rough fight model for the R9 and R12 boards: plain even boards, no summons, and no keywords except Hunker and Bristle;
- a rough model of the hold-everything line, which the design doesn't model.

Nothing ran in Godot. The probes are in this folder. `hedgerow-breaker-model.py` is the designer's model plus four flags: `other`, `lollop2`, `lollop11` and `wakeshare`. `hedgerow-breaker-fight.py` holds the fight and Treasury probes. Both run with `python3 -I`.

Target used throughout: the designer's typical board, 52 / 158 / 531 / 1,793 at rounds 6 / 9 / 12 / 15.

**In short:** keep it. It's the right light pass. Dozey doubling on a visible three-turn clock is the best reward moment in the tribe, and the hoard question is real. But three things break it:
- A second Squire Lollop, which a committed player usually finds, takes the on-time Supper line to 3.7× the target at round 15.
- A golden Sergeant deletes any carry for 5 gold a fight.
- The mid-game window the design calls its weak spot is probably its strongest.

Each has a fix that keeps the core.

## Ranking

The panel has one design, so I rank its three routes, then score the whole.

| Rank | Route | Reward moments | Decisions | Identity | Scale guardrail |
|---|---|---|---|---|---|
| 1 | **Supper** (Dozey carry) | 5 | 4 | 5 | **Fails as written.** A second Lollop takes it to 3.7× at R15 on time. In band with "your other Hedgerow folk" and a 5–7.5% share |
| 2 | **Treasury** (hold everything) | 3.5 | 4.5 | 4.5 | Not modelled and has no harness line. Two Masts loop the Larder at ×1.67 a turn, up to the hand limit |
| 3 | **Parish** (wide) | 3 | 2 | 3 | Closest to the band (1.0–1.4×) |

**Why the Supper wins.** Every three turns the dormouse visibly doubles, and you can see it coming on his pips. The pass also gives five real decisions about one unit:
- feed now or hold;
- the F4 gap;
- move him to face the scout, or keep the count;
- when to buy the third copy;
- where Lollop stands.

It is also the most Hedgerow-shaped of the three: hoarding, sleeping, and Passing to the last unit.

**Why the Treasury is second.** It is the tribe's question in its purest form: hold or cash. The Sergeant's Great Hoard throw is the best answer moment in the pool. But the doc treats it as insurance, not as a route. The Supper's feasts starve it, and nothing models it.

**Why the Parish is third.** "Cash every Acorn at once" removes the tribe's own decision. Mallow doubling the runt every turn is a nice small reward. Otherwise it's a wide aura board that any tribe could field.

**Whole design:** reward moments 4.5, decisions 4, identity 4.5. **Verdict:** adopt it once #1 and #2 are fixed, with #3–#8 tested in the sweep.

---

## Breaks

| # | Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|---|
| 1 | **Must fix** | **Two Lollops is the common case, and it plays like a golden Lollop.** Every Line unit gains 10% from each copy, and the biggest gains 10% of itself from each. The doc says its tail "needs three tier 3–6 triples". One extra plain copy gets most of the way there | Designer's model, with a second Lollop at R13 in place of Mast (which does almost nothing in this line, see #6): R15 is **6,668 on time (3.72×)** and 2.84× on the mean; R16 is 3.81×. The doc's three-triple tail is 5.4×. **How common:** a tier 6 shop has 6 units, 40% of them from tier 6, out of about 12 tier 6 units in a 5-tribe pool. So each shop offers Lollop about 0.19 times. With no recruit timer, a player who refreshes 8 times a turn sees about **1.7 Lollops a turn**. Hiring Fair adds a Hedgerow option on a 5-Hedgerow board | Make **"your other Hedgerow folk touching this"** the text now; it's the designer's own first dial. Sweep the share at 5% and 7.5% with two copies in the line. Probe results at R15, as the mean of on time and late: other + 5% gives **1.15×** with one Lollop and **1.42×** with two; other + 7.5% gives 1.74× with two; other + 10% gives 1.51× with one and 2.07× with two. Add "buy every Lollop" to `hedgerow_supper`, because a real player will |
| 2 | **Must fix** | **A golden Sergeant plus a Stash leaves the enemy across at 0/1.** At 20% per gold, a 5-gold Stash takes 100%. That deletes the opponent's best unit every fight, for 5 gold. Tier 3 triples are routine, and Hedgerow makes Stashes cheaply (the Partner, Sorrel, any three Acorns). The owner wants answers that reach a carry *sometimes*; this reaches it every time. The player recruiting with the scout places the Sergeant after seeing the board | Card text and Acorn values (Acorn 1, Stash 5, Great Hoard 16 gold). My fight probe at R9: halving Dozey alone moves his board from 100% to 11% against a typical board | **Golden: "throw your two smallest Acorns."** Each throw takes its own share, so two Stashes leave a quarter. Only a Great Hoard (16 gold) still wipes. It keeps the golden rule ("two" for "a") |
| 3 | Should fix (test first) | **Rounds 6–11 are probably the Supper's strongest window, not its weakest.** The doc says it is "Behind at once (rounds 3–8)" and that "Urchin's Hunker is what keeps this window close". The model shows the on-time line ahead the whole way: 1.25× at R4, 1.67× at R6, 1.46× at R9 | **Rough fight model**, with Dozey 87/87 in B3 and Hunker. The on-time R9 Supper (231 stats) beats every even 7-unit board up to its own total, every time. Against 260–300 it wins half. Dozey alone (174 stats) beats an even 200-stat board. Every enemy that attacks him dies in the exchange, and he takes half damage, so a carry that kills in one hit outlasts an even board bigger than itself. Without Hunker, the board loses to an even 213. Results are all 0% or 100%, which spends the variance budget the wrong way (fundamentals §3: the smaller board should win 14–26% of fights) | Check it in the harness's R6–R11 field fights before trusting either reading. If it holds, **swap Dr Urchin (tier 3) and Mrs Mallow (tier 4).** Hunker then arrives around R7 and the Parish's runt-doubler earlier. The tier spread stays 3/3/3/3/2/2 |
| 4 | Should fix | **The late curve still rests on one card.** Tribe-only fixed Lollop's splash, not the line's need for him. Dozey alone grows ×2 every 3 turns, which is ×1.26 a round. Lollop's self-share lifts that to about ×1.39, and his spread carries the board | `share=0` (no Lollop): the Supper falls to **0.80× at R14 and 0.67× at R16**. I also tried a 10% share to the board at each wake as a second outlet. It lifts the no-Lollop line to 1.0× at R15, but heats R9 to 1.88× on time. That's the wrong lever | Sweep w and the period with no Lollop, one, and two, not only one at 10%. A tier 6 capstone is normal in Battlegrounds, so this can be accepted if the no-Lollop line stays within the band. If it falls well under, the next outlet belongs at tier 5, not on the wake |
| 5 | Should fix | **The checkpoint rounds sit on the wakes.** An on-time Dozey bought on R4 wakes on R6, R9, R12 and R15, exactly the checkpoints. The late line wakes on R7, R10, R13 and R16, so every late checkpoint is its lean turn | R12 reads 2.08× on time against 0.68× late. One round later, R13 reads 1.88× against 1.58×. The w table and the "Mean ×typical" column inherit the same bias | Report every round, or a three-round average. Have the harness snapshot by wake phase; the doc's snowball check already asks for this |
| 6 | Should fix | **The Treasurer and Mast are dead in the Supper, and the Treasury isn't a line.** Each feast empties the Larder, so "the Treasurer is the Supper's insurance against an answer to Dozey" doesn't hold under the Supper's own policy | The model's Supper Larder is 5 gold at R9 and R12, and 0 at R15. The Treasurer gains +5–10 a turn while Lollop gives each Line unit about +50. Mast pays about one Acorn. **Treasury probe** (hold everything from R1, one Partner, Sorrel in back, Mast at R12): the Larder grows 43 → 118 gold from R12 to R15, and the Treasurer reaches about **760 at R15**, about 0.42 of a typical board. That is a real second carry | Add a **`hedgerow_treasury`** harness line (hold everything; the Treasurer as Pass target; Mast; Sergeant ammunition) and model it. Pitch it as its own route, not as insurance |
| 7 | Should fix | **Two Masts loop the Larder.** Each Stash earns an Acorn a turn, and three Acorns make a 5-gold Stash. So a held Larder grows about ×1.33 a turn with one Mast, and ×1.67 with two or a golden one. Two tier 6 copies are common (#1) | The probe gives 266 gold by R15 with two Masts. The only brake is the 10-card hand (7.1.1). It binds at about 8 Great Hoards (~130 gold), and then also blocks buying (4.2.2) and loses new Acorns (7.1.2), none of which the player is told. At that size, cashing with Hayward is +130/+130 for every Hedgerow unit now and later, and the Sergeant can throw a Great Hoard every fight from interest alone | Make the designer's fallback the text: **"up to 5 Acorns a turn"**. It's a rate limit on a loop, which the brief allows. Show the hand limit next to the Larder |
| 8 | Should fix | **The Sleeping Partner is neutral economy in Hedgerow clothes.** It pays 5 gold every 3 turns for as long as it sits, at tier 1, for any tribe. The pass 2 card gave 6 Acorns in all (up to 10 gold once combined). This repeats the Lollop splash at tier 1, and it's the common economy lead the owner fears (09d) | Losses in R1–R3 cost no Health (round base 0/0/0), so a R1 Partner costs nothing. Sold on R4, it nets +3 gold and a body for three fights. Kept, it pays 25 gold by R15. Every seat that sees one should open with it | **"Every 3 turns in this slot: get an Acorn per Hedgerow unit touching this."** A Hedgerow opener with 3 touching still gets a Stash on R3. A full Line gets 7 Acorns (about 11 gold), and another tribe's board gets 1. It also adds a placement choice |
| 9 | Should fix | **The Standing Committee is too small at the target scale.** It gives +1 Attack per unit touching, flat and Attack only | A full Line gains +49 Attack a turn. At R12 the Supper board is about 1,100 and Lollop adds about 350 a turn. At R15, +49 is about 1% of the board | Let it read the board. For example: **"End of Turn: the smallest Hedgerow unit touching this gains your biggest unit's Attack."** (14 words). The committee lifts the runt to the carry's Attack: it pairs with Mallow, gives the Parish its punch, and scales with the game. Sweep the size |
| 10 | Should fix | **Two orders on one board.** End of Turn effects resolve in reading order (F1–F4, then B1–B3), but Pass and touching follow the zigzag. To place Lollop well, a player must know both | A Dozey in B3 is last in reading order, so Lollop always shares his size from before the wake. A Dozey in F4 wakes before a back-row Lollop. The doc's own model note says this "flatters a B3 Dozey" | Move Lollop to **Start of Turn**. He then always shares the final size from last turn, there's no order to learn, and the share lands as the turn opens, where the player sees it. Mast already uses Start of Turn |
| 11 | Should fix | **Words that mean two things.** "Acorn" names both the 1-gold item (Mast's "get an Acorn", Spill) and every Acorn item (Dozey, Sergeant, Treasurer, Hayward, Beadle). "Get" counts combining for Pym but not for Beadle. In the Sergeant's "It loses 10% per gold", both "it" and "10% of what" are unclear. Hayward's "now and later" is the rulebook's "this game" (12.1.1). Lollop writes "10%" where the Oozes design writes "a tenth" | Card texts; the wording guide's "one word per concept" rule | Treasurer: "per gold in your Larder". Mast: **"Start of Turn: get an Acorn per 5 gold in your Larder."** (11 words instead of 16, and a Great Hoard still gives 3). One rule for "get": combining counts, for both Pym and Beadle. Sergeant: "…at the enemy across: it loses a tenth of its stats per gold." Hayward: "this game". Choose "a tenth" or "10%" for every tribe |

### Notes

- **Late in the game, the feast's payoff comes from Hayward.** Once Hayward is down, feeding Dozey 26 gold gives him +13/+13, or +26/+26 after the wake. Hayward gives every Hedgerow unit +26/+26 whether you feed or cash, and cashing also gives you 26 gold. So from about R10 the headline question leans towards "cash", and feeding is mostly a decision for R4–R9. That's fine if the pitch says so. The per-gold food dial keeps feeding alive longer.
- **Triples form as soon as you get the third copy** (7.3.1), and the golden goes to hand. In the Supper line, "play the third copy only on a turn right after a wake" must read "buy". A golden Dozey adds little beyond merging two stacks. That merge is its reward moment (the Dormitory), and it works.
- **The Parish line contradicts the card.** It says "cash before buying, so new Hedgerow units count from the next play onward", but Hayward's bonus covers units "now and later", so the order doesn't matter. One of the two is wrong.
- **Crumb's "Pass its stats" needs a ruling.** Does Hayward's standing bonus go with him? The Queen of Elfland ruling (12.1.5) leaves tribe bonuses out. If the bonus does go, every late Crumb carries +X/+X of Hayward into the carry for 2 gold.
- **Clover: "After you summon a Hedgerow unit."** It costs one word and loses nothing for Hedgerow, since Kits and Shrewlets are Hedgerow folk. It also stops a grown or golden Clover feeding another tribe's summons.
- **Beadle and Pym fade after R10.** They add +4–6/+4–6 a turn to a 500-stat Dozey. That's fine for feeders bought on R3–R8; just don't count them as late payoffs.
- **The model charges no gold.** Held Acorns and the F4 gap therefore cost nothing in it. That is one reason it never shows the "behind at once" phase the doc claims.

## What survives

- **The Long Sleep.** Dozey doubles every third turn he stays put, wake pips show the count, and feeding before a wake is doubled with him. It is visible, permanent, plannable, and a reward moment every three turns.
- **"Move him or keep the count."** It turns the scout into a real choice. Dozey is the easiest carry in the game to aim at, and that is the right price for the sleep.
- **Crumb's sold Pass**, the tribe's clean way to pile a support's growth onto the carry. With Mallow it makes a small combo: double him, then sell him.
- **Mallow doubling the runt**, a spread compounder that limits itself by design.
- **The Sergeant's share-based throw** (non-golden), aimed across by position. The Stash halves the target and the Great Hoard wipes it: an answer you pay for and aim.
- **Hunker on the last unit**, the hold-its-stats piece the audit asked for. If anything it's too good (#3).
- **Tribe-only, permanent Lollop and Committee**, and Hayward's bonus showing on shop units. These pass the audit's permanence and progression tests.
- **The wording.** Median 9.5 words, maximum 17, no new keywords, and every limit sits in Details.

## Cross-tribe conflicts

- **Lollop matches the Oozes carry's Elder Ooze:** "End of Turn: your other Oozes permanently gain a tenth of your biggest Ooze's stats." It's the same verb, rate and timing, and the "touching" gate is the only difference. Only one tribe should own "your others gain a share of your biggest".
- **Dozey's double every third turn matches the Fairies carry's Queen**, who "doubles your biggest Ring every third turn".
- **"Leave it alone and it grows"** now appears in four tribes:
  - the Fairies engine: an empty Ring gains half a turn;
  - the Oozes engine: a back-row Belly simmers for half a turn;
  - the Birds wild design: Grow while away;
  - the Hedgerow engine: Dozey asleep.

  Hedgerow has the oldest claim (pass 2's "After 3 turns in this slot") and the plainest fiction, a dormouse asleep. The cross-tribe synthesis should keep the timed double here and give the others a different clock or verb.
