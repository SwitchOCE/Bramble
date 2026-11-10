# Fresh cold-reader event score — first attempt

This is the frozen first repair attempt (UI through `ec6d7575`, capture method `204c14cc`);
its images/manifests were archived locally before the next reshoot. It is retained as a failed
review, not the final repaired result. The initial six-fix implementation was insufficient.

Three fresh readers independently read one fight each, using only the packet and images. Each assessed its modes separately. No feedback or source hints were sent to the readers. This separate scorer prepared truth from `strips/*/manifest.json` (`events`, `event_ticks`, attack/opening/result intervals), then read only the three frozen `cold-reader-first-repair-{combat-mid,homecoming,rival}.md` answers and inspected images. No previous reader reports, README, implementation or Godot were used. This scores the captured first attempt, not subsequent repairs.

**R** = right, **C** = can't tell/not established in the raw answer, **W** = wrong. Card positions use the packet convention. Ability names and conditions are not required. A correct damage pair does not establish its initiator. A visible self change needs no second source card; reduced-motion static source/target cues count. For other effects, **S/L** means source-to-effect attribution / landing or visible change; merely locating a flash does not establish its effect. An absent card-source event is stated explicitly.

**Result:** 50/57 attack initiators R, 7 C; all 57 attack damage pairs and all 62 attack-caused unit deaths have the correct causal pair. Opening source/effect attribution, Take/reward landings and some hero spark origins remain unresolved or wrong. This is not a full source/effect pass.

## Attacks and death causes

Every death cause in these tables is R in every listed mode. `→` identifies the initiating attacker; `+` includes the actual additional hitter. Numbers are event indices, not frame numbers.

| combat_mid attack | Truth; death cause | Initiator ×1 / ×4 / reduce |
|---|---|---|
| 021 | bottom B2→top B2; bottom B2 killed by top B2 return hit | R / R / R |
| 026 | top F1 + F2→bottom F4; combined 1+4 kills F4 | R / R / R |
| 031 | bottom F1→top F2; F1 killed by F2 return hit | R / R / R |
| 036 | top F3 + F2→bottom F2; F3 killed by bottom F2 return hit | R / R / R |
| 045 | bottom F2→top F2; each kills the other | C / C / R |
| 054 | top B2→bottom F3; B2 killed by F3 return hit | R / R / R |
| 058 | bottom F3→top F1; F1 killed by F3 | R / R / R |
| 062 | top B3→bottom F3; each kills the other | R / R / R |
| 069 | bottom B1→top B1; neither dies | R / R / R |
| 075 | top B1→bottom B1; bottom B1 killed by top B1 | R / R / R |
| 080 | top B1→bottom B3; B1 killed by B3 return hit | R / C / R |

The combat reader calls attack-021's return hit **4**, but the event amount is **3** in every mode. That numerical assertion is W; the hitter, recipient and lethal cause are R.

| homecoming attack | Truth; death cause | Initiator ×1 / ×4 |
|---|---|---|
| 020 | bottom F1→top F1; top F1 killed by bottom F1 | R / R |
| 026 | top F3→bottom F4; F3 killed by F4 return hit | R / R |
| 030 | bottom F2 copy→top F2; top F2 killed by copy | R / R |
| 033 | top B1→bottom F2 copy; B1 killed by copy return hit | R / C |

| rival attack | Truth; death cause | Initiator ×1 / ×4 |
|---|---|---|
| 025 | bottom F1→top F2; F1 killed by F2 return hit | R / C |
| 033 | bottom F2→top F2; bottom F2 killed by top F2 return hit | C / C |
| 039 | bottom B2→top F2; B2 killed by F2 return hit | R / R |
| 043 | top F1→bottom F4; F4 killed by F1 | R / R |
| 047 | bottom F1 summon→top F2; each kills the other | R / R |
| 054 | top F3→bottom F3; bottom F3 killed by top F3 | R / R |
| 058 | bottom B1→top F1; B1 killed by F1 return hit | R / R |
| 062 | top F4→bottom B3; B3 killed by F4 | R / R |

Initiator C frame causes (frames numbered 1–8): combat 045 ×1 f1→f2 jumps ticks 1153→1190 across damage 1185; ×4 593→615 across damage 609. Combat 080 ×4 f1→f2 jumps 1169→1191 across damage 1185. Homecoming 033 ×4 jumps 389→411 across damage 405. Rival 025 ×4 jumps 190→206 across damage 206; rival 033 ×1 jumps 692→711 across damage 707 and ×4 303→317 across damage 316. These sheets show the damage pair, without a sampled initiating displacement. Reduced motion identifies combat 045/080 through held pocket outlines/triangles.

