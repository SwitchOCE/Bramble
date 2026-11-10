# Build 8 strong-field library — 10 Nov 2026

Command: `tools/sim/recapture_field.sh --strength top4`, with committed defaults,
no config overrides. Source: `eb52a95fc50bf1a7ef6219244c732b1197affa05` (includes Soup 0.2,
step 0 `3336f79e202579c21528050513cb298fc509f845`).

- 120 line lobbies, seeds **20262000–20262119**; capture time 1,016.3 seconds.
- Strength filter: **top4**. Sampling seed: **91407**.
- Per line, lobby rotation and placement stratum limit: **64**.
- **14 lines; 480 whole trajectories**. All six lobby rotations represented;
  top-four counts by rotation: 104, 84, 64, 80, 76, 72.
- Stored library: **1,652,109 bytes**, at `content/fields/baseline.json.gz`.
- Expanded JSON: **34,958,324 bytes**.
- Library SHA-256: `3653057c0127bd55ab32bdbb09bf7f95b8831ad8764b7d6c5f63f8fb7ca711fa`.
- Raw fights SHA-256: `4752018b0ea3d9b8fb7c5f42c53161275ecdb04dd67af07a19f6f7a066e685a4`.
- Players CSV SHA-256: `01a83af3aefdc51bc81881cc1cfde91469996cd789c8d9503c9c441b589a4932`.

Raw captures and import/capture logs: `build/strong-field/recapture/`.
The capture completed without script or engine error lines. The earlier partial
capture was discarded and restarted after Soup's share changed.

The fight-reader fix and subsequent UI/harness fixes landed while this capture
ran. They change no authored content or line policies: `field_library.source_data`
compares the complete gameplay hashes and profiles equal between the named
capture source and the current tree. The generator retains the actual capture
source commit rather than relabelling its provenance.

The stored file is below 2 MB and Git's file-size limit; the docs size guard
passes without an allowlist change. Pack loading, SHA checks, memory and the
200-game field-inclusive soak are recorded alongside the final export evidence.
