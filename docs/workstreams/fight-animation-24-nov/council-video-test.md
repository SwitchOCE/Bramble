# Can the council take video? (24 Nov 2026)

Test clip: today's plain attack from the comparison fight, 1.0 s, 60 fps, 960x540. Truth from the fixture's per-frame log: the attacker starts moving at clip frame 9, contact (centres 0.62 card heights apart) at frame 20, the damage burst at frame 23.

| Member | How it viewed the clip | Start | Contact | Speed | Verdict |
|---|---|---|---|---|---|
| GPT Sol (gpt-6.2-sol, high) | ffmpeg frames as contact sheets | 9 | 18 (borders touch) | "speeds up on the approach" | right |
| Gemini Neon (gemini-4-neon, high) | direct read gave one frame; then ffmpeg frames, contact sheets and single PNGs | 9 | 17 tip to tip, peak overlap 20, burst 23 | "speeds up sharply… brief hold at peak overlap" | right, to the frame |
| Claude Opus | reads PNG frames (as every agent in this phase did) | — | — | — | not tested separately |

So all three council members can review the clips by pulling frames. None of them sees motion at playback speed; they read frames. Whether the motion feels right is still the owner's to judge.
