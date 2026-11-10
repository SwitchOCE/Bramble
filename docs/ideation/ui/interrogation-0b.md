# Interrogation of step 0b (reference library and layout options), 10 Nov

Step 0b matches what the owner asked for: real frames of the Bazaar, TFT and Battlegrounds at several game states, a breakdown of layout and depth, simple layout options with the Bazaar as the bar, and the Everdell/Ori world. These findings are about making it land, most important first.

## Findings, each with a change

1. **Nothing makes the Everdell/Ori world for Bramble.** The owner said "capture" that look. The plan studies it in other games but never paints it for us. Build 8 has no background art: the board sits on flat tan, and the game ships portraits only. The folio already has 15 painted woodland zones (`docs/folio/art/web/zone-*.jpg`). **Change:** add one `tools/art/` batch of 3–4 recruit-board backdrops in the Everdell/Ori mood, made from the zone prompts with Ori frames as references. Composite each behind real Ink-B units, so the owner can judge whether the two styles clash.

2. **Layout mockups from the image model can promise looks we can't build.** "Concept images through `tools/art/`" give a painted screen that Godot 2D may never reach. **Change:** build each option from real build-8 screenshots (`render_screens.sh` works today, so this doesn't wait for step 0) plus painted backdrop layers. Label any image-model screen "concept". Each option names the Godot technique behind its depth: a skewed board, shadow sprites, parallax layers, or a Camera3D.

3. **The game-state list fits Battlegrounds, not the Bazaar.** The Bazaar has no recruit board to fill, no scouting and no deaths. It has merchants and events, item boards facing each other, and fights that run on cooldowns. Copying BG states onto the benchmark gives empty or forced frames. **Change:** one shared core of menu, shop, inspect, fight start, mid-fight and end screen, plus a short state list per game.

4. **Video download may fail, and Everdell isn't a video game to capture.** yt-dlp is often blocked from cloud IPs, and Codex's reviewer may refuse a download. Everdell's look lives in Andrew Bosley's board-game art, not in gameplay video. **Change:** run captures on the Optiplex. Try Steam trailers first (direct 1080p files, no yt-dlp needed), then YouTube. Use stills for Everdell. Plan item 4 should say this.

5. **Five capture workers duplicate one script.** Scene detection, a blur score and dedup make the same tool five times. **Change:** one worker writes the capture script and runs it for every game. Keep fresh breakdown agents for the Bazaar, TFT and BG, and one for Everdell and Ori together. Galaxy: use the Steam shots from `visual-comparison.md` instead of capturing.

6. **The old frames are already gone.** The frames listed in `visual-comparison.md` sat in an earlier session's scratchpad and were deleted. **Change:** add `docs/ideation/ui/reference/` to `.gitignore` in step 0b's first commit, and keep a manifest in the repo (game, state, source URL, timestamp) so the frames can be fetched again.

7. **The proof checks the frames, not the result the owner wants.** **Change:** the proof becomes each layout option shown beside a Bazaar frame of the same state, plus the critic's plain-words notes.

8. **Day 0 holds four stages in a row.** Capture, breakdown, layouts and critic all come before the day-1 gallery. **Change:** start the layout options once the Bazaar breakdown is done. If they run late, the gallery goes out with the references and they follow.

| Item | Moves the problem? | Proposed by | Verdict |
|---|---|---|---|
| Bazaar/TFT/BG frames | Yes | Owner | Keep (finding 3) |
| Everdell/Ori study | Yes | Owner | Keep, add a backdrop batch (1) |
| Galaxy capture | Little | Agent | Cut, reuse Steam shots |
| One worker per game | No | Agent | Shrink (5) |
| Image-model mockups | Risky | Agent | Shrink (2) |
| PC + mobile frames | Partly | Agent | Keep where both exist |
| Fresh critic, no scores | Yes | Agent (09e) | Keep |
| World-only default | Yes | Agent | Keep; owner can override |

**Fixed after:** the owner picks a layout in the day-1 gallery. That pick only counts if it was shown on our real units and a painted backdrop (findings 1 and 2).
