# Compost viewer — agent's calls

18 Nov 2026. These are the agent's layout and look choices, not an approved mock-up.

- Reuse the card browser's 55% black dim, rounded dark pane, cream display type, muted
  supporting type and Close button. The modal canvas sits above the game's cards and cog.
- Centre a 940 × 936 pane on the existing 1920 × 1080 stage. It scales with the game at
  1366 × 768. Keep the same frame when empty so opening it has a consistent destination.
- Use the shared card maker at 244 px high, stepping down 164 px with a small alternating
  horizontal offset. The newest card is fully visible and painted above the next one.
  Names, Attack, Health and tier also sit beside each card so overlap never hides those facts.
  Hover either the card or its caption for the usual shared tooltip, including Alt details.
- Show `Compost`, a card count and `Newest first`. Follow this task's newest-first order;
  the older tribe ideation document suggested highest tier first. Keep duplicate entries.
- Empty copy: `Your Compost is empty.` / `Bury a shop unit to add it here.` As on dev,
  the chip appears only once the core has created the heap. An existing heap that becomes
  empty keeps its chip and the empty message. Browsing never creates or changes a core heap.
- Heaps store card identities and tiers, not buffed or golden instances. Display plain printed
  stats, rules, art and keywords. The adapter supplies detached data without allocating live
  UIDs or changing the pool, RNG or game log.
- Fight support uses the same viewer. Replay keeps running; the open list updates on heap
  changes, retaining the scroll offset. Panel clicks and keys do not skip combat. It closes
  when the game changes screens. Escape is handled once in the panel before Pause; a click
  outside (including the chip or cog) only dismisses it.
- Only two lines added to the shared-worker fight file, `fight_replay.gd`, to carry full
  card presentation data for new heap entries. Other fight, slot, glow and tooltip files
  are untouched.

Validation: new GUT coverage uses viewport clicks for opening, chip/outside dismissal and
Escape, checks core/view/event/UID preservation, checks all 12 entries against core order,
scrolls to the oldest card and shows its shared hover, exercises the empty state and a
non-Briars lobby, and verifies combat progresses and refreshes an open viewer. Close's GUI
signal follows the existing browser test pattern; its native click was also checked in a
rendered fixture at 1366 × 768.

Review follow-up: remove the synthetic turn-1 chip. Tests explicitly create core heaps when
they need a chip, retain existing-empty and non-Briars coverage, and verify that opening and
closing the viewer leaves core state unchanged. Validation uses native `./scripts/check.sh`
with `LP_NUM_THREADS=2`, without a fixed-fps wrapper. `FEEL_TMP` and XDG data/config/cache
directories point into `/tmp` because the sandbox cannot write the default home caches.
Result: `check.sh: all steps passed` — 807 native tests, rendered checks, soak checks and record
replay. No flakes occurred, so no conditional `origin/dev` comparison was needed.

Media is outside Git in `../n18-media/compost/`: `recruit-{empty,three,twelve}-{1366x768,1920x1080}.png`.
The screenshot scenes under `tests/screens/compost_*.tscn` use real core entries and adapter
data. Additional twelve-card scrolled and hover shots show access to the oldest entries and
the usual tooltip.
