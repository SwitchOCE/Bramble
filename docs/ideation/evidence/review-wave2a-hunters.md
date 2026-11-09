# Hunters build scope review (10 Nov 2026)

Fresh scope reviewer, range d5b5b4f8..5cd5cd71 on ideation/wave2a. Verbatim report.

## Scope review: `ideation/wave2a` d5b5b4f8..5cd5cd71 (Hunters pass 3 and fix-ups)

The brief gave me the owner's words, the approved plan and the binding DECISIONS entries, so no verdict below depends on a missing source.

**Counts:** 20 keep, 1 cut, 0 simplify, 2 ask.

**Does it move the original problem?** In the rules, yes. In play, partly.
- Hunter payoffs are now shares of the enemy and permanent, and the Glutton concentrates them.
- In 3 bot games I ran with forced Hunter seats, the Hunter seats still alive grew ×1.28–1.54 a round from R8 to R14. 5 of the 7 reached ×1.3.
- Their R12 boards were only 216–467, against B's target of about 900.
- Hunters grow only as fast as the boards they eat.

**The cut:**
1. Commit 04b95d32's new `_best_replacement_slot` ignores the committed lines' protected engine pieces. My probe shows a line seat selling its protected piece. After the merge, every wave line's `keep` list loses that protection, and those lines are what will measure wave 2a.

**The asks:**
1. The pin fix (5cd5cd71) is a hard purchase filter on every `hard:<build>` seat. The shipped game seats every bot that way, so all game opponents and the harness's Hard anchors now buy only their own tribe from R1. The build doc implies the real game is unaffected. Keep it, narrow it, or give it the committed lines' R4 window?
2. The build doc says preset A keeps the synthesis shares. The code gives Hunters B's values under A. Fix the sentence or add A overrides.

**Clear to merge into ideation/main?** Not yet. Fix the cut and decide ask 1 first. Ask 1 changes every opponent a playtester meets, and it changes what the B/C run on d5b5b4f8 stands for. Then do the planned merge, the fixture re-record and the merged-tree gate. I did not read the worker's gate.

---

## Your questions

**1. Does the build match the design and the calls?** Yes. No card's text, numbers or timing differ without a logged reason.
- **Bodies:** all 16 match the design table (Nip 2/2 through Isegrim 7/10).
- **Text:** follows the design, with logged changes:
  - Brock and Isegrim say "Hunters" (README amendment 2).
  - Lane-Bard (amendment 9).
  - B uses ⅔ and ⅓ shares, and C changes 9 shares. All values equal paper `presets.json`.
- **Timing:**
  - Trophies land at the next Start of Turn (design call 1).
  - Isegrim picks from the settled board (amendment 4) but pays from bell stats.
  - A Sable that gets her quarry from a loan strikes after the loans (presets decision, item 5).
  - Jack goes last (fix-ups call).
- **Worker's own readings.** These are proposals. They are in rulebook 9.6.5–9.6.8 as `[PROPOSED ideation]` but not yet in DECISIONS:
  - duplicate Sable text strikes once per dispatch, using the strongest;
  - Isegrim doesn't re-pick after a strike his loan enabled;
  - Brock keeps the enemy across from him at the bell, even if Jenny moves it;
  - an Ermeline that enters mid-fight earns no Pelt;
  - Pelts skip board spell scaling but still count as spells;
  - pack rewards need lethal attack damage;
  - Whirligig skips a pair if either enemy would gain.
- **Small differences:**
  - The design's Sable "trades alone / needs a joiner" preview isn't built.
  - The scout's paw-print prices moved into the reader (09e, explained in the build doc).
  - The build doc says the archive stays "until checkpoint 2". Plan v3 moved that to step 5.

**2. Rule (b) on every Hunters card.** Every card's condition can be true when its trigger fires. The one trap found (a Sable with an empty across slot missing her strike after a late loan) was fixed in 02a2ac4d, with a test.
- Fire rates in the 3 forced-Hunter games, as triggers per fight with the card on board (bots, small sample):

