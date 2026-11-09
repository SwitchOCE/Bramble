Calibrated. Only Birds needed changes, two dials: Chiffchaff +3 and Redbreast 1/6, in both presets. The other five tribes keep their agents' values. On one convention every tribe now sits at 901–1,040 in B (1.15× spread) and 1,675–2,168 in C (1.29× spread).

## 1. Convention and conversion

**What is counted.** I checked this against `/home/alex/code/Bramble-ideation-sol/tools/sim/fight_capture.gd` (`_active_snapshot` of the `combat_start` views):
- Each seat's pre-start, end-of-recruit board: Attack + Health of the 7 slots after auras and slot Rings.
- Eggs are in. Belly, away, hand and doorstep are out.
- The Fetch twin is not in the pre-start number. It is made in `pass3_fairy_combat.gd` at Start of Combat. The `Pass3Views` overlay that shows it early is UI-only (`game_session.gd:121`).

**What differed between agents was "typical", not the counting.** All six preset models already counted this way. The README's differences (Fetch twin, Bellies, sky) applied only to the syntheses' models. But:
- Birds used only line A.
- Bog used only the court line.
- Oozes used only line B.

The harness seats two lines per tribe, so I converted every tribe to the same figure:
1. For each of the tribe's two harness lines, take the line's median board at R11, R12 and R13.
2. Take the geometric mean of those three. This evens out cycle phases: Birds' trips, Dozey's wakes, the Oozes' second stomach.
3. Average the two lines, because the harness seats both equally.

The raw R12 figure is shown beside it.

| Tribe (two harness lines) | B smoothed | B raw R12 | C smoothed | C raw R12 | Agent's claim (B / C) |
|---|---|---|---|---|---|
| Birds (homecoming, tempo) | 901 | 864 | 1,675 | 2,299 | 966 / 1,969 (line A only) |
| Fairies (ring, court) | 977 | 950 | 1,940 | 1,880 | 950 / 1,880 |
| Bog (court, swamp) | 1,032 | 1,024 | 1,896 | 1,858 | 988 / 1,859 (court only) |
| Hunters (pack, open season) | 923 | 922 | 1,810 | 1,848 | 922 / 1,848 |
| Oozes (engine B, Pot Luck) | 968 | 978 | 1,897 | 1,887 | 954 / 1,771 (line B only) |
| Hedgerow (supper, parish) | 1,040 | 924 | 2,168 | 1,972 | 924 / 1,972 |

- The average of the six is about 974 in B and 1,898 in C.
- R8–R14 growth a round:

| Tribe | B | C |
|---|---|---|
| Birds | ×1.52 | ×1.83 |
| Fairies | ×1.55 | ×1.74 |
| Bog | ×1.67 | ×1.85 |
| Hunters | ×1.66 | ×1.90 |
| Oozes | about ×1.55 | about ×1.8 |
| Hedgerow | ×1.65 | ×1.75 |

- Design on this convention is below 900 for every tribe: Birds 461, Fairies 600, Oozes 728, Bog 696, Hunters 624, Hedgerow 362. The earlier "about 900 at design" for Fairies and Oozes counted the twin and the Bellies. So all six are raised, Fairies and Oozes included. That departs from the letter of the plan ("stay at design size"), so the orchestrator should log it.

## 2. Changes to the agents' values

**Birds** (the only tribe changed):
- **birds_chiffchaff_gain:** B 2→3, C 2→3. This is a new key; today the gain is a card number in `content/units/chiffchaff.json`.
- **birds_redbreast_share:** B and C 1/8→1/6.

Why:
- With both lines pooled, the agent's dials gave 737 in B and 1,447 in C, about 0.8× target.
- The tempo line's carry, Chiffchaff, is away at R12. Its gain is compounded by every homecoming, so raising it lifts both lines.
- A sixth on Redbreast is a mild lift: the biggest unit's share goes from 39%/57% to 40%/60% (homecoming/tempo lines).

Rejected:
- **Cuckoo 1/5 in B.** It reaches 944, but the two-Cuckoo Flock hits 9,345 at R14, about 4× the field.
- **Cuckoo 1/4, h 2.6 or Golden Egg ×4 in C.** Each gives bigger tails or messy card text.

The cost of the chosen raises:
- Chiffchaff plays as a 4/5 on turn 1. The pooled R6 board is 63 against a field of 53 (1.19×).
- C reads 1,675 smoothed and 2,299 raw, so the target of 1,800 sits between the two measures.
- The two-Cuckoo Flock at the final values is 4,280 / 8,357 at R14 / R15 in B, and 19,866 / 31,480 in C. That is a reported tail.

