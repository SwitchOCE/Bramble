import json
T3, T23, T6 = 1/3, 2/3, 1/6
rows = [
 # Birds
 ("birds_homecoming_multiplier", 2.25, 2.5), ("birds_golden_homecoming_multiplier", 3.0, 3.0),
 ("birds_cuckoo_share", 0.125, 0.15), ("birds_golden_egg_multiplier", 2.0, 3.0), ("birds_stork_gold_step", 6, 5),
 ("birds_chiffchaff_gain", 3, 4), ("birds_redbreast_share", T6, T6), ("birds_jack_daw_share", 0.25, 0.25),
 ("birds_jack_daw_permanent", True, True), ("birds_stork_recalls", 1, 1), ("birds_trip_turns", 2, 2),
 ("birds_swallow_trip_turns", 1, 1), ("birds_golden_tern_trip_turns", 1, 1), ("birds_golden_egg_enabled", True, True),
 ("birds_goose_eggs", 1, 1), ("birds_lump_multiplier", 1.0, 1.0), ("birds_ratchet_multiplier", 1.0, 1.0),
 ("birds_redwing_share", 0.5, 0.5), ("birds_redwing_targets", 2, 2), ("birds_tom_tit_reduction", 50, 50),
 ("birds_tom_tit_targets", 1, 1), ("birds_dunnock_turns", 1, 1), ("birds_dunnock_targets", 1, 1),
 ("birds_whistlers_loss_share", 0.5, 0.5), ("birds_whistlers_flock_count", 7, 7), ("birds_swallow_gold", 1, 1),
 ("birds_jay_acorns", 1, 1),
 # Fairies
 ("fairies_ring_growth", 2.0, 4.0), ("fairies_lob_turns", 2, 2), ("fairies_nan_rings", 2, 2), ("fairies_lob_growth", 1.0, 3.0),
 ("fairies_silky_growth", 1.0, 2.0), ("fairies_fetch_share", 1.0, 1.0), ("fairies_monarch_period", 2, 2),
 ("fairies_monarch_multiplier", 2.0, 3.0), ("fairies_golden_monarch_multiplier", 3.0, 4.0), ("fairies_annis_rings", 1, 1),
 ("fairies_annis_sale", True, True), ("fairies_queen_rings", 1, 1), ("fairies_queen_period", 1, 1), ("fairies_sally_rings", 1, 1),
 ("fairies_initial_ring_size", 1.0, 1.0), ("fairies_chaser_gold", 1, 1), ("fairies_reel_moves", 2, 2),
 ("fairies_wisp_attack", 1, 1), ("fairies_wisp_health", 1, 1), ("fairies_witch_ring_share", 1.0, 1.0),
 ("fairies_hob_shield_targets", 1, 1), ("fairies_belladonna_targets", 1, 1), ("fairies_changeling_steals", 1, 1),
 ("fairies_shy_thank_gold", 2, 2),
 # Bog
 ("bog_soak_keep", 2, 3), ("bog_golden_soak_keep", 4, 6), ("bog_nan_share", 0.5, 0.5), ("bog_golden_nan_share", 1.0, 1.0),
 ("bog_ranocchio_share", 0.5, 0.5), ("bog_golden_ranocchio_share", 1.0, 1.0), ("bog_tiddy_share", 0.5, 0.5),
 ("bog_golden_tiddy_share", 1.0, 1.0), ("bog_bitter_share", 0.25, 0.25), ("bog_bitter_round_up", True, True),
 ("bog_soak_mired_only", True, True), ("bog_kiss_period", 3, 3), ("bog_frog_multiplier", 2.0, 2.0),
 ("bog_golden_frog_multiplier", 3.0, 3.0), ("bog_kisses_per_fight", 1, 1), ("bog_frog_doubles_per_turn", 1, 1),
 ("bog_hopkin_share", 0.25, 0.25), ("bog_bufo_halvings", 1, 1), ("bog_gideon_hitbacks", 1, 1), ("bog_sal_toll_multiplier", 1.0, 1.0),
 ("bog_cutter_gold", 1, 1), ("bog_pretender_gold", 1, 1), ("bog_king_peatlings", 2, 2), ("bog_peatling_stat_share", 1.0, 1.0),
 ("bog_prima_donna_patches", 3, 3), ("bog_chorus_lends", 2, 2), ("bog_lantern_lures", 1, 1), ("bog_jenny_pulls", 1, 1),
 ("bog_capstone_gain_toll", False, False),
 # Hunters
 ("hunters_nip_share", T23, 0.75), ("hunters_sable_share", T23, 0.75), ("hunters_lutra_share", T23, 0.75),
 ("hunters_glutton_share", T23, 1.0), ("hunters_lodger_share", T23, 1.0), ("hunters_wick_share", T3, 0.5),
 ("hunters_grizel_share", T3, 0.5), ("hunters_pelt_share", T3, 0.5), ("hunters_russet_buff_share", T23, 0.75),
 ("hunters_golden_russet_buff_share", 1.0, 1.0), ("hunters_ermeline_pelts", 1, 1), ("hunters_golden_ermeline_pelts", 2, 2),
 ("hunters_laird_multiplier", 2, 2), ("hunters_golden_laird_multiplier", 3, 3), ("hunters_golden_take_multiplier", 2.0, 2.0),
 ("hunters_sable_strike", 1.0, 1.0), ("hunters_golden_sable_strike", 2.0, 2.0), ("hunters_agnes_hit_back", 0.5, 0.5),
 ("hunters_golden_agnes_hit_back", 0.25, 0.25), ("hunters_isegrim_health_cut", 0, 0), ("hunters_russet_copies", 1, 1),
 ("hunters_lane_bard_gold", 1, 1), ("hunters_golden_lane_bard_gold", 2, 2), ("hunters_lane_bard_triggers", 2, 2),
 ("hunters_take_floor", 1, 1), ("hunters_young_brock_share", 1.0, 1.0), ("hunters_trophies_after_fight", True, True),
 # Oozes
 ("oozes_soup_share", 0.125, T6), ("oozes_elder_share", 0.5, 0.75), ("oozes_golden_elder_multiplier", 2.0, 2.0),
 ("oozes_aspic_bonus", 0.5, 0.5), ("oozes_golden_aspic_multiplier", 2.0, 2.0), ("oozes_nell_meals", 1, 1),
 ("oozes_bubble_belly", 1, 1), ("oozes_dollop_belly", 1, 1), ("oozes_dollop_discount", 1, 1), ("oozes_slice_share", 0.2, 0.2),
 ("oozes_slice_count", 1, 1), ("oozes_hasty_share", 0.2, 0.2), ("oozes_hasty_swallows", 1, 1), ("oozes_hasty_release_deaths", 3, 3),
 ("oozes_golden_soup_reads", 2, 2), ("oozes_granny_attack_multiplier", 1.0, 1.0), ("oozes_posset_loss_share", 0.5, 0.5),
 ("oozes_moss_golden_reduction", 25, 25), ("oozes_bubble_splits", 1, 1), ("oozes_pie_gold", 1, 1), ("oozes_wobbly_drip", 1, 1),
 ("oozes_frumenty_meals", 1, 1), ("oozes_syllabub_fires", 1, 1),
 # Hedgerow
 ("hedgerow_dozey_wake_multiplier", 2.0, 3.0), ("hedgerow_golden_dozey_wake_multiplier", 2.0, 3.0), ("hedgerow_dozey_period", 3, 3),
 ("hedgerow_dozey_food_per_gold", 2.0, 2.0), ("hedgerow_partner_period", 3, 3), ("hedgerow_partner_acorns", 2, 2),
 ("hedgerow_crumb_pass", 1, 1), ("hedgerow_crumb_sell_share", 1.0, 1.0), ("hedgerow_clover_share", 1.0, 1.0), ("hedgerow_pym_pass", 3, 3),
 ("hedgerow_sorrel_summons", 1, 1), ("hedgerow_burdock_kits", 1, 1), ("hedgerow_mallow_multiplier", 2.0, 3.0), ("hedgerow_mallow_targets", 2, 2),
 ("hedgerow_urchin_bristle", 2, 2), ("hedgerow_urchin_hunker_targets", 1, 1), ("hedgerow_sergeant_share_per_gold", 0.1, 0.1),
 ("hedgerow_sergeant_throws", 1, 1), ("hedgerow_beadle_pass", 2, 2), ("hedgerow_treasurer_per_gold", 1.0, 2.0),
 ("hedgerow_hayward_per_gold", 1.0, 1.0), ("hedgerow_committee_share", 0.25, 0.25), ("hedgerow_lollop_share", 0.1, 0.1),
 ("hedgerow_mast_gold_step", 5, 5), ("hedgerow_mast_cap", 5, 5), ("hedgerow_larder_gold", [1, 5, 16], [1, 5, 16]),
 # Shared
 ("scale_hero_spell_percent", 10, 20), ("pass3_loop_guards", True, True),
]
keys = [r[0] for r in rows]
assert len(keys) == len(set(keys)), "duplicate"
B = {k: b for k, b, c in rows}; C = {k: c for k, b, c in rows}
s = json.dumps({"B": B, "C": C}, indent=2)
json.loads(s)
open("presets.json", "w").write(s)
print(len(keys), "keys")
# check C >= B except known generous-lower keys
lower_ok = {"birds_stork_gold_step", "hunters_agnes_hit_back", "hunters_golden_agnes_hit_back"}
for k, b, c in rows:
    if isinstance(b, (int, float)) and not isinstance(b, bool) and c < b and k not in lower_ok:
        print("C below B:", k, b, c)
