# Pass 3 presets: B and C

*Paper values, 10 Nov 2026. For wave 2 and checkpoint 1: `../../plan-scale-rework.md`, step 2, and `../../DECISIONS.md`, "Generous first".*

These are the starting dials for pass 3's two presets. They come from three sources: the six tribes' paper models, a calibration that put all six on one way of counting, and a breaker's review. The harness and play will correct them.

The owner (note 09h): "giving out power overly generously and then dialing it back, rather than starting from too weak and dialing up ... it's probably going to be more enjoyable to have overly powerful effects and an unbalanced game than weak effects and a boring game."

- **B, the default.** A typical R12 board of about 900.
  - The Fetch twin is full again. The Oozes' Stone Soup and Elder are back at their synthesis values. This undoes amendment 1's resize.
  - The other four tribes are raised to match.
  - Counted the harness's way, all six tribes were below 900 at design (about 360–730). So all six are raised, Fairies and Oozes included.
- **C, overly generous.** About twice B. It gets there by raising engine rates: growth per trigger, multipliers, shares and counts. No base body gets bigger.
- **Direction.** No dial is below its design value. Every C value is at B's value or more generous. For three dials a lower number is more generous: Mrs Stork's gold step, Lob's turns and the Monarch's period.
- **On paper:**
  - The typical R12 board (smoothed) averages 999 in B and 1,985 in C.
  - At R12, the biggest tribe is at most 1.25× the smallest in B, and 1.21× in C.
  - Across R8–R16 that gap is 1.3–2.4×. Every tribe stays within an order of magnitude of the others.

This replaces the provisional C in `content/pass3/rates.json` on `ideation/wave2a`, which doubled every listed rate.

## 1. What is counted

The harness convention (`tools/sim/HARNESS.md`, "Metrics"; `fight_capture.gd`, `_active_snapshot`):
- **The board:** each seat's board at the end of the recruit phase, before Start of Combat. That is the Attack + Health of the units in the 7 slots, after auras and slot Rings.
- **In:**
  - Eggs.
  - Auras: the Lump's Nest, Harvest Supper, Redwing's Eggs.
  - Permanent gains that have landed. Takes and Soak land at the next Start of Turn (amendment 6), so they show on the next round's board.
- **Out, reported separately:** Bellies, Birds away, hand and doorstep.
- **Out, because they happen at Start of Combat:** the Fetch twin, Wisps, Granny's gather, Sable's strike, Hasty's swallow, and the fight-only part of Jack Daw's steal.

**Typical.** Each tribe has two harness lines.
1. For each line, take its median board at that round.
2. Average the two lines, because the harness seats both equally.

| Tribe | Line 1 | Line 2 |
|---|---|---|
| Birds | homecoming | tempo |
| Fairies | ring | court |
| Bog | court | Swamp |
| Hunters | Pack | Open Season |
| Oozes | engine B (Aspic from R6) | Pot Luck |
| Hedgerow | Supper | Parish |

**R12 smoothed.**
1. For each line, take the geometric mean of its R11, R12 and R13 medians.
2. Average the two lines.

This evens out the tribes' cycles: Birds' trips, Dozey's wakes, the Oozes' second stomach.

**Tribes that feed on the enemy.** Bog and Hunters grow from the enemy. So they were fed a lobby made of all six tribes, and the run was repeated until the numbers settled. That took three rounds.

**Design value.** The pass 3 synthesis value, before amendment 1. Wave 1 built every Birds and Fairies dial at its design value except the Fetch twin, which it built at 1/2.

## 2. The dials

**Engine** means the dial sets how fast a board grows: a gain per trigger, a multiplier, a share, or how often or how many times growth fires. Answers, defence, economy, fixed token bodies, fight-only effects and rule switches are not engines.

**Bold** marks values changed after the tribe agents set them. The calibrator changed Chiffchaff and Redbreast. The breaker's findings led to the changes to the Cuckoo in C, Chiffchaff in C and the Monarch.

### Birds

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| birds_homecoming_multiplier | Fly South (all fliers) | Stats multiplier when a Bird comes home | 2 | 2.25 | 2.5 | yes |
| birds_golden_homecoming_multiplier | Fly South, golden | The same, for a golden Bird | 2 | 3 | 3 | yes |
| birds_cuckoo_share | The Cuckoo | After a Bird comes home, your other Birds gain this share of its stats. Copies stack | 1/10 | 1/8 | **0.15** | yes |
| birds_golden_egg_multiplier | Mother Goose (Golden Egg) | Egg multiplier, once per Bird | 2 | 2 | 3 | yes |
| birds_stork_gold_step | Mrs Stork | Gold spent per early recall (lower is more generous) | 6 | 6 | 5 | yes |
| birds_chiffchaff_gain | Chiffchaff | When played: +X/+X. It fires again on every homecoming. New key | 1 | **3** | **4** | yes |
| birds_redbreast_share | Mr Redbreast | Share of each homecoming Bird he gains | 1/8 | **1/6** | **1/6** | yes |
| birds_jack_daw_share | Jack Daw | Share of the enemy across that your biggest Bird steals at Start of Combat | 1/4 | 1/4 | 1/4 | yes |
| birds_jack_daw_permanent | Jack Daw | The steal is permanent (true) or fight-only | true | true | true | no |
| birds_stork_recalls | Mrs Stork | Birds recalled per step | 1 | 1 | 1 | yes |
| birds_trip_turns | Fly South | Trip length in turns | 2 | 2 | 2 | yes |
| birds_swallow_trip_turns | One Swallow | Trip length (amendment 10) | 1 | 1 | 1 | yes |
| birds_golden_tern_trip_turns | Old Tern, golden | Trip length | 1 | 1 | 1 | yes |
| birds_golden_egg_enabled | Mother Goose | Golden Eggs on | true | true | true | no |
| birds_goose_eggs | Mother Goose | Golden Eggs per play (golden ×2). New key | 1 | 1 | 1 | yes |
| birds_lump_multiplier | The Great Lump | Multiple of its Nest Bird's stats the Lump adds | 1 | 1 | 1 | yes |
| birds_ratchet_multiplier | The Gabble Ratchet | Stats multiplier of a dropped-in Bird | 1 | 1 | 1 | no |
| birds_redwing_share | Redwing | Egg size, as a share of its away Bird | 1/2 | 1/2 | 1/2 | yes |
| birds_redwing_targets | Redwing | Away Birds that leave big Eggs | 2 | 2 | 2 | yes |
| birds_tom_tit_reduction | Tom Tit | Damage Reduction % on the biggest other Bird | 50 | 50 | 50 | no |
| birds_tom_tit_targets | Tom Tit | Birds protected | 1 | 1 | 1 | no |
| birds_dunnock_turns | Mrs Dunnock | Turns cut from a trip | 1 | 1 | 1 | yes |
| birds_dunnock_targets | Mrs Dunnock | Trips cut per End of Turn | 1 | 1 | 1 | yes |
| birds_whistlers_loss_share | The Seven Whistlers | Share the enemy loses | 1/2 | 1/2 | 1/2 | no |
| birds_whistlers_flock_count | The Seven Whistlers | Different Birds needed for the omen | 7 | 7 | 7 | no |
| birds_swallow_gold | One Swallow | Gold when played. New key | 1 | 1 | 1 | no |
| birds_jay_acorns | Mrs Jay | Acorns when sold. New key | 1 | 1 | 1 | no |

