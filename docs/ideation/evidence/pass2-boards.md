# Pass 2: round 9 benchmark boards

R9 after recruiting/EOT, before Start of Combat. Absolute attack/health fields are current recruit totals including tribe, Ring and recruit aura bonuses; the runner reconstructs permanent layers by subtracting those live bonuses, then lets the real combat engine reapply them. Away Birds use their own totals; Eggs are generated only by PlayerState/HeldUnits. These economically plausible static fixtures are not recorded shop/action traces or optimized best boards. Heroes ignored. High: T2/T3/T4/T5 at R2/R4/R6/R8 (24 gold climbs). Low: T2/T3/T4 at R3/R6/R8 (13 gold climbs). Base income through R9 is 62. No T6 is assumed at R9.

All six tribes share the same income and climb assumptions. Buff histories below are deliberately conservative and use the amended cards; the draft hand totals are rebuilt rather than carried forward. Layout is fixed for every opponent. Each fight starts fresh, so permanent gains earned in one benchmark fight never carry to the next.

| Board | Tier | F1 | F2 | F3 | F4 | B1 | B2 | B3 |
|---|---:|---|---|---|---|---|---|---|
| Hunters high | 5 | Sable 5/7 | Grey Agnes 4/7 | golden Wick 6/8 | Grizel 7/8 | Old Lutra 6/7 | Old Brock 4/7 | The Lodger 6/6 |
| Hunters low | 4 | Little Nip 4/5 | Young Brock 1/3 | Sable 2/3 | The Toll-Bard 2/4 | Wick 2/3 | Charcoal Burner 6/8 | Old Lutra 4/5 |
| Hedgerow folk high | 5 | Mrs Sorrel, Harassed 4/5 | Mrs Clover, Midwife 4/6 | Dr Urchin 4/7 | Mrs Burdock, Expecting Again 4/5 | Kit 4/4 | The Standing Committee 6/7 | Mrs Mallow, Feeding Them Up 5/7 |
| Hedgerow folk low | 4 | Mrs Sorrel, Harassed 2/3 | Mr Pym 2/4 | Sergeant-at-Conkers 3/3 | — | The Sleeping Partner 1/2 | Mrs Burdock, Expecting Again 1/2 | Alderman Dozey 10/16 |
| Oozes high | 5 | Stone Soup 7/9 | Elder Ooze 5/9 | Bubble and Squeak 5/6 | Wee Wobbly 3/6 | Aunt Aspic 3/5 | Figgy Duff 5/7 | The Sixpenny Pie 3/6 |
| Oozes low | 4 | Wee Wobbly 1/4 | Stone Soup 4/6 | The Sixpenny Pie 1/4 | Turnip Scarecrow 0/4 | Little Dollop 1/2 | Mr Syllabub 3/6 | Dishwater Nell 1/2 |
| Bog folk high | 5 | Madame Bufo 3/6 | Gideon, Basso Profundo 4/8 | The Prima Donna 3/9 | Young Pretender 4/3 | Signor Ranocchio, Tenor 7/8 | Tiddy Mun 4/7 | Vaulting Hopkin 4/2 |
| Bog folk low | 4 | Bridge Toad 1/3 | The Peat Cutter 2/4 | The Natterjack Chorus 3/4 | Turnip Scarecrow 0/4 | Young Pretender 3/2 | Spitfire Sal 1/3 | Wee Wobbly 1/4 |
| Fairies high | 5 | Will-o'-the-Wisp 7/10 | Reel-Mistress 8/11 | Old Moth Annis 6/6 | Lady Belladonna 6/10 | Sally Spore 3/5 | Nan Toadstool 9/7 | Rainbow Chaser 5/5 |
| Fairies low | 4 | Moss Ooze 6/8 | Lob-Lie-by-the-Fire 2/3 | Cluricaun 5/6 | Changeling 2/2 | Hob-in-the-Hearth 1/3 | Old Moth Annis 3/2 | — |
| Birds high | 5 | Mr Redbreast 7/9 | Egg 9/10 | Redwing 4/6 | Egg 9/9 | Tom Tit 5/6 | The Cuckoo 5/8 | Mother Goose 6/9 |
| Birds low | 4 | Mr Redbreast 5/7 | Egg 2/5 | Mrs Jay 4/4 | Jack Daw 4/4 | Tom Tit 4/5 | Mrs Stork 4/7 | Charcoal Burner 4/6 |

