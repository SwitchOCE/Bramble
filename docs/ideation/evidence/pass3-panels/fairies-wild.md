# Fairies, pass 3: the carry is a place

Pass 3 design, angle **identity and delight**. 9 Nov 2026, a workflow designer, briefed with the owner's notes 09a, 09c, 09d and 08e, `fundamentals.md` sections 1 and 3, `plan-scale-rework.md` (Step 1, Track C) and the wording guide. I had no price list. Numbers are sized against the target shape with a small count model (end of this file), not costed.

## The pitch in one breath

In Battlegrounds, power lives on minions. **Fairies keep their power in the ground.** A Ring is power on a slot. It outlives every unit that stands on it, and **every Ring grows when your Rings grow**. So a Fairy's carry isn't a unit. It's a place. Whoever steps into your big Ring becomes the giant: a 1/1 Wisp, a T1 hag, or the enemy's own carry, dragged across by a Changeling.

Three things Battlegrounds can't do, which this design builds the tribe around:

1. **The carry is a place.** Your best "unit" is B1. You choose who stands there each turn: the hag whose curse reads her Ring, a Wisp that must be attacked, Belladonna, or a neutral with cleave.
2. **Power moves in the fight.** Reel-Mistress passes the giant Ring down the line, so every dancer takes a turn being the giant.
3. **The enemy's carry fights on your Ring.** The Changeling swaps it onto your side, where it stands on your Ring and hits its own board.

*Similar to:* Battlegrounds' Blood Gems for the shared Ring size number, and Galaxy's slot buffs for Rings that stay on a slot.

## What changes from the current slice

| Area | Now | Pass 3 |
|---|---|---|
| Ring | +A/+H on a slot, capped at +4/+4 | A slot holds a **count** of Rings. Each gives your **Ring size**, one number for your whole board, shown on your hero. Starts at +1/+1. No cap. |
| Growth | Linear, about +2 stats a turn a card | **Rings × Ring size.** Ring makers raise the count; growers raise the size. Every Ring, old or new, gets the new size. |
| Rainbow keyword | Paint slots by playing into them; bands fade | Removed as a keyword. The "rainbow" is now simply **a Ring on every slot**: the Chaser's pot and Cluricaun's growth read it. |
| Hex keyword | Flat −Attack, capped at your tier | Removed. Hedge Witch's curse reads her own slot's Ring, so it scales with the engine. |
| Shy route | Brownies give flat buffs, Silky Rings their slots | Brownies are **banks**: they work while they stay, and when you thank them the gift lands. |
| Belladonna | Enemies across | **The biggest enemy**, in any row. |
| Fetch | Base copy of the unit behind | A copy of the unit behind, **Ring and all**. Moves to tier 4. |
| Silky | Tier 4 | Tier 3 (the Shy payoff must land while the brownies are still on board). |
| Fairy Monarch | Rings under Fairies +1/+1 | **Midsummer:** every 3rd End of Turn, double your Ring size. |
| Queen's Teind | Shares printed and permanent stats only | Shares **Rings included**. The Ring stays on the slot. |

Tier spread stays 3/3/3/3/2/2. Every current creature, name and portrait is kept.

---

# The engine: Rings × Ring size

## Rules

- **Ring** *(reminder: whoever stands on this slot gains your Ring size for each Ring here.)*
  - "Ring this slot" adds one Ring to the slot. Rings stay on the slot when units move, are sold or die. Empty slots keep them too.
  - The slot badge shows the total and the count: `+40/+40 · 4`.
- **Ring size** *(reminder: what each Ring gives. Starts at +1/+1.)*
  - It's one number for your board, shown on your hero like the Supper chip.
  - "Your Rings grow +1/+1" raises it, so **every** Ring on every slot gains at once.
  - It's permanent and visible in the shop.
- **Stats from a slot are slot stats**, as now (8.5). Shy units ignore them (12.1.7). Fights copy both the counts and the size, and so do ghosts.
- **Horseshoe** (neutral) halves the slot's total across, rounded down. It's now a real answer.