### Fairies

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| fairies_ring_growth | Cluricaun | After you Tier up, if every slot has a Ring: Ring size grows by this (golden ×2) | 1 | 2 | 4 | yes |
| fairies_lob_turns | Lob-Lie-by-the-Fire | Turns stayed per growth step when thanked (lower is more generous) | 3 | 2 | 2 | yes |
| fairies_nan_rings | Nan Toadstool | Rings on this slot when played and again when sold (golden ×2) | 1 | 2 | 2 | yes |
| fairies_lob_growth | Lob-Lie-by-the-Fire | Ring size gained per step when thanked (golden ×2) | 1 | 1 | 3 | yes |
| fairies_silky_growth | Silky | Ring size gained after each Shy unit is thanked (golden ×2) | 1 | 1 | 2 | yes |
| fairies_fetch_share | Cradle Fetch | Share of the Fairy behind it copied at Start of Combat, Ring included. Fight-only | 1 (built 1/2) | 1 | 1 | yes |
| fairies_monarch_period | Fairy Monarch | Midsummer every Nth End of Turn; one shared clock (lower is more generous) | 3 | **2** | **2** | yes |
| fairies_monarch_multiplier | Fairy Monarch | Midsummer multiplies Ring size by this | 2 | 2 | **3** | yes |
| fairies_golden_monarch_multiplier | Fairy Monarch, golden | The golden multiplier | 3 | 3 | **4** | yes |
| fairies_annis_rings | Old Moth Annis | Rings on the slots behind, per End of Turn and per sale (golden ×2) | 1 | 1 | 1 | yes |
| fairies_annis_sale | Old Moth Annis | She also fires after any sale | true | true | true | yes |
| fairies_queen_rings | Queen of Elfland | Rings on every slot per unit destroyed behind her (golden ×2) | 1 | 1 | 1 | yes |
| fairies_queen_period | Queen of Elfland | She tithes every Nth End of Turn | 1 | 1 | 1 | yes |
| fairies_sally_rings | Sally Spore | Rings on the nearest empty slot per End of Turn | 1 | 1 | 1 | yes |
| fairies_initial_ring_size | (every Ring) | Ring size at game start | 1 | 1 | 1 | no |
| fairies_chaser_gold | Rainbow Chaser | Gold per slot with a Ring, when sold | 1 | 1 | 1 | no |
| fairies_reel_moves | Reel-Mistress | Moves per Ring per fight | 2 | 2 | 2 | no |
| fairies_wisp_attack | Will-o'-the-Wisp | Wisp token Attack (golden Will ×2) | 1 | 1 | 1 | no |
| fairies_wisp_health | Will-o'-the-Wisp | Wisp token Health | 1 | 1 | 1 | no |
| fairies_witch_ring_share | Hedge Witch | The enemy across loses Attack equal to this × her slot's Ring (golden ×2). New key | 1 | 1 | 1 | no |
| fairies_hob_shield_targets | Hob-in-the-Hearth | Biggest Fairies given Shield (golden 2). New key | 1 | 1 | 1 | no |
| fairies_belladonna_targets | Lady Belladonna | Nightshade on the enemy across (golden adds the units beside it). New key | 1 | 1 | 1 | no |
| fairies_changeling_steals | Changeling | Steals of the enemy across, until it attacks (golden 2). New key | 1 | 1 | 1 | no |
| fairies_shy_thank_gold | Shy (rule 12.1.7) | Gold paid when a Shy unit is thanked (golden 4). New key | 2 | 2 | 2 | no |

### Bog folk

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| bog_soak_keep | Soak (keyword) | +k/+k per Attack that this unit's Bitter took from its Mired enemies. It lands at the next Start of Turn. Soak only | 1 | 2 | 3 | yes |
| bog_golden_soak_keep | Soak, golden | The golden keep | 2 | 4 | 6 | yes |
| bog_nan_share | Warty Nan | Start of Turn: your smallest Bog folk gains this share of the Toll | 1/4 | 1/2 | 1/2 | yes |
| bog_golden_nan_share | Warty Nan, golden | The golden share | 1/2 | 1 | 1 | yes |
| bog_ranocchio_share | Signor Ranocchio | After attacking a Mired enemy: +1/+1 per (1/share) of its Attack | 1/4 | 1/2 | 1/2 | yes |
| bog_golden_ranocchio_share | Signor Ranocchio, golden | The golden share | 1/2 | 1 | 1 | yes |
| bog_tiddy_share | Tiddy Mun | Start of Turn: the Bog folk beside her split this share of the Toll | 1/2 | 1/2 | 1/2 | yes |
| bog_golden_tiddy_share | Tiddy Mun, golden | The golden share | 1 | 1 | 1 | yes |
| bog_bitter_share | Bitter (keyword) | The biter loses this share of its Attack before the hit, for the fight. It feeds Soak and the Toll | 1/4 | 1/4 | 1/4 | yes |
| bog_bitter_round_up | Bitter | Rounds up, never below 1 Attack | true | true | true | no |
| bog_soak_mired_only | Soak | Counts only enemies on this unit's own patches | true | true | true | no |
| bog_kiss_period | His Highness and the Prince | Every Nth kiss (a fight with a Sink): double the Bog folk beside him | 3 | 3 | 3 | yes |
| bog_frog_multiplier | His Highness and the Prince | The frog's multiplier | 2 | 2 | 2 | yes |
| bog_golden_frog_multiplier | His Highness and the Prince, golden | The golden multiplier | 3 | 3 | 3 | yes |
| bog_kisses_per_fight | His Highness and the Prince | At most one kiss a fight, shared by all your frogs (guard) | 1 | 1 | 1 | no |
| bog_frog_doubles_per_turn | His Highness and the Prince | A unit is doubled at most once a turn; the biggest multiplier wins (guard) | 1 | 1 | 1 | no |
| bog_hopkin_share | Vaulting Hopkin | Back row: attacks first using this share of the highest Attack in front (golden 1/2) | 1/4 | 1/4 | 1/4 | no |
| bog_bufo_halvings | Madame Bufo | Times her killer's Attack is halved (golden 2) | 1 | 1 | 1 | no |
| bog_gideon_hitbacks | Gideon | Hit-backs on his Mired biter per bite (golden 2) | 1 | 1 | 1 | no |
| bog_sal_toll_multiplier | Spitfire Sal | Start of Combat: deal this × the Toll, split among Mired enemies (golden 2) | 1 | 1 | 1 | no |
| bog_cutter_gold | Peat Cutter | Gold next turn on a Sink, once a fight (golden 2) | 1 | 1 | 1 | no |
| bog_pretender_gold | Young Pretender | Gold next turn after killing a Mired enemy (golden 2) | 1 | 1 | 1 | no |
| bog_king_peatlings | Peat King | Times a fight sunk enemies rise as Peatlings (golden 4) | 2 | 2 | 2 | no |
| bog_peatling_stat_share | Peat King | A Peatling's share of the sunk enemy's starting stats | 1 | 1 | 1 | no |
| bog_prima_donna_patches | Prima Donna | Slots she Mires: across and beside | 3 | 3 | 3 | no |
| bog_chorus_lends | Natterjack Chorus | Bog folk beside it that borrow its Mire and Soak | 2 | 2 | 2 | yes |
| bog_lantern_lures | Lantern Man | Biggest enemies in any row that he Mires (golden 2). Resolves last (amendment 4) | 1 | 1 | 1 | no |
| bog_jenny_pulls | Jenny Greenteeth | Pulls the biggest enemy in the row across to face her | 1 | 1 | 1 | no |
| bog_capstone_gain_toll | Prima Donna, Jenny, Peat King, Lantern Man | Lever: "When played: gain the Toll" | false | false | false | no |