The table includes recruit auras and Rings on home units, and full Egg forecasts; combat-only bonuses (Agnes, Sable, Committee, Bitter, Mire, Snap, Daw theft and emergence buffs) are applied by the engine. An Egg is a replacement for its away Bird, not an additional owned purchase. All Rings, paint, stored bodies, inventory and away trips are explicit in [the JSON fixture](pass2-boards.json).

**Hunters, high:** Two Suppers. Sable has one front-row Cordial; Lutra has one permanent Take. Wick is golden. No permanent Pounce growth is assumed: Lodger grows only during each fight. Agnes grants only F3; F4 Grizel does not join merely because she is beside Wick.

62 base income. Nine bought copies (27), four climbs (24), two Suppers (6), Cordial (1) = 58, leaving 4 for refreshes before any Spoils or Lutra income.

**Hunters, low:** No Supper or T4 Hunter. Nip has two Takes; Lutra one. Burner has two Pinches (+2/+2), rather than inventing permanent growth on the Burner itself. Brock retains amended 1 Attack.

62 base. Seven units (21), delayed climbs (13), two 1-gold spells (2) = 36. Remaining gold may fund missed refreshes, replacements and Burner spending.

**Hedgerow folk, high:** Two Suppers. Kit was summoned with Clover present, so its permanent +1/+1 also receives the standing +2/+2. Other bodies are amended base plus Supper. Mallow arrived R9 and gave Burdock +1/+1 at that End of Turn: Burdock had total 7, smaller than the Clover-buffed Kit’s 8. Committee reads all seven and grants +3 Attack each this fight.

62 base. Six bought units plus one created Kit (18), climbs (24), two Suppers (6) = 48. Fourteen gold remains for refreshes and earlier replacements.

**Hedgerow folk, low:** No Supper or T4. Dozey arrived R6, received Pym +2/+2 then woke R8 from 4/7 to 8/14; the second Pym Pass on R9 makes 10/16, within the +12/+12 permanent cap. F4 is empty to make B3 the Pass end. One Stash remains for the Sergeant; the earlier Stash was cashed. No Kit remains.

62 base. Six units (18), delayed climbs (13); six Partner Acorns form two Stashes, one cashed for 5 and one retained. Generous remaining budget represents misses and temporary units, not free stats.

**Oozes, high:** Two Suppers. Soup has four Recruit-Phase swallow procs across four turns (+4/+4). Aspic fed the Pill Bug and Posset for two turns while in front of it (+2/+2). Only five inside bodies are bought; Figgy has arrived but has no stored copy yet. Elder grants only +1/+1 on emergence; the stronger draft values are not baked in.

62 base +2 Spoils +3 earlier Pie payments; two Dollop discounts save 2. Twelve bought units (36), climbs (24), two Suppers (6), refreshes (3) = 69 before discounts, paid by 67 income +2 savings. Static budget, not a claimed shop trace.

Inside: F1: pill_bug 3/6; F2: mrs_posset 6/5; F3: lodger 4/4; F4: little_dollop 3/4; B3: young_brock 1/3.

**Oozes, low:** No Supper, Elder or Figgy. Soup has three once-a-turn swallow gains. Pie uses its amended 1/4 body and Belly 2. Five stored bodies; no free hidden Belly stats. The Lamp Moth release gives no combat buff, since its text is When played.

62 base. Twelve bought units (36), delayed climbs (13) = 49, leaving 13 before Dollop/Pie/Nell income for misses and temporary units.

Inside: F1: pill_bug 1/4; F2: young_pretender 3/2; F3: wick 2/3; F3: lamp_moth 1/2; B1: mrs_posset 2/1.

