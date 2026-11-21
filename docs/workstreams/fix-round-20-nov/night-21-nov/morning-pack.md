# Morning pack, night of 21 Nov

Two pieces of work were built overnight: the type line with its keyword tooltips (plan step 6, PR 249) and the recruit batch of animations (plan step 12, PR 250). Both passed every check. Neither is merged into dev, because each has one question only you can answer (section 5). Tonight's build has both in it.

## 1. Try this first

The build is `Bramble-windows-c60fb423c-1122-0115-night-21-nov`. Your PC was off at 01:20, so the Optiplex retries the Taildrop every 10 minutes until 09:20. If it isn't in Downloads, get it from R2 in PowerShell:

```
npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/f3/f33e4f3bcb0a2d7b8d7b4372cd463ded634cea1179a89f2b89a6196889b0eca1.zip --remote --file "$HOME\Downloads\Bramble-windows-c60fb423c-1122-0115-night-21-nov.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-c60fb423c-1122-0115-night-21-nov.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-c60fb423c-1122-0115-night-21-nov"
```

Start it with `Play-Bramble.cmd`. Then try these three things, about five minutes in all:

1. **Hover a unit in the shop and on the board.** Each card now shows its type on a cream strip above the stats. The keyword boxes open in the light on the left, not beside the card. Find the Home Guard: its Charge marks now sit above the strip.
2. **Buy, refresh and tier up.** Drag a shop card straight onto the board, press refresh, and tier up. The gold counts down. The old shop sinks and the new one drops in. A band of light sweeps across the shop on tier-up.
3. **Swap a hand card onto an occupied slot.** The slot lights blue, the unit there lifts and dims, and a pale copy waits in the hand. Let go and watch it fly to the hand. Then fill your hand and buy a card, so it joins from the waiting stack.

## 2. Key choices made without you

These are the calls that most change what you will see. The full logs sit next to this page once the PRs merge; until then they are on the PR branches: [taste-anim-recruit.md](https://github.com/SwitchOCE/Bramble/blob/anim/recruit-batch/docs/workstreams/fix-round-20-nov/night-21-nov/taste-anim-recruit.md) (PR 250) and [taste-type-line-tooltips.md](https://github.com/SwitchOCE/Bramble/blob/fix/type-line-tooltips/docs/workstreams/fix-round-20-nov/night-21-nov/taste-type-line-tooltips.md) (PR 249).

- **A press finishes any move at once** (anim entry 3). A fast player sees moves snap to their end instead of running under the next click.
- **Gold counts down for every spend** (anim entry 4), including buying to the hand and an Active's cost, not only the prototype's buys, refresh and tier-up.
- **The swap keeps your approved look** (anim entry 8): blue rim and pale hand copy, from the swap mock-up. The prototype's lift is added, but the unit dims blue, not the prototype's grey.
- **Tier-up flash without its glow** (anim entries 15 and 16). The tier numbers squash and open instead of turning in 3D. The sweep of light is a shader, and it may look stronger on a bright card.
- **The type strip is cream and covers about 20 px of the art** (type-line log). Every unit shows its type, including one-word types.

## 3. What nothing could see

- **Motion and feel with a real mouse.** The animations were filmed at 60 frames a second with a scripted pointer and compared with the prototypes frame by frame. No one felt the drag, the timing, or a press cutting a move short.
- **Your screen and graphics card.** Every check ran on the Optiplex's virtual display. The sweep's brightness and the blue dimming on a bright card were not seen on real hardware.
- **Small text at 1366×768.** The type strip's text is about 11 px at board size on a small screen. No one checked whether it reads.
- **Sound.** Sound Wave 2 (PR 247) touches the fight screen. Tonight's work is on the recruit screen, so they were not tried together.
- **The drop path of the price tag.** Only the "tag travels" path ran, because the switch is set to it (question 2).

## 4. Done and how it was checked

- **Type line and tooltips (PR 249).** All checks passed (1053 tests). Shots were compared with the mock-up. A test checks that the pips clear the strip.
- **Recruit animations (PR 250).** All checks passed (1063 tests). Each animation was filmed and compared with its prototype. A first scope review found the swap had lost your approved look, so a fix worker put it back. A second review found no cuts. It ran the held-card test twice, once with the fix and once without, and the test failed without it.
- **Tonight's build.** dev with both PRs merged in: all checks passed (1066 tests), then the Windows build `Bramble-windows-c60fb423c-1122-0115-night-21-nov`, against the third run's ghost field `field-fa1d51ec`. It is in R2, and the Taildrop retries as above.
- **Films and shots** (game next to prototype, for each animation, and the swap fix) are in R2 under `docs/workstreams/fix-round-20-nov/night-21-nov/films/`. Get them with `python tools/assets/assets.py pull docs/workstreams/fix-round-20-nov/night-21-nov/films`.

## 5. Questions

1. **Pips on cards with a type strip (PR 249).** The Charge and Supply pips used to sit where the strip now is. Options: above the strip, over the stat discs, or a shorter strip on those cards. **Recommend: above the strip, as built.** Both stay readable and the strip looks the same on every card.
2. **The price tag when you drag a shop card (PR 250).** Your buy-to-board mock-up says the price coin travels with the card. Prototype 18 says it drops off. **Recommend: travels, as built and as on dev,** so you see what you'll pay. Say "drops" and it's one switch.
3. **Turn-start income coins and the new shop dropping in (prototypes 9 and 10).** Are these in the recruit batch, or later? **Recommend: next batch.** The refresh's drop-in can be reused for them.
4. **Four proposed rules, waiting for your yes:**
   - 4.2.2a: buying straight onto an empty slot works at any hand size.
   - 7.1.2a: waiting cards can't be played, cast, sold or counted toward a triple.
   - 7.2.2a: a unit that must stay for the fight also stays when you try to swap it.
   - 7.2.3a: a swap uses the usual free-move timing, and neither unit's Recruit fires.

   **Recommend: yes to all four.** Each one is how the build already works.

Answer 1 and 2 and I merge both PRs into dev.

## Disk

Disk use: `/` 94 of 163 GB used, `/data` 14 of 70 GB used, the same at the start and at the end of the night.

Removed: the first animation worktree, which the fix replaced (312 MB), the animation films' scratch (29 MB, now in R2), and the gate scratch. Also the old fix-round-2 zip (184 MB, in R2).

Kept until PRs 249 and 250 merge, about 0.9 GB in all:
- the PR 249 worktree (351 MB) and its fixtures in `/data/tmp/w-type` (230 MB);
- the PR 250 fix worktree (320 MB) and `/data/tmp/w-anim2` (6 MB).

Kept for now: `/data/tmp/w-buy/shots` (38 MB), and tonight's zip in `/data/worktrees/build-win/build/windows` (186 MB, in R2) while the Taildrop retries.