**Fairies, Bog, Hunters, Oozes and Hedgerow:** kept as the agents set them. They already sit at 0.92–1.20× on the common measure.
- **Hedgerow C is the hottest** at 2,168 smoothed, because raw R12 falls in the Supper's trough before Dozey's wake. It is still inside 1.3×, so I kept it, erring generous. If it needs cutting, cut hedgerow_mallow_multiplier from 3 to 2 first.
- **Bog:** if it runs hot, the first cut is bog_nan_share back to its design value of 1/4. That also removes Bog's R6 lead of 1.28× in B and 1.45× in C.

## 3. Shared pieces

**Cards shared between tribes, and cards that read a tribe's dials:**
- **Click Beetle** (doubles "When played"). Every Birds homecoming replays "When played", so the Beetle doubles Chiffchaff's +3 on each landing and gives two Golden Eggs per Goose landing (×3 each in C).
  - An upper-bound probe (Chiffchaff at +6 all game) takes Birds' R12 from 901 to 1,230 in B and from 1,675 to 2,289 in C. The real effect is smaller, since the Beetle is tier 5.
  - Rule question for the build: does amendment 11 ("never repeat a doubling") stop the second Egg? Cross-tribe §8 says it doesn't.
  - Fairies' Nan Toadstool goes from 2 to 4 Rings per play. Hedgerow's Crumb and Burdock gain very little.
- **Charcoal Burner** gives "a twentieth of their stats". If that includes slot Rings, it turns Fairies' Rings into permanent body stats every turn. The Ring size at R12 is about 8 in B and 16 in C, so this matters. Make it read body stats only, as Shy does.
- **Spells:**
  - The Golden Egg's text is generated from the multiplier dial (`pass3_text.gd:230`), so "Triple" in C is fine.
  - Harvest Supper is capped at +3/+3, and only the Birds model counts it. The other five read about 5% low until the ceiling is lifted.
  - No model includes the board-scaled hero powers and spells.
  - Larder items (shared with Mrs Jay and the hoarder hero), Pelts, Slices, Horseshoe and the Hedge Witch all scale on their own. No change needed.
- **Tribes that feed on the enemy** (Hunters' Takes, Bog's Soak, Hasty's fifth, Jack Daw's steal) read stats that include Rings and Start of Combat buffs.
  - The calibrated lobby at R11 is about 13% bigger than the fields Bog and Hunters were fed: about 628 against 552–556 in B, and about 1,110 against 962–990 in C.
  - Expect Bog around 1,090 (B) and 2,030 (C) raw, and Hunters around 980 and 1,960.

**Start of Combat order (amendment 4):**
- **The Fetch twin becomes a decoy.** Undoing amendment 1 means the twin is the copied Fairy at full size plus the Fetch slot's own Ring (`_fetch`, then `_apply_slot_grants`). So it is at least as big as the Fairy it copies. Every biggest-enemy effect (Hasty, the Lantern Man, Isegrim, Jenny) will pick the twin instead of the real carry. The fix is a tie-break that skips copies made this fight, or accepting it.
- **Jack Daw is still a coin flip.** His steal aims across and resolves in the ordinary step, in random side order with the twin, Granny's gather, the Whistlers and the Changeling. So whether his permanent steal reads a fight-only twin or gathered Granny is a coin flip.
  - He is about 12% of Birds' board: without the permanent steal, Birds drop from 901 to 809 (B) and from 1,675 to 1,459 (C).
  - If amendment 5 makes him fight-only, compensate on harness evidence: Chiffchaff +4 or Redbreast 1/5.
- **Sable's strike reads her across quarry before Isegrim re-aims her.** Her strike needs to resolve after Isegrim's hunt. Hasty can also swallow a Sable already buffed by her strike and keep a fifth of that fight-only gain.
- **Spitfire Sal never hits the Lantern Man's lured enemy.** She resolves "after patches", in the ordinary step, while the Lantern lures last. Fine if intended; otherwise move her after the Lantern.

## 4. Every dial (key: B / C)

