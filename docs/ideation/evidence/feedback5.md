# Round 5 clarity fixes

Branch: `ideation/feedback5`, starting at `578230f`. Reports read from
`origin/ideation/c-pt5-{a,b,c,d,e}:docs/ideation/evidence/pt5-{a,b,c,d,e}.md`.
Wording follows `docs/ideation/wording-guide.md`. No effects, card numbers, targeting,
limits, stat calculations, rewards, or balance were changed.

## Items and before/after lines

1. **Stat causes.** Before: `Rainbow Chaser +2/+0, now …` or four unexplained
   `-1/+0` changes after Cluricaun died. After: `Rainbow Chaser (F1) +2 Attack
   (Jenny Greenteeth (F1)'s aura lost), now …`; each affected unit names
   `Cluricaun (F1)'s aura lost`. Aura gains and changes retain their source too;
   Ring, Rainbow and Hex are named. Before: `Bitter` followed by an unexplained
   delta. After: `-3 Attack (Bitter)`. Ordinary buffs and permanent rewards name
   the source unit's ability. The Chaser recovery in this scenario is the loss
   of Jenny's Attack penalty, rather than new Rainbow growth.
2. **Failed actions.** Before: Wobbly's full-board release/Drip and Posset's
   death damage could disappear silently; Mousewife suppressed repeated failures.
   After: `Wee Wobbly (F1) has no room for Drip.`,
   `…has no room for Field Vole; it stays inside.`,
   `Mrs Posset (F1): no enemy across.`, and `Mousewife: no room for a Mouse`
   in the hero toast, on every failed attempt. Summons, named placements, empty
   Ring slots, bird arrivals and Belly releases report failure; a lost Belly
   release correctly says `it is lost for this fight`. Recruit failures also
   reach the UI and CLI as `No room for Mouse.` Limits, Spill and held-unit
   consumption retain their existing behavior.
3. **Card vocabulary.** Before: `bogs`, `gains mired`, `loses mired`, `parasite`,
   `borrowed attack`, `-- Bell`, and damage `with Effect`. After: `applies Mire`,
   `is Mired`, `is no longer Mired`, `will die after its next attack
   (Ichneumon Wasp)`, `uses the highest enemy Attack for its first attack`,
   `Start of Combat`, and `with its ability`. Audited both `combat_log.gd` and
   `play_fight_log.gd`; side-swap/waiting states use plain effect words as well.
4. **Rings.** Before: `{slot: Ring +1/+1}`. After: `[Slot: Ring +1/+1]` in board and
   Scout text, with no raw dictionary-style braces.
5. **Duplicate names.** Retained and extended the existing slot tracking:
   `Field Vole (F1)` and `Field Vole (F3)` remain distinct in both logs.
   Existing regressions cover movement, summons and transformation too.
6. **Pack roles.** Before: `X attacks Y in a Pack with Z`. After:
   `X attacks Y in a Pack attack; Z joins the attack.` The leader stays first;
   the Pack unit explicitly joins it. Multiple joiners use `join`.
7. **Sale payout.** Before: Rainbow Chaser's tag could say `sell: 1 gold` before
   paying 13. After: `sell: 13 gold` for a bought, normal Chaser with seven
   painted slots. The sale button, details and CLI use the actual base sale
   plus Rainbow payout; the underlying sale rules are unchanged.
8. **Frumenty.** Before: only `Belly 1. This has the text of what's inside it.` After:
   `Borrowed from Hoglet Mother: Bristle 2. …` for a golden held Mother, in
   recruit and combat details and the CLI. Nonborrowed Belly/Fly South/Shy and
   excluded play/sell/home clauses are omitted; limits remain visible.
9. **Enemy keywords.** Before: the play tool glossary only covered cards in
   your current views. After: last-fight enemy units and summons contribute
   `Bristle: …`, `Hex: …`, etc., once each. Enemy-card reminders use the same
   hover/tap slip on PC and phone; that existing GUI path is now tested.
