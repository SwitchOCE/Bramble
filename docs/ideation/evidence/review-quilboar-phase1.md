**Scope review: `ideation/quilboar` cc6d26d5..4d23628e** (11 commits, 64 files, +2,957 / −48)

The brief supplied all three scope sources: the owner's words, the plan, and the target range. I read committed revisions only and ran no Godot. I relied on the worker's gate run (1,942 Godot tests and 77 Python tests, all passing, in `phase1.md`).

**Counts:** 22 keep, 0 cut, 1 simplify, 3 ask.

**Does it move the original problem (a reference to judge our scale against)?** Partway. The reference is built and plays: a test runs an 8-seat lobby with one reference seat for three rounds. Nothing has been measured yet. Whether its numbers can be trusted depends on H1's accounting and fidelity checks.

**Clear to merge into ideation/main behind the flag?** Yes. There are no cuts, and with the flag off the game behaves exactly as before: the historical complete-game fixture passes without re-pinning. None of the asks blocks the merge.

**Ask items**
1. **The bot departs from §9 in three ways.**
   - It refreshes at most 4 times a turn (`bot_quilboar.gd:87`). §9 limits cycled units to 4 a turn, not refreshes.
   - It always casts Gem Days first, so Trailblazer's "both" lands on a Gem Day instead of Foodie.
   - The 2-flex-unit cap isn't built.

   The refresh cap could roughly halve cycling, and paper puts cycling at ×1.6 of the board at R15.
2. **`tools/sim/quilboar_line.json`** is the §9 harness profile, not Phase 1. Nothing reads it, and the bot hardcodes the same lists. Who will load it, and when?
3. **`rates.json` stores dials no code reads:** the Phase 2 dials (`geomant_gems`, `bandit_gems`, `roogug_every`, `brigand_barrage_casts`), `gem_round`, `refiner_per_fight` and the loop-guard block. They copy §6's JSON exactly. Confirm Phase 2 will read them.

**Inventory and verdicts** (the pr-report inventory is folded into this table to save space)

| # | Item | Where | Used by | Stated reason | Verdict |
|---|---|---|---|---|---|
| 1 | `reference_quilboar` false; preset "B" | game_config.gd:39-40 | loader, bots, combat | §8.1 | keep |
| 2 | 13 units, 3 spells, rates | content/reference/quilboar/ | loader | §8.1, §4 | keep |
| 3 | Loader; overlay drops `qb_*` when off | reference_quilboar.gd `configure`; scale_overlay.gd:17-38 | session, rules | §8.1 | keep |
| 4 | Editor-build requirement | reference_quilboar.gd:9-13 | every gate | none stated (phase1.md) | keep: enforces "never in a player build" |
| 5 | Export exclusion | export_presets.cfg ×4 | exports | spec header | keep |
| 6 | Gem size in halves, rounded up, chip | player_state.gd:17-20; recruit_context.gd:368; tribe_bonuses.gd:76 | gems, UI | §8.2 | keep |
| 7 | `gem` effect, two ledgers, carry-back | recruit_context.gd:368-386; combat_world.gd `gem`; recruit_carry.gd | Hogrider, Brigand, hand gems, steal | §8.3 | keep |
| 8 | Tokens, `scaling_exempt` | recruit_context.gd:355 | spell scaling | §8.4 | keep |
| 9 | Choose One | quilboar_choices.gd; recruit_rules.gd:345,711 | cards, bots | §8.5 | keep |
| 10 | Random `add_card` filter | reference_quilboar.gd `random_card` | Tunneler, Trapper | §8.6 | keep |
| 11 | Dials, caps-off test | reference_quilboar.gd `_card`, `rates` | effects | §8.7 | keep |
| 12 | Trailblazer budget | quilboar_choices.gd:40-51 | Choose One | §8.8 | keep |
| 13 | Trapper income, Sly refreshes | content modes | modes | §8.9 | keep |
| 14 | Confiscation steal | reference_quilboar.gd `steal_gems` | spell | §8.10 | keep |
| 15 | Bot `quilboar_choose_one` | bot_quilboar.gd | lobbies | §8.11 | keep |
| 16 | Hard and Naive bots resolve Choose One | bot_brain.gd:906-918 | mixed lobbies | none; prevents a stall | keep |
| 17 | `reference_alive` counter | game_session.gd:725 | end steal | §9 gem_policy | keep |
| 18 | Choose One view, gem-size state | game_session.gd:230,313 | UI | §8.2 display | keep |
| 19 | 48 known-answer tests | tests/core/test_quilboar*.gd | gate | §8.12 | keep |
| 20 | Validator checks, 7 Python tests | check_units.py:491-597 | gate | §8.1 gate check | keep |
| 21 | Gate driver | tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh | evidence | DECISIONS: drivers are committed | keep |
| 22 | Docs | phase1.md, content README, engine.md | readers | none stated | keep |
| 23 | Three dead hooks | below | nothing | §8.4, §8.8 | simplify |
| 24 | Bot departures from §9 | bot_quilboar.gd:87 | — | none stated | ask 1 |
| 25 | Line profile JSON | tools/sim/quilboar_line.json | nothing | §9 | ask 2 |
| 26 | Unread dials | rates.json | nothing | §6 | ask 3 |