### Hunters

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| hunters_nip_share | Little Nip | Take: gain this share of the quarry's stats, permanently | 1/2 | 2/3 | 3/4 | yes |
| hunters_sable_share | Sable | Take share | 1/2 | 2/3 | 3/4 | yes |
| hunters_lutra_share | Old Lutra | Take share | 1/2 | 2/3 | 3/4 | yes |
| hunters_glutton_share | The Mountain Glutton | After each Take: gain this share of the quarry's stats | 1/2 | 2/3 | 1 | yes |
| hunters_lodger_share | The Lodger | After a Take beside this: gain this share of the quarry's stats | 1/2 | 2/3 | 1 | yes |
| hunters_wick_share | Wick | After this joins a kill: gain this share of the target's stats | 1/4 | 1/3 | 1/2 | yes |
| hunters_grizel_share | Grizel | After your pack kills: its attackers gain this share of the target's stats | 1/4 | 1/3 | 1/2 | yes |
| hunters_pelt_share | Pelt token | Give a Hunter this share of the biggest quarry's stats | 1/4 | 1/3 | 1/2 | yes |
| hunters_russet_buff_share | Mistress Russet | The poached copy carries this share of the quarry's permanent buffs | 1/2 | 2/3 | 3/4 | yes |
| hunters_golden_russet_buff_share | Mistress Russet, golden | The golden share | 1 | 1 | 1 | yes |
| hunters_ermeline_pelts | Madame Ermeline | Pelts a fight | 1 | 1 | 1 | yes |
| hunters_golden_ermeline_pelts | Madame Ermeline, golden | Pelts a fight | 2 | 2 | 2 | yes |
| hunters_laird_multiplier | The Laird | "Take:" text triggers this many times | 2 | 2 | 2 | yes |
| hunters_golden_laird_multiplier | The Laird, golden | Triggers | 3 | 3 | 3 | yes |
| hunters_golden_take_multiplier | Every golden Hunter | Golden shares are this × the normal share (rule 7) | 2 | 2 | 2 | yes |
| hunters_sable_strike | Sable | Start of Combat: gain this × her quarry's Attack, this fight | 1 | 1 | 1 | no |
| hunters_golden_sable_strike | Sable, golden | The golden strike | 2 | 2 | 2 | no |
| hunters_agnes_hit_back | Grey Agnes | Pack leaders take this share of the hit back (lower is stronger) | 1/2 | 1/2 | 1/2 | no |
| hunters_golden_agnes_hit_back | Grey Agnes, golden | The golden share | 1/4 | 1/4 | 1/4 | no |
| hunters_isegrim_health_cut | Old Isegrim | Lever: cut the biggest enemy's Health by this (off) | 0 | 0 | 0 | no |
| hunters_russet_copies | Mistress Russet | Copies per Russet Take (× the Laird) | 1 | 1 | 1 | no |
| hunters_lane_bard_gold | Lane-Bard | Gold next turn per quarry attack | 1 | 1 | 1 | no |
| hunters_golden_lane_bard_gold | Lane-Bard, golden | The golden gold | 2 | 2 | 2 | no |
| hunters_lane_bard_triggers | Lane-Bard | Triggers a fight | 2 | 2 | 2 | no |
| hunters_take_floor | Every Take | Shares round down, but give at least +X/+X | 1 | 1 | 1 | yes |
| hunters_young_brock_share | Young Brock | He inherits this share of a sold Hunter beside him | 1 | 1 | 1 | yes |
| hunters_trophies_after_fight | Rule (amendment 6) | Takes land at the next Start of Turn, with a pending badge | true | true | true | no |

Hunter bodies stay as printed in both presets, from Nip and Wick at 2/2 (T1) up to Isegrim at 7/10 (T6). This is not a key.

### Oozes

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| oozes_soup_share | Stone Soup | Shop units gain this share of your biggest Ooze's stats. Kept on purchase; only the best Soup counts; rounds down | 1/10 (amendment 1: 1/12) | 1/8 | 1/6 | yes |
| oozes_elder_share | Elder Ooze | After your biggest Ooze eats a non-Ooze, your other board Oozes gain this share of the meal | 1/2 (amendment 1: 1/4) | 1/2 | 3/4 | yes |
| oozes_golden_elder_multiplier | Elder Ooze, golden | Multiplies the share | 2 | 2 | 2 | yes |
| oozes_aspic_bonus | Aunt Aspic | Oozes in front of her gain this much more from eating non-Oozes | +50% | +50% | +50% | yes |
| oozes_golden_aspic_multiplier | Aunt Aspic, golden | Multiplies the bonus | 2 | 2 | 2 | yes |
| oozes_nell_meals | Dishwater Nell | Shop units eaten at Start of Turn by the biggest Ooze beside her | 1 | 1 | 1 | yes |
| oozes_bubble_belly | Bubble and Squeak | Meals the usual carry digests each Start of Turn (golden 2) | 1 | 1 | 1 | yes |
| oozes_dollop_belly | Little Dollop | Belly meals (golden 2) | 1 | 1 | 1 | yes |
| oozes_dollop_discount | Little Dollop | Gold off a buy straight into her (golden 2) | 1 | 1 | 1 | no |
| oozes_slice_share | Cut-and-Come-Again | Start of Turn: a Slice with this share of your biggest Ooze's stats | 1/5 | 1/5 | 1/5 | yes |
| oozes_slice_count | Cut-and-Come-Again | Slices a turn (golden 2) | 1 | 1 | 1 | yes |
| oozes_hasty_share | Hasty Pudding | Your biggest Ooze permanently gains this share of the enemy it swallows | 1/5 | 1/5 | 1/5 | yes |
| oozes_hasty_swallows | Hasty Pudding | Enemies swallowed at Start of Combat (golden 2) | 1 | 1 | 1 | yes |
| oozes_hasty_release_deaths | Hasty Pudding | Friendly deaths before it releases its prisoner | 3 | 3 | 3 | no |
| oozes_golden_soup_reads | Stone Soup, golden | Biggest Oozes it reads | 2 | 2 | 2 | yes |
| oozes_granny_attack_multiplier | Granny Stir-Up | Gains this × the Attack of the gathered Oozes. Fight-only | 1 | 1 | 1 | no |
| oozes_posset_loss_share | Mrs Posset | Her killer loses this share of its stats for the fight | 1/2 | 1/2 | 1/2 | no |
| oozes_moss_golden_reduction | Moss Ooze, golden | Damage Reduction % on units coming out of your Oozes | 25 | 25 | 25 | no |
| oozes_bubble_splits | Bubble and Squeak | Splits a fight (golden 2) | 1 | 1 | 1 | no |
| oozes_pie_gold | Sixpenny Pie | Gold per unit inside when it dies | 1 | 1 | 1 | no |
| oozes_wobbly_drip | Wee Wobbly | The Drip's Attack and Health when nothing is inside | 1 | 1 | 1 | no |
| oozes_frumenty_meals | Frumenty | Last meals whose text it keeps (golden 2) | 1 | 1 | 1 | no |
| oozes_syllabub_fires | Mr Syllabub | Times a released unit's Start of Combat fires (golden 2) | 1 | 1 | 1 | no |