## Other sources and effects

Opening effects count. The eight-frame whole-phase opening capture is a coverage limitation, not an exemption. The following rows cover the manifested changes and relevant trigger cues; grouped modes have identical scores unless specified.

| combat_mid packet | Source/effect truth | S/L and raw-answer evidence |
|---|---|---|
| Opening marks | bottom F2, F3, B3 mark their opposing quarry; top F3 assigns top F2 a quarry at bottom F3 | C/C all modes: badges/paws seen; individual source→hunter→quarry assignments not established |
| Opening Mire | top B1→bottom B1; top B2→bottom B2 patches/statuses | C/C all: both top sources flash, but reader cannot identify recipients/effect |
| Opening neighbour gain | top F3→top F2 +1 Attack | R/R all, including reduced-motion static pulse/changed badge |
| Opening self gain | bottom B3→itself +3 Attack | C/R all: correct changed card, source explicitly uncertain |
| Opening reduction | top B2→bottom B2 −1 Attack | W/R ×1/×4: reader instead suggests bottom B3→B2; C/R reduce |
| Opening bottom B1 trigger | bottom B1 fires with no target and no effect | No missing landing to invent; reader observes flash and no numerical effect |
| 021/031 Pack cue, then 026/036 | top F2 flashes and joins next attack | Hitter/landing R all; no additional numeric buff exists to demand from the flash |
| 036 Take/growth | bottom F3 takes top F3, then gives itself +1/+1 | C/R all: correct recipient/gain, reader cannot choose dead badger versus fox as source |
| 045 dead-unit reward | dead bottom F2 takes top F2 and receives permanent +1/+1 (`source=target=2`) | R/C all: floating dead fox/+1/+1 is recognized, final reward landing is not |
| 045 wait cue | top B1 waits for bottom B1 | C/C all: reader sees top B1 dark-symbol flash but cannot identify its effect/recipient |
| 062 Take | bottom B3 takes top B3; quarry link ends | C/C all: death, weasel flash and nearby acorn/paw seen without a settled source→landing account. No new stat gain event exists here |
| 069/075 | top B1 self +2 Attack, then self −2 | R/R all: reader identifies both self changes; no separate source is required |

Combat opening ×1/reduce samples ticks 0/85/171/256/342/427/513/598; ×4 0/31/62/93/125/156/187/218. For example, the self-gain trigger/result (451/477 at ×1; 130/140 at ×4) and the reduction trigger/result (513/539; 149/159) are compressed between or across adjacent samples. The sheets leave a misleading adjacency between bottom B3's flash and bottom B2's red stat cue. In 036, f4–8 show the dying top F3 and bottom F3's growth together; the reader still cannot identify which originated the gain. In 045, f3–8 show the dead-fox reward but do not yield a readable landing. In 062, f3–8 show the death and weasel flash/acorn without resolving that source/landing for the reader.

| homecoming packet | Source/effect truth | S/L at both speeds |
|---|---|---|
| Opening marks | top F2 gives top F1/F3 quarry at bottom F2; top F3 gives top F2 quarry at bottom F3 | C/C: source assignments untraceable |
| Opening +1 Attack | top F2→top F1 and F3; top F3→top F2 | R/R for F2→F1 and F3→F2; C/R for F2→F3 (reader explicitly cannot attribute third gain) |
| Opening replacement/death | bottom F2 triggers its own death and summons a copy of bottom B1 into F2 | C/R for replacement source/visible portrait change; **W death claim**: both answers say no opening death, though death event 10 precedes summon 11 |
| Opening Ring gain | new bottom F2 39/40→43/44, from its slot Ring; source field null | No card source required; landing R. Copy resemblance is recognized, but self-death causation is not |
| Opening reductions | bottom F2 copy→top F2 −2 Attack; bottom B1→top B1 −2 Attack | C/R: both reductions read across opening/020, sources not assigned |
| Opening shield | bottom B3→bottom B1 shield | C/C: B3 flash and B1 blue outline seen but not linked or understood as an effect |
| 020 self trigger | top F1→top B1 +1 Attack | R/R; ×4 positive badge cue in 020 resolves to 1 in 026, sufficient without naming rule |

Homecoming opening ×1 samples 0/61/123/184/246/307/369/430; ×4 0/26/52/78/103/129/155/181. Self-death/summon ticks 254/290 (×1) lie between f5 and f6; at ×4 death75/summon93 lie around f4/f5. Both look like shrinking/replacement, and the raw reader does not identify the self-death cause. The reductions and shield are packed into the final opening frames: ×1 source/result ticks316/343,343/369,369/395; ×4 103/112,112/122,122/132. These are actual attribution gaps in this packet, not failures to name conditions.

