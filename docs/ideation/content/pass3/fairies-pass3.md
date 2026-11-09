# Fairies, pass 3: the synthesis

9 Nov 2026, the Fairies synthesizer. **Base:** Wild ("the carry is a place"), ranked first by the breaker. **Grafted in:**
- from Carry: the Shield holder, the Shy ruling, and a Queen whose Teind makes Rings;
- from Engine: the copy guard, and Wisps lighting emptied slots for the non-carry route.

Every breaker point is answered below: taken, changed or rejected, with the reason. Effects are sized against the target shape by reasoning about the boards on rounds 6, 9, 12 and 15, using a paper model with a gold ledger (`fairies-pass3-model.py`, beside this file). There is no price list. Godot was not run.

## In short

- **Fairies keep their power in the ground.** A slot holds a count of Rings, and every Ring gives your one **Ring size**. Old Rings grow when the size grows, so the carry is a place, and the fight's question is who stands on it.
- **Five changes to Wild:**
  1. **Copy guards** on every grower.
  2. **Cluricaun every 3rd End of Turn**, not every turn.
  3. **Annis also Rings on every sale.** This is the late gold sink: Ring spells turn out to be rare in late shops.
  4. **Hob gives Shield** instead of banking Rings.
  5. **The Queen tithes every turn to Ring every slot**, instead of sharing stats.
- **The model's boards, as a multiple of the Battlegrounds mean:**

  | Line | R6 | R9 | R12 | R15 |
  |---|---|---|---|---|
  | Carry line, every piece on time | 0.87× | 0.72× | 1.23× | 1.17× |
  | Court line | 0.94× | 1.09× | 1.30× | 1.37× |
  | Low roll | 0.85× | 0.51× | 0.47× | 0.55× |
  | Top 1% (peaks at 5.5× on R16) | 0.87× | 1.00× | 1.76× | 2.46× |

  The breaker's two-copy stack now comes out *below* the plain line.
- **Main risks** (sim questions 1–3):
  - the carry line puts about 90% of its stats into two giants;
  - Fairy carries depend on how often Horseshoe shows up;
  - without a tier 6 Fairy, the Court falls to 0.6× by R15.

---

## The pitch

In Battlegrounds, power lives on minions. **Fairies keep it in the ground.** A Ring is power on a slot. It outlives every unit that stands on it, and every Ring grows when your Rings grow. Whoever steps into your big Ring becomes the giant: a T1 hag, Belladonna, or the enemy's own carry, stolen by the Changeling.

Three things Battlegrounds can't do, and the tribe is built around them:
1. **The carry is a place.** Your best "unit" is B1, and you pick who stands there each fight.
2. **Power moves in the fight.** Reel-Mistress walks the giant Ring down your line.
3. **Their carry fights on your Ring.** The Changeling brings it over to your side.

*Similar to:* Battlegrounds' Blood Gems, for one number that buffs many things. Galaxy's slot buffs, for power that stays on a slot. The difference is that old Rings keep growing.

---

# The engine: Rings × Ring size

## Rules

- **Ring** *(reminder: whoever stands on this slot gains your Ring size for each Ring here)*.
  - "Ring this slot" adds one Ring to the slot.
  - Rings stay when units move, are sold or die. Empty slots keep them too.
  - The badge shows the slot's total and count: `+72/+72 · 12`.
- **Ring size** *(reminder: what each Ring gives; starts at +1/+1)*.
  - One number per player, shown on your hero like the Supper chip.
  - "Your Rings grow +1/+1" raises it, so every Ring on every slot gains at once.
  - It's permanent and visible in the shop.
- **Slot stats are slot stats** (8.5).
  - Shy units ignore them (12.1.7).
  - Fights and ghosts copy both the counts and the size.
- **Removed:**
  - the Ring cap (8.5.4);
  - the Rainbow keyword (the "rainbow" is now just a Ring on all seven slots);
  - Hex.
- **Anti-splash, by construction:** Ring size belongs to its player. A Hedgerow player who casts Spore Cloud gets Rings worth +1/+1 each.
- **Copy guards:** every grower works once, however many copies you own.
  - Two Cluricauns share one count.
  - Two Silkies grow once per departure.
  - Two Monarchs run one Midsummer clock.
  - A golden copy grows double.
- **Shy, written out:** only thanking counts as leaving. Thanking means an aimed spell (12.1.7). Selling or destroying a Shy unit doesn't count, and destroyed Shy units pay no gold.

**Why it compounds.** Total Ring stats are count × size, and both grow:
- **Count** grows with gold, through Annis's sale trigger, plus Nan, Sally and the Queen.
- **Size** grows with the tier 3 cards and doubles at tier 6.

A Ring placed on round 2 is +1/+1 that day and +13/+13 on round 15.

**Why it concentrates, or doesn't.** Size growth helps every Ring equally, so where each Ring goes decides the board's shape. Annis in a corner stacks one slot. Annis in the middle feeds two. That is the engine's main decision.

## The rate parameters (for the lever sweep)

| Lever | What it sets | Default | Sweep |
|---|---|---|---|
| **g (primary)** | Cluricaun's period (grows +1/+1 every 1/g End of Turns) | **every 3rd** (g = ⅓) | 1, ½, ⅓, ¼ |
| p | Monarch's Midsummer period | every 3rd End of Turn | 2, 3, 4 |
| lob | Lob's gift: +1/+1 per this many turns stayed | 3 | 2, 3, 4 |
| m | Reel-Mistress's moves per Ring per fight | 2 | 1, 2, 3 |
| qk | Queen's Rings per slot per tithed unit | 1 | 1, 2 |
| sale | Annis's sale trigger | on | on, off |
| fetch | How much of the unit behind Fetch copies | full | full, ½ |

**Why g = ⅓ and not ½.** Once shop supply is honest (below), both full lines at g = ½ average 1.38–1.48× over rounds 10–16. The carry line peaks at 1.9×. At ⅓ they average 1.16–1.21× and peak at 1.52×, while the low roll stays at about 0.5×. The sweep table under Boards has every lever.

## When it comes online

- **Carry line (the Fairy Ring):**
  - Behind at once: 0.87× on R6 and 0.72× on R9, while three Shy banks hold slots without taking Rings.
  - **Online on R10:** Lob is thanked, Fetch arrives in front of the carry, and Belladonna steps onto B1. The board goes to 1.52×.
  - Then 1.23–1.28× on R11–R12, 0.92× on R13, and 1.44× at the first Midsummer on R14.
