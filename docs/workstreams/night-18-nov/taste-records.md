# Records choices

- Storage and export needed a local format: one JSON document or append-only JSON lines.
  Chose one compact `.jsonl` per game in `user://records`, flushed per entry, so unfinished games survive quitting and the folder can be zipped. No automatic deletion or transfer; disk use grows with games.
- The orchestrator suggested seed + actions + turn hashes, with fight boards for ghosts; I chose this design because UI views omit rules state.
  Chose hashes of all persistent rules internals (RNG, pools, private counters, stat layers), at turn start, before fights and after fights. Exact replay rests on that coverage.
- Ghost payloads could keep visible units alone or full rules data; Reserve and tribe effects need more.
  Chose boards, hands, slots, counters, heaps and standing effects after End of Turn, before combat, plus the actual ghost when it fights. Future ghost construction rests on these; matchmaking/import stays outside this item.
- Replays across rules changes could silently use different cards; weighed permissive replay against a build check.
  Chose a local code/content fingerprint, version and engine, plus a commit stamped into Windows builds. A different fingerprint is refused; keep the original executable to replay exported records.

- Review found fixed card data dominated fight snapshots; weighed full copies against card-template deltas.
  Chose nondefault stat layers and added effects only (applied values, no schemas or golden templates); boards and hands retain their slots and order. Full-state hashes still cover everything, and format 2 marks the changed payload.
- Test and soak records must not accumulate in the owner's export folder.
  Chose process-wide GUT setup and soak output under `build/`; normal game defaults stay in `user://records`. A regression test and before/after gate counts check isolation.
