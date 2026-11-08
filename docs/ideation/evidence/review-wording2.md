# Review: wording pass 2 (`ideation/c-wording2`)

Fresh cloud reviewer, 8 Nov 2026. Target `origin/ideation/main...origin/ideation/c-wording2` (14 commits, 163 files). Scope: the owner's words in `docs/design/owner-notes/2026-11-08e-text-too-wordy.md` (all four sections, read from `ideation/main`) and the plan's rule that the effects don't change. The branch's own docs (`wording-guide.md`, `wording-pass.md`) were treated as proposals.

## Summary

- **Counts:** 1 cut, 1 ask, 10 keeps on scope items. I read every changed text (all 103 content files, 22 keyword reminders, 7 help words, 14 how-to-play pages, the combat-log and recruit-notice strings) and checked 46 of them against mechanics JSON and `src/core`. 44 match the engine. One is a cut and one is an ask.
- **Does it move the owner's problem?** Yes, clearly. Against `ideation/main`, card text goes from median 13 / p90 24 / max 36 words to 11 / 18 / 26. That is now at Battlegrounds and Galaxy levels (BG minions 11 / 16 / 23, Galaxy 11 / 19 / 27). Golden text goes from 15 / 26 / 41 to 12 / 18 / 28. Reminders are about one line each. How-to-play drops from 825 words to 357. Reminder text is off the card and sits on an italic, smaller, muted slip on hover or tap. I re-ran `tools/research/word_counts.py --ref origin/ideation/main` to get these numbers.
- **Effects unchanged:** confirmed. See section 2.
- **Cut:** the Pack reminder says "the unit on its left". The engine joins any unit beside it.
- **Ask:** the how-to-play damage page no longer mentions Last Blow, the round toll, the cap or Last Stand. Nothing explains them before a fight now.

## 1. Meaning drift

Method: for each changed card, I diffed the old and new `text`, `golden_text` and `details` and read them beside the card's `mechanics`. For the claims that were new or riskiest, I read the mechanic script or combat code.

### Cut

| Text | Says | Engine | Fix |
|---|---|---|---|
| Pack reminder (`content/schema/effects.json`) | "When the unit on its left attacks, this joins in, using up its own attack." | `CombatHunt.joiners` takes joiners from `BoardGeometry.adjacent(leader.slot)`, so the leader can be on either side. A Pack unit to the left of a back-row Vaulting Hopkin (which attacks first, per `AttackOrder.early_slots`) joins a leader on its **right**. Brother Wolf's own card ("Pack, with each unit beside this") contradicts the reminder. "Using up its own attack" is correct (`unit.flagged = true`). | "When a unit beside this attacks, this joins in, using up its own attack." Placement advice belongs in a tip, not in the rule. |

### Checked against the engine and kept (46)