10. **Five text rewrites, after checking the mechanics.**

| Text | Before | After |
| --- | --- | --- |
| Queen of Elfland | `Your other Fairies split their stats.` | `Other Fairies share the destroyed units' stats.` |
| Queen Details | No explanation of `Teind 1/3`. | `Teind counts End of Turns since this was played and resets after 3. Shares base stats and permanent buffs evenly; spare points go in board order.` |
| Brother Wolf | `Pack, with each unit beside this. It lets them attack first.` | `Pack: this joins attacks by units beside it, once each a cycle. Those units lead the attacks.` |
| Changeling | `Start of Combat: trade places with the enemy across. It fights for you until it attacks.` | `Start of Combat: swap sides with the enemy across. Swap back after that enemy attacks once.` |
| Young Brock | `Start of Combat: units beside this get +1 Attack and the enemy across from this as quarry.` | `Start of Combat: units beside this gain +1 Attack. They mark the enemy across from this as quarry.` |
| Pass | `Gives the bonus to the last touching unit to its right, or keeps it. While recruiting, at End of Turn.` | `Gives the bonus to the last touching unit rightward; recruiting waits until End of Turn.` |

Queen still destroys the units behind her (or herself when none), sharing only
base stats and permanent buffs; Teind still increments/reset at the same times.
Wolf joins rather than leads those attacks. Changeling exchanges both side and
slot, then returns after the borrowed enemy's attack. Brock's existing Details
retain the exception for units already holding a quarry. Both normal and golden
faces stay at or below 22 words; Pass is one 16-word reminder sentence.

## Tests

`tests/ui/test_feedback5_log.gd`:

- Item 1: `test_aura_losses_name_cluricaun_on_every_affected_unit_and_gains_name_the_source`,
  `test_rainbow_chaser_attack_recovery_names_jennys_lost_aura_and_hex_names_hex`,
  `test_bitter_shows_stacked_amount_and_regular_stat_changes_name_their_source`.
- Item 2: `test_wobbly_fails_plainly_for_both_drip_and_held_unit_without_spending_a_release`,
  `test_posset_death_reports_no_enemy_across_without_dealing_damage`,
  `test_generic_and_placed_summons_report_no_room_including_empty_rings`,
  `test_failed_belly_release_is_lost_for_the_fight_instead_of_staying_inside`,
  `test_mousewife_no_room_event_reaches_both_log_and_hero_toast`,
  `test_recruit_summons_and_placed_summons_report_every_missing_slot`.
- Item 3: `test_logs_use_mire_mired_and_the_actual_wasp_and_wren_card_words`;
  updated `test_wasp_health_loss_and_death_use_card_words_and_are_not_named_nightshade`
  in `tests/ui/test_engines.gd`.
- Items 5–6: `test_pack_names_the_joiner_and_keeps_same_named_units_distinct`;
  existing `tests/ui/test_review_tribes56_log.gd` covers same-name units after
  movement, summoning and transformation (updated its stat-line expectation).
- Render scenario: `test_screenshot_exchange_contains_mire_bitter_amount_and_full_board_failure`.
- No rules drift: `test_logging_keeps_aura_bitter_and_failed_summon_results_and_random_streams_identical`
  compares logged/quiet fights, rewards, trigger counts and both random streams;
  existing `tests/core/test_combat_logging.gd` covers lethal credit and Last Stand.

`tests/ui/test_feedback5_details.gd`:

- Item 2: `test_recruit_no_room_notice_reaches_the_screen_and_cli`.
- Item 4: `test_rings_print_slot_words_instead_of_dictionary_syntax`.
- Item 8: `test_frumenty_details_show_borrowed_golden_rules_in_both_phases`,
  `test_frumenty_borrowed_rules_exclude_unborrowed_text_and_keep_limits`.