**Bog folk, high:** One Supper. Ranocchio has grown once in each of three earlier fights (+3/+3); Tiddy arrived R8 and buffed Bufo and Gideon once each in that fight. Corrected amended bases give Ranocchio 7/8 and Tiddy 4/7. Living mirers wait once; no extra Mire income is converted into imaginary stats.

62 base. Seven bought units (21), climbs (24), Supper (3) = 48. Fourteen remains for refreshes and earlier replacements before any Bog income.

**Bog folk, low:** No Supper or T4 Bog. Chorus lends Mire/Bitter to adjacent Peat Cutter and Scarecrow; locks, waits, Sal damage and Snap are computed in the engine. Wobbly has no inside body.

62 base. Seven bought units (21), delayed climbs (13) = 34. Twenty-eight may be spent on misses, spells whose temporary effects have ended and replacements.

**Fairies, high:** Two Suppers. Thanked Hob, Lob and Silky on R8: three +2/+2 Rings. Annis kept +2 Attack and +2 Health from the prior Hearth supports. Nan adds her played Ring; a prior Sally proc fills that Ring to +4/+4. Only three occupied slots are painted, keeping Chaser at one pair; Annis adds +1 Attack to Nan and Chaser at R9 End of Turn. Shy bodies were not grown before departure.

62 base +6 Shy income on R9. Ten bought cards including the three departed supports (30), climbs (24), two Suppers (6), three 1-gold thank-you spells (3) = 63, leaving 5 for refreshes.

**Fairies, low:** No Supper or Silky; six bodies. Lob and Hob keep amended printed stats: 2/3 and 1/3. Prior support supplies +6 Attack total (Moss +3, Cluricaun +2, Annis +1) and +6 Health total (Moss +3, Cluricaun +3). Moss has a Nan Ring +1/+1. Only Cluricaun is painted (+1 Attack). This recomputes the draft’s overstated roughly 60 to an explicit 43 stats.

62 base. Seven bought units including a sold Nan (21), delayed climbs (13) = 34; at least 28 remains for misses/replacements. Ring is from Nan, not the absent Silky.

**Birds, high:** Two Suppers. Three Nests; two empty. Chiffchaff has been played twice and both it and Jay gained +4/+4 from two previous Cuckoo EOTs; Cuckoo has since moved from F3 to B2 and Redwing to F3. Redwing reaches both Eggs, so full stats 9/10 and 9/9 apply; Tom Tit does not add Health twice. Old Tern is away with its Nest covered by Cuckoo. Goose has a prior +0/+0 beyond Supper.

62 base. Eight bought units including three away Birds (24), climbs (24), two Suppers (6) = 54, leaving 8 before Swallow/Spoils income for refreshes.

**Birds, low:** One Supper. Two Nests, one covered by Burner. Chiffchaff has one play and a Pinch (+1/+1), making the away Bird 4/5; Tom Tit gives the Egg full Health, for 2/5. Old Tern is away with a covered Nest. Jack Daw steals in the fight, not in the fixture.

62 base. Eight bought units (24), delayed climbs (13), Supper (3), Pinch (1) = 41; 21 remains for misses/replacements before Bird income.

**Reproduce:** `systemd-run --user --scope -p MemoryMax=3G -- godot --headless -s res://tools/sim/pass2_boards.gd -- repetitions=100 seed=92100 out=build/pass2-boards`. The runner uses existing Combat/RecruitRules/PlayerState fight machinery. No existing fixed-board JSON round-robin reader was found; this script is a thin adapter, while `tools/sim/bench.gd` remains the full-game benchmark runner. It produces a win/tie/loss JSON and Markdown matrices for high, low and all twelve boards. Every unordered pair plays each seed twice with sides swapped; draws score half only in the separately labelled score column.

Results are recorded in [pass2-build.md](pass2-build.md). Static-board results measure these compositions and placements, not card pick rates, shop frequency, bot strength, or player experience.