### Hedgerow

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| hedgerow_dozey_wake_multiplier | Alderman Dozey | Every 3 turns in this slot: multiply his stats by this | 2 | 2 | 3 | yes |
| hedgerow_golden_dozey_wake_multiplier | Alderman Dozey, golden | The golden wake. The golden doubles his food, not this (rulebook 7.3.5) | 2 | 2 | 3 | yes |
| hedgerow_dozey_period | Alderman Dozey | Turns in his slot per wake | 3 | 3 | 3 | yes |
| hedgerow_dozey_food_per_gold | Alderman Dozey | Stats per gold of Larder items played on him (design is +1/+1 per 2 gold) | 1/2 | 2 | 2 | yes |
| hedgerow_partner_period | Sleeping Partner | Turns in slot per payout | 3 | 3 | 3 | yes |
| hedgerow_partner_acorns | Sleeping Partner | Acorns per touching Hedgerow unit, per payout (golden ×2) | 1 | 2 | 2 | yes |
| hedgerow_crumb_pass | Mr Crumb | When played: Pass +X/+X | 1 | 1 | 1 | yes |
| hedgerow_crumb_sell_share | Mr Crumb | When sold: Pass this share of its stats | 1 | 1 | 1 | yes |
| hedgerow_clover_share | Mrs Clover | Share of her stats given to each Hedgerow summon | 1/2 | 1 | 1 | yes |
| hedgerow_pym_pass | Mr Pym | After you get a Stash: Pass +X/+X | 3 | 3 | 3 | yes |
| hedgerow_sorrel_summons | Mrs Sorrel | Shrewlets per attack; each Spills an Acorn in the back row | 1 | 1 | 1 | no |
| hedgerow_burdock_kits | Mrs Burdock | 1/1 Kits when played | 1 | 1 | 1 | no |
| hedgerow_mallow_multiplier | Mrs Mallow | End of Turn: multiply your smallest Hedgerow unit's stats by this | 2 | 2 | 3 | yes |
| hedgerow_mallow_targets | Mrs Mallow | Smallest units she affects (golden ×2) | 1 | 2 | 2 | yes |
| hedgerow_urchin_bristle | Dr Urchin | Bristle value | 2 | 2 | 2 | no |
| hedgerow_urchin_hunker_targets | Dr Urchin | Your last Hedgerow units with Hunker | 1 | 1 | 1 | no |
| hedgerow_sergeant_share_per_gold | Sergeant-at-Conkers | The enemy across loses this share of its stats per gold thrown | 1/10 | 1/10 | 1/10 | no |
| hedgerow_sergeant_throws | Sergeant-at-Conkers | Larder items thrown at Start of Combat (golden 2) | 1 | 1 | 1 | no |
| hedgerow_beadle_pass | Beadle Warrenby | After you get an Acorn: Pass +X/+X | 1 | 2 | 2 | yes |
| hedgerow_treasurer_per_gold | Honorary Treasurer | End of Turn: +X/+X per gold in your Larder | 1 | 1 | 2 | yes |
| hedgerow_hayward_per_gold | Goodman Hayward | Hedgerow folk get +X/+X per gold played, this game | 1 | 1 | 1 | yes |
| hedgerow_committee_share | Standing Committee | Each End of Turn, touching Hedgerow folk gain this share of the smallest one (golden ×2) | 1/5 | 1/4 | 1/4 | yes |
| hedgerow_lollop_share | Squire Lollop | Start of Turn: touching Hedgerow folk except your biggest gain this share of it (golden ×2) | 1/10 | 1/10 | 1/10 | yes |
| hedgerow_mast_gold_step | Old Mother Mast | Start of Turn: one Acorn per this much Larder gold | 5 | 5 | 5 | no |
| hedgerow_mast_cap | Old Mother Mast | Up to this many Acorns a turn (golden 10). The tribe's one loop guard | 5 | 5 | 5 | no |
| hedgerow_larder_gold | Larder items | Acorn, Stash and Great Hoard values in gold. Three combine into the next | 1/5/16 | 1/5/16 | 1/5/16 | no |

### Shared

| Key | Card | What it does | Design | B | C | Engine |
|---|---|---|---|---|---|---|
| scale_hero_spell_percent | Hero powers and spells | Board-scaled hero powers and spells, as a percent. Kept from the pool-rules commit on `ideation/wave2a`. No model includes it | 10 | 10 | 20 | yes |
| pass3_loop_guards | Pool rule (amendment 11) | Copy guards: extra Cluricauns, Silkies and Monarchs share one count | true | true | true | no |

## 3. Typical boards on one scale

These are the final dials, counted as in section 1. Each figure is the average of the tribe's two lines. "Lobby median" is the median of the six tribes. Bog and Hunters were fed this lobby.

**B**

| Tribe | R8 | R10 | R12 | R12 smoothed | R14 | R16 | Growth a round, R8–R14 |
|---|---|---|---|---|---|---|---|
| Birds | 161 | 318 | 904 | 901 | 1,970 | 5,296 | ×1.52 |
| Fairies | 172 | 553 | 1,020 | 977 | 2,148 | 5,326 | ×1.52 |
| Bog | 148 | 314 | 1,127 | 1,130 | 3,049 | 9,549 | ×1.66 |
| Hunters | 138 | 331 | 998 | 977 | 3,066 | 8,710 | ×1.68 |
| Oozes | 141 | 347 | 978 | 968 | 2,637 | 5,965 | ×1.63 |
| Hedgerow | 130 | 498 | 924 | 1,040 | 2,839 | 8,378 | ×1.67 |
| **Lobby median** | 144 | 339 | 988 | 999 (mean) | 2,738 | 7,171 | ×1.63 |
| **Largest ÷ smallest** | 1.31 | 1.76 | 1.25 | 1.25 | 1.56 | 1.80 | |

**C**

| Tribe | R8 | R10 | R12 | R12 smoothed | R14 | R16 | Growth a round, R8–R14 |
|---|---|---|---|---|---|---|---|
| Birds | 201 | 638 | 2,516 | 1,797 | 8,238 | 20,940 | ×1.86 |
| Fairies | 236 | 1,085 | 2,024 | 1,940 | 6,059 | 22,747 | ×1.72 |
| Bog | 177 | 458 | 2,124 | 2,161 | 7,485 | 30,605 | ×1.87 |
| Hunters | 162 | 474 | 1,980 | 1,949 | 7,848 | 29,088 | ×1.91 |
| Oozes | 165 | 495 | 1,887 | 1,897 | 6,410 | 16,955 | ×1.84 |
| Hedgerow | 201 | 883 | 1,898 | 2,168 | 6,898 | 32,937 | ×1.80 |
| **Lobby median** | 189 | 567 | 2,002 | 1,985 (mean) | 7,191 | 25,918 | ×1.83 |
| **Largest ÷ smallest** | 1.46 | 2.37 | 1.33 | 1.21 | 1.36 | 1.94 | |

How to read it:
- **C against B.** C's R12 lobby median is 2.0× B's.
- **The reference curves** (`../../evidence/reference-curves.md`):
  - Battlegrounds, September 2025: mean 759 at turn 12, growth ×1.56 a turn.
  - Battlegrounds, November 2026: median 2,598, growth ×1.94. It is measured after Start of Combat, so it reads high against our pre-start boards.
  - Today's Bramble bots: 133. They are counted without Rings, Eggs or auras.
- **The curves cross:**
  - Fairies and Hedgerow lead at R10.
  - Bog and Hunters lead late.
  - In B, Birds and Fairies trail late (0.70–0.81 of the lobby at R13–R16).
  - In C, the Oozes trail at R16 (0.65).
