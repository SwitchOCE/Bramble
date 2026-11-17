# Records choices

- Storage and export needed a local format: one JSON document or append-only JSON lines.
  Chose one compact `.jsonl` per game in `user://records`, flushed per entry, so unfinished games survive quitting and the folder can be zipped. No automatic deletion or transfer; disk use grows with games.
- The owner chose seed + actions + turn hashes, with fight boards for ghosts; UI views omit rules state.
  Chose hashes of all persistent rules internals (RNG, pools, private counters, stat layers), at turn start, before fights and after fights. Exact replay rests on that coverage.
- Ghost payloads could keep visible units alone or full rules data; Reserve and tribe effects need more.
  Chose boards, hands, slots, counters, heaps and standing effects after End of Turn, before combat, plus the actual ghost when it fights. Future ghost construction rests on these; matchmaking/import stays outside this item.
- Replays across rules changes could silently use different cards; weighed permissive replay against a build check.
  Chose a local code/content fingerprint, version and engine, plus a commit stamped into Windows builds. A different fingerprint is refused; keep the original executable to replay exported records.