| Card | Per fight |
|---|---|
| Glutton | 1.57 |
| Grizel | 1.29 |
| Ermeline | about 1.0 |
| Nip | 0.77 |
| Lutra | 0.73 |
| Wick | 0.64 |
| Lodger | 0.57 |
| Lane-Bard | 0.52 gold events (cap 2; paper hoped for 1–2 gold a turn) |
| Russet | 0.29 copies |

- Russet is the weakest: she needs her own Take and a pool card at your tier or lower. Reported, not a fix.
- **Rule (a):** the build doc names keystone-removing low rolls (no Isegrim for the Pack, no Laird for Open Season), but nothing measures them. The nearest paper figure is Open Season with the Laird not doubling: 1.00× / 0.93× at R12 / R15. There is no figure for the Pack without Isegrim.

**3. Jack Daw.** The recipient no longer depends on which side resolves first, and it is tested across seeds.
- Jacks now run after all late picks and Hunter loans, in fixed side-then-slot order, copied text included (`pass3_combat.gd:127-135`).
- The test checks the recipient over 12 seeds against an enemy answer that halves the would-be recipient. A copied-Jack test covers 8 seeds. Both passed in my run.
- Caveat: when both sides have a Jack, side 0 always goes first. That is deterministic but not symmetric. It is rare.

**4. Whirligig.** The guard stops the Ring gift, and it is tested.
- A pair is skipped if either enemy would gain from its destination Ring (`pass3_row_swap.gd`, `combat_moves.gd:132`).
- Counterexample test: with the guard off, the 90-Attack carry moves onto a +40 Ring and reaches 130. With it on, the carry stays at 90. The real card blocks the pair and deals no damage. Equal Rings still swap, and the pass 2 face is unchanged. Passed.
- Cost: on a board Ringed in every slot with unequal Rings, nearly every occupied pair is skipped. The Beetle is close to blank against Fairies until the W2b rewrite.

**5. The pin fix.** It is not a weakened bar. It is a hard filter that makes the bar pass by construction, and it reaches every game bot.
- The two earlier fix-ups are real valuation fixes (55a3a37f, 04b95d32):
  - off-route Cluricaun is worth 0 without seven Rings;
  - a replacement gets the destination slot's Ring.
  - They change every Hard bot on Ring boards, pinned or not.
- **Does a pinned seat now play its declared strategy under B?** Yes, trivially. Seeds 31–34 give Fairy shares of 1.0 / 0.0. Across 4 shipped-config games, 291 of 292 tribal buys were on-build.
- **Does it change unpinned Hard?** Truly unpinned `hard` seats are untouched, but neither the game nor the field has any:
  - the game seats every bot as `hard:varied`, which becomes `hard:<build>` (`game_config.gd:127`, `bot_lobby.gd:15`, `game_session.gd:588`); my probe found all 7 bots pinned;
  - the harness `hard_field:varied` anchors become pins the same way;
  - committed lines and free-choice seats are exempt.
- **Effect in the shipped game:** same build, 4 games at B (seeds 41–44), the filter switched off against on:

| | Filter off | Filter on |
|---|---|---|
| Off-build share of tribal buys | 62.5% (275 of 440) | 0.3% (1 of 292) |
| Tribal buys | 440 | 292 (−34%) |
| Median board, R12 | 270 | 251 |

- With the filter off, almost every build splashed Hunters heavily: a Birds Highway seat bought 17 Hunters and 6 Birds. Either BotHunt overvalues Hunter cards or Hunters are strong at B. The filter hides that question.
- **The B/C run on d5b5b4f8 won't represent the head:**
  - its anchors splash freely; at the head they don't;
  - after the merge, its lines lose engine-piece protection (the cut);
  - it has the pass 2 Hunters.

**6. Other tribes.** Their rules and dials are unchanged apart from the intended shared changes. Their bot play did change (ask 1 and the cut).
- `rates.json` only adds `hunters_*` keys. The other tribes' dials are identical in A, B and C.
- No other-tribe test assertion changed. The edits:
  - route pass 2 Hunter tests to the archived definitions;
  - update the pool counts;
  - add a third tier-3 card to the triple-reward fixture;
  - move the pinned test and the Birds recruit suite from A to B (the re-base call).
- **Shared rule changes, all intended:**
  - Jack's final step;
  - the Whirligig guard;
  - pass 3 start order also applies when only Hunters bring pass 3 content;
  - Syllabub and copy replays now share one dispatch path, which adds an on-board/halted check to copy replays.