- **Birds' raw R12 in C (2,516) falls on the tempo line's peak round.** Smoothed, it is 1,797.
- **Bog and Hunters read above the calibrator's figures** (1,032 and 923 smoothed in B). The calibrated lobby they feed on is bigger than the field they were tuned on. The calibrator predicted this.

## 4. First cuts if C proves too strong

Cut a dial only for one of the fun problems in `DECISIONS.md`: one line winning whatever the player chooses, or runaway snowballs in most lobbies. Cut one dial at a time, on the tribe that stands out. The figures below are C's smoothed R12 and its ratio to C's lobby median.

**Birds**
1. **birds_homecoming_multiplier, 2.5 → 2.25,** if Birds outgrow the lobby on every line. It carries most of C's excess. Smoothed R12 goes 1,797 → 1,415, and R14 goes from 1.15× to 0.78× the lobby.
2. **birds_golden_egg_multiplier, ×3 → ×2,** if one Bird decides fights. At R12 the biggest unit is 39% of the homecoming board and 85% of the tempo board. Smoothed R12 goes to 1,491.
3. **birds_cuckoo_share, 0.15 → 1/8,** if a Flock with stacked Cuckoos still runs away. Smoothed R12 goes to 1,761. After that, the next step is the rule "only your best Cuckoo counts" (section 5, finding 2).

If Birds win the early rounds, Chiffchaff +4 → +3 takes R8 from 1.06× to 0.94× the lobby (smoothed R12 1,599).

**Fairies**
1. **fairies_ring_growth, 4 → 3,** if the R10 peak shows in the harness. Today R10 is 1.91× the lobby, and the court line alone is 2.3×. After the cut, R10 is 1.68×, R12 0.89× and smoothed R12 1,719.
2. **fairies_monarch_multiplier, ×3 → ×2 (golden ×4 → ×3),** if Fairies run away late. R14 goes from 0.84× to 0.60× and R16 from 0.88× to 0.42×. R12 is unchanged.
3. **fairies_fetch_share, 1 → 1/2,** if fights are decided at Start of Combat. The pre-start board doesn't change; only fight power falls.

**Bog**
1. **bog_soak_keep, 3 → 2 (golden 6 → 4).** It is the only dial C raises over B. Smoothed R12 goes 2,161 → 1,757.
2. **bog_nan_share, 1/2 → 1/4 (golden 1 → 1/2),** if Bog wins the early fights. R6 goes 78 → 69, and smoothed R12 goes to 2,022.
3. **bog_kiss_period, 3 → 4,** if frog highrolls run away late. Smoothed R12 goes to 2,103. This is below design, so make it only on evidence.

**Hunters**
1. **hunters_glutton_share, 1 → 3/4.** It is the largest C raise, and the Glutton holds the biggest share of the board. Smoothed R12 goes 1,949 → 1,759, or 1,702 at 2/3.
2. **The Takers (Nip, Sable, Lutra), 3/4 → 2/3,** if two Hunter boards feeding each other run away. Smoothed R12 goes to 1,754.
3. **hunters_grizel_share, 1/2 → 1/3,** if the Pack line alone is the outlier.

**Oozes**
1. **oozes_soup_share, 1/6 → 1/7.** Smoothed R12 goes 1,897 → 1,516. The Oozes are already 0.65× the lobby at R16 in C, so cut this only on a clear sign.
2. **oozes_elder_share, 3/4 → 2/3,** instead of Soup, if Pot Luck wins whatever it faces. Smoothed R12 goes to 1,771.

**Hedgerow**
1. **hedgerow_mallow_multiplier, ×3 → ×2.5,** if the Parish wins late. Smoothed R12 goes 2,168 → 1,722. The on-time Parish at R14–R16 goes from 2.4×/3.7×/4.2× the lobby to 1.2×/1.7×/1.8×. A ×2.5 needs new card wording.
2. **Then ×2.** Smoothed R12 goes to 1,320. This removes all of the Parish's C raise.
3. **hedgerow_dozey_wake_multiplier, ×3 → ×2 (golden too),** if the on-time Supper wins whatever it faces. Smoothed R12 goes to 1,861.

## 5. The breaker's findings and what was done

**1. Fairies peak early, then fade. Taken.**
- **The change:**
  - fairies_monarch_period 3 → 2 in both presets.
  - In C, also fairies_monarch_multiplier 2 → 3, and the golden 3 → 4.
- **The effect,** as the ratio to the lobby median at R14 and R16:

  | | Before | After |
  |---|---|---|
  | B | 0.50 / 0.45 | 0.78 / 0.74 |
  | C | 0.38 / 0.25 | 0.84 / 0.88 |

- R12 is unchanged in both presets.
- R13 stays low: 0.70 in B and 0.61 in C.
- The R10 peak stays: 1.63× in B and 1.91× in C. The breaker's cut for it waits on the harness, so it is now C's first Fairies cut (section 4).
- **New tail, reported:** the ring line's top 1% reaches 56,248 (B) and 276,568 (C) at R16.

**2. In C, a Flock with two Cuckoos wins from R12 on. Taken, with a compensation.**
- **The change:** birds_cuckoo_share in C 0.2 → 0.15, as the breaker set it.
- **The compensation:** birds_chiffchaff_gain in C 3 → 4. Without it, Birds' C typical falls from 1,675 to 1,599 smoothed, further below the 1,800 target. With it, the typical is 1,797.
- **Two Cuckoos now,** as the ratio to the lobby at R12 / R14 / R16:

  | | Two Cuckoos |
  |---|---|
  | C before | 1.8 / 2.8 / 2.9 |
  | C now | 1.6 / 1.9 / 1.7 |
  | B, for comparison | 1.8 / 1.6 / 2.3 |

  The breaker called B's figure a normal tail, and C's now matches it.
- **Cost:**
  - Chiffchaff plays as a 5/6 in C.
  - Birds C sits at 1.06× the lobby at R8.
- **Card text:** 0.15 prints as "15%". The clean-text alternative is 1/7 ("a seventh"), with about the same numbers: 1,788 smoothed, and two Cuckoos at 1.5–1.7×.
- **Rejected for now: the breaker's alternative rule, "only one Cuckoo counts".** It changes the card in both presets, and B's Cuckoo tail is already normal. It stays the next step if stacking still wins.
- **Reported tail: a golden Cuckoo plus one more.** It is still big:
  - C: 2.4–2.5× / 3.8–4.1× / 4.7–6.6× at R12 / R14 / R16.
  - B: 2.7–2.9× / 3.2–3.8× / 3.7–6.0×.
  - The ranges come from two ways of modelling the golden Cuckoo. The breaker's 3.1× / 7.4× / 11.6× was on the calibrated C values.

**3. Hedgerow C: Mallow at ×3 drives both an early lead and a late runaway. Not taken now; it becomes Hedgerow's first cut.**
- **Why not now:** the breaker made the fix conditional on the harness showing the Parish winning late.
- The runaway is the on-time Parish, one of six shop-luck variants. That is a highroll, not what happens in most lobbies. Generous first means cutting on evidence.
- **The first cut is ×2.5, not the calibrator's ×2,** because ×2 removes all of the Parish's C raise.
- **The early lead, counted as in this document:** 1.06× at R8 and 1.56× at R10. The breaker's 1.47–1.83× used the pooled median of the six variants.

