# Build 9 strong-field library — 12 Nov 2026

Why: the hand limit changed from 10 to 4 (rulebook 7.1.1, note `2026-11-11c`). The library seals the gameplay config it was captured under, so build 8's library was refused at game start (the build 9 soak's 40 field games all failed `GameSession.create`).

Command: `tools/sim/recapture_field.sh --strength top4`, with committed defaults, no config overrides. Source: `68e8c976594b22f66e81ef6830f74d16d6e40ced` (ideation/main with the hand of 4, hex units and the arena layout; no content or rate changes since build 8 besides the hand).

- 120 line lobbies, seeds 20262000–20262119; strength filter top4; sampling seed 91407; per-line limit 64.
- 14 lines; 480 whole trajectories.
- Stored library: 1,654,474 bytes at `content/fields/baseline.json.gz` (expanded JSON 35,274,539 bytes).
- Library SHA-256: `e66bbd284f5e01c0f4b54add366684dc7950f30fb4bbf92c4908d01ea7d76100`.

Raw captures and logs: `build/strong-field/recapture/` (not committed). The capture exited 0.
