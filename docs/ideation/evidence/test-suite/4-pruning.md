# Test pruning and slimming candidates, 10 Nov

The tests that play whole Hard-bot games caught **0** real regressions in the window, and they take most of the suite's time. These are bot_brain, the field regression, and the real-game tests in balance_2, bot_held, pass3_bots and line_policies. bot_brain alone took 62 s in a one-file run on 7 Nov. That is about a quarter of that day's 223 s tests step. The harness sims run these code paths hundreds of times a day, so the whole-game tests belong in a slow tier. The real catches came from UI and contract tests, and those stay.

**Sources:**
- **Times:** marked (m) where measured from single-file GUT runs in Codex rollouts, 7–9 Nov (`/tmp/claude-1000/prune.7nSA/measured.txt`, made by `/tmp/claude-1000/prune.7nSA/mine.py`). All other times are estimates from the code. One 8-seat Hard game takes about 6–12 s; bot_brain's pinned-game test alone measured 12.2 s.
- **Failures (a/b/c/dev):** `/tmp/claude-1000/runhist.Prqr/per_file.csv`.
- **Re-pin commits:** `/tmp/claude-1000/profile.GzWk/churn2.json`.

| # | File (tests) | Est. s | Fails a/b/c/dev | Guards | Action |
|---|---|---|---|---|---|
|1|core/test_bot_brain `test_a_pinned_bot_plays_its_strategy`|12.2 (m)|file: 0/2/3/6|pinned build buys its tribe (threshold re-pinned in wave2a)|MOVE to slow tier|
|2|bot_brain `test_best_and_naive_profiles_play_full_games`, Hard half|6–8|〃|Hard finishes a game|DELETE the Hard half. Rows 4 and 5 still play Hard games to the end. Keep the naive game|
|3|bot_brain `test_a_seed_replays_exactly`|12–20|〃|determinism|SHRINK to `max_rounds` 8. Row 4 keeps the full-game SHA check|
|4|core/test_field_normal_regression|25–50 (4 Hard games + SHA)|never failed; fixture re-pinned 5× in 36 h|any change to rules or AI behaviour|MOVE to slow tier (merge gate, cloud)|
|5|core/test_balance_2 `test_a_real_game_starts_on_40…`|6–12|0/3/0/4|damage bound per round|MERGE: play one Hard lobby once per run (static cache in a helper), shared with rows 2 and 9|
|6|core/test_bot_held `test_hard_really_swallows_and_flies`|~10 of 13–15 (m)|0/4/0/4|Hard really swallows and flies (archived content)|SHRINK to 12 rounds, as pass3_bots does|
|7|core/test_pass3_bots `test_a_real_hard_lobby…`|~8 of 10.4 (m)|0/0/0/3|Hard uses the pass-3 engines|SHRINK from 12 to 8 rounds|
|8|core/test_line_policies `test_line_lobby_has_real_heroes…`|3–6|0/0/2/2|line bots finish, with heroes and places|MERGE into `test_short_all_line_lobby…` (8 rounds) and move its asserts there|
|9|core/test_full_games|4–8|0/0/0/1|game ends with places 1–8; pool conservation (5.3)|SHRINK from 5 seeds to 2, and skeleton from 2 seeds to 1. Also run the per-turn pool check on row 5's `full_game()` lobby, because `defaults()` is the retired prototype config|
|10|core/test_game_log|2–3|0/0/0/1|log shape|SHRINK: play seed 7 once in `before_all` (5 plays become 1)|
|11|core/test_field_mode `test_two_hundred_deals…`|2–5|0/0/0/1|unique rival trajectories|SHRINK from 200 to 50 deals|
|12|core/test_combat_logging|1–3|never|quiet fights give the same result as logged ones|SHRINK from 32 to 8 seeds|
|13|bot_brain `test_quiet_fight_has_the_same_result`|<0.1|–|same as row 12|DELETE: row 12 checks the same thing on more fights, even at 8 seeds|
|14|core/test_legal_actions `test_nothing_is_legal_once_the_game_is_over`|~0.5|file: 0/1/0/3|nothing is legal after game over|SHRINK: end the game by setting health instead of playing it. Keep the random legal-move game|
|15|ui/test_playthrough `test_scripted_player_reaches_game_over`|12–25 (2 App games with Hard seats)|2/1/0/2|the whole UI journey|KEEP 1 seed in the fast tier; MOVE the 2nd seed to slow|
|16|ui/test_playthrough `test_every_unit_fits_its_tiles…`|3–6 (2,198 tiles)|〃|tile fit|MERGE with test_cards' every-slice-card tile check into one sweep|
|17|ui/test_screens_smoke `test_combat_plays_back_over_time`|2.0 of real waiting|never|playback advances and pauses|SHRINK: step the screen's process by hand instead of waiting|
|18|ui/test_full_game `_game_with_aimed_hero`|1–4|0/0/0/1|aimed hero power|SHRINK: pin the seed instead of trying up to 29 `start_game` calls|
|19|RecruitKit and `Legacy.library()` in `before_each` (~1,100 builds)|22–50 (≤45 ms per build: test_bot_burner did 14 builds in 0.61 s (m))|–|–|SHRINK: parse the library once and deep-copy it for each kit|
|20|core/test_unit_library `test_loads_every_unit_file…`|<0.5|1/8/0/2; re-pinned in 11 of 12 commits|load errors|REWRITE: unit count equals the JSON files in `content/units`, and pool ⊂ all. Drop the 157/25/109 literals; the content step prints them|
|21|ui/test_portraits (count asserts only)|<0.5|2/5/0/2; 7 re-pins|a portrait for every card|REWRITE the counts as pool + created cards, computed. Keep the per-card checks; they made both catches|
|22|ui/test_fixture_port (unit count)|<0.5|1/5/0/2; 6 re-pins|the port lists every unit|REWRITE: compare against the library's size|
|23|core/test_slice_keywords (pool, spell and tribe counts; Acorn values)|<0.5|0/6/0/3; 7 re-pins|slice pool and keywords|REWRITE: take the counts from the library and config, and read card numbers from the card data|
|24|core/test_game_session `test_state_keys…`, `test_unit_view_keys…`|<0.5|2/8/1/2; allow-list edited in 24 commits|the UI state contract|REWRITE: read the list of added keys from `engine.md`, so there is one list, not two. Keeps both catches|
|25|card-number asserts in balance_1, balance_2, belly, fly_south, slice_fairies, bot_held|<0.5 each|b: 1/3/1/2/1/4|mechanic behaviour|REWRITE: take expected values from the card's own numbers. Re-pins like Hex 8→3→1 and larder 26→22 were data edits|
|26|core/test_benchmark_boards (72 boards, 180 pairs)|<0.5|0/2/0/0 (the orchestrator's only gate "catch")|fixture shape|REWRITE: take the counts from the fixture file|
|27|`tests/fixtures/field/normal-9af89c2.json`|0|–|nothing reads it (DECISIONS.md:316)|DELETE|
|28|`test_check_parity.gd` and the gate's parity step|~1 + one Godot launch|–|pool parity|MERGE: drop the gate's separate parity launch|

**Checked and kept:**
- **Caught real regressions:** test_cards (8.6 s (m); 2 catches), test_core_port (3), test_polish (3), test_milestone_b (1), test_phone_layout (2).
- **Kept for other reasons:**
  - test_fight_capture: it guards the capture format the sims rely on.
  - test_wave1_lines: cheap.
  - test_engine_docs: its "re-pin" is writing the doc, which is the point.
  - The `test_mech_*` files: cheap, and slice cards still use the Bristle and Nightshade combat code.

## Expected savings

- **Fast tier** (worker and reviewer runs): about **100–190 s** less per run, out of a 245–340 s tests step:
  - moving rows 1, 4 and 15 to the slow tier: 45–75 s
  - shrinks and merges: 30–65 s
  - library cache: 22–50 s
- **Full suite** (merge gate, cloud): about **55–110 s** less, from the shrinks, merges and cache only.
- **Re-pins:** rows 20–24 account for 32 of the 88 per-file re-pin failures. After the rewrites, adding content stops failing them.

**Caveat:** only 6 files have measured times, and those are from 7–9 Nov; everything else is estimated from the code. Turn on `-gjunit_xml_file` first, and re-rank by measured time before cutting anything.
