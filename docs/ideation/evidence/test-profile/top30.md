# Slowest 30 scripts and tests

From `junit.xml` (GUT alone, commit b5601aa). Suite total by script times: 371.5 s over 180 scripts and 1894 tests.

## Scripts

| # | Script | Tests | Seconds | Share | Slowest test (s) |
|---|---|---|---|---|---|
| 1 | `tests/core/test_bot_brain.gd` | 28 | 60.8 | 16.4% | `test_a_seed_replays_exactly` (30.42) |
| 2 | `tests/core/test_field_normal_regression.gd` | 1 | 51.9 | 14.0% | `test_normal_lobby_matches_complete_games_captured_at_0946909` (51.93) |
| 3 | `tests/ui/test_playthrough.gd` | 3 | 25.8 | 7.0% | `test_scripted_player_reaches_game_over` (21.04) |
| 4 | `tests/core/test_bot_held.gd` | 24 | 24.0 | 6.4% | `test_hard_really_swallows_and_flies` (22.31) |
| 5 | `tests/core/test_placing_bar_probe.gd` | 1 | 22.8 | 6.1% | `test_probe_runs_two_real_paired_boards_with_held_out_fights` (22.82) |
| 6 | `tests/core/test_balance_2.gd` | 26 | 17.4 | 4.7% | `test_a_real_game_starts_on_40_and_damage_is_bounded_by_base_plus_seven` (14.38) |
| 7 | `tests/core/test_pass3_bots.gd` | 20 | 10.7 | 2.9% | `test_a_real_hard_lobby_plays_both_replacement_engines` (10.08) |
| 8 | `tests/core/test_overlay_text.gd` | 4 | 8.6 | 2.3% | `test_every_card_all_overlay_combinations_has_text_for_changed_rule_parameters` (8.51) |
| 9 | `tests/ui/test_polish.gd` | 20 | 8.0 | 2.1% | `test_a_real_games_words_have_no_raw_ids_in_the_log_or_the_tool` (6.77) |
| 10 | `tests/ui/test_big_numbers.gd` | 6 | 6.8 | 1.8% | `test_badges_fit_fixed_sizes_and_recover_font_on_combat_stat_updates` (4.20) |
| 11 | `tests/core/test_field_mode.gd` | 12 | 6.0 | 1.6% | `test_field_game_reaches_a_winner_with_real_eliminations_and_repeats_exactly` (2.79) |
| 12 | `tests/core/test_legal_actions.gd` | 13 | 5.5 | 1.5% | `test_every_legal_action_succeeds_through_a_whole_game` (4.73) |
| 13 | `tests/core/test_birds.gd` | 70 | 5.3 | 1.4% | `test_ratchet_cannot_land_elsewhere_when_the_nest_slot_is_filled` (0.11) |
| 14 | `tests/core/test_wave1_lines.gd` | 10 | 5.0 | 1.3% | `test_each_wave1_line_plays_a_short_real_lobby_without_falling_back` (1.09) |
| 15 | `tests/core/test_line_policies.gd` | 5 | 4.8 | 1.3% | `test_line_lobby_has_real_heroes_pool_damage_and_eliminations` (3.84) |
| 16 | `tests/core/test_oozes.gd` | 58 | 4.6 | 1.2% | `test_cut_and_come_birds_sell_for_good_after_fighting` (0.23) |
| 17 | `tests/core/test_upset_combat.gd` | 15 | 4.2 | 1.1% | `test_native_and_data_answer_positive_controls_and_oversized_negative_control` (1.44) |
| 18 | `tests/core/test_full_games.gd` | 4 | 4.1 | 1.1% | `test_bot_games_end_with_one_winner_1_1_3` (2.81) |
| 19 | `tests/core/test_balance_1.gd` | 37 | 3.9 | 1.1% | `test_a_tier_6_shop_is_mostly_high_tiers` (0.20) |
| 20 | `tests/ui/test_screens_smoke.gd` | 11 | 3.7 | 1.0% | `test_combat_plays_back_over_time` (2.09) |
| 21 | `tests/ui/test_scenarios.gd` | 6 | 2.8 | 0.7% | `test_every_scenario_loads_and_fights_with_a_log_line_per_event` (0.76) |
| 22 | `tests/ui/test_core_port.gd` | 9 | 2.6 | 0.7% | `test_bot_only_game_reaches_game_over_screen` (1.64) |
| 23 | `tests/core/test_scale_review.gd` | 12 | 2.5 | 0.7% | `test_each_lever_is_alone_opt_in_and_game_reuses_one_private_library` (0.85) |
| 24 | `tests/core/test_pass1_fixes.gd` | 20 | 2.4 | 0.6% | `test_take_growth_survives_a_simultaneous_trade_for_nip_and_lutra` (0.46) |
| 25 | `tests/core/test_fly_south.gd` | 30 | 2.4 | 0.6% | `test_a_golden_auto_boarded_with_a_full_hand_must_fight_before_flying` (0.25) |
| 26 | `tests/core/test_fight_capture.gd` | 3 | 2.3 | 0.6% | `test_json_captures_reproduce_every_fight_in_a_real_lobby` (2.17) |
| 27 | `tests/ui/test_phone_layout.gd` | 11 | 2.1 | 0.6% | `test_late_scout_shop_keeps_targets_and_clears_the_hand_at_both_sizes` (0.46) |
| 28 | `tests/ui/test_cards.gd` | 16 | 2.1 | 0.6% | `test_every_slice_card_keeps_its_portrait_and_readable_rules_or_chip_on_desktop` (0.85) |
| 29 | `tests/core/test_slice_keywords.gd` | 26 | 2.0 | 0.5% | `test_full_game_pool_keeps_shops_varied_and_uses_only_the_slice` (0.17) |
| 30 | `tests/ui/test_lane_display.gd` | 8 | 1.9 | 0.5% | `test_phone_scout_projection_uses_the_named_slots_and_keeps_shop_cost_visible` (0.41) |