| rival packet | Source/effect truth | S/L at both speeds |
|---|---|---|
| Opening quarry/Mire | bottom F4 quarry→top F4; bottom F2 assigns bottom F1/F3→top F2; bottom F3 assigns F2→top F3; bottom B1 assigns B2→top B1. Top F2→bottom F2 Mire | C/C: pulses/paws observed without complete assignments |
| Opening neighbour gains | bottom F2→F1/F3 +1 Attack; bottom F3→F2 +1 | C/R: all three gains read, sources uncertain |
| Opening side bonus | top-side Hermitage +4/+4 to all five top cards; `side_trigger`, stats source null | **W/R**: reader wrongly attributes it to top B1, whose own trigger follows the side bonus |
| Opening Nightshade | top B1→bottom B1 status | C/C: tint observed, no source→status landing account |
| Opening self gain | bottom B2→itself +3 Attack | **W/R**: reader suggests F2/F3→B2, rather than B2 self change |
| 025 release | dead bottom F1→summoned bottom F1 | R/R: dying creature identified as source of replacement |
| 025 aura | bottom B1 aura→new F1 +1 Attack (`source=null`, `causes.source=5`) | C/R: recipient/gain read; direct source uncertain between F2/B1 |
| 025/033 self Pounce cues | bottom F2 pulse→its next attack; bottom B2 pulse→its next attack | F2 C/C: pulse seen but its next attack initiator is C. B2 R/R across 033→039: same flashing bird is visibly next attacker; naming Pounce is unnecessary. No additional numeric buff is required |
| 047 Take | bottom F3 takes top F2; quarry link ends | C/C: paw at dead top F2 and F3 flash seen, source/landing not established. No new stat gain exists here |

Rival opening ×1 samples 0/73/146/219/291/364/437/510; ×4 0/27/54/81/108/135/162/189. Side buff/result ticks362/398 and top B1 status-source trigger398 overlap the f6→f7 gap at ×1; ×4 result111 and subsequent trigger111/status121 are compressed between f5/f6. This produces the incorrect top B1 source attribution. Bottom B2 trigger/result424/451 (×1),121/130 (×4) follow F2/F3 flashes; self origin is not read. Rival 025 f5–8 show the new unit and B1/F2 flashes together, leaving the aura source C. Rival 047 f3–8 show the dead quarry and bottom F3 pulse without resolving the link.

## Result/outro and system packets

| Packet | Hero landing/amount/Health | Card-origin reading |
|---|---|---|
| combat_mid all three modes | R: top hero −3, 34→31; bottom stays38 | C: sole starting survivor bottom B3 is identified, but reader cannot assign its individual spark contribution. Base2 is a system portion, not a source card |
| homecoming both modes | R: top hero −6, 40→34; bottom stays40 | R: result explicitly identifies F1/F3/F4/B1/B2/B3 origins and excludes copied F2. No rule-name explanation required |
| rival both modes | R: bottom hero −7, 30→23; top stays40 | C: collective top side read, individual F1/F3/F4/B1 spark origins not established. Base3 is a system portion |

The complete damage result is assessed, including final attack/result overlap, not just the last unit death. Combat and rival spark paths overlap around hero/board art in their result frames; readable total damage does not repair unreported individual origins. Homecoming event37 is **system Early Spoils +1 to side0**, with no card source and no source event to identify. Its gold landing is not established in these raw images/answers (C effect coverage); it must not be charged as a missing unit-source attribution. Likewise, slot Ring bonuses and the rival side bonus must not be assigned invented card sources.

## Original six checks

| Check | First-attempt outcome |
|---|---|
| Reduced held attacker cue / separate joiner hits | R: all 11 reduced attackers and both 1+4 joint-hit/death sequences read. Normal-motion initiation still has seven Cs listed above |
| Source pulse+mote to every effect (Take links, self Pounce, wait, growth, Gideon gain/expiry) | Partial: Gideon's self ±2 R; subsequent self-Pounce actors visible, but Take source links/growth origin and wait recipient remain C. Opening effects add C/W attribution gaps |
| Dead-unit reward visible landing | C all three combat modes: dead fox/reward seen, destination not established |
| Counterdamage pop anchored to recipient | R causal pairs and all attack deaths; combat021 return amount W (4 read versus actual3) |
| Death fade at home | R for all attack deaths; homecoming opening self-death is not read (W explicit no-death claim) |
| Full hero result / actual rival Health | R totals and final Health in all seven modes; individual combat/rival survivor origins remain C |

The captured evidence verifies these gaps; it does not establish whether an unsampled animation would resolve them during continuous play. Preserve the frozen answers and this score when repairing or recapturing.