- **Fixed-dial replays:** 96 of 96 tests passed at 5cd5cd71 in my run of the capture, field, upset, Hunters-start, Whirligig, committed-lines, bot-brain and Hunter-content suites. That includes the older capture replays. The thirds-precision fix has a negative-control test.

**7. Can Hunters compound in real play?** Yes, as fast as their prey.
- In the forced-Hunter games, the surviving Hunter seats grew ×1.28–1.54 a round from R8 to R14, much like the other tribes there (×1.21–1.61).
- Across the 4 shipped-config games, the lobby median went 91 → 571 from R8 to R14 (×1.36 a round). That counts living seats only: 32 at R8, 18 at R14.
- Bots measure the floor of an engine, and these are small samples.

**8. Gold-plating.** Nothing large.
- Guard-off branches in the Hunter code (counting duplicate text, stacking Lairds) exist only for the diagnostic switch's counterexample tests. The pool-rules review accepted the same pattern.
- The capture-precision sidecar (`pass3_rates.gd:68-102`) stores the rate map a second time, as a string. It fixed a real replay mismatch (a Take that should pay 4 paid 3), so keep it. The bench already writes captures at full precision, so a smaller fix at the one writer that rounds may exist.
- Two one-line wrappers in `recruit_rules.gd` were inlined, with no behaviour change.
- The GUT time budget went from 600 to 900 seconds. Much of the growth is the pinned test now playing 4 full games.

---

## What the range changes

Factual inventory only, with the stated reason for each.

