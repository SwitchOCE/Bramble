# Birds pass 1 build

8 Nov 2026. Implements the revised `content/birds-pass1.md`, including its Revision section.

The shop has 16 Birds at **3/3/3/3/2/2**. Barn Owl is out of the pool; the Cuckoo takes her place. All revised bodies, tiers, normal and golden text, mechanics and details are wired. Card text stays at 4–21 words; caps, ties and timing rulings live in Details.

Homecoming now has beside-Nest Dunnock, Bird-only Old Tern Discover, Goose's permanent flock buff (including Birds away), and Whistlers counting this turn's homecomings. Hatchery has the strongest Tom Tit aura after Redwing, normal half-current-stat Goose Eggs, flat Goose strikes, the Cuckoo's departure extension and permanent away growth, half-current-stat Lump (full golden), and Ratchet's temporary current-stat landings. Ratchet leaves the trip and Nest unchanged after combat.

Own Egg tap/hover and combat details show the Egg's own stats, its Bird's current stats and the return countdown. Enemy combat Eggs hide the Bird's current stats and return countdown. Dragging the Lump previews its destination total, including its Nest and Ring. Opponent scouts retain their existing information limits.

Updated Bird bot card hints and the three Bird strategies for the revised cards; their selection, tribe priors, power values and tier curves are unchanged. No other tribe's card effects changed.

No spec mechanic was substituted. Unspecified ties use reading order for Dunnock; each adjacent Cuckoo extends a departure once, additively. Whistlers targets Birds as written, excluding Eggs. Old Tern alone opts out of Discover's normal lower-tier fill.

Runtime verification completed 9 Nov 2026, starting from `fde4e66` on `ideation/birds-pass1`. It used `source /opt/bramble/env.sh` and a temporary `GODOT` wrapper that runs each invocation with `systemd-run --user --scope -p MemoryMax=3G --`. Only one Godot process from this verification ran at a time; no machine-wide lock was required.

**Full gate passed:** `GODOT=/tmp/bramble-birds-godot ./scripts/check.sh`, all ten steps. Compilation loaded 413 files with 0 failures. GUT ran **1,469/1,469 passing tests across 138 scripts, 20,242 assertions**, with the strict hook reporting no risky or pending tests. This includes all 69 Birds mechanics tests, all four new Birds content tests and all four new Birds UI tests. Content/schema checks covered 146 files with 0 problems; all 46 Python tests, version, shell, formatting, lint, Ruff and whitespace checks also passed.

Runtime fixes: explicitly typed the content tests' tribe arrays and card dictionaries and converted numeric Variants before building roster vectors. Replaced Dunnock's unsupported GUT dictionary-versus-null comparison with an Egg identity assertion. Corrected the blocked-Ratchet fixture to use Hoglet Mother's own death summon: friendly-death listeners run before Belly release, so the old Belly-first assumption was wrong. The test still proves no landing in another slot and only one attempt per Nest, even after the blocking Hoglet dies. Updated legacy total-library counts for the retained, non-pool Barn Owl and Goose's Egg expectation to half its current stats. Let deferred UI frees finish in the phone tooltip test. No card effects, including other tribes' effects, changed during verification.

Cuckoo's bespoke portrait is still pending and is now explicitly registered in `content/portraits_pending.json`; it intentionally uses the existing Birds tribe fallback. The portrait test counts the retired Barn Owl as a retained slice definition, while the shop remains at 98 units and 16 Birds.

**Single soak passed:** `GODOT=/tmp/bramble-birds-godot tools/checks/soak.sh 200 20261108`. Exactly 200 games, seeds **20261108–20261307**, **3,466 rounds, 10,933 fights, 0 violations**, exit 0, 976.1 seconds. No problem lines in the Godot log. All 16 current shop Birds fired in the slice coverage report, including Cuckoo, Tom Tit, Goose and Whistlers. The three `no_attacks` draws were accepted terminal results, not violations. Full local log: `build/check/soak.log`.

**Phone capture passed and visually inspected:** [Egg tooltip, 1688×780](birds-pass1-egg-phone.png), equivalent to 844×390 phone points at 2×. Captured with `xvfb-run -a -s '-screen 0 2560x1440x24' /tmp/bramble-birds-godot --rendering-driver opengl3 --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- commit_nest 1688x780 docs/ideation/evidence/birds-pass1-egg-phone.png`, exit 0. The Egg's **4/5**, its Bird's **7/10**, and **"Old Tern comes home in 2 turns."** are readable and unclipped. No layout fix was needed. Xvfb/llvmpipe emitted V-Sync-unavailable and shader-cache-recompile warnings; no script errors. Local capture log: `build/check/birds-pass1-egg-phone.log`.


## Scope review follow-up (9 Nov 2026)

Addressed all four findings from `origin/ideation/c-review-birds-pass1:docs/ideation/evidence/review-birds-pass1.md`. Rulebook 12.1.4 and both engine references now give Mother Goose the normal Egg rule. Combat Details pass the viewer's side to the Egg reader, hiding enemy Bird stats and trip countdowns. The UI regression checks both player sides and preserves own Egg information. Dunnock's new F1-due-next-turn/F3-later regression passes without a mechanic change. Both Lump Details use "comes home". Renamed the stale Swallow adjacency test to state its one-gold payout.

Verification used `source /opt/bramble/env.sh`, with every Godot invocation wrapped in `systemd-run --user --scope -p MemoryMax=3G --`, one process at a time. Focused Birds regressions passed **75/75**. One full `scripts/check.sh` gate passed all ten steps: **1,471/1,471 GUT tests, 138 scripts, 20,256 assertions**, no risky or pending tests; 413 files compiled with zero failures; all 46 Python tests passed. A preliminary test invocation unintentionally selected the full suite and was stopped before the focused run; the full gate ran once.

The subsequent `tools/checks/soak.sh 50 20261109` passed: **50 games**, seeds **20261109–20261158**, **873 rounds, 2,742 fights, zero violations**, exit 0, 238.1 seconds. Its two `no_attacks` draws were accepted terminal results. No Godot log problems. Local logs: `build/check/gut.log`, `build/check/soak.log`; gate transcript: `/tmp/bramble-birds-review-gate.log`.
