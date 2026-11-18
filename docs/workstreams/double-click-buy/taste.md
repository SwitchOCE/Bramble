# Double-click buy — 18 November 2026

Owner: "when you double click a unit in the shop, I want it to buy and go to your hand."

- Shop units stay still until the existing 8 px drag threshold. A single click keeps its detail;
  a double-click buys on the flagged second press. The normal purchase flight into the hand
  and triple presentation remain the feedback. Empty board slots never invite an auto-play.
- Refused purchases use the same request, refusal message and unchanged rules state as a
  refused drag-buy. No extra refusal copy or gesture timing was added.
- Double-clicking a shop spell would feel natural as a matching buy shortcut. This is a
  question for the owner; spells retain their current click and drag behavior.
- Evidence: 11 new real-mouse-event GUT cases; 46 tests passed with the existing recruit-core
  and triple suites. Film reviewed at 60 fps, 143 frames, 1920×1080:
  `/home/alex/code/Bramble-media/double-click-buy/double-click-buy.mp4`.
  Report: one buy, gold 10 → 8, Sentry in hand, zero board units, no pending carry.
  The test-only film fixture supplies the second press's double-click flag because tools/feel
  sends synthetic mouse events without the OS flag. No production timer was added.