1. **Schema and data**
   - `content/pass3/rates.json:78-104`: 27 `hunters_*` dials at paper B, plus 9 C overrides at `:160-168`. Read by `Pass3Rates`. Reason: plan v3, "Every engine rate is a dial", and the paper presets.
   - 16 Hunter unit files rewritten, and 7 prototype bodies set to `pool: false`. Reason: `hunters-pass3.md`.
   - `content/spells/pelt.json`: Hunter-only target, fixed reward. Reason: design.
   - `tests/core/data/pass2_hunters_units.json`: archive of the old definitions, used by `legacy_hunters.gd`. Reason: build doc, rollback tests.
   - New state: `PlayerState.item_doorstep` and `RecruitUnit.poached_offer`. Reason: design (full-hand Pelts wait; Russet's copy is marked).
   - Hunter bot strategies, `tools/sim/lines/hunters.json`, and the upset-audit evidence updated.
   - Rulebook 9.3.2a edited; 9.6.5–9.6.8 added as `[PROPOSED ideation]`.
2. **Scheduled or background jobs:** none.
3. **Features:**
   - Hunters' combat and recruit rules (`pass3_hunter_*.gd`, `pass3_hunters.gd`). Reason: design.
   - Jack's final step. Reason: fix-ups call.
   - The Whirligig guard. Reason: fun-probe call.
   - Reader preview of the recorded quarry and its Take (`pass3_hunter_preview.gd`, `card_detail.gd`). Reason: design, scout price.
   - Pelt portrait and Hunter-only aiming.
4. **External services or libraries:** none.
5. **Config:**
   - 27 nullable `GameConfig` dial keys.
   - `GUT_TIMEOUT=900` (`scripts/check.sh:26`). Reason: the worker's.
6. **Public interfaces:**
   - New classes: `Pass3Hunters`, `Pass3HunterCombat`, `Pass3HunterGains`, `Pass3HunterStart`, `Pass3RowSwap`, `Pass3HunterText`, `Pass3HunterPreview`, `BotHunt`.
   - New methods: `BotBrain._best_replacement_slot` (`bot_brain.gd:433`), `BotEval.follows_strategy` (`:154`), `BotEval.ring_change` (`:266`), `Pass3Rates.freeze_values` / `restore_values`, `FightCapture.freeze_config`.
7. **Internal machinery:**
   - the capture-precision sidecar;
   - the per-dispatch strike guard;
   - the pin purchase filter (`bot_brain.gd:362`);
   - Ring-aware replacement;
   - bell prey snapshots in `combat.notes`.
8. **Deleted:** Pounce leaves the slice (its code stays); the old Hunter texts; `RecruitRules._triple_reward` and `_feed`.

**Unrequested:**
- the pin filter reaching every game and anchor seat (the stated reason covers the test pin and line sims only);
- the capture sidecar (reason: the worker's failed run);
- the dispatch guard (the worker's);
- the GUT budget (the worker's);
- the wrapper inlining (no reason stated);
- the worker's seven rules readings.

**Size:** 125 files, +5,392 / −406.

## Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| 16 Hunter units and Pelt | keep | matches `hunters-pass3.md` and amendments 2 and 9 | — |
| 27 dials, B and C | keep | equal to `presets.json` | — |
| Prototypes retired, pass 2 archive | keep | plan: pass 2 stays as rollback | fix the "checkpoint 2" wording |
| Takes, shares, queue, Laird, Lodger, Glutton, Pack, Agnes, Wolf, Lane-Bard, Russet, Ermeline | keep | `pass3_hunter_gains.gd:6,40,125`; tests pass | — |
| Late Isegrim/Brock loans, deferred Sable strike | keep | `pass3_hunter_start.gd:14,34` | log the readings in DECISIONS |
| Jack final step | keep | `pass3_combat.gd:127`; 12-seed test | — |
| Whirligig guard | keep | counterexample test | W2b rewrite revisits it |
| Heir, Pelt doorstep, Hunter-only aim, poach marker | keep | recruit tests | — |
| Text from rates, rulebook entries | keep | tagged PROPOSED | — |
| Reader preview | keep | design, 09e | — |
| Upset-audit entries | keep | the audit fails closed on unknown abilities | — |
| BotHunt and strategies | keep | design's bot needs | — |
| `lines/hunters.json` | keep | keys are in main's loader list | — |
| Capture sidecar | keep | negative-control test | — |
| `GUT_TIMEOUT` 900 | keep | the suite grew | — |
| Ring-aware valuation and Cluricaun condition (55a3a37f) | keep | real defects, 4 directed tests | — |
| Birds recruit suite moved off preset A | keep | the re-base call's simplify | — |
| Wrapper inlining, shared replay path | keep | no behaviour change beyond the on-board/halted check | — |
| Worker's rules readings | keep | rulebook 9.6.5–9.6.8 | orchestrator logs them |
| `_best_replacement_slot` (04b95d32) | **cut** | probe: protected piece sold; `committed_line_brain.gd:46` bypassed | fix before merge |
| Pin filter (5cd5cd71) and its tests | **ask** | probe: all game bots pinned; off-build 62.5% → 0.3% | decide its reach |
| Build doc's preset A sentence | **ask** | preset A overrides only `fairies_fetch_share` | fix the sentence or add A values |

**Cut, the fix:**
- Make `_best_replacement_slot` skip the committed lines' protected pieces: an override in `committed_line_brain.gd`, or one overridable "can replace" check in `bot_brain.gd`.
- Add a test through `_clear_slot_for` with an engine piece that isn't a native Hunter, Bog or Fairy keeper.
- `test_committed_lines` passes today only because Brother Wolf is also protected by `BotHunt.keep_engine`.

**Gaps:**
- The keystone-removing low rolls (rule a) aren't measured. The harness run on wave 2a's head should include them.
- The pinned regression no longer tests the bot's judgement.
- No Sable "trades alone" preview.

**Open questions (yours to decide):**
1. Ask 1, the pin's reach. My lean is the committed lines' rule: flexible before R4 or under 3 bodies, neutral fillers allowed. It matches 09f's "early units should be somewhat flexible". Either way, check why every build splashes Hunters when unfiltered.
2. Ask 2, the preset A sentence.

## Files

- Probe test: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters/test_probe_rv.gd`
- Pin and engine-piece results: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters/probe_out.jsonl`
- Filter on/off games: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters/probe_out_b.jsonl`
- The 96-test run: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters/gut_c.log`
- Analysis script: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters/analyze.py`

Every Godot run held `/tmp/bramble-godot.lock` with the 3 GB cap, one process at a time, in a temporary `git archive` copy. That copy is deleted, and the worktree `/home/alex/code/Bramble-ideation-balance` is untouched.