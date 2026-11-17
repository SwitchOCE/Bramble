# Morning pack, 18 Nov

Nine of the ten briefs were built. Seven are merged into `dev` and finished, and keywords (brief 2) is merged but part-done. The power check (brief 6) and Ambush (brief 7) are built but held for you, because each has open questions. The `dev` build is below, and a second build adds Ambush, so you can play it before deciding.

## 1. Try this first (5 minutes)

**Get the builds.** Taildrop failed overnight because your PC was offline. A retry sends both zips once the PC is online, so check Taildrop first. If they aren't there, paste this in PowerShell:

```
npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/d1/d1e36392335af290e500db5217cee03ed903fc9509be0acc5d4e1ce425ab59e8.zip --remote --file "$HOME\Downloads\Bramble-windows-94e72563b-1118-0036-night-18-nov.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-94e72563b-1118-0036-night-18-nov.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-94e72563b-1118-0036-night-18-nov"
```

The preview, which is `dev` plus the power check and Ambush and is **not** on `dev`:

```
npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/f5/f5d94f9e8bdcff33a6d0aa656505bef6e1fdabbbdeebfb85444a96912b2148be.zip --remote --file "$HOME\Downloads\Bramble-windows-609dea577-1118-0058-preview-ambush.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-609dea577-1118-0058-preview-ambush.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-609dea577-1118-0058-preview-ambush"
```

**Then, in the `dev` build:**
1. **Keywords.** Hover a card with keywords, hold **Alt**, and point at a keyword: for nesting, open **Cards**, search *Flying Ace*, and point at *Decorated*, then *Medal* inside it. Let go of Alt. Are the marks on the bottom border readable on your screen?
2. **Duplicates and triples.** Buy two copies of one unit and watch the gold glow. Buy a third and watch the triple. It's 1.80 s, and a click finishes it early.
3. **Cards and a fight.** From the start screen press **Cards** (between Play and Quit), then play a turn and watch the fight: the wind-up, the lunge, the recoil and the deaths.

**In the preview:** play Mice, and watch **Ambush** strike once per fight (Toothpick Ballista has it at tier 3).

## 2. Key choices made without you

Each is in the [run log](README.md) or the brief's `taste-*.md`. All can be redone in one place.

- **Attack and Health are now a diamond and a shield**, so the gold coin only ever means price. Coin drawing A (milled, bold numbers) was chosen from 3. [taste-shop](taste-shop.md)
- **Duplicate glow: the slow, shallow "breath"** (A), chosen over a quicker, deeper pulse. [taste-dupes](taste-dupes.md)
- **Triple: brisk, 1.80 s.** A ceremonial 2.16 s version is filmed too. [taste-triple](taste-triple.md)
- **Fight motion:** a small wind-up (4 frames), a lunge into the target, recoil, and a knock, tip and shrink on death. Attack timing is unchanged. [taste-fight](taste-fight.md)
- **Card browser:** the tribe picker stays on the start screen, with Cards added. The mock-up's amber ring on Cards is left out, because on that screen amber means "this tribe is in". The browser opens only during recruit, not fights. [taste-browser](taste-browser.md)
- **Order and Bury buttons stay where they were, over the art.** The worker built a strip under the board labelled "B1 · Order (1)". That is a new design you haven't seen, so it was taken out and kept on branch `night/keywords-action-strip`. [run log](README.md)
- **Ambush (preview only):** half Attack, once per unit per fight. Dame Bodkin, the capstone, makes pile-on Ambushes full Attack. Pigeon Lieutenant's row charge is back: each unit in the row makes an ordinary attack. These are my calls, from your "start generous and dial back". [ambush-check](https://github.com/SwitchOCE/Bramble/blob/night/ambush/docs/design/ambush-check.md) (on the Ambush branch)

## 3. What nothing could see

- **Feel and motion:** fights, the triple, the glow pulse and Alt-holding were judged from 60 fps films on a software renderer. Nothing has run on your hardware: frame pacing, input delay and GPU are all unseen.
- **Readability at 1366×768 on your screen.** The marks measure 15 px with 9 px numerals in a software render, against 6–7 px before. Your eyes on your laptop are the real test.
- **A test passed while the thing was broken:** the duplicate glow's pulse never drew (identical frames), and its test checked a setting, not pixels. A reviewer caught it by measuring the films. It is fixed now, with a pixel test shown to fail on the old shader. Other motion tests may check settings rather than pixels in the same way.
- **Sound:** none anywhere.
- **Game records on Windows:** the records folder (`%APPDATA%\Godot\app_userdata\Bramble\records`) and replay were tested on Linux only. [records.md](records.md)
- **The power check can't see damage that doesn't change who survives.** That is why most Ambush cards read ×1 on it.
- **Reference films** of Battlegrounds, Galaxy and others were placed side by side with ours, but not time-aligned beat by beat.
- **The keyword comparison shots** were taken while the action strip was in place. New shots of the restored buttons show no overlap with the marks.

