# Second-reshoot cold-reader score

Frozen second repair assessment of images committed in `dfffd6dc`. Retained before the next fixes/reshoot.

Three new independent readers read only the packet and their assigned JPEGs, each mode separately. Reports were frozen before release to this scorer. Truth was refreshed from the committed manifests before reading the reports. Scoring uses the 57 attacks, 85 opening focus sheets and 14 overview/result sheets (156 sheets, 1,248 sampled frames), with `events`, `event_ticks` and capture intervals. Opening focus continuations are read with their overview and adjacent focuses. No implementation, README or earlier review was opened; no Godot was run.

**R** right; **C** can't tell/not established; **W** wrong. The test is which card caused what visible change, not naming a rule or its condition. Correct paired static source/target symbols count in reduced motion; absence of a moving line alone is not failure. For a joint attack, both contributing cards and their visible hits count; primary/helper order is not an extra effect. No final Health is inferred by subtraction.

## Per-run result

| Run | Attacker / contributing cards | Damage pairs / lethal cause | Other card-source effects | Hero result |
|---|---|---|---|---|
| combat_mid ×1 | 11 R | All R causally; 054 return number W | Opening R; wait self-action C | −3 and 34→31 R; survivor and hero/system origins R |
| combat_mid ×4 | 11 R | All R causally | Opening R; wait self-action C | −3 and 34→31 R; survivor and hero/system origins R |
| combat_mid reduce | 11 hitter sets R; 026 individual hit mapping C | Reciprocal pairs R; individual 026 amount attribution C | Branch renewal, Take links and +2 source C; pause cue R; details below | −3 and 34→31 R; individual origins C |
| homecoming ×1 | 4 R | All attack deaths R | Opening paths R; self-replacement observed, death classification W | Six card origins and−6 R; final hero Health C |
| homecoming ×4 | 4 R | All attack deaths R | Same as ×1 | Six card origins and−6 R; final hero Health C |
| rival ×1 | 8 R | All R | Neighbour quarry assignment source C; other effects R; alleged B3 change W | Hero+four survivor origins,−7 and 30→23 R |
| rival ×4 | 8 R | All R | Card paths R; alleged B3 change W | Hero+four survivor origins,−7 and 30→23 R |

Totals: **all 57 attacker/contributing-card sets R**, including both partners in joint attacks. All 57 attack damage pairs and all 62 attack-caused unit deaths have the correct causal opponents; reduced026 retains an individual hitter-to-number mapping gap. This is a partial source/effect result, not an unconditional pass.

## Every attack/mode

All death causes below are R. A dying attacker is killed by the named defender's return hit; mutual means each kills the other. `+` is an actual additional hitter. Modes appear ×1 / ×4 / reduce where applicable.

| combat_mid event | Truth and death | Attacker/contributor grade |
|---|---|---|
| 021 | bottom B2→top B2; bottom B2 dies | R/R/R |
| 026 | top F1 + F2→bottom F4; bottom F4 dies | R/R/R (reduce individual number mapping C) |
| 031 | bottom F1→top F2; bottom F1 dies | R/R/R |
| 036 | top F3 + F2→bottom F2; top F3 dies | R/R/R |
| 045 | bottom F2→top F2; mutual death | R/R/R |
| 054 | top B2→bottom F3; top B2 dies | R/R/R |
| 058 | bottom F3→top F1; top F1 dies | R/R/R |
| 062 | top B3→bottom F3; mutual death | R/R/R |
| 069 | bottom B1→top B1; neither dies | R/R/R |
| 075 | top B1→bottom B1; bottom B1 dies | R/R/R |
| 080 | top B1→bottom B3; top B1 dies | R/R/R |

Combat036 ×4 f1–3 (ticks667/693/719) show both partners highlighted, the wolf moving and badger dying; both contributors and the 1+4 target hits are read. The reader cannot establish primary versus helper, which does not fail the source/effect test. Reduced026/036 likewise identify both highlighted contributing cards and the separate1/4 hits. Reduced026 explicitly cannot individually match those numbers to the two cards (C numeric mapping); no missing leader-role label or attack-order explanation is required.

Combat054 ×1/reduce raw reads the return pop as−1; manifest event56 is 5 damage from bottom F3 to top B2. This value is W even though pair/death are R. At ×4 the reader sees−5 then a later−1 display. Exact return values at036/062 and reduced021 are also partly obscured in the raw answers (C numeric detail). No extra damage event corresponds to the later−1 display in080 ×4; the actual return amount is 5. These are display/reader-number ambiguities, not new causal sources.

| homecoming event | Truth and death | Attacker ×1/×4 |
|---|---|---|
| 020 | bottom F1→top F1; top F1 dies | R/R |
| 026 | top F3→bottom F4; top F3 dies | R/R |
| 030 | bottom F2 copy→top F2; top F2 dies | R/R |
| 033 | top B1→bottom F2 copy; top B1 dies | R/R |