## Tests

| # | Test | Script | Seconds |
|---|---|---|---|
| 1 | `test_normal_lobby_matches_complete_games_captured_at_0946909` | `tests/core/test_field_normal_regression.gd` | 51.93 |
| 2 | `test_a_seed_replays_exactly` | `tests/core/test_bot_brain.gd` | 30.42 |
| 3 | `test_probe_runs_two_real_paired_boards_with_held_out_fights` | `tests/core/test_placing_bar_probe.gd` | 22.82 |
| 4 | `test_hard_really_swallows_and_flies` | `tests/core/test_bot_held.gd` | 22.31 |
| 5 | `test_scripted_player_reaches_game_over` | `tests/ui/test_playthrough.gd` | 21.04 |
| 6 | `test_best_and_naive_profiles_play_full_games` | `tests/core/test_bot_brain.gd` | 15.12 |
| 7 | `test_a_real_game_starts_on_40_and_damage_is_bounded_by_base_plus_seven` | `tests/core/test_balance_2.gd` | 14.38 |
| 8 | `test_a_pinned_bot_plays_its_strategy` | `tests/core/test_bot_brain.gd` | 14.25 |
| 9 | `test_a_real_hard_lobby_plays_both_replacement_engines` | `tests/core/test_pass3_bots.gd` | 10.08 |
| 10 | `test_every_card_all_overlay_combinations_has_text_for_changed_rule_parameters` | `tests/core/test_overlay_text.gd` | 8.51 |
| 11 | `test_a_real_games_words_have_no_raw_ids_in_the_log_or_the_tool` | `tests/ui/test_polish.gd` | 6.77 |
| 12 | `test_every_legal_action_succeeds_through_a_whole_game` | `tests/core/test_legal_actions.gd` | 4.73 |
| 13 | `test_badges_fit_fixed_sizes_and_recover_font_on_combat_stat_updates` | `tests/ui/test_big_numbers.gd` | 4.20 |
| 14 | `test_every_unit_fits_its_tiles_and_keeps_its_full_text` | `tests/ui/test_playthrough.gd` | 3.84 |
| 15 | `test_line_lobby_has_real_heroes_pool_damage_and_eliminations` | `tests/core/test_line_policies.gd` | 3.84 |
| 16 | `test_bot_games_end_with_one_winner_1_1_3` | `tests/core/test_full_games.gd` | 2.81 |
| 17 | `test_field_game_reaches_a_winner_with_real_eliminations_and_repeats_exactly` | `tests/core/test_field_mode.gd` | 2.79 |
| 18 | `test_json_captures_reproduce_every_fight_in_a_real_lobby` | `tests/core/test_fight_capture.gd` | 2.17 |
| 19 | `test_combat_plays_back_over_time` | `tests/ui/test_screens_smoke.gd` | 2.09 |
| 20 | `test_bot_only_game_reaches_game_over_screen` | `tests/ui/test_core_port.gd` | 1.64 |
| 21 | `test_phone_recruit_boards_fit_at_all_requested_digit_counts_and_tap_shows_exact_stats` | `tests/ui/test_big_numbers.gd` | 1.46 |
| 22 | `test_native_and_data_answer_positive_controls_and_oversized_negative_control` | `tests/core/test_upset_combat.gd` | 1.44 |
| 23 | `test_golden_changeling_fires_once_in_both_start_orders` | `tests/core/test_round3_rules.gd` | 1.40 |
| 24 | `test_a_very_long_sentence_stays_inside_the_note` | `tests/ui/test_log_note.gd` | 1.11 |
| 25 | `test_phone_combat_boards_fit_and_one_tap_uses_current_exact_health` | `tests/ui/test_big_numbers.gd` | 1.11 |
| 26 | `test_each_wave1_line_plays_a_short_real_lobby_without_falling_back` | `tests/core/test_wave1_lines.gd` | 1.09 |
| 27 | `test_field_save_keeps_mode_and_replays_actions` | `tests/core/test_field_launch.gd` | 1.03 |
| 28 | `test_short_all_line_lobby_with_both_caps_disabled` | `tests/core/test_line_policies.gd` | 0.96 |
| 29 | `test_game_over_screen_lays_out_cleanly` | `tests/ui/test_playthrough.gd` | 0.95 |
| 30 | `test_same_seed_same_game_determinism` | `tests/core/test_full_games.gd` | 0.88 |

## Distribution of test times

median 0.033 s, min 0.000 s, p90 0.156 s, max 51.93 s. Tests under 0.15 s: 1697 (65 s). Tests over 1 s: 27 (254 s). Top 15 scripts: 263 s (71%).