- **Court line:**
  - Online on R7 with the rainbow and the Chaser's 7-gold sale (1.14×).
  - Strongest on R10–R12 (1.28–1.39×), with the Queen tithing every turn from R11.
  - It dips before Midsummer (0.79× on R14) and recovers on R15 (1.37×).

## The decisions it creates

1. **Where does Annis stand?**
   - From F1 she feeds B1 alone: the carry.
   - From F2 she feeds B1 and B2, twice the Rings per sale: the court.
   - Every sale you make all game follows that choice.
2. **Sell to grow, or save to climb?** Every sale Rings Annis's slots. A buy-and-sell costs 2 gold for one Ring. Late, that is the Fairy gold sink, and it competes with tier-ups and Hiring Fair.
3. **Thank the brownie now or later?**
   - Lob pays in 3-turn steps.
   - Silky pays once per departure, and her own departure counts.
   - Thanking frees a slot and pays 2 gold.
4. **Who stands on the big Ring this fight?** Read the scout:
   - the Witch zeroes the unit across;
   - the Changeling steals it onto your Ring;
   - Belladonna poisons their biggest;
   - Fetch doubles whoever you chose.
5. **Keep a gap or field a seventh unit?**
   - Sally Rings only empty slots.
   - Will lights only empty Rings.
   - The Queen's tithe slot is always empty at combat.

---

# The 16 cards

**Sizes behind the payoff numbers** (from the model, full lines):
- Ring size is about **2 / 6 / 13** on rounds 9 / 12 / 15.
- One Ring is therefore worth **4 / 12 / 26** stats (Attack plus Health).
- The carry line has 27 / 43 / 62 Rings, with 17 / 33 / 52 of them on B1.
- The Court has 42 / 76 / 124 Rings.

Tier spread 3/3/3/3/2/2. Every creature, name and portrait is kept.

## Tier 1

### Nan Toadstool: Pixie Trickster, 2/1
- **Text:** When played or sold: Ring this slot.
- **Golden 4/2:** When played or sold: Ring this slot twice.
- **Condition:** play it, and later sell it. Both happen anyway.
- **Payoff:**
  - 2 Rings a copy, plus Annis's Ring when you sell it.
  - Played on B1 on round 1, its 2 Rings are worth 8 / 24 / 52 stats on rounds 9 / 12 / 15, and double that once Fetch copies B1.
- **Permanence:** permanent, on the slot.
- **Enabler:** every Ring reader (Witch, Fetch, Reel, Wisps, the Changeling). It also fills gaps in the rainbow.
- **Concentrates:** yes. You pick the slot.
- *Note:* rule 6.1.3a's odds make a given tier 1 unit about 1% a refill at tier 6, so the late "rebuy Nan" plan is rare. Annis's sale trigger does that job now.

### Rainbow Chaser: Leprechaun Cobbler, 2/2
- **Text:** When sold: get 1 gold per slot with a Ring.
- **Golden 4/4:** When sold: get 2 gold per slot with a Ring.
- **Condition:** spread Rings. The full rainbow is all seven slots.
- **Payoff:**
  - 5–7 gold on rounds 6–9. The Court line's Chaser pays 7 on R7, 4 more than it cost.
  - The sale also Rings Annis's slots.
- **Permanence:** one-shot gold, repeatable whenever a Chaser shows up.
- **Enabler:** pays for the count engine and pulls toward the rainbow that Cluricaun needs.
- **Concentrates:** no. It rewards spreading, which is its tension with the carry.

### Hedge Witch: Hag of the Hedgerow, 1/3
- **Text:** Start of Combat: the enemy across loses Attack equal to this slot's Ring.
- **Golden 2/6:** Start of Combat: the enemy across loses Attack equal to twice this slot's Ring.
- *Details:* a +30/+30 Ring takes 30 Attack, to a floor of 0. A Fetch copying her reads its own slot.
- **Condition:** Rings under her, and a unit across.
- **Payoff:**
  - On a spread slot of about 5 Rings: −10 / −30 / −65 Attack on rounds 9 / 12 / 15.
  - On the Court's B2 on R12 (28 Rings): −168.
  - As the carry-line stander on B1 on R15 (52 Rings): −676. That zeroes nearly anything across.
- **Permanence:** a combat answer that scales with the permanent engine.
- **Enabler:** gives a non-carry slot a job, and gives the carry slot a second one.
- **Concentrates:** yes. She is the best cheap stander on the big Ring.
- **Delight:** the old hag in the fairy ring. Their 300-Attack carry walks out with 0.

## Tier 2

### Old Moth Annis: Moth Pixie, 2/4
- **Text:** End of Turn and after you sell: Ring the slots behind this.
- **Golden 4/8:** End of Turn and after you sell: Ring the slots behind this twice.
- *Details:* any sale counts, the Chaser and Nan included. From F1 or F4 she Rings one slot; from F2 or F3, two.
- **Condition:** standing in the front row, and selling.
- **Payoff:**
  - From F1, the carry line's B1 gets 1 Ring a turn (13 by R15) plus one per sale (about 24 by R15, mostly churn). That is 37 of B1's 52 Rings on R15: +962 stats on B1, and the same again on the Fetch twin.
  - From F2, the Court gets 2 Rings per sale.
- **Permanence:** permanent.
- **Enabler:** the main count engine, and the tribe's late gold sink.
- **Concentrates:** yes from a corner, no from the middle. That's the main placement decision.
- **Why the sale trigger** (new): in late shops, Ring spells are 5–8% a refill and Nan is about 1%. Without a sink, the model's carry line left 40–50 gold unspent by R16 and fell to 0.6–0.9× late. With the sink, every Fairy has something to do with spare gold, and it follows a placement the player chose.

### Sally Spore: Sprite Gardener, 2/4
- **Text:** End of Turn: Ring your empty slot nearest this.
- **Golden 4/8:** End of Turn: Ring your empty slot nearest this twice.
- **Condition:** a gap on your board.
- **Payoff:** 1 Ring a turn into a gap. In the carry line she grows B3 from R4 to R8 (4 Rings) before a Shy unit takes it. Beside the Queen, she Rings the tithe slot, where a Wisp lights at combat.
- **Permanence:** permanent; the Ring stays after she leaves.
- **Enabler:** Will (empty Rings), the rainbow, and the Queen's tithe slot.
- **Concentrates:** yes, beside one gap. Move her to spread.