**The five questions**

1. **Phase 1 against §8 items 1–12:** all twelve are built.
   - The unit set is the Choose One line minus Roadboar. §8.19 puts Roadboar in Phase 2, but §10's paper line uses it from R6, so early accounting will run slightly under paper. This is a gap in the plan, recorded in the content README.
   - Click Beetle isn't in the tree, so item 12's test checks timing instead: a second When-played trigger doesn't repeat the mode or Hogrider.
   - Built beyond the twelve items: the editor-build requirement, the export exclusion, the validator checks, Choose One handling for ordinary bots, the gate driver and the line JSON. Only the line JSON has no reader.
2. **Isolation is real.**
   - The loaders read only units, spells and heroes (unit_library.gd:34-48).
   - `qb_*` content enters only through `configure`, and only when both the flag and an editor build are present.
   - With the flag off, the overlay strips `qb_*` even from a reference library (test_quilboar_isolation.gd:41).
   - Exports exclude `content/reference/*`, and an export couldn't switch it on anyway.
   - Saved games can't reach it: no saved-config path exists, and a field library that carries the flag fails the config-mismatch check.
   - With the flag off, nothing new appears in fight inputs (:78) or player-state views (:89).
   - The reference GDScript does ship in player exports, but it can't run there.
3. **Fidelity matches the plan.**
   - Gem size affects only future gems and rounds up per gem, separately for Attack and Health.
   - Gems from units aren't casts; gems from hand are. Gems played in a fight last only that fight.
   - Refiner's and Champion's size gains carry back from fights.
   - Hogrider fires after the chosen mode, and Gem Day counts as a Choose One card.
   - Trailblazer applies to the first Choose One card each turn. Golden doubles numbers, not counters.
   - rates.json equals §6 exactly, and the deviations built are exactly §7's list. Brigand's Barrage mode waits for §8.17.
4. **The bot is a faithful copy of §9, which comes from the comp guides** (Jeef's comp data via bobs-ledger, Firestone, slyders).
   - It commits at R6, or earlier on Gem Rat or Tunneler, and climbs on [2, 4, 6, 9, 11] with a save before tier-ups.
   - It picks modes as §9 specifies and keeps a cycle slot.
   - It sells Created cards for 0 and alternates hand gems between the carry and the engine units.
   - It holds Confiscations, with the steal once 3 or fewer players are alive, and keeps Tunneler and Refiner in the back row.
   - It is fair apart from ask 1. H1's 0.5–2× accounting check is what proves it.
5. **Little is gold-plated.** The validator checks (+134 lines) are the heaviest extra, and they enforce the `qb_` naming rule.

**Simplify:** three hooks that nothing reaches in normal play. Remove them, or route Trailblazer through the query.
- The `choose_one_both` query: no card answers it, and `_both()` does the work (quilboar_choices.gd:35).
- The per-card `quilboar_ref` copy: readers use the player's and the fight's copies instead (reference_quilboar.gd:44).
- `CombatWorld.card_def`: only tests set it (combat_world.gd:11).

**Gap:** `allowed()` switches the reference off silently on a non-editor build. A misrouted H1 run would seat a plain Hard bot and report no error. Log an error when the flag is set but refused.

**Open questions (the orchestrator decides):** asks 1–3.

Paths: plan `/home/alex/code/Bramble-ideation-sol/docs/ideation/reference/quilboar/quilboar-port.md` and evidence `/home/alex/code/Bramble-ideation-sol/docs/ideation/reference/quilboar/phase1.md` (both at 4d23628e).
