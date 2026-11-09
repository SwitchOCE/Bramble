# Cold reader: source and effect attribution

The owner confirmed that Batch 1 asks which card caused an effect and what it did. Knowing
that card's printed rule or qualifying condition belongs in its reader and Batch 4's teaching.
The reviewers received only `cold-reader-packet.md` and the JPEG sheets. They did not receive
source code, event/checkpoint JSON, manifests, the evidence README or expected answers.
They inspected native board crops, with each ×4 run preceding its ×1 match. One reviewer
covered combat_mid and reduced motion; two independent readers covered homecoming and rival.

## First pass

All 57 sheets were inspected: 23 attacks at each speed and 11 attacks under reduced motion.
Every attacking group and death/counterhit was identified. The following is the readers'
image-based account; descriptions use portraits and screen-relative positions, not hidden IDs.

| Fight / attack | Visible exchange and deaths, at ×1 and ×4 |
| --- | --- |
| combat_mid 021 | Lower back-middle green creature hits upper back-middle elf; creature dies to 3 counterhit, elf survives on 1. |
| combat_mid 026 | Upper front-left old man and front-second wolf hit lower front-right badger; badger dies to combined 1+4; old man takes 1, wolf survives. |
| combat_mid 031 | Lower front-left mouse hits upper front-second wolf; mouse dies to 4 counterhit, wolf survives on 2. |
| combat_mid 036 | Upper front-third badger and front-second wolf hit lower front-second fox; badger dies to 5 counterhit, fox survives on 1 after combined 1+4. |
| combat_mid 045 | Lower front-second fox hits upper front-second wolf; both die to 4 and 5 respectively. |
| combat_mid 054 | Upper back-middle elf hits lower front-third fox; elf dies to 5 counterhit, fox survives on 3. |
| combat_mid 058 | Lower front-third fox hits upper front-left old man; old man dies to 5, fox survives on 2. |
| combat_mid 062 | Upper back-right frog group hits lower front-third fox; both die to 5 and 3 respectively. |
| combat_mid 069 | Lower back-left black/red creature hits upper back-left brown portrait; both survive. Brown portrait loses 1; lower creature loses 2. |
| combat_mid 075 | Upper back-left brown portrait hits lower back-left creature; lower creature dies to 4; upper survives on 4. |
| combat_mid 080 | Upper back-left brown portrait hits lower back-right blue-coated animal; upper dies to 5, lower survives on 1. |
| homecoming 020 | Lower front-left moth hits upper front-left armored portrait; armored unit dies to 6, moth survives on 5. |
| homecoming 026 | Upper front-right badger hits lower front-right red bird; badger dies to 18 counterhit, bird survives. |
| homecoming 030 | Lower front-second pale purple portrait hits remaining upper front badger; badger dies to 43, attacker survives unchanged against 0 Attack. |
| homecoming 033 | Upper back-left red-haired portrait hits lower front-second purple portrait; upper dies to 43 counterhit, lower survives on 43. |
| rival 025 | Lower front-left yellow ooze hits upper front-second frog; ooze dies to 16, frog survives on 14. A top-hat mole appears from the ooze's slot. |
| rival 033 | Lower front-second golden badger hits upper frog; badger dies to 16, frog falls from 14 to 8. |
| rival 039 | Lower back-middle blue-scarfed animal hits upper frog; attacker dies to 16, frog survives on 1. |
| rival 043 | Upper front-left green fiddler insect hits lower front-right fox; fox dies to 9, insect survives on 6. |
| rival 047 | Lower front-left top-hat mole hits upper frog; both die to 16 and 2 respectively. |
| rival 054 | Upper front-third pale black-haired portrait hits lower front-third badger; badger dies to 7, attacker survives on 8. |
| rival 058 | Lower back-left purple-coated badger hits upper front-left insect; badger dies to 9, insect survives on 3. |
| rival 062 | Upper front-right old man hits lower back-right fox; fox dies to 6, attacker survives on 3. |

Reduced motion identified the same eleven combat_mid exchanges and deaths. Two Pack hits
showed only the last −4 contribution clearly, even though Health/portrait tracking revealed
the full 1+4 exchange. This prompted one accumulating Pack damage pop; Peck strikes remain
separate. Counterhit bursts sometimes sit close to the target while the attacker is lunging;
the readers assigned their recipients correctly from the changing Health beads.

Four source attributions were genuinely unresolved in the first pass:

- combat_mid 069: the upper back-left brown portrait's Attack gain, 2→4.
- combat_mid 075: that portrait's Attack loss, 4→2.
- rival 025 at ×4: the lower back-middle blue-scarfed animal's apparent 6→7 Attack change.
- rival 025: the released mole's 1→2 Attack gain.

The fixes pulse self-effect sources at the actual stat change, follow the emitted aura-source
IDs when no separate trigger event exists, and finish stat rolls before the next attack starts.
The last change keeps a Start of Combat gain from appearing to happen during the first attack.

## Refreshed-image check

The updated deterministic sheets were rechecked using only the packet and images.
The reviewer reported no remaining source/effect uncertainty in the changed cases:

| Case | Refreshed image observation |
| --- | --- |
| combat_mid 069, ×1/×4/reduced | Upper back-left brown card activates its own effect and gains +2 Attack, 2→4. |
| combat_mid 075, ×1/×4/reduced | The same brown card activates as its Attack returns 4→2; the change is attributable to that card. |
| rival 025, ×1/×4 | Lower back-left purple-coated badger pulses and sends a star to the released mole, whose Attack rises 1→2 with Health unchanged. The blue-scarfed back-middle animal already starts at 7; no gain occurs within this strip. |
| homecoming 020, ×1/×4 | Upper front-left armored card pulses and sends a sparkle to upper back-left red-haired card: +1 Attack, 0→1. Other previously noted reductions now finish before the attack strip begins. |
| Pack 026, ×1/×4/reduced | Upper old man plus wolf cause a readable 5 total damage pop on lower front-right badger, which dies. |
| Pack 036, ×1/×4/reduced | Upper badger plus wolf cause a readable 5 total damage pop on lower front-second fox, whose Health goes 6→1. |

**Result:** the source/effect cold-reader check passes under the owner's clarified criterion.
The original full-fight observations cover all 23 attacks at each speed and all 11 reduced-motion
attacks; the addendum resolves the identified source and overlapping-pop findings. No printed
rule condition or keyword name was supplied as an answer. Those teaching inputs remain below.

## Batch 4 inputs, not added combat narration

The first readers could see many effects without naming their printed conditions. The
teaching/reference work should cover targeting exceptions through a surviving front row,
Pack eligibility, quarry rewards and permanent growth, temporary Counter Attack gains and
expiry, immediate attacks, Belly release and aura gains, acorns and round-damage sparks.
Each card's exact condition remains in its existing reader. This batch adds no rule captions
to combat to answer those teaching questions.