### Hob-in-the-Hearth: Brownie Helper, 2/5
- **Text:** Shy. Start of Combat: your biggest unit gains Shield.
- **Golden 4/10:** Shy. Start of Combat: your two biggest units gain Shield.
- *Golden details:* Shy pays 4 gold.
- *Details:* he picks when he fires, after Cradle Fetch has copied. Shield doesn't stop Nightshade, which is a loss, not damage.
- *Shield reminder:* prevents the first damage this would take each fight.
- **Condition:** a big unit, and a slot to keep him in. Shy, so he takes no Ring himself; stand him on a small slot.
- **Payoff:** the giant survives one hit. At R12 the biggest enemy hit is about 100–300, a sizeable share of a 200/200 stander's Health.
- **Permanence:** combat only, every fight he stays.
- **Enabler:** holds the carry, and thanking him feeds Silky.
- **Concentrates:** it makes concentration safer.
- **Change from Wild:** Wild's Hob banked Rings on his slot. Annis's sale trigger now does that job, and the carry needed a holder (breaker point 7; graft from Carry's Hob).

## Tier 3: where your Rings start to grow

### Cluricaun: Leprechaun Reveller, 3/5
- **Text:** Every 3rd End of Turn: if every slot has a Ring, your Rings grow +1/+1.
- **Golden 6/10:** Every 3rd End of Turn: if every slot has a Ring, your Rings grow +2/+2.
- *Details:*
  - All seven slots count, empty or not.
  - The count starts when your first Cluricaun is played and shows on the card.
  - More Cluricauns share the count and grow once.
- **Condition:** the rainbow, a Ring on all seven slots. That costs a carry player about 6 Rings off the carry, once.
- **Payoff:**
  - With the rainbow from R7: +1 on R9, R12 and R15.
  - Each step is worth 2 × your Rings: +54 / +86 / +124 stats on rounds 9 / 12 / 15, then doubled by Midsummer.
- **Permanence:** permanent, and this game.
- **Enabler:** every Ring. It shares the rainbow with the Chaser.
- **Concentrates:** neutral. Its condition forces a little spread first.
- **Delight:** completing the rainbow, the tribe's mid-game milestone.

### Lob-Lie-by-the-Fire: Brownie Lubber, 3/6
- **Text:** Shy. When this leaves: your Rings grow +1/+1 per 3 turns it stayed.
- **Golden 6/12:** Shy. When this leaves: your Rings grow +2/+2 per 3 turns it stayed.
- *Golden details:* Shy pays 4 gold.
- *Details:* turns are End of Turns on your board, and moving doesn't reset them. Selling or destroying it isn't leaving.
- **Condition:** wait, then thank it with an aimed spell. It's the time-bounded shape the owner liked (02i).
- **Payoff:**
  - Bought on R5 and thanked on R10: +1/+1 on 33 Rings, which is +66 stats, plus Silky's +1.
  - Thanked on R11 instead: +2.
  - Kept 9 turns: +3. On 50 Rings that's +300 in one click.
- **Permanence:** permanent.
- **Enabler:** Silky.
- **Concentrates:** neutral.
- **Delight:** Lob's last night. You thank him, and the whole board jumps.

### Silky: Grey Brownie, 3/7
- **Text:** Shy. After a Shy unit leaves: your Rings grow +1/+1.
- **Golden 6/14:** Shy. After a Shy unit leaves: your Rings grow +2/+2.
- *Golden details:* Shy pays 4 gold.
- *Details:* this counts too. More Silkies grow once per departure. Only thanking counts as leaving.
- **Condition:** thanking Shy units, Silky included.
- **Payoff:**
  - Lob and Silky thanked on R10–R11: +2 Ring size on 33–36 Rings, about +140 stats.
  - Every later grow and Midsummer is built on that.
- **Permanence:** permanent.
- **Enabler:** Hob and Lob, and any aimed spell (Pinch of Dust, a Spore Cloud on a Shy unit's slot).
- **Concentrates:** neutral.
- **Tier 3** (from 4, as in Wild): her gift has to land while Hob and Lob are still on board.

## Tier 4

### Changeling: Changeling Babe, 3/3
- **Text:** Start of Combat: steal the enemy across until it attacks.
- **Golden 6/6:** Start of Combat: steal the enemy across until it attacks twice.
- *Details:* this takes its place on their side. Then both go home.
- **Condition:** something worth stealing across from it. You re-place it after scouting.
- **Payoff:** the stolen unit stands on your slot and gains your Ring there. It hits its own board. On the Court's B1 on R12 (+168/+168), a stolen 300/300 fights as 468/468.
- **Permanence:** combat only. This is the answer card.
- **Enabler:** the big Ring. On it, whatever you steal inherits your Ring.
- **Concentrates:** it turns your concentration against them.
- **Fairy resilience:** an enemy Changeling that takes your stander leaves your Ring at home, and their babe stands on it for you.
- **Text cut:** 15 words to 10. The swap and the swap back are unchanged.

### Will-o'-the-Wisp: Wisp Lantern-Bearer, 3/6
- **Text:** Start of Combat: summon a 1/1 Wisp into each empty Ring.
- **Golden 6/12:** Start of Combat: summon a 2/2 Wisp into each empty Ring.
- **Condition:** empty slots that hold Rings. Those are gaps grown by Sally, slots emptied by thanking, or the Queen's tithe slot.
- **Payoff:**
  - The Court's B3 Wisp is 38 stats on R12 and 170 on R15.
  - A gap carry (B1 left empty on 33 Rings, R12) lights a 199/199 Wisp in it.
- **Permanence:** combat only, but it reads permanent Rings.
- **Enabler:** Sally, the Queen, Reel (one more dancer).
- **Concentrates:** yes, on the gap-carry board. It also adds bodies, which helps against overkill.
- **Change from Wild:** no "must be attacked first", so no Taunt is needed (breaker point 5). Carry's Reborn refill ("your biggest Ring refills once") is a sweep variant, not base text, because it pushed the card to 16 words.

### Cradle Fetch: Fetch Double, 2/4
- **Text:** Start of Combat: become a copy of the unit behind, Ring and all.
- **Golden 4/8:** Start of Combat: become a golden copy of the unit behind, Ring and all.
- *Details:*
  - From F2 or F3, it copies the bigger unit behind.
  - Two Fetches never copy the same unit.
  - The copy's Start of Combat text fires.
  - This slot's own Ring still applies.
- **Condition:** your carry stands behind it.
- **Payoff:** a second carry for the fight: +204 on R10, +420 on R12, +1,390 on R15. It also gives a second Witch curse or a second Nightshade.
- **Permanence:** combat only, but predictable. The shop shows combat-start stats, so it's visible (breaker point 4).
- **Enabler:** holding. With two giants, one death doesn't end the carry.
- **Concentrates:** it makes concentration safe, and it's the reason the carry line works.
- **Golden fix:** the old golden text ("copy your biggest unit") broke wording rule 7. A golden copy doubles the copied unit's text.

## Tier 5

### Reel-Mistress: Pixie Dancing-Mistress, 4/7
- **Text:** After a unit on a Ring attacks: its Ring moves to your next unit. Twice per Ring.
- **Golden 8/14:** After a unit on a Ring attacks: its Ring moves to your next unit. Four times per Ring.
- *Details:* "next" means your next attacker. Rings that meet add up. Fights run on a copy, so Rings go home afterwards.
- **Condition:** units on Rings, attacking.
- **Payoff:**
  - The carry's Ring swings three times a fight instead of once.
  - On R12 that's two extra +198 swings; on R15, two extra +676 swings.
  - It also fixes overkill: each swing is a new kill.
- **Permanence:** combat only.
- **Enabler:** cheap dancers and Wisps.
- **Concentrates:** yes, in the fight.
- **Why the limit:** each move reuses the whole Ring. Unlimited, every attack would be a giant one, about a 7× multiplier. m is a sweep lever. "Twice per Ring" says the limit belongs to the Ring, not to the Mistress (breaker point 4).

### Lady Belladonna: Sprite Poisoner, 4/8
- **Text:** Start of Combat: give the biggest enemy Nightshade.
- **Golden 8/16:** Start of Combat: give the two biggest enemies Nightshade.
- *Nightshade reminder:* when attacked, this first loses half its Health.
- **Condition:** they have a biggest unit. Everyone does.
- **Payoff:** their carry, about 300 / 1,000 stats on rounds 12 / 15, falls to a few small hits. A back-row carry is only bitten once their front row is gone.
- **Permanence:** combat only.
- **Enabler:** Wisps and Reel add more hits.
- **Concentrates:** no. It's the anti-carry card, and it also stands on B1 as a big body.
- **Cross-tribe flag:** "biggest enemy, any row" is one of 6+ such answers across the pass 3 tribes. If the cross-tribe synthesis cuts it, the fallback is "Start of Combat: give the enemy across Nightshade." (golden: "and the units beside it").

## Tier 6

### Fairy Monarch: Fairy Monarch, 6/8
- **Text:** Every 3rd End of Turn: double your Ring size.
- **Golden 12/16:** Every 3rd End of Turn: triple your Ring size.
- *Details:*
  - The count starts when your first Monarch is played and shows on your hero.
  - More Monarchs don't add a count.
  - A golden one triples: the doubling's gain, doubled.
- **Condition:** time.
- **Payoff:**
  - Played on R12, it doubles on R14 (Ring size 6 to 12).
  - On the carry line the board goes from 1,080 on R13 to 2,520 on R14.
- **Permanence:** permanent, and this game.
- **Enabler:** every Ring.
- **Concentrates:** neutral.
- **Delight:** **Midsummer**, a countdown the whole lobby can see coming.
- **Cut:** "When played: Ring every slot." It was 7 Rings once, about 5% of the late board, and its removal brings the tribe's median text to 10.5 words. It's kept as the `monring` sweep variant.

### Queen of Elfland: Fairy Queen, 8/8
- **Text:** End of Turn: destroy the units behind this. Ring every slot for each.
- **Golden 16/16:** End of Turn: destroy the units behind this. Ring every slot twice for each.
- *Details:* destroyed Shy units pay no gold and don't count as leaving. The tithed slots are empty at combat, so Will lights them.
- **Condition:** cheap units behind her, each turn. Any unit works: a 3-gold buy is 7 Rings.
- **Payoff:**
  - In the Court from R11, one tithe a turn: +42 Rings by R16.
  - On R15 at Ring size 14, each tithe is +196 stats.
  - From F2 or F3 she tithes two units a turn: 14 Rings for 6 gold.
- **Permanence:** permanent.
- **Enabler:** Sally (she Rings the emptied slot), Will (a Wisp lights it), Nan (Rings its slot before it's tithed).
- **Concentrates:** no. It spreads Rings onto every slot. This is the Court's tier 6.
- **Change:**
  - Wild's Queen shared Ring stats into units, the "bonus laundering" rule 12.1.5 was written to stop (breaker point 2).
  - At the breaker's t = ½, my first model showed the share adding a negligible amount to the late board.
  - This Queen adds count, not stats. Rule 12.1.5 is untouched, it's 13 words, and it turns gold into Rings for the spread route the way Annis does for the carry.
- **Delight:** **the Teind.** Every turn the court pays its tithe, and the whole ring glows.

**Token, Wisp:** a 1/1 Fairy (2/2 from a golden Will). It exists only in combat and takes its slot's Ring.

## Wording check

| Card | Words | Card | Words |
|---|---|---|---|
| Nan Toadstool | 7 | Old Moth Annis | 12 |
| Lady Belladonna | 8 | Hedge Witch | 13 |
| Sally Spore | 9 | Lob-Lie-by-the-Fire | 13 |
| Hob-in-the-Hearth | 9 | Cradle Fetch | 13 |
| Fairy Monarch | 9 | Queen of Elfland | 13 |
| Rainbow Chaser | 10 | Cluricaun | 15 |
| Silky | 10 | Reel-Mistress | 17 |
| Changeling | 10 | | |
| Will-o'-the-Wisp | 11 | | |

**Median 10.5, p90 15, max 17**, against the guide's ≤11 / ≤17 / ≤22. Wild was 12.5 / 17 / 21.
- Every text is trigger, colon, effect.
- Annis has two triggers before one colon.
- The reminder terms are Ring, Ring size, Shy, Shield and Nightshade. Shield is Track B's shared keyword, not a Fairy term.

---

# Routes

## Carry route: the Fairy Ring

**The idea:** B1, protected behind F1 and F2, holds most of your Rings. Annis in F1 Rings it every turn and on every sale. Cradle Fetch in F2 copies whoever stands there. Choose the stander from the scout.

**How the carry holds its stats** (the breaker's 50–80% share point):
- **Two giants:** Fetch's twin (45% of the board) beside the stander (44%).
- **Shield:** Hob, while he stays.
- **Reel:** after the stander's swing, its Ring moves on twice, so three different units swing as giants.
- **Variant:** a Wisp giant in an empty B1.
- **Unknown:** whether two giants at about 90% of the board beat an even board of the same total. That's sim question 2.

**Board on R12** (model, Ring size 6, 43 Rings, 33 on B1; combat start):

| Slot | Unit | Rings | Combat stats |
|---|---|---|---|
| F1 | Old Moth Annis | 1 | 8/10 |
| F2 | Cradle Fetch | 1 | Copy of B1, plus its own Ring: 208/212 |
| F3 | Cluricaun | 1 | 9/11 |
| F4 | Will-o'-the-Wisp *(a harness bot would field the Witch or Changeling here)* | 1 | 9/12 |
| B1 | **Lady Belladonna** | 33 | 202/206 |
| B2 | Fairy Monarch | 2 | 18/20 |
| B3 | Hob-in-the-Hearth (Shy) | 4 | 2/5, gives B1 or F2 Shield |
| | **Total** | | **932 (1.23×)** |

**Board on R15** (Ring size 13 after Midsummer on R14; 52 Rings on B1): Belladonna 680/684 and the Fetch twin 693/697. Reel-Mistress (B3) replaced Hob on R13. **Total 3,036 (1.17×).**

## Non-carry route: the Court

**The idea:**
- Annis in F2 feeds B1 and B2 on every sale.
- Nan, Sally and the Chaser paint the rainbow by R7.
- Cluricaun grows it.
- From R11, the Queen in F4 tithes a cheap unit in B3 every turn, Ringing all seven slots, and Will lights a Wisp in the emptied B3.
- The answers (Witch, Changeling, Belladonna) do the fighting.

**Board on R12** (Ring size 6, 76 Rings; combat start):

| Slot | Unit | Rings | Combat stats |
|---|---|---|---|
| F1 | Lady Belladonna | 4 | 29/33 |
| F2 | Old Moth Annis | 3 | 21/23 |
| F3 | Cluricaun | 5 | 34/36 |
| F4 | Queen of Elfland | 5 | 39/39 |
| B1 | Changeling | 28 | 172/172, steals the unit across onto +168 |
| B2 | Will-o'-the-Wisp | 28 | 172/175 |
| B3 | (tithed) Wisp | 3 | 19/19 |
| | **Total** | | **983 (1.30×)**, biggest unit 35% |

**Board on R15** (Ring size 14, 124 Rings): the Monarch on B1 and Will on B2 at about 610/610 each; the front row at 87–160 per stat; a 85/85 Wisp in B3. **Total 3,551 (1.37×).**

## Answers to other tribes' carries

| Card | Reach | At scale |
|---|---|---|
| Lady Belladonna | Biggest enemy, any row | Halves its Health each time it's hit. Proportional, so it scales. |
| Hedge Witch | Across | Takes Attack equal to her Ring. On a big Ring she zeroes it. |
| Changeling | Across | Their carry hits its own board from your Ring. |
| Cradle Fetch | Copies the unit behind | Doubles any of the three above. |
| Wisps | Their attackers | Extra bodies soak the swings that overkill. |

## Answers to Fairies (what keeps them honest)

- **Horseshoe** (neutral, 1 gold) halves the Ring across from a slot. Aimed at B1, it halves the stander, and the Fetch copy too.
- **Biggest-enemy answers** (Track B) hit the stander or the twin. Nightshade gets through Shield.
- **Proposed for the neutral panel: Cold Iron**, "Start of Combat: halve the biggest enemy's Ring." This halves rather than nullifies, matching Horseshoe's size. It's the folklore weakness.
- **Wide, even boards** punish the two-giant carry's overkill unless Reel is dancing.

## Weak points

- **Early tempo.**
  - The carry line is 0.85–0.87× on R6–R7 and 0.72× on R9, while Lob, Silky and Hob sit on slots without Rings.
  - That's the "behind at once" an engine should have. If the harness shows Fairies losing too much Health before R10, raise the Shy bodies again, or thank Lob at 3 turns.
- **The low roll is a slump.**
  - Missing Lob and Silky leaves Ring size at 1–2 until Midsummer: 0.47× on R12 and 0.55× on R15.
  - It's still within an order of magnitude, but it's the tribe's worst case.
- **Court without a tier 6 Fairy:** 1.16× on R12, then 0.59× on R15 and 0.44× on R16. Hiring Fair (5 Fairies) is its insurance.
- **Horseshoe dependency.** The carry can't dodge a Horseshoe by moving: the Ring is the slot. The fallback is Annis in F2 and two big slots.
- **Stranded Rings.** A Ring holder killed before it attacks leaves the Ring on an empty slot. Mire and skipped attacks stall the dance.
- **The gold sink is clicks.** Buy, play, sell, a few times a turn. The UI should let a sale from hand count, or show "sell to Ring" on Annis's slots. That's for the engine panel.

## Two highroll moments

1. **Midsummer at the Long Dance** (top 1%: golden Cluricaun on R8, golden Monarch on R11).
   - On R13 the golden Monarch triples Ring size from 8 to 24.
   - B1's 40 Rings go from +320/+320 to +960/+960. Belladonna is 964/968, and at the bell the Fetch becomes a second one at 988/992.
   - Reel-Mistress walks B1's Ring down the line twice, so three pixies each swing for about 960.
   - The board is 4,462 against a 1,177 mean (3.8×).
   - *What the player says:* "every fairy on my board took a turn being the giant."
2. **Their carry danced for me** (Court, R12).
   - Their Dozey is 300/300 in B1. You scouted it, so the Changeling stays on your B1, where your Ring is +168/+168.
   - At Start of Combat they trade places. Dozey fights for you at 468/468 and kills their best support.
   - Belladonna has given him Nightshade, as their biggest.
   - When he goes home, each hit halves him: 300, 150, 75.
   - *What the player says:* "their carry killed their own board, then my court finished him."

Also on the menu:
- **Lob's last night:** thanked after 9 turns, every Ring grows +3/+3.
- **The rainbow:** the seventh slot lights, and the Chaser pays 7.
- **The Teind:** the Queen eats a 3-gold Hedgehog, and seven slots glow.

---

# Boards at rounds 6, 9, 12 and 15

## How the numbers were made

`fairies-pass3-model.py` plays scripted lines round by round against the real income, tier-up costs and discounts (4.1, 4.6). It keeps a gold ledger, runs End of Turn effects from the cards on board, and reports Attack plus Health at combat start, including the Fetch copy and the Wisps. It plays no fights and no shops, so read it as shape, not win rate.

**Shop supply.**
- **Rule 6.1.3a's odds:** a Boundary Stone is about 17% of a refill at tier 4, 8% at tier 5 and 5% at tier 6. A given tier 1 unit is about 1% a refill at tier 6.
- **What the model allows:**
  - one Ring spell a turn through tier 4, then one every 2nd turn;
  - Nan cycles only through tier 4;
  - leftover gold is churned through Annis (2 gold a Ring).
- **Why it matters:** my first runs, like Wild's, cast three Boundary Stones a turn late. That overstates the late game by about 15–25%, and it hides the missing gold sink.

**The lines are best-case scripts.** "Full line" means every key card shows up on time. The harness, with real shops, will land between the slow and low rows.

## The rows

| Line (default levers) | R6 | R9 | R12 | R15 | Mean R10–16 | Peak |
|---|---|---|---|---|---|---|
| Target (BG Sep 2025 mean) | 53 | 194 | 759 | 2,600 | 1.00× | |
| `fairies_ring`, full line | 46 (0.87×) | 140 (0.72×) | 932 (1.23×) | 3,036 (1.17×) | 1.21× | 1.52× on R10 |
| `fairies_ring`, slow shops (T5 R10, T6 R12, Monarch R13) | 46 (0.87×) | 160 (0.82×) | 919 (1.21×) | 3,264 (1.26×) | 1.14× | 1.51× on R10 |
| `fairies_ring`, low roll (no Lob or Silky) | 45 (0.85×) | 99 (0.51×) | 356 (0.47×) | 1,436 (0.55×) | 0.56× | 0.91× on R10 |
| `fairies_ring`, high roll (golden Cluricaun R8) | 46 | 194 (1.00×) | 1,292 (1.70×) | 4,364 (1.68×) | 2.00× | 2.51× on R16 |
| `fairies_ring`, top 1% (+ golden Monarch R11) | 46 | 194 (1.00×) | 1,338 (1.76×) | 6,386 (2.46×) | 2.89× | 5.50× on R16 |
| `fairies_ring`, breaker's copies, **with guards** | 46 | 134 (0.69×) | 742 (0.98×) | 1,820 (0.70×) | 0.88× | 1.23× |
| the same copies, **without guards** | 46 | 172 (0.89×) | 1,030 (1.36×) | 2,516 (0.97×) | 1.27× | 1.49× |
| `fairies_court`, full line | 50 (0.94×) | 211 (1.09×) | 983 (1.30×) | 3,551 (1.37×) | 1.16× | 1.39× on R11 |
| `fairies_court`, no tier 6 Fairy | 50 (0.94×) | 211 (1.09×) | 884 (1.16×) | 1,543 (0.59×) | 0.90× | 1.28× on R11 |

## Reading the rows

- **The shape is the engine shape the owner asked for:**
  - behind at once (0.72–0.87× on R6–R9 on the carry line, while the Shy banks sit);
  - ahead from the online turn (1.52× on R10);
  - then 1.15–1.25× on R12–R15, with 1.44× on Midsummer turns and 0.9× in the turn before.
- **The Court is the tempo route.** It's ahead from R7, strongest on R10–R12, and stays level late with a tier 6.
- **Spread:**
  - low roll about 0.5×;
  - top 1% 5.5× on R16, about 6× the full line's 0.89× that round;
  - both inside the owner's 10×.
  - The high roll (a golden Cluricaun) is about 2×. That's a triple, not a common find.
- **Copies are no longer a snowball.**
  - With guards, the breaker's stack (a second Cluricaun, Silky and Monarch) comes out *below* the plain line, because second copies cost gold and slots and grow nothing.
  - Without guards, it's +40%.
- **Lumps:** Midsummer still steps the curve (0.92× on R13, 1.44× on R14). That's the reward moment. p = 4 flattens it; p = 2 makes the top 1% 15×.
- **Carry share is high:** about 45% on each giant. Rule 1.6's risk is real, and the holders are the answer (sim question 2).

## The lever sweep (model, every other lever at default)

| Lever | Ring full R12 / R15, mean | Low R12 / R15 | Top 1% peak | Court R12 / R15, mean |
|---|---|---|---|---|
| **default (g = ⅓)** | 1.23 / 1.17, 1.21 | 0.47 / 0.55 | 5.5× | 1.30 / 1.37, 1.16 |
| g = 1 (every End of Turn) | 1.99 / 2.22, 2.16 | 1.25 / 1.60 | 12.0× | 2.10 / 2.51, 2.06 |
| g = ½ (every other) | 1.42 / 1.43, 1.48 | 0.66 / 0.90 | 7.2× | 1.50 / 1.56, 1.38 |
| g = ¼ | 1.04 / 1.08, 1.14 | 0.47 / 0.55 | 4.2× | 1.09 / 1.18, 1.07 |
| p = 2 (Midsummer every other) | 1.23 / 2.31, 1.61 | 0.47 / 0.55 | 15.6× | 1.30 / 1.27, 1.38 |
| p = 4 | 1.23 / 1.26, 1.13 | 0.47 / 0.29 | 3.0× | 1.30 / 0.70, 1.07 |
| Fetch copies at half (fetch = ½) | 0.96 / 0.91, 0.94 | 0.37 / 0.43 | 4.2× | unchanged |
| Annis's sale trigger off | 1.01 / 0.77, 0.93 | 0.36 / 0.34 | 3.4× | 1.01 / 1.00, 0.91 |
| Plans' spells as written (no supply limit) | 1.34 / 1.60, 1.43 | — | 7.7× | 1.31 / 1.39, 1.18 |

**Sweep advice.**
- Run g first: ⅓, then ½.
- If the harness's median Fairy board is under 0.9× on R10–R14 with real shops, step to ½.
- If it's over 1.3×, try p = 4 before ¼.
- The sale trigger is the late game. Turning it off drops the carry line to 0.77× on R15 and the Court to a 0.91× average.

---

# Harness lines

Card ids are `content/units/*.json` and `content/spells/*.json` ids. "Keep" means don't sell it for a plain upgrade. The climb schedules are the model's.

```json
{
  "fairies_ring": {
    "kind": "engine_carry",
    "tribe": "fairies",
    "engine_flag": true,
    "priority": [
      "old_moth_annis", "cluricaun", "nan_toadstool", "lob_lie_by_the_fire", "cradle_fetch",
      "fairy_monarch", "silky", "belladonna", "hob_in_the_hearth", "sally_spore",
      "reel_mistress", "hedge_witch", "changeling", "rainbow_chaser", "will_o_the_wisp",
      "queen_of_elfland"
    ],
    "keep": ["old_moth_annis", "cluricaun", "cradle_fetch", "fairy_monarch", "belladonna"],
    "buy_only_if": {
      "rainbow_chaser": "sell it the same turn it pays 5 or more",
      "will_o_the_wisp": "a ringed slot will stay empty at combat",
      "queen_of_elfland": "pivot to fairies_court",
      "sally_spore": "before T5; sell her when the slot is needed"
    },
    "place": {
      "carry_slot": "B1",
      "old_moth_annis": "F1",
      "cradle_fetch": "F2",
      "cluricaun": "F3",
      "shy_units": "B2 or B3, the slots with the fewest Rings",
      "fairy_monarch": "B2",
      "reel_mistress": "B3",
      "nan_toadstool": "played on B1 while B1 is empty; sold from B1"
    },
    "stander_on_carry_slot": [
      "changeling if the enemy unit in B1 is bigger than our stander would be",
      "hedge_witch if the enemy unit in B1 has Attack at least half our B1 Ring",
      "otherwise belladonna, else the biggest body we own"
    ],
    "spells": {
      "spore_cloud": "buy; aim at the rainbow's missing slot, else B1",
      "boundary_stone": "buy; aim at the rainbow's missing slot, else B1",
      "pinch_of_dust": "only to thank a Shy unit",
      "hiring_fair": "at T5+ with 5+ Fairies and no fairy_monarch by R11",
      "horseshoe": "buy when the scout shows a Fairy carry; aim across its slot",
      "harvest_supper": "skip"
    },
    "thank": [
      "lob_lie_by_the_fire: when its turns on board reach a multiple of 3 and silky is on board; else at 6",
      "hob_in_the_hearth: only with silky on board, or when the slot is needed (about R13)",
      "silky: last, after the other Shy units have left"
    ],
    "climb": {"T2": 2, "T3": 4, "T4": 6, "T5": 9, "T6": 11},
    "save": [
      "R1-R8: spend to 0, holding only the next scheduled tier-up",
      "from R9: hold 6 for hiring_fair while at T5+ with no fairy_monarch",
      "otherwise churn the rest: buy the cheapest unit, play it in the flex slot, sell it (Annis Rings B1); stop at 1 gold"
    ],
    "knobs": ["Annis F1 or F2 (one giant or two)", "thank turn for Lob", "churn on or off", "stander rule"]
  },
  "fairies_court": {
    "kind": "tempo",
    "tribe": "fairies",
    "engine_flag": false,
    "priority": [
      "old_moth_annis", "nan_toadstool", "sally_spore", "rainbow_chaser", "cluricaun",
      "lob_lie_by_the_fire", "hedge_witch", "changeling", "silky", "belladonna",
      "queen_of_elfland", "will_o_the_wisp", "fairy_monarch", "reel_mistress", "cradle_fetch",
      "hob_in_the_hearth"
    ],
    "keep": ["old_moth_annis", "cluricaun", "queen_of_elfland", "belladonna", "changeling"],
    "buy_only_if": {
      "rainbow_chaser": "hold until 6+ slots have a Ring, then sell",
      "cradle_fetch": "one slot holds over a third of the board"
    },
    "place": {
      "old_moth_annis": "F2",
      "cluricaun": "F3",
      "queen_of_elfland": "F4; a cheap unit in B3 every turn",
      "will_o_the_wisp": "B2 once the Queen is down",
      "changeling": "B1, or across the scouted biggest enemy",
      "hedge_witch": "across their highest-Attack unit",
      "nan_toadstool": "played into an unringed slot, then sold",
      "sally_spore": "beside the gap that most needs a Ring; later beside the tithe slot"
    },
    "spells": {
      "spore_cloud": "the rainbow's missing slot first, then B1 or B2",
      "boundary_stone": "the rainbow's missing slot first, then B1 or B2",
      "pinch_of_dust": "only to thank a Shy unit",
      "harvest_supper": "when 3 gold is spare",
      "hiring_fair": "at T6 with 5+ Fairies and no Fairy tier 6",
      "horseshoe": "buy when the scout shows a Fairy carry"
    },
    "thank": [
      "lob_lie_by_the_fire: at 3 turns if silky is on board, else at 6",
      "silky: the turn after Lob"
    ],
    "climb": {"T2": 2, "T3": 4, "T4": 6, "T5": 8, "T6": 10},
    "save": [
      "never bank more than 2, except to hold the Chaser for a turn where its sale pays a tier-up and a buy",
      "with the Queen down: keep 3 gold each turn for the unit she tithes",
      "churn the rest through Annis (2 Rings a sale from F2); stop at 1 gold"
    ],
    "knobs": ["Queen in F2/F3 (two tithes a turn) or F4", "Monarch or a second answer on B1", "rainbow by R7 or R8"]
  }
}
```

**Checks the harness should report** (breaker points 6 and 7):
- **Rainbow tax:** how often the carry line skips the rainbow, and whether it wins more when it does.
- **Carry share:** the stander's and the twin's share of board stats, against win rate.
- **Thank timing:** the round Lob is thanked, against the result.

---

# Engine support needed

| Need | For | Notes |
|---|---|---|
| Ring as a count per slot; player-level `ring_size`; slot total = count × size | Every Ring card | Replaces stat-stacking `slot_effect` for Ring. Remove the 8.5.4 cap. Snapshots and ghosts carry `ring_size`. The badge shows total and count. |
| `ring_size_add` (n) and `ring_size_multiply` (k) | Cluricaun, Lob, Silky, Monarch | `multiply` exists for units |
| One shared counter per effect for all copies, shown on the hero or card | Cluricaun, Monarch, Silky | The copy guard. Golden sets the step to 2, or the multiplier to 3. |
| Trigger "after you sell" (any unit), with End of Turn on the same effect | Annis | New listener. `on_sold` exists only for the seller itself. |
| `slot_effect` at `behind` (one or two slots) | Annis | Selector exists |
| `on_play` and `on_sold` on one entry | Nan | `when sold` exists (Chaser) |
| `per`: slots with a Ring | Chaser | New `per` source |
| Condition: every slot has a Ring | Cluricaun | New |
| Value source: this slot's Ring | Hedge Witch | Start of Combat −Attack, floor 0 |
| `turns_on_board`, not reset by moves | Lob | `turns_in_slot` resets on a move |
| `on_leave` (thanked only) and `after_shy_leaves` | Lob, Silky | Shy exists. Selling and destroying are excluded. |
| Shield keyword and the "biggest" selector | Hob, Belladonna | Track B. Hob resolves after Cradle Fetch. Nightshade's loss isn't damage, so Shield doesn't stop it. |
| Copy with current combat stats, Ring included; golden copy; two Fetches never share | Cradle Fetch | Extends `cradle_fetch` |
| Dance limit `m` per Ring | Reel-Mistress | Today it's once a fight; make it a parameter |
| Changeling | — | Text change only; the effect is unchanged |
| Teind every `qp` End of Turns; "Ring every slot qk times per destroyed unit" | Queen | Destroy-behind exists. Remove the "or this if none" clause and the share. |
| Spells read the caster's `ring_size` | Spore Cloud, Boundary Stone | Anti-splash. Spell retunes are proposed to the spell panel. |
| Rule edits | 8.5.4, 12.1.7 | Drop the Ring cap. In 12.1.7, replace "Silky Rings a thanked unit's vacated slot" with Silky's grow. 12.1.5 is unchanged. |

---

# The breaker's points

| # | Breaker point | Call | What I did, and why |
|---|---|---|---|
| 1 | Second copies stack into a common snowball | **Taken** | Copy guards on Cluricaun, Silky and the Monarch's clock. The model's breaker stack now averages 0.88× on R10–R16, below the plain line's 1.21×. Without guards it averages 1.27×. |
| 1b | Then test g = 1 against g = ½ | **Taken, and went further** | g = 1 runs 2.2×; g = ½ runs 1.4–1.5× on full lines. Default **g = ⅓** (1.16–1.21×), with ½ as the first step if the harness runs cold. |
| 2 | The Queen launders Rings into unit stats; set t = ½ and cut her to 17 words | **Changed** | t = ½ made her share negligible in my first model, so she was dead text. She now **makes Rings** every turn: 12.1.5 is untouched, she's 13 words, and the Court gets a late engine. |
| 3 | "Leaves" is undefined | **Taken** | Carry's ruling, written on Lob and Silky and in Rules: only thanking counts. Selling or destroying doesn't, and destroyed Shy units pay nothing. |
| 4 | Much fight power is combat-only (Fetch, Reel) | **Partly taken** | Fetch's twin is in the shop's combat-start stats, and every Fetch number here counts it. Reel's text now says "Twice per Ring". Reel's extra swings stay invisible; they're a secondary payoff, not a main one. |
| 5 | Must-be-attacked needs Taunt | **Taken** | Removed. Plain Wisps on empty Rings. |
| 6 | The rainbow tax may be paid anyway | **Taken as a harness check** | Kept as designed. Annis from F1 feeds only B1, so finishing the rainbow costs real off-carry Rings. The harness reports how often the line skips it. |
| 7 | Carry share 50–80% | **Taken: holders** | Fetch's twin, Hob's Shield and Reel's dance. The share is still about 45% per giant, so this is sim question 2. |
| S2 | Holders: Cleave on Cluricaun, or Will as Reborn | **Changed** | Shield on Hob instead. Cleave needs a host, and Cluricaun's text is the rainbow engine at 15 words. Shield is Track B's keyword, and the audit values it slightly above Cleave (+13 against +11). Will's refill is a sweep variant because it pushed Will to 16 words. |
| S3 | Anti-splash: Ring spells use the caster's size | **Taken, by construction** | Ring size is per player. |
| S6 | No Taunt | **Taken** | See 5. |
| S7 | Check other panels for one-number engines | **Flagged** (below) | Count × size is distinct because old Rings grow. Midsummer has the same shape as Hedgerow's every-3rd-turn doubling. |
| X1 | Too many biggest-enemy answers across tribes | **Flagged** | Belladonna keeps "biggest", with a fallback text for the cross-tribe synthesis. |
| X2 | Fixed slots depend on Horseshoe supply | **Accepted as identity** | It's in Weak points. The Annis-F2 two-giant board is the dodge. Cold Iron is proposed as a halve, not a null. |
| — | **New finding:** the designs' late Ring spells exceed what shops offer | **Fixed** | Annis's sale trigger is the late gold sink. The model limits Ring spells to rule 6.1.3a's odds. |

---

# What changed from Wild

| Card | Wild | Pass 3 | Why |
|---|---|---|---|
| Old Moth Annis 2/3 → **2/4** | End of Turn: Ring the slots behind this | **And after you sell** | The late gold sink |
| Sally Spore 1/4 → **2/4** | Unchanged text | Body | Early valley |
| Hob-in-the-Hearth 1/4 → **2/5** | Shy bank: Ring its slot per turn stayed | **Shy. Your biggest unit gains Shield** | Holder (graft from Carry); Annis now banks |
| Cluricaun 3/4 → **3/5** | Every End of Turn | **Every 3rd End of Turn**; copies share | Breaker point 1; sizing |
| Lob-Lie-by-the-Fire 2/4 → **3/6** | Per 2 turns | **Per 3 turns** | Sizing; Wild's own fallback |
| Silky 2/5 → **3/7** | Unchanged text | Copies grow once | Copy guard |
| Changeling | Swap…swap back after it attacks once | **Steal…until it attacks** | 15 words to 10 |
| Will-o'-the-Wisp | Wisps must be attacked first | **Plain Wisps** | No Taunt |
| Cradle Fetch | Golden copies your biggest | **Golden copy**; F2/F3 copy the bigger unit; two never share | Wording rule 7; guard |
| Reel-Mistress | "Twice a fight" | **"Twice per Ring"** | Breaker point 4 |
| Fairy Monarch | Every 3rd End of Turn: double | **One shared clock**; "when played" stays cut | Guard; length |
| Queen of Elfland | Every 3rd: destroy, share stats including Rings | **Every End of Turn: destroy behind, Ring every slot per unit** | 12.1.5; a live late engine for the Court |

Unchanged from Wild: Nan, the Chaser, Hedge Witch and Belladonna (texts), and every body not listed.

# Flags for the other panels

- **Cross-tribe:**
  - Belladonna's biggest-enemy reach (fallback above).
  - Midsummer's every-3rd doubling has the same shape as Hedgerow's Dozey. If only one tribe keeps that shape, the Fairy alternative is p = 2 with "grow by half".
- **Spell panel:**
  - Spore Cloud "Ring a slot twice" and Boundary Stone "Ring a slot three times", reading the caster's Ring size.
  - Ring spells are rare in late shops, so no tribe's late game should lean on them.
- **Neutral panel:** Cold Iron, "Start of Combat: halve the biggest enemy's Ring."
- **Engine/UI:** a "sell to Ring" hint on Annis's slots, and the shared counters on the hero.

# What the sims must answer for Fairies

1. With real shops, where does the median Fairy board sit on R10–R14 at g = ⅓ and ½? How often is a Fairy board at 2× the lobby median or more?
2. **Two giants at about 90% of board stats** (stander plus Fetch twin, with Hob and Reel), against an even board of the same total (fundamentals 1.6). Does the carry line need Annis in F2 (two big slots) to hold?
3. Horseshoe plus one biggest-enemy answer against the carry line on R12. Does the carry still win sometimes, and does the answer land sometimes?
4. **The Court without a tier 6** (0.59× by R15): is Hiring Fair enough insurance, or does the Queen need to be reachable earlier?
5. **The sale trigger:** how much gold the bots churn a turn, and whether it crowds out tier-ups (the model churns 1–5 times a turn from R9).