| rival event | Truth and death | Attacker ×1/×4 |
|---|---|---|
| 025 | bottom F1→top F2; bottom F1 dies | R/R |
| 033 | bottom F2→top F2; bottom F2 dies | R/R |
| 039 | bottom B2→top F2; bottom B2 dies | R/R |
| 043 | top F1→bottom F4; bottom F4 dies | R/R |
| 047 | bottom F1 summon→top F2; mutual death | R/R |
| 054 | top F3→bottom F3; bottom F3 dies | R/R |
| 058 | bottom B1→top F1; bottom B1 dies | R/R |
| 062 | top F4→bottom B3; bottom B3 dies | R/R |

## Other card sources and landings

Grades below describe source-to-change attribution, not just spotting a flashing portrait.

| Fight / packet | ×1 | ×4 | Reduce |
|---|---|---|---|
| Combat opening003/004/005: bottom F2/F3/B3→opposing F2/F3/B3 paw marks | R | R | R: correct paired source/target symbols identified, despite reader's no-line caveat |
| Combat006/008/011/012: top B1→bottom B1, top B2→bottom B2 patch/status cues | R | R | R static pairs; no numeric change required |
| Combat010: top F3→top F2 hunter and bottom F3 quarry links | R | R | C renewal/link: raw cannot distinguish renewed existing marks, f1–8 ticks352–387 |
| Combat013: top F3→top F2 +1 Attack | R | R | R paired green pulse/badge and3→4 |
| Combat014: bottom B1 pulse with no target/no changed card | R observed absence | R observed absence | R observed absence; no missing landing invented |
| Combat016: bottom B3 self2→5 Attack | R | R | R self pulse and badge change; no incoming card required |
| Combat019: top B2→bottom B2 −1 Attack | R | R | R paired red source/badge; settled4 in021 |
| Combat021/031 then026/036: top F2 pulse then joins attack | R | R | Joint hitter set R; 026 individual number mapping C as above |
| Combat036: top F3 quarry→bottom F3 hunter, self+1/+1, acorn landing off bottom hero | R | R | C directed relation; gain/changed card and two acorn locations observed |
| Combat045: dead bottom F2 takes top F2; dead self receives+1/+1; acorn off hero | R | R | C relation/landing; dead fox bonus badges seen but directed source/reward connection uncertain |
| Combat045 wait: top B1 self pause/wait action | C effect (unspecified pulse) | C effect (unspecified pulse/arrow) | R visible top B1 pause-like double-stroke cue; no other recipient required |
| Combat062: top B3 quarry→bottom B3 hunter→off-hero acorn | R | R | C directed relation/landing; no stat gain event is expected here |
| Combat069: top B1 targets bottom B1 and self2→4 Attack | R | R | C source: reader offers bottom B1 as possible cause of top B1 gain |
| Combat075: top B1 self4→2 expiry | R | R | R self pulse/badge change; explaining why it expires is not required |

Combat036 reduced f3–8 (1167 Take;1230 stats) and062 f3–8 (1805 Take) give tokens, paired flashes and off-hero acorns, but the reader explicitly cannot assign the directed relationship. In045 reduced f3–8, reward1450 and wait1486 share the interval; reward relationships remain uncertain, but the reader explicitly identifies top B1's pause-like double-stroke symbol (R self pause). Normal045 f4–8 show top B1's pulse/arrow without recognizing its waiting action (C effect). At normal ×1 wait1554; ×4 wait911. Event53's bottom B1 target is the card waited for (condition), not a separate effect recipient, so naming it is not required. Normal069/075 self gain/expiry is successfully described without naming conditions.

The dead reward has `source=target=2` in event52: **the dead bottom F2**, not a surviving recipient. Normal readers' floating dead fox/+1/+1 and acorn endpoint are therefore R; requiring a living stat increase would be an incorrect scoring condition. An unlabelled gold amount does not erase the visible acorn landing.

| Homecoming packet, both speeds | Grade |
|---|---|
|003/004/005 top F2→F1/F3→bottom F2; top F3→F2→bottom F3 paw relays | R using focus continuations+overview |
|006/008 top F2→F1/F3 and F3→F2 +1 Attack | R |
|009 bottom F2 self pulse→fade/shrink→matching bottom B1 portrait replacement | Visible self-replacement sequence R; no B1 source arrow required (`source=2`, copied portrait5). Raw explicitly classifies it as transformation/replacement, not death: W event/death classification |
|009/013 new F2 39/40→43/44 Ring gain | Landing R; card source N/A (slot Ring, `source=null`). No requirement to identify another card |
|013/015 bottom F2→top F2, bottom B1→top B1 Attack reductions | R |
|017 bottom B3→bottom B1 blue outline/shield | R; crossing B2 correctly excluded |
|020 top F1→top B1 +1 Attack | R |