**Why it compounds.** Total Ring stats are count × size, and both grow. Count grows with gold and board slots; size grows with the T3 cards and doubles at T6. A Ring you place on round 2 is +1/+1 that day and +25/+25 on round 15. That gives exactly the engine shape the plan asks for: behind at once, level in a few turns, clearly ahead after.

**Why it concentrates (or doesn't).** Size growth helps every Ring equally, so *where you put each Ring* decides your board's shape. Stack them on one slot and you have a carry. Spread them over seven and you have a court of even, big units. That is the engine's decision.

## The rate parameters (for the lever sweep)

| Lever | What it sets | Default | Sweep |
|---|---|---|---|
| **g (primary)** | Ring size per grow step: Cluricaun each turn, Lob per 2 turns, Silky per departure | +1/+1 | 1, 2, or +1 every 2nd turn (0.5) |
| **p** | Monarch's Midsummer period | every 3rd End of Turn | 2, 3, 4; smooth variant "+¼ each End of Turn" |
| m | Reel-Mistress moves per Ring a fight | 2 | 1, 2, 3, unlimited |
| t | Queen's Teind share of the Ring's stats | all | all, half |

Start the sweep on **g** and **p**. They set the mid and late slope. m and t mostly set the spread.

## When it comes online

- **Fairy Ring line (carry):** level by round 7–8, once every slot has a Ring and Cluricaun starts growing. Clearly ahead from round 10, when Lob is thanked and Fetch copies the carry. The first Midsummer is on round 13.
- **Fairy Court line (tempo):** online on round 7 with the rainbow. Strongest on rounds 7–10, then level, with the Queen and a late Monarch keeping it in the band.

## The decision it creates

- **Every Ring: stack or spread?** The carry wants one slot. Cluricaun and the Chaser want a Ring on all seven. Annis in a corner stacks, and Annis in the middle spreads.
- **Thank the brownie now or later?** Thanking now gives gold and a free slot. Waiting gives a bigger gift.
- **Keep a gap or field a seventh unit?** Sally only grows empty slots, and Wisps fill empty Rings at Start of Combat.
- **Who stands on the big Ring this fight?** Read the scout first. The hag curses the unit across. The Changeling steals the unit across. A Wisp must be attacked. Belladonna poisons their biggest.

---

# The 16 cards

Typical sizes used for the payoff numbers: **Ring size about 4 / 10 / 25 on rounds 9 / 12 / 15**, with about 22 / 33 / 47 Rings on the board, 13 / 24 / 38 of them on the carry slot in the Ring line. One Ring is therefore worth about 8 / 20 / 50 stats.

## Tier 1

### Nan Toadstool: Pixie Trickster, 2/1
- **Text:** When played or sold: Ring this slot.
- **Golden 4/2:** When played or sold: Ring this slot twice.
- **Condition:** playing it, and later selling it. Both are things you do anyway.
- **Payoff:** 2 Rings a copy, kept all game: about 16 / 40 / 100 stats on rounds 9 / 12 / 15. A late rebuy and sell is 2 net gold for +20/+20 on round 12 or +50/+50 on round 15.
- **Permanence:** permanent, on the slot.
- **Enabler:** every Ring reader: Witch, Wisp, Fetch, Reel, Changeling. It also paints rainbow slots for the Chaser and Cluricaun.
- **Concentrates:** yes. You pick the slot.
- **Delight:** the T1 you still buy on round 14.

### Rainbow Chaser: Leprechaun Cobbler, 2/2
- **Text:** When sold: get 1 gold per slot with a Ring.
- **Golden 4/4:** When sold: get 2 gold per slot with a Ring.
- **Condition:** spread Rings. The full rainbow is all seven slots.
- **Payoff:** 5–7 gold on rounds 6–9, which is 2–4 more than its price. It's the Fairy economy: gold you turn into Nan cycles and Ring spells, worth about 30–70 stats by round 12.
- **Permanence:** one-shot gold, which you can repeat whenever a Chaser shows up.
- **Enabler:** pays for the count engine. It also pulls you toward the rainbow that Cluricaun needs.
- **Concentrates:** no. It rewards spreading, and that is its tension with the carry.

### Hedge Witch: Hag of the Hedgerow, 1/3
- **Text:** Start of Combat: the enemy across loses Attack equal to this slot's Ring.
- **Golden 2/6:** Start of Combat: the enemy across loses Attack equal to twice this slot's Ring.
- *Details:* a +12/+12 Ring takes 12 Attack. A Fetch copying her uses its own slot.
- **Condition:** Rings under her, and their unit across from her.
- **Payoff:** on a spread slot of about 4 Rings, −16 / −40 / −100 Attack. On the carry slot she is the carry, and takes −52 / −240 / −950: she zeroes whatever stands across.
- **Permanence:** a combat answer that grows with the permanent engine.
- **Enabler:** gives the carry slot a second job, and makes Rings under a non-carry worth more.
- **Concentrates:** yes. She is the best cheap stander on the big Ring.
- **Delight:** the old hag in the fairy ring. Their 300-Attack carry walks out with 0.

## Tier 2

### Old Moth Annis: Moth Pixie, 2/3
- **Text:** End of Turn: Ring the slots behind this.
- **Golden 4/6:** End of Turn: Ring the slots behind this twice.
- **Condition:** standing in the front row.
- **Payoff:** from F1 or F4, 1 Ring a turn on one back slot: about 7 / 10 / 13 Rings by rounds 9 / 12 / 15, or 56 / 200 / 650 stats. From F2 or F3, 2 a turn, split over two slots.
- **Permanence:** permanent.
- **Enabler:** the main count engine. Corner Annis feeds the carry slot; middle Annis feeds the court.
- **Concentrates:** yes from a corner, no from the middle. That's a placement decision every turn.

### Sally Spore: Sprite Gardener, 1/4
- **Text:** End of Turn: Ring your empty slot nearest this.
- **Golden 2/8:** End of Turn: Ring your empty slot nearest this twice.
- **Condition:** a gap on your board.
- **Payoff:** 1 Ring a turn into a gap. Kept from round 4 to 9, that's about 6 Rings: 48 / 120 / 300 stats. The Ring stays after she leaves.
- **Permanence:** permanent.
- **Enabler:** Will-o'-the-Wisp (empty Rings), and a gap carry that a Wisp fills at Start of Combat.
- **Concentrates:** yes, if you keep her beside one gap. Move her to spread.

### Hob-in-the-Hearth: Brownie Helper, 1/4
- **Text:** Shy. When this leaves: Ring its slot for each turn it stayed.
- **Golden 2/8:** Shy. When this leaves: Ring its slot twice for each turn it stayed.
- *Golden details:* Shy pays 4 gold.
- **Condition:** keep him on board, then thank him with an aimed spell.
- **Payoff:** 4 turns on board gives 4 Rings on his slot and 2 gold: about 32 / 80 / 200 stats.
- **Permanence:** permanent.
- **Enabler:** Silky (thanking him grows every Ring). Stand him on the carry slot while Annis Rings it, then step the carry in.
- **Concentrates:** yes. It's your carry slot's banker.
- **Delight:** "Hob kept the hearth warm until the carry arrived."

## Tier 3: where your Rings start to grow

### Cluricaun: Leprechaun Reveller, 3/4
- **Text:** End of Turn: if every slot has a Ring, your Rings grow +1/+1.
- **Golden 6/8:** End of Turn: if every slot has a Ring, your Rings grow +2/+2.
- *Details:* all seven slots, empty or not.
- **Condition:** the rainbow, a Ring on all seven slots. That costs a carry player 6 Rings once.
- **Payoff:** +1 Ring size a turn from about round 7: +132 / +396 / +850 stats on rounds 9 / 12 / 15, or about +1,700 once Midsummer has doubled it.
- **Permanence:** permanent, and this game.
- **Enabler:** every Ring, and the Chaser shares the rainbow.
- **Concentrates:** it's neutral. Its condition forces a little spread first.
- **Delight:** completing the rainbow. It's the tribe's mid-game milestone.

### Lob-Lie-by-the-Fire: Brownie Lubber, 2/4
- **Text:** Shy. When this leaves: your Rings grow +1/+1 per 2 turns it stayed.
- **Golden 4/8:** Shy. When this leaves: your Rings grow +2/+2 per 2 turns it stayed.
- *Golden details:* Shy pays 4 gold.
- **Condition:** waiting, then an aimed spell. It's time-bounded in the way the owner liked ("don't move for 3 turns, then X").
- **Payoff:** 6 turns gives +3 Ring size at once. On round 10 with 26 Rings that's +156 stats in one click. On round 12 it's worth about 200, and on round 15 about 280, or 560 after Midsummer.
- **Permanence:** permanent.
- **Enabler:** Silky.
- **Concentrates:** neutral.
- **Delight:** Lob's last night. You thank him and the whole board jumps.

### Silky: Grey Brownie, 2/5
- **Text:** Shy. After a Shy unit leaves: your Rings grow +1/+1.
- **Golden 4/10:** Shy. After a Shy unit leaves: your Rings grow +2/+2.
- *Details:* this counts too.
- **Condition:** thanking Shy units, including herself.
- **Payoff:** 2–3 departures give +2–3 Ring size: about +88 / +198 / +280–560 stats.
- **Permanence:** permanent.
- **Enabler:** Hob and Lob, and any aimed spell, such as Spore Cloud on a Shy unit's slot.
- **Concentrates:** neutral.
- **Tier move (from 4):** her gift has to land while Hob and Lob are still on board, on rounds 5–8.

## Tier 4

### Changeling: Changeling Babe, 3/3
- **Text:** Start of Combat: swap sides with the enemy across. Swap back after it attacks once.
- **Golden 6/6:** Start of Combat: swap sides with the enemy across. Swap back after it attacks twice.
- **Condition:** something worth stealing across from it. You re-place it after scouting.
- **Payoff:** the stolen unit stands on your Ring, so it hits harder, and it hits its own board. Their unit across is worth about 25–60 / 100–300 / 300–900 stats. You get a kill from it and a damaged carry when it goes home.
- **Permanence:** combat only. This is the answer slot.
- **Enabler:** the big Ring. Put the Changeling on it and the enemy you steal inherits your Ring.
- **Concentrates:** it uses your concentration against them.
- **Fairy resilience:** an enemy Changeling taking your stander leaves your Ring at home. Their babe stands on it and fights for you.

### Will-o'-the-Wisp: Wisp Lantern-Bearer, 3/6
- **Text:** Start of Combat: summon a 1/1 Wisp into each empty Ring. Wisps must be attacked first.
- **Golden 6/12:** Start of Combat: summon a 2/2 Wisp into each empty Ring. Wisps must be attacked first.
- *Flag:* the golden text is the wording guide's doubling, but it's nearly blank at scale. The variant "Wisps come back once" is better and breaks rule 7.
- **Condition:** empty slots that hold Rings: gaps grown by Sally, or slots you emptied on purpose.
- **Payoff:** a gap of about 6 Rings makes a 25/25 decoy on round 9, 61/61 on round 12 and 151/151 on round 15. Must-be-attacked works within the row that can be attacked (9.5.4). On the gap-carry board the giant is a Wisp.
- **Permanence:** combat only, but it reads permanent Rings.
- **Enabler:** Sally, Hob's empty slot after a thank-you, Reel (a Wisp is one more dancer).
- **Concentrates:** yes. It's the gap carry's body, and it **holds stats**: they have to hit it.
- **Owner thread:** "Decoy lights that fill empty slots and draw attacks: I'm interested to see what that would look like" (02h).

### Cradle Fetch: Fetch Double, 2/4
- **Text:** Start of Combat: become a copy of the unit behind, Ring and all.
- **Golden 4/8:** Start of Combat: become a copy of your biggest unit, Ring and all.
- *Details:* the copy takes that unit's current stats, Ring included, and this slot's Ring still applies. The copy's Start of Combat text fires.
- **Condition:** the carry stands behind it. F1 copies B1, F4 copies B3, and F2/F3 copy the left unit behind.
- **Payoff:** a second carry for the fight: about +110 / +500 / +1,900 stats.
- **Permanence:** combat only, but predictable. The shop shows combat-start stats.
- **Enabler:** carry holding (two giants, so one death doesn't end the carry), and a second Witch curse, Changeling steal or Belladonna.
- **Concentrates:** it makes concentration safe.
- **Tier move (from 3):** copying a carry Ring and all is a tier 4 payoff.

## Tier 5

### Reel-Mistress: Pixie Dancing-Mistress, 4/7
- **Text:** After a unit on a Ring attacks: its Ring moves to your next unit. Twice a fight.
- **Golden 8/14:** After a unit on a Ring attacks: its Ring moves to your next unit. Four times a fight.
- *Details:* the limit is per Ring. Rings that meet add up. Fights run on a copy, so Rings return home after the fight.
- **Condition:** units on Rings attacking.
- **Payoff:** the carry's Ring swings three times a fight, not once: about +100 / +480 / +1,900 damage. Spread Rings gather onto your later attackers.
- **Permanence:** combat only.
- **Enabler:** Wisps and cheap Fairies as dancers.
- **Concentrates:** yes, in the fight.
- **Why the limit:** each move reuses the whole Ring. Unlimited, every attack would be a giant attack, which is roughly a 7× multiplier. The sweep tests m.
- **Folklore:** mortals in a fairy ring dance until they drop. A dancer whose Ring moves on keeps its damage and can fall.

### Lady Belladonna: Sprite Poisoner, 4/8
- **Text:** Start of Combat: give the biggest enemy Nightshade.
- **Golden 8/16:** Start of Combat: give the two biggest enemies Nightshade.
- *Nightshade reminder:* whenever attacked, this first loses half its current Health.
- **Condition:** they have a biggest unit. Everyone does.
- **Payoff:** their carry, about 65 / 250 / 850 stats, falls to a few small hits. A back-row carry is only bitten once their front row is gone.
- **Permanence:** combat only.
- **Enabler:** Wisps, which add more attacks, and Reel.
- **Concentrates:** no. It's the anti-carry card.
- **Change:** it goes back to the owner's original intent ("helps wide boards deal with really, really big boards", 02k): it always finds the giant.

## Tier 6

### Fairy Monarch: Fairy Monarch, 6/8
- **Text:** Every 3rd End of Turn: double your Ring size.
- **Golden 12/16:** Every 3rd End of Turn: triple your Ring size.
- *Details:* counts End of Turns from the turn it's played. The counter shows on the card.
- **Condition:** time.
- **Payoff:** played on round 11, it doubles on rounds 13 and 16. By round 15 that's about +1,000 stats, half the board.
- **Permanence:** permanent, and this game.
- **Enabler:** every Ring.
- **Concentrates:** neutral.
- **Delight:** **Midsummer.** A countdown everyone in the lobby can see coming.

### Queen of Elfland: Fairy Queen, 8/8
- **Text:** Every 3rd End of Turn: destroy the units behind this, or this if none. Other Fairies share their stats, Rings included.
- **Golden 16/16:** Every 3rd End of Turn: destroy the units behind this, or this if none. Other Fairies share double their stats, Rings included.
- *Details:* the Rings stay on their slots. Shared stats are permanent unit stats. Tribe bonus and auras are excluded.
- **Condition:** cheap Fairies behind her on ringed slots, and other Fairies to share with.
- **Payoff:** on the court board, about 250 stats shared on round 13 and about 800 on round 16. Tithing the carry slot's stander copies the whole carry Ring into the court.
- **Permanence:** permanent.
- **Enabler:** Nan, which refills a tithed slot and adds two more Rings there.
- **Concentrates:** no. It turns one concentrated slot into an even court. That's the route's T6.
- **Rule change:** 12.1.5 excluded Rings to stop "bonus laundering". On ideation, copying Ring power into units is the point. t (all or half) is the lever.
- **Delight:** **tithe the dancer, keep the Ring.**

**Token, Wisp:** a 1/1 Fairy (golden Will: 2/2). It exists only in combat and takes its slot's Ring.

---

# Routes

## Carry route: the Fairy Ring (engine line)

- **The idea:** one slot (usually B1, protected behind F1 and F2) holds about half your Rings. Choose its stander each fight.
- **How the carry holds its stats:**
  - The Fetch in F1 copies it, Ring and all.
  - The gap version leaves B1 empty, so a Wisp giant fills it and must be attacked once the back row opens.
  - Reel passes its Ring on, so the giant swings three times a fight.
- **Typical round 12 board** (Ring size 10, 33 Rings, 24 on B1):

| Slot | Unit | Combat stats |
|---|---|---|
| F1 | Cradle Fetch | Copy of B1: about 245/250 |
| F2 | Old Moth Annis | Rings B1 and B2 |
| F3 | Cluricaun | Ringed: 23/24 |
| F4 | Hedge Witch | Curses the unit across |
| B1 | Lady Belladonna on +240/+240 | 244/248 |
| B2 | Reel-Mistress | Ringed: 34/37 |
| B3 | Gap: a Wisp | 41/41, must be attacked |

## Non-carry route: the Court (tempo line)

- **The idea:** Annis in the middle, Sally, Nan and the Chaser paint the rainbow by round 7. Cluricaun grows it.
- **Answers:** Witch, Changeling and Belladonna beat the other tribes' carries.
- **T6:** the Queen turns two ringed slots into permanent stats for the whole court every third turn.
- **Typical round 12 board:** six or seven Fairies at about 45/45 each, every slot with 5–6 Rings. Fewer, even, big bodies beat one carry among small ones at equal totals (audit 6).

## Answers to other tribes' carries

| Card | Reach | At scale |
|---|---|---|
| Lady Belladonna | The biggest enemy, any row | Halves its Health each time it's hit. The strongest answer, and proportional. |
| Hedge Witch | Across | Takes Attack equal to her Ring. On the carry slot she zeroes it. |
| Changeling | Across | Their carry hits its own board, from your Ring. |
| Wisps | Their attackers | Decoys must be attacked first. A small Wisp soaks a 300-Attack swing. |
| Fetch | Copies the unit behind | Doubles any of the three above. |

## Weak points

- **Early tempo.** Bodies are small, and the gap board fields six. The model's round 4–5 boards are about 75–85% of today's median.
- **Horseshoe** halves the Ring across, and a **"biggest enemy" answer** (Track B) hits the stander. Proposed for neutrals: **Cold Iron**, "Start of Combat: the biggest enemy's Ring does nothing", the folklore weakness.
- **Overkill against wide boards** when the carry slot passes about half the board. Fetch, Wisps and Reel are the holders. If you skip them, spread.
- **Stranded Rings.** A Ring holder killed before it attacks keeps the Ring on an empty slot. Mire and skipped attacks stall the dance.
- **Supply.** If you miss all three T3 growers, Ring size stays near 1 (the low roll, about 0.45× target). Three of them at T3 make that rare.
- **The rainbow tax.** The carry line spends 6 Rings off-carry to turn Cluricaun on.

## Two highroll moments

1. **Midsummer at the Long Dance (round 13).**
   - The Monarch's third End of Turn doubles Ring size from 13 to 26.
   - B1's 28 Rings go from +364/+364 to +728/+728.
   - At the bell, the Fetch in F1 becomes a second 730/730. A Wisp lights up in B3 at 79/79 and must be attacked.
   - Reel-Mistress walks B1's Ring down the line twice. Three different pixies each swing for 730.
   - *What the player says:* "every fairy on my board took a turn being the giant."
2. **Their carry danced for me (round 12).**
   - Their Dozey is 300/300 in F2. You scouted it and moved the Changeling onto F2, your +120/+120 Ring.
   - At Start of Combat they trade places. Dozey is a 420/420 on your side and kills their best support.
   - Belladonna has already given him Nightshade, as the biggest enemy.
   - When he goes home, each Wisp hit halves him: 300 → 150 → 75.
   - *What the player says:* "their carry killed their own board, then my lights finished him."

Also on the menu:
- **Lob's last night:** thanked after 8 turns, every Ring grows +4/+4.
- **The Teind:** a Nan standing on +500/+500 is tithed, and five Fairies gain +100/+100 each. The Ring stays, and a new Nan steps into it.

---

# Harness lines

Card ids are `content/units/*.json` ids. "Keep" means don't sell it for a plain upgrade.

## Line `fairy_ring` (engine / carry)

**Buy and keep, in priority order:**
1. `nan_toadstool`: play it on the carry slot (B1). Sell it there. Rebuy and resell whenever 2 gold is spare, all game.
2. `old_moth_annis`: F1, so it Rings B1. Move it to F2 when the Fetch needs F1.
3. `hob_in_the_hearth`: stand it on B1 on rounds 3–6, and thank it when the carry is ready.
4. `lob_lie_by_the_fire`: thank it at 6+ turns, or the turn before T6.
5. `cluricaun`: complete the rainbow by round 8.
6. `silky`
7. `sally_spore`: beside a gap. Sell it at T5 for slot space.
8. `cradle_fetch`: in front of the carry.
9. `will_o_the_wisp`: only if you keep a gap.
10. `reel_mistress`
11. `fairy_monarch`
12. `belladonna`
13. `hedge_witch`: late, as the B1 stander when the scout shows a big unit across B1.
14. `changeling`
15. `queen_of_elfland`: only to pivot to spread.
16. `rainbow_chaser`: buy only to sell at 5+ ringed slots.

**Spells:** `spore_cloud` and `boundary_stone` on B1. `pinch_of_dust` or any aimed spell to thank Shy units.

**Climb:** T2 on round 2, T3 on round 4, T4 on round 6, T5 on round 9, T6 on round 10–11.

**Save:**
- From round 8, bank 2–3 gold so you reach T6 by round 11 and can still buy.
- At T5+ with no Monarch by round 11, save 6 for Hiring Fair.
- Otherwise spend everything; Nan cycles are the gold sink.

## Line `fairy_court` (tempo / wide)

**Buy and keep, in priority order:**
1. `old_moth_annis`: F2 or F3.
2. `nan_toadstool`: play it into an unringed slot, then sell.
3. `sally_spore`: keep it until the rainbow is done.
4. `rainbow_chaser`: sell it when it pays 5+.
5. `cluricaun`
6. `hedge_witch`: across their best attacker.
7. `changeling`: across their carry.
8. `will_o_the_wisp`
9. `belladonna`
10. `queen_of_elfland`: in F2, with cheap Fairies on B1 and B2.
11. `fairy_monarch`
12. `lob_lie_by_the_fire`
13. `reel_mistress`
14. `cradle_fetch`
15. `silky`
16. `hob_in_the_hearth`

**Spells:** `spore_cloud` on any unringed slot first. `harvest_supper` on a Fairy.

**Climb:** T2 on round 2, T3 on round 5, T4 on round 7, T5 on round 9, T6 on round 11.

**Save:**
- Never bank more than 2 gold, except to hold the Chaser's sale for a turn where it pays for a tier-up and a buy together.
- Spend every turn.

---

# Scale reasoning

The model (`fairies-wild-model.py` and `fairies-wild-model-final.py`, beside this file) counts Rings and Ring size per round for scripted strong lines. Unit bodies add a small linear base, 27–89 stats over rounds 6–16. It ignores fights, so read it as shape, not as win rate. The target is Battlegrounds' September 2025 mean board.

| Round | 6 | 9 | 10 | 12 | 13 | 15 |
|---|---|---|---|---|---|---|
| Target (BG Sep 2025 mean) | 53 | 194 | 305 | 759 | 1,177 | 2,600 |
| `fairy_ring`, typical (no Hob or Silky) | 49 (0.9×) | 222 (1.1×) | 416 (1.4×) | 659 (0.9×) | 1,551 (1.3×) | 2,151 (0.8×) |
| `fairy_ring`, every engine piece found | 49 | 296 (1.5×) | 574 (1.9×) | 929 (1.2×) | 2,151 (1.8×) | 2,883 (1.1×) |
| `fairy_court`, Queen R11, Monarch R13 | 57 (1.1×) | 262 (1.4×) | 372 (1.2×) | 639 (0.8×) | 1,064 (0.9×) | 2,620 (1.0×) |
| Low roll (no Lob, rainbow R10, Monarch R13) | 49 | 90 (0.5×) | 156 | 329 (0.4×) | 441 | 1,399 (0.5×) |
| High roll (golden Lob, golden Monarch) | 49 | 222 | 520 | 791 | 2,735 (2.3×) | 3,655 (1.4×) |
| Top 1% (two Monarchs, golden Lob) | 49 | 222 | 520 | 1,517 (2.0×) | 1,773 | 9,295 (3.6×) |

**Reading:**
- **The level is right:** level to round 7, then compounding.
- **The spread is wide:** the low roll is about 0.45× and the top 1% about 3.6×, inside the owner's 10×.
- **The curve is lumpy:** the thank-you turn (round 10) and Midsummer (round 13) are steps. They're the reward moments, but a step that every Fairy player takes on the same round is a tribe clock. If sims show it as a common snowball:
  1. Halve g (Cluricaun every 2nd turn).
  2. Or set Lob to per 3 turns.
  3. Or use the smooth Monarch ("+¼ each End of Turn" gives 0.9–1.3× with no step).
- **Carry share runs high, 50–80% of the board, in the model**, because the script stacks nearly every Ring on B1. The intended line stops at about half and lets the Fetch double it. The harness should search over that share.
- **Stats per gold:** a Nan cycle is about 8 stats a gold on round 9, 20 on round 12 and 50 on round 15, against Battlegrounds' 2.8 to 71 between turns 8 and 14.

---

# Engine support needed

| Need | For | Notes |
|---|---|---|
| Ring = count per slot; player-level `ring_size`; slot total = count × size | Every Ring card | Replaces `slot_effect` stat stacking for `Ring`. Remove the 8.5.4 cap. Snapshots and ghosts carry `ring_size`. The badge shows total and count. |
| Effects `ring_size_add` (`n`) and `ring_size_multiply` (`k`) | Cluricaun, Lob, Silky, Monarch | `multiply` already exists for units |
| `slot_effect` `at: behind` (several slots) | Annis | Selector exists |
| Trigger `on_sold` plus `on_play` on one entry | Nan | `when sold` exists (Chaser) |
| `per`: slots with a Ring | Chaser | New `per` source |
| Condition: every slot has a Ring | Cluricaun | New condition |
| Value source: this slot's Ring | Hedge Witch | Start of Combat −Attack, floor 0 |
| `turns_on_board` (not reset by moves) | Hob, Lob | `turns_in_slot` resets on a move |
| Trigger `on_leave` (Shy) and `after_shy_leaves` | Hob, Lob, Silky | Shy exists; Silky's listener exists |
| Must-be-attacked status | Will's Wisps | Rule 9.5.4 exists; the engine has no Taunt yet |
| Copy with current combat stats, Ring included | Fetch | Extends `cradle_fetch` |
| Dance limit `m` per Ring | Reel | Today it's "once a fight"; make it a parameter |
| Target: biggest enemy, any row | Belladonna | Track B mechanic |
| `every` counter and size multiply | Monarch | `every` exists (Teind) |
| Teind pool includes slot Rings, with parameter t | Queen | Rule 12.1.5 change |
| Spell retune: Spore Cloud "Ring a slot twice", Boundary Stone "Ring a slot three times" | Neutral spells | Proposed, for the spell owner |

**Rulings to add:**
- Rings give a stolen unit standing on them their stats (unchanged).
- An aimed Ring spell on a Shy unit's slot thanks it, and the Rings still land.
- A unit whose Ring dances away keeps its damage and can die (unchanged).
- Must-be-attacked Wisps follow 9.5.4.

## Owner direction, and where this leaves it

- **"The fairy stuff is cool. The slot effects." (02h):** slots are now the whole engine.
- **Curses (02h):** the Witch keeps the curse and drops the Hex keyword. Her curse now scales.
- **The rainbow (02h):** "a pot of gold, and you've got to do something to go get it". The something is now a Ring on all seven slots. That's visible and permanent, and it competes with the carry. The fading bands are gone, and that's a deviation. The reason: they were invisible work, and permanent Rings make the pot plannable.
- **Shy:** keeps the 9 Nov rule (only an aimed spell). The waiting-for-a-payoff shape follows 02i ("don't move for 3 turns, then X: that's cool").
- **No caps:** the Ring cap and the Hex tier cap go. The rate limits left are Reel's moves (it's a multiplier) and the Changeling's swap back (it's a steal). Both are sweep levers.
- **Text:** the median card is 12.5 words, a little over the guide's 11. The p90 is 17 and the longest (Queen) is 21. The Fairy reminder terms drop from six (Ring, Rainbow, Hex, Shy, Nightshade, Changeling) to three: Ring, Shy, Nightshade.