**4. The tight spread holds at R12 only. Taken.**
- Section 3 now gives the spread at every round. With the Monarch fix it is 1.3–1.9× in B and 1.3–2.4× in C over R8–R16.
- The breaker's 3.1× (B) and 4.6× (C) at R16 came mostly from the Fairies' fade. Without the fix, Fairies give 2.9× in B and about 5× in C at R16, counted as here.

**5. Bog and Hunters, fed a lobby of all six tribes. Confirmed; no change.**
- At R12 (B / C): Bog 1,127 / 2,124 and Hunters 998 / 1,980.
- Late leads at R15–R16:
  - Bog: 1.33–1.37× in B, 1.18–1.40× in C.
  - Hunters: 1.21–1.26× in B, 1.12–1.32× in C.

**6. Two Hunter boards that meet every round feed each other.** They grow ×2.09 a round in B and ×2.27 in C. Reported only. If it shows in play, the Takers' share is Hunters' second cut.

**7. The 1-billion clamp. Fine.**
- The largest paper board is the Oozes' top-1% line in C: 466,650 at R16.
- The Fairies' new ring tail in C is 276,568.
- Both are far below 1 billion.

**8. Loop guards. Fine.**
- Click Beetle's second Golden Egg goes to a different Bird, which cross-tribe §8 allows.
- Worst case in C: 6 Eggs in one landing, still once per Bird.

**9. "Every C value is at or above B" holds in the generous direction.** Mrs Stork's step, Lob's turns and the Monarch's period are lower numbers that give more power. The opening now says so.

**10. To log in `DECISIONS.md`:**
- **Fairies and Oozes are above design in B.** This departs from the plan's "stay at design size". The reason: counted the harness's way, their design boards are 600–730, not 900.
- **The Monarch changes** (finding 1) and **the Cuckoo and Chiffchaff changes in C** (finding 2).
- **Jack Daw stays permanent** until amendment 5's harness check. The compensation is agreed in advance, in case he becomes fight-only:
  - B: Chiffchaff +4. Smoothed R12 goes 809 → 926.
  - C: Chiffchaff +5. Smoothed R12 goes 1,595 → 1,786.

**11. Reported tails; no change.** These are the breaker's figures:
- The Oozes' top-1% line in C is 21× the lobby at R16. The two-goldens line is 4.1×.
- Hunters' top 1% in C is 2.7–2.8× at R14.
- Hedgerow's on-time Supper is 3.1× (B) and 4.2× (C) at R9. Lowering the food dial to 1 only takes R9 to 2.5×.

## 6. Notes for the build

**New keys:**
- Birds: birds_chiffchaff_gain, birds_goose_eggs, birds_swallow_gold and birds_jay_acorns are card numbers today. Chiffchaff's gain is set in `content/units/chiffchaff.json`, and its card text reads that number.
- Fairies: fairies_witch_ring_share, fairies_hob_shield_targets, fairies_belladonna_targets, fairies_changeling_steals and fairies_shy_thank_gold don't have keys yet.
- The Bog, Hunters, Oozes and Hedgerow keys arrive with wave 2.

**Card text follows the dials,** as the Golden Egg's does (`pass3_text.gd:230`).
- The text code (`_fraction`) only prints a share as a fraction when it matches one almost exactly. So the JSON gives thirds and sixths at full precision: 0.1667 would print as "16.67%".
- 0.15 prints as "15%".
- The Monarch reads "every 2nd End of Turn" in both presets, and "triple" (golden "quadruple") in C.

**Data shapes:**
- hedgerow_larder_gold is a list: [Acorn, Stash, Great Hoard].
- Hunter bodies are not a key.

**Rule questions the presets raise.** The calibrator found these, and they are the orchestrator's calls.
- **Click Beetle doubles "When played".** Every homecoming replays it, so Chiffchaff's gain doubles on each landing and the Goose gives two Golden Eggs.
  - Does amendment 11 stop the second Egg? Cross-tribe §8 says no.
  - An upper-bound probe doubles Chiffchaff's gain all game. It takes Birds' smoothed R12 from 901 to 1,222 (B) and from 1,797 to 2,565 (C). The real effect is smaller, because the Beetle is tier 5.
- **Charcoal Burner** should read body stats only, not slot Rings, as Shy does. Otherwise it turns Fairies' Rings into permanent stats every turn. At R12 a Ring is about 8 in B and 16 in C.
- **The full Fetch twin is a decoy.** It is the copied Fairy plus the Fetch slot's own Ring, so it is at least as big as the real carry. Every biggest-enemy effect picks it: Hasty, the Lantern Man, Isegrim, Jenny. Either add a tie-break that skips copies made this fight, or accept the decoy.
- **Jack Daw's permanent steal is a coin flip.** It resolves in the ordinary Start of Combat step, in random side order with the twin, Granny's gather, the Whistlers and the Changeling.
- **Sable's strike reads her quarry before Isegrim re-aims her.** The strike should resolve after Isegrim's hunt. Hasty can also swallow a Sable already buffed by her strike and keep a fifth of that fight-only gain.
- **Spitfire Sal never hits the Lantern Man's lured enemy.** She resolves before the lure. That is fine if intended; otherwise move her after the Lantern.

**Not modelled:**
- Harvest Supper's ceiling: only the Birds model counts the Supper. The pool rules lift the ceiling, so the other five read about 5% low.
- Board-scaled hero powers and spells (scale_hero_spell_percent): no model includes them.

## 7. Where the paper is shaky

1. **Real play may land well below paper.** These are scripted lines. Wave 1's one Birds game read about 0.3× its model, and Fairies' bots ran a Ring size of 2.2 against the model's 4–6. Step 4's accounting check should run before these dials land. That argues for erring generous.
2. **Each tribe's "typical" comes from a different kind of model:** shop-luck variation, scripted variants, timing variants. Differences within about 15% are noise.
3. **Birds' tempo line runs one fixed cycle.** It peaks on even rounds and dips on odd ones. Raw R12 in C is 2,516; smoothed, 1,797.
4. **The pre-start board hides fight power:**
   - The Fairies' ring line fights at about 1.75× its board in B: 1,354 against 772 at R12.
   - Granny's gather, Birds in the sky and Sable's strike are also fight-only. Birds hold about 177–388 in reserve at R12 in B.
   - The field sim may crown Fairies. The cut that only touches fight power is fetch_share.
5. **The Fairies' R10 peak depends on the model's Ring sizes.** If real play matches the bots, the peak shrinks and the late fade returns, so the Monarch raise matters more.
6. **The lobby here is the median of six model figures, not a seated lobby.** Bog and Hunters were fed this lobby, not real ones.
7. **Hedgerow's optional Treasury line is not counted.** If the harness seats it, Hedgerow reads lower: 735 in B and 1,304 in C, on the calibrator's run.
8. **The harness lines never buy a second Cuckoo or a golden one.** Only play will show those tails.

**Model files** (`presets-model/`; the calibrator's and breaker's reports are in `../../evidence/presets/`):
- `six.py` and `final/six.json`: section 3.
- `cuts.py`: section 4.
- `birds_final.py`, `final/cuckoo_text.py`, `final/cuckoo3.py`, `final/goldcuckoo.py`: Birds.
- `fairies_final.py`: Fairies.
- `presets_json.py`: the JSON below.
- `calib/` and `adv/`: the calibrator's and the breaker's runs.

## 8. The presets as JSON

This holds every key from the tables in section 2. Thirds and sixths are at full precision, so the card text reads them as fractions.