Homecoming009 f1–8 captures own pulse, fade and replacement: self-death tick398/summon434 at ×1;219/237 at ×4. The raw answer does not identify a separate killer, correctly observes that no hit number exists, but says no opening death. The manifest records self-death before summon; retain that classification discrepancy without pretending another card caused the observed replacement.

| Rival packet | ×1 / ×4 |
|---|---|
|003 bottom F4→top F4 mark | R/R |
|004/010 top F2→bottom F2 patch/status | R/R: the renewed landing need not name a distinct rule |
|006/007/008 neighbour quarry relays: bottom F2 assigns F1/F3→top F2; bottom F3 assigns F2→top F3 | C source, R endpoints at ×1; R/R at ×4. ×1 describes short links between the correct neighbours but does not establish which neighbour originated each assignment; ×4 explicitly gives direction |
|009 bottom B1→B2→top B1 mark | R/R |
|011/013 bottom F2→F1/F3 +1; F3→F2 +1 | R/R |
|020 top B1→bottom B1 purple status | R/R; no condition/secondary damage required |
|022 bottom B2 self4→7 Attack | R/R |
|025 dead bottom F1→new F1; bottom B1 aura→new F1 +1 Attack | R/R |
|025/033 self-Pounce cue→next attack by F2/B2 against top F2 | R/R: source/path and subsequent initiating actor read |
|047 bottom F3↔dead top F2→off-hero acorn | R/R visible route/landing; numeric benefit not required |

Rival033/039 raw additionally claims bottom B3 changes portrait and4/4→4/6 then reverts. **W extra effect at both speeds:** no such event exists; inspecting033's eight frames shows bottom B3 remaining fox4/4 while bottom B2 pulses. This unsupported reader observation does not establish a real transformation or a missing implementation source. It should not be repaired by inventing a source event.

## Hero/system packets and final Health

| Packet | Card origins | Hero/system origin | Landing/damage | Final Health |
|---|---|---|---|---|
| Combat ×1/×4 | bottom B3 R | bottom hero/base R visually; no source card for base 2 | top hero−3 R |34→31 R; bottom38 R |
| Combat reduce | bottom B3 star identified, contribution link C | bottom hero star identified, contribution link C | top hero−3 R |34→31 R; bottom38 R |
| Homecoming ×1/×4 | F1/F3/F4/B1/B2/B3 R; copied F2 correctly sends no star | base 0, no extra card required | top hero−6 R | top final34 **C**; bottom40 R |
| Rival ×1/×4 | top F1/F3/F4/B1 R | top hero/base R; no card source for base 3 | bottom hero−7 R |30→23 R; top40 R |

Homecoming result f3–8 converge six paths over the top hero/Health area. Both raw reports explicitly cannot read its final numeral; the manifests say34. Displayed−6 from40 does not substitute for reading the requested final Health. Combat reduced result has separate survivor/hero stars but the reader explicitly cannot establish the two contributions; retain C without requiring motion itself.

Rival's opening014 +4/+4 is a **side/hero system bonus**, not top B1's card ability: event14 `side_trigger`, events15–19 `source=null`. Both readers now correctly see top hero→all five recipients. Card-source grade N/A, hero origin/landings R. Homecoming Early Spoils event37 is system+1 to side0, no card source; its reward landing is not reported/readable here (C coverage, card origin N/A). Initial combat_start boards/slot bonuses likewise have no replayed card-source event to attribute; initial setup is R observed, source N/A. Ring gain on the copied unit is separately accounted for above.

## Original six outcomes

| Check | Second-reshoot outcome |
|---|---|
| Held attacker cue / separate joiner hits | All 57 attacker/contributor sets R and both joint hits visible; reduced026 individual number mapping C. Primary/helper order is not required |
| Source pulse→each effect (Take, Pounce, wait, growth, Gideon gain/expiry) | Normal directed effects largely R; normal wait self-action C, reduced pause cue R; reduced Take/growth relationships and Gideon gain source C; expiry R without requiring condition knowledge |
| Dead-unit reward visible landing | R normal: correct dead-self reward+off-hero acorn; reduced directed landing C |
| Counterdamage pop anchored to unit | All causal recipients/deaths R; some exact values C/W, especially054 return5 read as1 |
| Death fade at home | All 62 attack deaths causally R; homecoming self-replacement read but explicit no-opening-death classification W |
| Full hero result / actual rival Health | Rival30→23 R both; combat34→31 R all; homecoming final34 C both despite readable−6 |

This score preserves reported uncertainty and separates it from verified static cues, no-card system events and unsupported extra observations. Continuous-play readability beyond these captured intervals was not tested.