## 4. Done and verified

Every merge into `dev` passed two gates: `scripts/check.sh` (12 stages: tests, a 15-game bot soak, record replay, pixel checks), which I ran on each branch over `dev`, and a fresh scope reviewer checking it against your words in the brief, with no cut or ask items left.

| Brief | State | PR | How it was checked, beyond the gates |
|---|---|---|---|
| 1 Gold coin and shop prices | finished | [121](https://github.com/SwitchOCE/Bramble/pull/121) | Mock-up compared region by region at both sizes; a test buys a spell and checks it gets the cream disc in hand |
| 3 Refresh counter | finished | [121](https://github.com/SwitchOCE/Bramble/pull/121) | Rules tests for the count and the price steps; also fixed free refreshes counting as paid (4.4.5) |
| 4 Duplicates glow | finished | [127](https://github.com/SwitchOCE/Bramble/pull/127) | Pixel test that fails on the old shader; both candidates re-filmed |
| 5 Triple animation | finished | [126](https://github.com/SwitchOCE/Bramble/pull/126) | 18 triple tests; filmed with a full hand and with a Discover pick |
| 8 Game records | finished | [122](https://github.com/SwitchOCE/Bramble/pull/122) | 50 games replayed to identical states; a planted change is caught at the first differing turn. About 11 KB zipped per game |
| 9 Card browser | finished | [125](https://github.com/SwitchOCE/Bramble/pull/125) | 99 units and 3 spells from the game's data; opened through real clicks from both entries; closing it leaves the game pixel-identical |
| 10 Fight animations | finished | [124](https://github.com/SwitchOCE/Bramble/pull/124) | Before and after film; attack timing unchanged (12.68 s for the test fight) |
| 2 Keywords and tooltips | **part-done** | [129](https://github.com/SwitchOCE/Bramble/pull/129) | 864 mock-up regions compared; Alt filmed with nested details. Not done: Order/Bury words still cover art |
| 6 Power check | **built, held** | [123](https://github.com/SwitchOCE/Bramble/pull/123) | Fixed against its own buff control. Hand-worked 4–5 cases, partly met |
| 7 Ambush | **built, held** | [128](https://github.com/SwitchOCE/Bramble/pull/128) | Stacked on 6; check.sh passes on the preview |

Not started: none.

## 5. Questions, with my recommendations

1. **Merge the power check and Ambush into `dev`?** *Play the preview first, then merge if Ambush feels right.*
2. **Power check: which number does a designer pitch?** *The built-around number; "all ten cases" stays on the method page as the setup cost.*
3. **Is the partial, non-blind pass enough to rate Ambush?** *Yes: each card is compared with its old self on the same check.*
4. **Keep Bodkin's full-Attack pile-on Ambush as the capstone?** *Yes, it's the "capstone" exception you described.*
5. **On late high-Attack boards one half-Ambush still kills outright** (Ballista and Catapult read ×3 there, as Hit did). *Accept for now, and dial back after play.*
6. **Goldens of Ballista, Catapult, Bodkin and Lieutenant now only double stats.** *Give each a golden upgrade back, next run.*
7. **Where do Order and Bury go?** The strip under the board (on `night/keywords-action-strip`), or the bottom-border mark becomes the button, with the words in its tooltip (the worker's pick; it takes words off the card). *A mock-up of the mark-as-button first; I'd expect it to win.*
8. **Triple: brisk (1.80 s) or ceremonial (2.16 s)?** *Brisk.*
9. **A triple formed with a full hand, whose golden goes to the board, loses its Triple Reward.** This was in the core before tonight. *Fix it with the 7.3.6 gap below.*
10. **Browser: should the start screen's tribe picker go, and does Cards want a "new" marker?** *Keep the picker; no ring.*
11. **If the fight wind-up feels timid,** the fix is more time per attack, which the brief says to ask about. *Judge it in play first.*
12. **Five rulebook gaps have no brief:** move board to hand (7.2.4), sell from hand (4.3.7), play effects on recruit (7.2.3), recruit effects for units not bought (7.2.6), and Triple Reward when the triple forms (7.3.6). *One brief of its own, early next run.*
