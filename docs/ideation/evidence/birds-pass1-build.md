# Birds pass 1 build

8 Nov 2026. Implements the revised `content/birds-pass1.md`, including its Revision section.

The shop has 16 Birds at **3/3/3/3/2/2**. Barn Owl is out of the pool; the Cuckoo takes her place. All revised bodies, tiers, normal and golden text, mechanics and details are wired. Card text stays at 4–21 words; caps, ties and timing rulings live in Details.

Homecoming now has beside-Nest Dunnock, Bird-only Old Tern Discover, Goose's permanent flock buff (including Birds away), and Whistlers counting this turn's homecomings. Hatchery has the strongest Tom Tit aura after Redwing, normal half-current-stat Goose Eggs, flat Goose strikes, the Cuckoo's departure extension and permanent away growth, half-current-stat Lump (full golden), and Ratchet's temporary current-stat landings. Ratchet leaves the trip and Nest unchanged after combat.

Egg tap/hover and combat details show the Egg's own stats, its Bird's current stats and the return countdown. Dragging the Lump previews its destination total, including its Nest and Ring. Opponent scouts retain their existing information limits.

Updated Bird bot card hints and the three Bird strategies for the revised cards; their selection, tribe priors, power values and tier curves are unchanged. No other tribe's card effects changed.

No spec mechanic was substituted. Unspecified ties use reading order for Dunnock; each adjacent Cuckoo extends a departure once, additively. Whistlers targets Birds as written, excluding Eggs. Old Tern alone opts out of Discover's normal lower-tier fill.

Validation completed: content/schema checks (146 files, 0 problems), all 46 Python tests, version checks, shell checks, GDScript formatting and lint, Ruff and whitespace checks. Added focused normal/golden, timing, aura, landing, thin/depleted Discover, privacy, UI and preview regressions; updated legacy expectations.

A fresh static review found no remaining material correctness issue after correcting Swallow's replay wording.

**Runtime validation blocked:** the required machine-wide `/tmp/bramble-godot.lock` is occupied by another worker's long benchmark. This session's developer rule requires that lock and a 3 GB cap for every Godot run. Consequently the full gate, the single requested 200-game soak, and the phone Egg-tooltip capture/visual inspection have not run. No soak games or violation count are claimed.

Prepared capture: `tests/ui/shots/screenshot.gd -- commit_nest 1688x780 docs/ideation/evidence/birds-pass1-egg-phone.png` (844×390 phone points at 2×), under the shared lock and `systemd-run --user --scope -p MemoryMax=3G --`.