- Item 9: `test_last_fight_enemy_and_summon_keywords_join_the_same_glossary`,
  `test_enemy_only_keyword_opens_the_same_slip_on_pc_and_phone`.

Item 7: `tests/ui/test_feedback5_sales.gd::test_chaser_sale_tag_matches_actual_partial_and_full_payouts`
checks normal/golden, bought/created, and 0/3/7 painted slots against an actual sale.

Item 10: `tests/core/test_feedback5_wording.gd`:
`test_queen_names_destroyed_stats_and_explains_the_live_teind_count`,
`test_brother_wolf_text_names_who_joins_and_who_leads`,
`test_changeling_text_describes_both_sides_and_the_return_after_one_attack`,
`test_young_brock_text_distinguishes_recipients_from_the_enemy_across_brock`,
`test_pass_is_one_short_sentence_with_recruit_timing_and_a_touching_chain`,
`test_rewritten_cards_keep_both_faces_within_the_guide_limit`.

`tests/ui/test_followup_tribes56.gd` now checks every Mousewife fizzle instead of
one per fight, while retaining successful later summons and Spill assertions.

## Rendered shots

Generated by `tests/ui/render_screens.sh feedback5_log`, using the real attack
path in `tests/ui/feedback5_states.gd`, with one Godot process at a time.
Opened and visually inspected both native-size JPEGs:

- [PC, 1920×1080](feedback5/feedback5_log_1920x1080.jpg).
- [Phone, 1688×780](feedback5/feedback5_log_1688x780.jpg).

Both show Mire/Mired in the history, `-3 Attack (Bitter)` and `no room for Drip`
in the current log paragraph, plus the enemy Bitter explanation. Current log
text wraps inside its paper panel at both sizes. Older history scrolls normally.

## Validation

All Godot, gate, soak and render runs after the owner's memory instruction used
`systemd-run --user --scope -p MemoryMax=3G -- …`, sequentially. The required user
systemd bus and local Git metadata needed sandbox escalation; approval was
allowed. No automatic approval review rejected an action. No push was made.

- Ran `./scripts/check.sh` **once**, inside the required scope. Tools, versions,
  shell, Python, content, format, lint, import and compile all passed. The full
  test stage found three fixture/schema failures from emitting empty
  `borrowed_rules` metadata on ordinary units (1,415/1,418 tests passed).
- Fixed the metadata to appear only when populated; no fixture expectations
  were weakened. Rechecked formatting/lint for the two changed files, compiled
  all **407** scripts/resources successfully, and reran the full test stage:
  **1,418/1,418 tests, 19,737 assertions, 135 scripts; strict hook clean**.
  The final log also passes the gate's error scanner and risky-test check.
  Thus every gate check is green on the final implementation; the full gate
  script was not repeated. Logs: `build/feedback5-gate.log`,
  `build/feedback5-compile-final.log`, `build/feedback5-tests-final.log`.
- Independently compared the four rewritten unit JSON files against `578230f`
  after removing wording fields: every other field, including mechanics and
  numbers, is identical.

- Soak: `tools/checks/soak.sh 100 1794136631`, inside the required scope,
  **exit 0, zero violations**. Seeds `1794136631–1794136730` were fresh for this
  run; **100 games, 1,582 rounds, 4,911 fights**, 377.2 seconds. Fight endings:
  4,908 board-empty and 3 no-attacks; no attack/trigger-limit endings.
  Maximum 242 events in one fight. All slice cards fired at least once.
  Logs: `build/feedback5-soak.log` and `build/check/soak.log`.
- Checked the live soak scope: `MemoryMax=3221225472` (3 GiB), observed peak
  83,173,376 bytes at the check. No further memory failures occurred.

Implementation and screenshot commits: `d49ad17`, `96969a4`, `3045f4c`,
`dcf2b62`, `4fc1f2b`, `ef322f4`, `d64d1dc`. This evidence is committed
separately. All ten requested items are covered; no requested work remains.