```json
{
  "B": {
    "birds_homecoming_multiplier": 2.25,
    "birds_golden_homecoming_multiplier": 3.0,
    "birds_cuckoo_share": 0.125,
    "birds_golden_egg_multiplier": 2.0,
    "birds_stork_gold_step": 6,
    "birds_chiffchaff_gain": 3,
    "birds_redbreast_share": 0.16666666666666666,
    "birds_jack_daw_share": 0.25,
    "birds_jack_daw_permanent": true,
    "birds_stork_recalls": 1,
    "birds_trip_turns": 2,
    "birds_swallow_trip_turns": 1,
    "birds_golden_tern_trip_turns": 1,
    "birds_golden_egg_enabled": true,
    "birds_goose_eggs": 1,
    "birds_lump_multiplier": 1.0,
    "birds_ratchet_multiplier": 1.0,
    "birds_redwing_share": 0.5,
    "birds_redwing_targets": 2,
    "birds_tom_tit_reduction": 50,
    "birds_tom_tit_targets": 1,
    "birds_dunnock_turns": 1,
    "birds_dunnock_targets": 1,
    "birds_whistlers_loss_share": 0.5,
    "birds_whistlers_flock_count": 7,
    "birds_swallow_gold": 1,
    "birds_jay_acorns": 1,
    "fairies_ring_growth": 2.0,
    "fairies_lob_turns": 2,
    "fairies_nan_rings": 2,
    "fairies_lob_growth": 1.0,
    "fairies_silky_growth": 1.0,
    "fairies_fetch_share": 1.0,
    "fairies_monarch_period": 2,
    "fairies_monarch_multiplier": 2.0,
    "fairies_golden_monarch_multiplier": 3.0,
    "fairies_annis_rings": 1,
    "fairies_annis_sale": true,
    "fairies_queen_rings": 1,
    "fairies_queen_period": 1,
    "fairies_sally_rings": 1,
    "fairies_initial_ring_size": 1.0,
    "fairies_chaser_gold": 1,
    "fairies_reel_moves": 2,
    "fairies_wisp_attack": 1,
    "fairies_wisp_health": 1,
    "fairies_witch_ring_share": 1.0,
    "fairies_hob_shield_targets": 1,
    "fairies_belladonna_targets": 1,
    "fairies_changeling_steals": 1,
    "fairies_shy_thank_gold": 2,
    "bog_soak_keep": 2,
    "bog_golden_soak_keep": 4,
    "bog_nan_share": 0.5,
    "bog_golden_nan_share": 1.0,
    "bog_ranocchio_share": 0.5,
    "bog_golden_ranocchio_share": 1.0,
    "bog_tiddy_share": 0.5,
    "bog_golden_tiddy_share": 1.0,
    "bog_bitter_share": 0.25,
    "bog_bitter_round_up": true,
    "bog_soak_mired_only": true,
    "bog_kiss_period": 3,
    "bog_frog_multiplier": 2.0,
    "bog_golden_frog_multiplier": 3.0,
    "bog_kisses_per_fight": 1,
    "bog_frog_doubles_per_turn": 1,
    "bog_hopkin_share": 0.25,
    "bog_bufo_halvings": 1,
    "bog_gideon_hitbacks": 1,
    "bog_sal_toll_multiplier": 1.0,
    "bog_cutter_gold": 1,
    "bog_pretender_gold": 1,
    "bog_king_peatlings": 2,
    "bog_peatling_stat_share": 1.0,
    "bog_prima_donna_patches": 3,
    "bog_chorus_lends": 2,
    "bog_lantern_lures": 1,
    "bog_jenny_pulls": 1,
    "bog_capstone_gain_toll": false,
    "hunters_nip_share": 0.6666666666666666,
    "hunters_sable_share": 0.6666666666666666,
    "hunters_lutra_share": 0.6666666666666666,
    "hunters_glutton_share": 0.6666666666666666,
    "hunters_lodger_share": 0.6666666666666666,
    "hunters_wick_share": 0.3333333333333333,
    "hunters_grizel_share": 0.3333333333333333,
    "hunters_pelt_share": 0.3333333333333333,
    "hunters_russet_buff_share": 0.6666666666666666,
    "hunters_golden_russet_buff_share": 1.0,
    "hunters_ermeline_pelts": 1,
    "hunters_golden_ermeline_pelts": 2,
    "hunters_laird_multiplier": 2,
    "hunters_golden_laird_multiplier": 3,
    "hunters_golden_take_multiplier": 2.0,
    "hunters_sable_strike": 1.0,
    "hunters_golden_sable_strike": 2.0,
    "hunters_agnes_hit_back": 0.5,
    "hunters_golden_agnes_hit_back": 0.25,
    "hunters_isegrim_health_cut": 0,
    "hunters_russet_copies": 1,
    "hunters_lane_bard_gold": 1,
    "hunters_golden_lane_bard_gold": 2,
    "hunters_lane_bard_triggers": 2,
    "hunters_take_floor": 1,
    "hunters_young_brock_share": 1.0,
    "hunters_trophies_after_fight": true,
    "oozes_soup_share": 0.125,
    "oozes_elder_share": 0.5,
    "oozes_golden_elder_multiplier": 2.0,
    "oozes_aspic_bonus": 0.5,
    "oozes_golden_aspic_multiplier": 2.0,
    "oozes_nell_meals": 1,
    "oozes_bubble_belly": 1,
    "oozes_dollop_belly": 1,
    "oozes_dollop_discount": 1,
    "oozes_slice_share": 0.2,
    "oozes_slice_count": 1,
    "oozes_hasty_share": 0.2,
    "oozes_hasty_swallows": 1,
    "oozes_hasty_release_deaths": 3,
    "oozes_golden_soup_reads": 2,
    "oozes_granny_attack_multiplier": 1.0,
    "oozes_posset_loss_share": 0.5,
    "oozes_moss_golden_reduction": 25,
    "oozes_bubble_splits": 1,
    "oozes_pie_gold": 1,
    "oozes_wobbly_drip": 1,
    "oozes_frumenty_meals": 1,
    "oozes_syllabub_fires": 1,
    "hedgerow_dozey_wake_multiplier": 2.0,
    "hedgerow_golden_dozey_wake_multiplier": 2.0,
    "hedgerow_dozey_period": 3,
    "hedgerow_dozey_food_per_gold": 2.0,
    "hedgerow_partner_period": 3,
    "hedgerow_partner_acorns": 2,
    "hedgerow_crumb_pass": 1,
    "hedgerow_crumb_sell_share": 1.0,
    "hedgerow_clover_share": 1.0,
    "hedgerow_pym_pass": 3,
    "hedgerow_sorrel_summons": 1,
    "hedgerow_burdock_kits": 1,
    "hedgerow_mallow_multiplier": 2.0,
    "hedgerow_mallow_targets": 2,
    "hedgerow_urchin_bristle": 2,
    "hedgerow_urchin_hunker_targets": 1,
    "hedgerow_sergeant_share_per_gold": 0.1,
    "hedgerow_sergeant_throws": 1,
    "hedgerow_beadle_pass": 2,
    "hedgerow_treasurer_per_gold": 1.0,
    "hedgerow_hayward_per_gold": 1.0,
    "hedgerow_committee_share": 0.25,
    "hedgerow_lollop_share": 0.1,
    "hedgerow_mast_gold_step": 5,
    "hedgerow_mast_cap": 5,
    "hedgerow_larder_gold": [1, 5, 16],
    "scale_hero_spell_percent": 10,
    "pass3_loop_guards": true
  },
  "C": {
    "birds_homecoming_multiplier": 2.5,
    "birds_golden_homecoming_multiplier": 3.0,
    "birds_cuckoo_share": 0.15,
    "birds_golden_egg_multiplier": 3.0,
    "birds_stork_gold_step": 5,
    "birds_chiffchaff_gain": 4,
    "birds_redbreast_share": 0.16666666666666666,
    "birds_jack_daw_share": 0.25,
    "birds_jack_daw_permanent": true,
    "birds_stork_recalls": 1,
    "birds_trip_turns": 2,
    "birds_swallow_trip_turns": 1,
    "birds_golden_tern_trip_turns": 1,
    "birds_golden_egg_enabled": true,
    "birds_goose_eggs": 1,
    "birds_lump_multiplier": 1.0,
    "birds_ratchet_multiplier": 1.0,
    "birds_redwing_share": 0.5,
    "birds_redwing_targets": 2,
    "birds_tom_tit_reduction": 50,
    "birds_tom_tit_targets": 1,
    "birds_dunnock_turns": 1,
    "birds_dunnock_targets": 1,
    "birds_whistlers_loss_share": 0.5,
    "birds_whistlers_flock_count": 7,
    "birds_swallow_gold": 1,
    "birds_jay_acorns": 1,
    "fairies_ring_growth": 4.0,
    "fairies_lob_turns": 2,
    "fairies_nan_rings": 2,
    "fairies_lob_growth": 3.0,
    "fairies_silky_growth": 2.0,
    "fairies_fetch_share": 1.0,
    "fairies_monarch_period": 2,
    "fairies_monarch_multiplier": 3.0,
    "fairies_golden_monarch_multiplier": 4.0,
    "fairies_annis_rings": 1,
    "fairies_annis_sale": true,
    "fairies_queen_rings": 1,
    "fairies_queen_period": 1,
    "fairies_sally_rings": 1,
    "fairies_initial_ring_size": 1.0,
    "fairies_chaser_gold": 1,
    "fairies_reel_moves": 2,
    "fairies_wisp_attack": 1,
    "fairies_wisp_health": 1,
    "fairies_witch_ring_share": 1.0,
    "fairies_hob_shield_targets": 1,
    "fairies_belladonna_targets": 1,
    "fairies_changeling_steals": 1,
    "fairies_shy_thank_gold": 2,
    "bog_soak_keep": 3,
    "bog_golden_soak_keep": 6,
    "bog_nan_share": 0.5,
    "bog_golden_nan_share": 1.0,
    "bog_ranocchio_share": 0.5,
    "bog_golden_ranocchio_share": 1.0,
    "bog_tiddy_share": 0.5,
    "bog_golden_tiddy_share": 1.0,
    "bog_bitter_share": 0.25,
    "bog_bitter_round_up": true,
    "bog_soak_mired_only": true,
    "bog_kiss_period": 3,
    "bog_frog_multiplier": 2.0,
    "bog_golden_frog_multiplier": 3.0,
    "bog_kisses_per_fight": 1,
    "bog_frog_doubles_per_turn": 1,
    "bog_hopkin_share": 0.25,
    "bog_bufo_halvings": 1,
    "bog_gideon_hitbacks": 1,
    "bog_sal_toll_multiplier": 1.0,
    "bog_cutter_gold": 1,
    "bog_pretender_gold": 1,
    "bog_king_peatlings": 2,
    "bog_peatling_stat_share": 1.0,
    "bog_prima_donna_patches": 3,
    "bog_chorus_lends": 2,
    "bog_lantern_lures": 1,
    "bog_jenny_pulls": 1,
    "bog_capstone_gain_toll": false,
    "hunters_nip_share": 0.75,
    "hunters_sable_share": 0.75,
    "hunters_lutra_share": 0.75,
    "hunters_glutton_share": 1.0,
    "hunters_lodger_share": 1.0,
    "hunters_wick_share": 0.5,
    "hunters_grizel_share": 0.5,
    "hunters_pelt_share": 0.5,
    "hunters_russet_buff_share": 0.75,
    "hunters_golden_russet_buff_share": 1.0,
    "hunters_ermeline_pelts": 1,
    "hunters_golden_ermeline_pelts": 2,
    "hunters_laird_multiplier": 2,
    "hunters_golden_laird_multiplier": 3,
    "hunters_golden_take_multiplier": 2.0,
    "hunters_sable_strike": 1.0,
    "hunters_golden_sable_strike": 2.0,
    "hunters_agnes_hit_back": 0.5,
    "hunters_golden_agnes_hit_back": 0.25,
    "hunters_isegrim_health_cut": 0,
    "hunters_russet_copies": 1,
    "hunters_lane_bard_gold": 1,
    "hunters_golden_lane_bard_gold": 2,
    "hunters_lane_bard_triggers": 2,
    "hunters_take_floor": 1,
    "hunters_young_brock_share": 1.0,
    "hunters_trophies_after_fight": true,
    "oozes_soup_share": 0.16666666666666666,
    "oozes_elder_share": 0.75,
    "oozes_golden_elder_multiplier": 2.0,
    "oozes_aspic_bonus": 0.5,
    "oozes_golden_aspic_multiplier": 2.0,
    "oozes_nell_meals": 1,
    "oozes_bubble_belly": 1,
    "oozes_dollop_belly": 1,
    "oozes_dollop_discount": 1,
    "oozes_slice_share": 0.2,
    "oozes_slice_count": 1,
    "oozes_hasty_share": 0.2,
    "oozes_hasty_swallows": 1,
    "oozes_hasty_release_deaths": 3,
    "oozes_golden_soup_reads": 2,
    "oozes_granny_attack_multiplier": 1.0,
    "oozes_posset_loss_share": 0.5,
    "oozes_moss_golden_reduction": 25,
    "oozes_bubble_splits": 1,
    "oozes_pie_gold": 1,
    "oozes_wobbly_drip": 1,
    "oozes_frumenty_meals": 1,
    "oozes_syllabub_fires": 1,
    "hedgerow_dozey_wake_multiplier": 3.0,
    "hedgerow_golden_dozey_wake_multiplier": 3.0,
    "hedgerow_dozey_period": 3,
    "hedgerow_dozey_food_per_gold": 2.0,
    "hedgerow_partner_period": 3,
    "hedgerow_partner_acorns": 2,
    "hedgerow_crumb_pass": 1,
    "hedgerow_crumb_sell_share": 1.0,
    "hedgerow_clover_share": 1.0,
    "hedgerow_pym_pass": 3,
    "hedgerow_sorrel_summons": 1,
    "hedgerow_burdock_kits": 1,
    "hedgerow_mallow_multiplier": 3.0,
    "hedgerow_mallow_targets": 2,
    "hedgerow_urchin_bristle": 2,
    "hedgerow_urchin_hunker_targets": 1,
    "hedgerow_sergeant_share_per_gold": 0.1,
    "hedgerow_sergeant_throws": 1,
    "hedgerow_beadle_pass": 2,
    "hedgerow_treasurer_per_gold": 2.0,
    "hedgerow_hayward_per_gold": 1.0,
    "hedgerow_committee_share": 0.25,
    "hedgerow_lollop_share": 0.1,
    "hedgerow_mast_gold_step": 5,
    "hedgerow_mast_cap": 5,
    "hedgerow_larder_gold": [1, 5, 16],
    "scale_hero_spell_percent": 20,
    "pass3_loop_guards": true
  }
}
```