**Birds**
- birds_homecoming_multiplier 2.25 / 2.5
- birds_golden_homecoming_multiplier 3 / 3
- birds_cuckoo_share 0.125 / 0.2
- birds_golden_egg_multiplier 2 / 3
- birds_stork_gold_step 6 / 5
- birds_chiffchaff_gain 3 / 3 (new key; changed)
- birds_redbreast_share 0.1667 / 0.1667 (changed)
- birds_jack_daw_share 0.25 / 0.25
- birds_jack_daw_permanent true / true
- birds_stork_recalls 1 / 1
- birds_trip_turns 2 / 2
- birds_swallow_trip_turns 1 / 1
- birds_golden_tern_trip_turns 1 / 1
- birds_golden_egg_enabled true / true
- birds_goose_eggs 1 / 1 (new key)
- birds_lump_multiplier 1 / 1
- birds_ratchet_multiplier 1 / 1
- birds_redwing_share 0.5 / 0.5
- birds_redwing_targets 2 / 2
- birds_tom_tit_reduction 50 / 50
- birds_tom_tit_targets 1 / 1
- birds_dunnock_turns 1 / 1
- birds_dunnock_targets 1 / 1
- birds_whistlers_loss_share 0.5 / 0.5
- birds_whistlers_flock_count 7 / 7
- birds_swallow_gold 1 / 1 (new key)
- birds_jay_acorns 1 / 1 (new key)

**Fairies**
- fairies_ring_growth 2 / 4
- fairies_lob_turns 2 / 2
- fairies_nan_rings 2 / 2
- fairies_lob_growth 1 / 3
- fairies_silky_growth 1 / 2
- fairies_fetch_share 1.0 / 1.0
- fairies_monarch_period 3 / 3
- fairies_monarch_multiplier 2 / 2
- fairies_golden_monarch_multiplier 3 / 3
- fairies_annis_rings 1 / 1
- fairies_annis_sale true / true
- fairies_queen_rings 1 / 1
- fairies_queen_period 1 / 1
- fairies_sally_rings 1 / 1
- fairies_initial_ring_size 1 / 1
- fairies_chaser_gold 1 / 1
- fairies_reel_moves 2 / 2
- fairies_wisp_attack 1 / 1
- fairies_wisp_health 1 / 1
- fairies_witch_ring_share 1 / 1
- fairies_hob_shield_targets 1 / 1
- fairies_belladonna_targets 1 / 1
- fairies_changeling_steals 1 / 1
- fairies_shy_thank_gold 2 / 2
- pass3_loop_guards true / true

**Bog**
- bog_soak_keep 2 / 3
- bog_golden_soak_keep 4 / 6
- bog_nan_share 0.5 / 0.5
- bog_golden_nan_share 1 / 1
- bog_ranocchio_share 0.5 / 0.5
- bog_golden_ranocchio_share 1 / 1
- bog_tiddy_share 0.5 / 0.5
- bog_golden_tiddy_share 1 / 1
- bog_bitter_share 0.25 / 0.25
- bog_bitter_round_up true / true
- bog_soak_mired_only true / true
- bog_kiss_period 3 / 3
- bog_frog_multiplier 2 / 2
- bog_golden_frog_multiplier 3 / 3
- bog_kisses_per_fight 1 / 1
- bog_frog_doubles_per_turn 1 / 1
- bog_hopkin_share 0.25 / 0.25
- bog_bufo_halvings 1 / 1
- bog_gideon_hitbacks 1 / 1
- bog_sal_toll_multiplier 1 / 1
- bog_cutter_gold 1 / 1
- bog_pretender_gold 1 / 1
- bog_king_peatlings 2 / 2
- bog_peatling_stat_share 1 / 1
- bog_prima_donna_patches 3 / 3
- bog_chorus_lends 2 / 2
- bog_lantern_lures 1 / 1
- bog_jenny_pulls 1 / 1
- bog_capstone_gain_toll false / false

**Hunters**
- hunters_nip_share 0.6667 / 0.75
- hunters_sable_share 0.6667 / 0.75
- hunters_lutra_share 0.6667 / 0.75
- hunters_glutton_share 0.6667 / 1.0
- hunters_lodger_share 0.6667 / 1.0
- hunters_wick_share 0.3333 / 0.5
- hunters_grizel_share 0.3333 / 0.5
- hunters_pelt_share 0.3333 / 0.5
- hunters_russet_buff_share 0.6667 / 0.75
- hunters_golden_russet_buff_share 1.0 / 1.0
- hunters_ermeline_pelts 1 / 1
- hunters_golden_ermeline_pelts 2 / 2
- hunters_laird_multiplier 2 / 2
- hunters_golden_laird_multiplier 3 / 3
- hunters_golden_take_multiplier 2 / 2
- hunters_sable_strike 1.0 / 1.0
- hunters_golden_sable_strike 2.0 / 2.0
- hunters_agnes_hit_back 0.5 / 0.5
- hunters_golden_agnes_hit_back 0.25 / 0.25
- hunters_isegrim_health_cut 0 / 0
- hunters_russet_copies 1 / 1
- hunters_lane_bard_gold 1 / 1
- hunters_golden_lane_bard_gold 2 / 2
- hunters_lane_bard_triggers 2 / 2
- hunters_take_floor 1 / 1
- hunters_young_brock_share 1.0 / 1.0
- hunters_trophies_after_fight true / true
- hunters_bodies unchanged / unchanged