- **Units:** Ichneumon Wasp (`parasite.gd` needs `Hit.ATTACK`; return blows are attack hits too, so "damages" holds), Hasty Pudding golden "one beside it" (`adjacent(across)`), Laird of Sett (`lend_quarry` own_across; `bell_buff:false`, so no hidden Attack), Old Brock "next to" (`select: neighbours`) and the new geometry highlight, Young Brock and its details, Gabble Ratchet details "Once per Nest each fight" (`land_bird` key per nest), Cradle Fetch details "Start of Combat text fires" (`become_copy`, script comment), Earwig Mother details (`behind_or_nearest`), Sergeant-at-Conkers details "stays in hand" (`sergeant.gd` returns before `take_ammo`), Vaulting Hopkin "attacks first" (early slots lead the side's order), Hazel Dormouse plain text and its details (`bide_slumber.gd`), Still-Water Heron (`fast`, paid refresh), Bridge Toad details "before Start of Combat buffs" (`bell_top_attack` is set at the bell), Belladonna both versions (`facing`, `across`, golden branch), Jack Daw "steal" (the enemy is debuffed in `jack_daw.gd`), Changeling, Mag Pye, Granny Stir-Up, Elder Ooze, Figgy Duff, Cut-and-Come-Again, Dishwater Nell ("2+ tiers up" is the same as "was 2+ lower"), Queen of Elfland, Stone Soup, Mrs Stork, Mrs Dunnock, Tiddy Mun, Peat King, Madame Ermeline, Alderman Dozey (the cap moved to details), Hedge Witch as Hex 1.
- **Keywords:** Pounce ("next to" means `neighbours`, as in `damage_dealt`), Whistle ("on its turn" matches `whistle.gd`), Bide, Mire, Mired, Quarry plus the Take help word, Hex, Nightshade, Fly South, Nest, Shy, Pass.
- **Spells and heroes:** Harvest Supper (the summon exclusion moved to details), Hiring Fair, Bread from the Back, Stand Behind Me, Triple Reward (the tier 6 case moved to details), Hob Mumblecrust, Dame Farthing.

Pre-existing, not introduced by this branch: Hasty Pudding's normal text says "the enemy across". With `reach: 1`, `hasty.gd` swallows an enemy beside the across slot if that slot is empty. The old text had the same gap.

### Ask

- **How-to-play damage page** (`how_to_play.gd`) now reads only "Win a fight and the loser's hero takes damage. The more of your band still standing, the harder you hit." Last Blow, the round toll and cap, Last Stand and armor are now explained only by combat-log lines after the fact. The owner's principle allows rulings to live "in additional details … elsewhere", but no pre-fight "elsewhere" exists for these. Last Stand changes late-game decisions. Should a details layer or glossary page carry them, or is learning them from the log acceptable?

Minor wording notes (keep): the tribe-bonus help word is now "The tribe icon shows the bonus." That drops "golden does not double it" and "two tribes get both", though the how-to-play page keeps "even ones you get later". "Claims %s for the next shop" drops "if available".

## 2. Effects unchanged

- I parsed all 103 changed content JSON files and compared them with the `text`, `golden_text`, `details`, `golden_details` and the `effects.json` keyword strings removed. **No non-text field changed.**
- The two `src/core` diffs are display strings only: `board_upkeep.gd` RING_TEXT and the Discover shortfall note in `recruit_discover.gd`. The latter also had formatting reflowed.
- `check_units.py` gained `details` and `golden_details` as optional fields and counts their numbers in the golden-doubling check. That is a check change, not a gameplay change.
- `tools/checks/soak.sh 50 918273` gave **0 violations, exit 0**. One no-winner fight was logged (seed 918297, round 6, `no_attacks`), which is an informational line the soak already reports. A fresh container needed `godot --headless --import` first, because without the class cache the first run fails on parse errors.

## 3. Reminder look

The owner asked for reminders that are "italicized and made smaller and on hover … communicated differently visually".

- **PC (1920x1080, `wording2/reminder_1920x1080.jpg`):** the Acorn reminder sits on its own cream slip with a thick muted left edge. It is italic, in a muted colour, at font 25 against the rules' 31, and it opens on hover over an underlined keyword. This meets the request.
- **Phone (1688x780, `wording2/reminder_1688x780.jpg`):** the slip, italic and colour match PC. The reminder can't go below the phone minimum font (31), so the branch makes the details panel's rules text one size larger on phones instead. The reminder is smaller only relative to the rules, and it opens on tap. This is a reasonable reading of "smaller" on a phone. I kept it, but it is a design choice the owner hasn't seen.
- **Tests:** `test_reminder_slip.gd` covers italic, smaller, muted, below the rules, hover on PC, tap on phone, no reminder on the card face, and every keyword being a link. I probed it by setting `DESKTOP_FONT` to 31 (equal to the rules). `test_reminder_is_italic_smaller_and_set_apart_at_both_sizes` failed as it should, and I reverted the change.
- **Display nit (keep, polish later):** on PC the rules box scrolls once the slip is docked under it. In the 1920 shot, the last line ("Details") is clipped behind the scroll edge. The same layout was already on the reminder-hover branch.

## 4. Scope (anything beyond wording and reminder display)

| Change | Verdict | Why |
|---|---|---|
| Reminder slip (`reminder_slip.gd`), keyword links, tap or hover | keep | Directly requested by the owner. |
| 0.3 s hover grace so the pointer can reach the panel (`recruit_screen.gd`) | keep | Without it, hovering a keyword in the panel is impossible on PC. |
| Phone details rules text one size larger | keep | The only way to make the reminder relatively smaller at the phone font floor. Worth showing the owner. |
| `details` and `golden_details` second layer, plus `card_rulings.gd` | keep | The owner's "the player can find out in additional details … elsewhere". |
| `related_slots` handles "next to" and "beside" | keep | Keeps the slot highlight correct for the new words, and matches the engine. |
| Combat log merges the bell into the "Start of Combat" header | keep | Display wording only. |
| Text tool prints a DETAILS section | keep | Same second layer in the text client. |
| `PLAIN_ON_CARD` (Bide, Fast) and `EXACT_WORDS` (Take) | keep | Wording mechanics. They stop "takes damage" from linking. |
| `tools/research/word_counts.py`, the 40-word how-to-play page test | keep | Measures and holds the owner's goal. |
| Damage page content removed | ask | See section 1. |

## 5. Quality gate

`./scripts/check.sh` passed every step: tools, versions, shell, python, content (0 problems), format, lint, import, compile, and tests at **1317/1317**, with gut_strict ok.

## Not done

- I didn't play the build by hand. Phone and PC were judged from the branch's evidence shots and the tests.
- I didn't recheck every combat-log string against its event's semantics, only the changed lines.
- This branch doesn't contain the last 3 `ideation/main` commits (`e383234`, `67cd0b1`, `a092558`). They include owner-note sections 3 and 4, so the merge will need them.

---

# Re-review: pass 3 (`ada2ba0..116b9e0`)

Same scope and method as above. I reviewed only the delta: about 60 card files, 4 keyword reminders (Pass, Ring, Pack, Peck/Both Ends), 5 new help terms (Base, Round toll, Hit cap, Last Blow, Last Stand), the Lady Belladonna rename, Next income, the combat-log effect names, and the on-card tags. I read every changed text and checked 24 against the engine. No non-text field in any content JSON changed; I parsed and compared every changed file with text, details and name removed. The only `src/core` change is the hero view's Last Stand line ("unused."), which is display text; its explanation moved to the Last Stand help term.

## Summary

- **Counts:** 1 cut, 1 ask, 7 keeps.
- **Previous cut (Pack): fixed.** It now reads "When a unit beside this attacks, this joins in, using up its own attack.", which matches `CombatHunt.joiners`.
- **Previous ask (damage rules): resolved, keep.** The damage page now ends with "Rules: Round toll, Hit cap, Last Blow, Last Stand" as reminder links (`wording3/guide_10-*.jpg`). The terms match the engine: `_round_toll()` is `max(1, round - 7)`, i.e. 1, then one more a round from round 9.
- **Previous nit (Details clipped on PC): fixed.** With Next income out of the card rules, "Details" now shows in `wording3/reminder-1920x1080.jpg`.
- **New cut: combat-log effect names can describe the wrong ability.**
- **New ask: Harvest Supper no longer says it reaches units you get later.**

## Cut

**Combat-log effect names** (`CombatLog.effect_words`, and the same logic in `tools/play/play_fight_log.gd`). When a trigger isn't a named keyword, the log now prints the unit's *first* "X: effect" sentence. That is wrong when the trigger is a different ability. I probed it with a headless script against the branch's `trigger_name` and `effect_words`:
- **Hasty Pudding** fires `hasty` both when it swallows and when it lets prisoners go (`hasty.gd`, `on_friendly_death`). The release logs "Hasty Pudding: if this has room, swallow the enemy across."
- **A unit lent Pounce by Old Brock** fires `pounce` but has no Pounce keyword, so `trigger_name` falls back to its name. A pouncing Mrs Burdock logs "Mrs Burdock, Expecting Again: summon a 1/1 Kit behind this."

Before pass 3 these lines read "X's ability goes off.", which was vague but true. Fix:
- Add `pounce` to the named triggers.
- Give Hasty's release its own trigger id (or name it in the log).
- Better still, map effect words by mechanic id, not by "first colon".

A test that runs every trigger id through `trigger_name` against its card text would catch the rest.

## Ask

**Harvest Supper** went from "…gain +1/+1, even ones you get later, up to +3/+3" to "…gain +1/+1 for the rest of the game, up to +3/+3". The engine still applies the bonus to later arrivals (tribe bonus), and that is most of the card's value. The new text reads as "the units you have now". How-to-play page 12 still says "even ones you get later". Should the card keep it, e.g. "Your units of its tribe, now and later, gain +1/+1, up to +3/+3. Once a turn."?

## Checked against the engine (keep)

- **Reminders:**
  - Pass: "the last touching unit to its right, or keeps it" matches how it walks right through touching units.
  - Ring.
  - Peck.
  - Both Ends: "pricks its partner's attackers first" matches `both_ends.gd`. Hedgehog Twin's "+1/+2, pricks for 2" matches its params.
- **Help terms:** Base. Round toll and Last Stand match `game_session.gd`. Hit cap and Last Blow match the earlier guide text.
- **Units:**
  - Lady Belladonna: "the 2 across from the slots in front of this" is `select: facing`, i.e. `in_front_of(anchor)` on the enemy side.
  - Mrs Stork: "Every 6 gold you spend" is `every: 6`.
  - Jill Down-the-Tree: "your next Tier up costs at most 2" is `min(cost, climb_back)`.
  - Brother Wolf: "lets them attack first" is `can_lead`.
  - Reel-Mistress: "next unit in attack order" matches.
  - Wee Wobbly: Drip is 1/1.
  - Charcoal Burner: the text and its `recruit_view` regex were both updated, and the numbers swap correctly.
  - Also checked: Changeling, Elder Ooze, Prima Donna, Tiddy Mun, Jack Daw, Figgy Duff, Alderman Dozey, Cradle Fetch, Great Lump and Mother Goose ("base"), Rainbow Chaser and Cluricaun ("painted slot"), March Hare and A Leg Up ("Tier up").
- **Vocabulary sweep (keep):** "gain gold" became "get gold", "upgrade" became "Tier up", "printed/card/plain" became "base", "band" became "painted slot", and trigger colons are now consistent. These are one word per idea, which suits the owner's "make complicated things simple".

## Scope

| Change | Verdict | Why |
|---|---|---|
| Lady Belladonna rename (was "Belladonna Sprite", the same name as `belladonna_sprite`) | keep | Two cards with one name is a clarity bug. The rename doesn't touch the id or mechanics. |
| Next income off card rules, beside the gold plaque | keep | It was never card text. The 1080 shot shows it's no longer crowding the panel. |
| Damage terms as reminder links on how-to-play | keep | Answers the earlier ask, using the owner's reminder pattern. |
| On-card tags spelled as the trigger words ("Start of Combat", "Start of Turn", "End of Turn") | keep | One word per idea. They wrap to two lines over the portrait at 1920x1080; that's cosmetic. |
| Combat-log effect names | cut | See above. |
| End-turn toll label "Toll 1, cap 9" | keep | Shorter, same numbers. |
| Hero Last Stand line "unused." | keep | Explained by the new Last Stand term. |

## Gate (pass 3)

Pending: `tools/checks/soak.sh 30 5150` and `./scripts/check.sh` on `116b9e0` are still running. I'll update this section when they finish.