**Oozes**
- oozes_soup_share 0.125 / 0.1667
- oozes_elder_share 0.5 / 0.75
- oozes_golden_elder_multiplier 2 / 2
- oozes_aspic_bonus 0.5 / 0.5
- oozes_golden_aspic_multiplier 2 / 2
- oozes_nell_meals 1 / 1
- oozes_bubble_belly 1 / 1
- oozes_dollop_belly 1 / 1
- oozes_dollop_discount 1 / 1
- oozes_slice_share 0.2 / 0.2
- oozes_slice_count 1 / 1
- oozes_hasty_share 0.2 / 0.2
- oozes_hasty_swallows 1 / 1
- oozes_hasty_release_deaths 3 / 3
- oozes_golden_soup_reads 2 / 2
- oozes_granny_attack_multiplier 1 / 1
- oozes_posset_loss_share 0.5 / 0.5
- oozes_moss_golden_reduction 25 / 25
- oozes_bubble_splits 1 / 1
- oozes_pie_gold 1 / 1
- oozes_wobbly_drip 1 / 1
- oozes_frumenty_meals 1 / 1
- oozes_syllabub_fires 1 / 1

**Hedgerow**
- hedgerow_dozey_wake_multiplier 2 / 3
- hedgerow_golden_dozey_wake_multiplier 2 / 3
- hedgerow_dozey_period 3 / 3
- hedgerow_dozey_food_per_gold 2 / 2
- hedgerow_partner_period 3 / 3
- hedgerow_partner_acorns 2 / 2
- hedgerow_crumb_pass 1 / 1
- hedgerow_crumb_sell_share 1 / 1
- hedgerow_clover_share 1 / 1
- hedgerow_pym_pass 3 / 3
- hedgerow_sorrel_summons 1 / 1
- hedgerow_burdock_kits 1 / 1
- hedgerow_mallow_multiplier 2 / 3
- hedgerow_mallow_targets 2 / 2
- hedgerow_urchin_bristle 2 / 2
- hedgerow_urchin_hunker_targets 1 / 1
- hedgerow_sergeant_share_per_gold 0.1 / 0.1
- hedgerow_sergeant_throws 1 / 1
- hedgerow_beadle_pass 2 / 2
- hedgerow_treasurer_per_gold 1 / 2
- hedgerow_hayward_per_gold 1 / 1
- hedgerow_committee_share 0.25 / 0.25
- hedgerow_lollop_share 0.1 / 0.1
- hedgerow_mast_gold_step 5 / 5
- hedgerow_mast_cap 5 / 5
- hedgerow_larder_gold 1/5/16 / 1/5/16

No dial is below its design value, and every C value is at or above its B value.

## 5. Where the accounting is shaky

1. **Birds' tempo line is one fixed path.** Shop-luck jitter barely moves it, because Chiffchaff's trip cycle is fixed from R1. Its R12 swings with phase: 602 in B, and 507→2,299 from R11 to R12 in C. Smoothing is what puts Birds C at 1,675 rather than 2,299.
2. **Real play may land well below paper.** Wave 1's one Birds game read about 0.3× the model, and Fairies' bots had a Ring size of 2.2 against the model's 4–6. Step 4's accounting check should run before these dials land. That argues for erring generous.
3. **Fight power the pre-start number hides:**
   - Fairies' ring line fights at about 1.75× its measured board with the full twin (1,354 against 772 in B).
   - The Oozes' Granny gather, Birds' sky (about 177–388 in reserve at R12 in B) and Hunters' Sable strike are also fight-only.
   - The field sim may crown Fairies. The fight-only cut is fetch_share, which would mean going below design on evidence.
4. **Bog and Hunters depend on an assumed field.** Both were fed a target-shaped field, not the six calibrated tribes, so expect them about 6–12% higher (section 3).
5. **The pooled medians fall in gaps between lines.** For Fairies and Birds, the median depends on the seat mix between their two lines.
6. **Hedgerow's optional third line is not pooled.** If the harness seats the Treasury line, Hedgerow reads lower: 735 in B, 1,304 in C.

Scratch files are in /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/calib/:
- birds_sweep.py
- birds_final.py
- birds_final.out.txt
- two_cuckoo_cal.py
- hunters_r11_13.py