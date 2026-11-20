# Animations outside the fight: proposals (item 11, recruit half)

**Everything here is a proposal.** Nothing is decided; the owner chooses.

**I could not judge any motion by eye.** I checked only key frames (still screenshots at chosen moments) and the code. Speed, feel, easing, whether a motion reads at a glance, and whether a queue drags or rushes all need a person watching the page play.

Page: `docs/design/mockups/fix-round-20-nov/anim-recruit/index.html` (open the file in a browser; it loads the glass pieces from `docs/ideation-track-2/mockups/`). Each action has a looping prototype with Play, a scrubber, and a speed switch (1x, 1/2x, 1/4x) at the top. `index.html?shot=<id>&t=<ms>` draws one prototype's whole 1920 x 1080 screen frozen at that moment; that is how the PNGs were made.

**Cards are the dev branch's** (the branch the owner plays): units, stats, card text and prices (tier + 1) from dev's `src/content` (origin/dev 5d697e07), in `dev-cards.js`, which replaces `kit/data.js`'s main cards on this page. So there are no Medals or Orders: slots carry Renown (a pill over the slot, its points already in the unit's numbers), Actives are a round coin button, and Charge and Supply show as pips. Dev cards with no art yet show a plain glass panel.

47 actions: 16 new, 25 changed, 6 keep. "Now" is what the build does today, from the audit (`scratchpad/audit/actions.md`).

| # | Action | Mark | Now | Proposed | Timing |
|---|---|---|---|---|---|
| 1 | [Game opens to the start screen](index.html#p-boot) | changed | Instant. | The window lights up out of the dark, then the pane and its buttons settle in. | 0.9 s, once per launch. |
| 2 | [Toggle a tribe, or play only one](index.html#p-tribes) | changed | Instant redraw. | Turning a tribe on fills its amber ring and lifts the strike; "Only" turns the others off in a quick ripple. | 0.15 s per toggle; the ripple 40 ms apart, 0.3 s in all. |
| 3 | [Play: into the first recruit turn](index.html#p-play) | new | Instant swap. | The start pane lifts away and the recruit window comes up under it; the first shop drops in card by card. | 0.3 s out, shop lands over 0.5 s; about 1 s to playable. |
| 4 | [Open and close the card browser](index.html#p-browser) | changed | Instant. | The room dims, the browser's pane rises a little into place and its cards fill in, top left first. | Open 0.2 s, cards 20 ms apart (0.4 s); close 0.15 s. |
| 5 | [Pause and resume](index.html#p-pause) | changed | Instant. | Esc or the cog: the room dims and the pause pane settles from slightly small; Resume lets it go faster than it came. | Open 0.18 s, close 0.12 s. |
| 6 | [Hover a card](index.html#p-hover) | changed | The detail appears at once. | The card brightens and its detail grows in beside it; a hand card stands up first, as now. | Detail in 0.13 s, out 0.1 s; the hand card stands in 0.15 s. |
| 7 | [Open the leaderboard (Tab or your portrait)](index.html#p-board) | changed | Instant. | The leaderboard's pane unrolls down the right window and the players drop in, first place first. | Pane 0.2 s, rows 25 ms apart; 0.4 s in all. |
| 8 | [Open the Compost (click its plate)](index.html#p-compost) | changed | Instant. | What's in your Compost flies out of the plate and spreads out; closing sends it back. | Cards 0.26 s each, 35 ms apart (0.45 s); close 0.2 s. |
| 9 | [Turn starts: turn number and income](index.html#p-income) | changed | Both redraw at once. | The turn number flips; coins pour from the Next turn plate into your gold, which counts up as they land. | 0.8 s. Gold counts over 0.3 s from the first coin. |
| 10 | [Turn starts: a new shop](index.html#p-newshop) | changed | A 0.18 s cross-fade. | Last turn's shop sinks away; the new one drops in left to right, each price tag swinging in after its card. | Out 0.15 s, in 50 ms apart, 0.6 s in all. |
| 11 | [Turn starts: a frozen shop thaws](index.html#p-thaw) | new | The ice is gone at once. | The ice flashes and falls away card by card; the cards you froze stay. | 0.25 s per card, 40 ms apart; 0.5 s in all. |
| 12 | [Grudge pays, at the start of your turn](index.html#p-grudge) | new | Pays after the fight, unseen; next turn the numbers just pop. | Every unit with Grudge lights together; its gain rises from its Grudge mark and drops into its numbers. One beat however many there are. | 0.8 s for any number of units (50 ms apart). |
| 13 | [Relic Seeker's gold, at the start of your turn](index.html#p-relic) | new | Gold paid after the fight, unseen; not counted in the gold notice. | Relic Seeker lights and a coin arcs from it to your gold, which counts up as it lands. | 0.8 s. |
| 14 | [Old Campaigner gives its slot Renown](index.html#p-campaigner) | new | Renown given after the fight, unseen; the slot's pill just changes. | Old Campaigner lights; a gold star marked +2 (it survived) rises over it and drops onto its slot's Renown pill, which pops 1 to 3, and its numbers rise. | 0.8 s. |
| 15 | [Horde Runner gets a Hopper](index.html#p-hopper) | changed | The Hopper fades in, with nothing to say where from. | Horde Runner lights; the Hopper leaps out of it, grows as it arcs into the hand, and the hand opens to take it. | 0.75 s. |
| 16 | [Gold from the last fight (Shrew Cutpurse)](index.html#p-cutpurse) | changed | Static words on the transom ("+1 gold from the last fight"). | The gold arrives from the unit that earned it, as Relic Seeker's does, so no notice is needed. | 0.8 s. |
| 17 | [Start of turn, all together](index.html#p-queue) | new | Everything changes at once when the turn opens. | Income and the new shop first, then each effect in board order. Each starts sooner than the last, so a long queue speeds up instead of dragging. You can act at once; a press finishes the queue. | About 2.7 s here (gaps 0.42, 0.36, 0.31 s). One effect alone keeps its full beat. |
| 18 | [Buy a unit into your hand](index.html#p-buy) | changed | Carry, flight and hop as here; gold jumps, tag vanishes. | Carried as now. Let go over the hand, it flies to its place and hops; the hand opens for it. Its price tag drops off when lifted, and your gold counts down instead of jumping. | Lift 0.15 s, flight 0.25 s, hop 0.2 s; gold counts in 0.26 s. Keep: carry, flight and hop. Changed: gold and tag. |
| 19 | [Buy straight onto the board](index.html#p-buyboard) | new | Not possible: buys go to the hand only. | Carried from the shop, the empty slots light; let go over one, the unit drops in and hops. Works with a full hand. | Same as playing a unit: drop 4 to 6 frames, hop 0.2 s; gold counts in 0.26 s. |
| 20 | [Sell a unit](index.html#p-sell) | changed | The card fades and the gold jumps. | Over the shop it shows what it sells for; let go, it shrinks into the shop and a coin flies to your gold. | 0.45 s from let-go to gold. |
| 21 | [Sell to an eater (Gorger)](index.html#p-eat) | changed | Numbers pop with no light. | The sold unit flies shrinking into Gorger, as now; then Gorger lights and its numbers rise by what it ate. | Flight 0.3 s (keep), Gorger lights 0.35 s after. |
| 22 | [Sell a Seed into the Compost](index.html#p-compostsell) | keep | Flight and plate pop as here; gold jumps. | A unit with Seed flies shrinking to the Compost plate, which pops; the coin goes to your gold as for any sale. | Flight 0.3 s, plate pop 0.35 s (both as now); the coin is new. |
| 23 | [Bury a shop unit (Hedge-layer)](index.html#p-bury) | changed | The gold just changes. | Click Bury, then a shop unit: it flies shrinking into the Compost plate as now; then Hedge-layer lights and sends its gold. | Flight 0.3 s (keep); the effect 0.6 s after. |
| 24 | [Refresh the shop](index.html#p-refresh) | changed | A 0.18 s cross-fade; a place that rolls the same card doesn't change. | The button dips; the shop sinks and the new one drops in; the count above the button ticks down. | 0.5 s from the click to a full shop. |
| 25 | [Freeze and unfreeze](index.html#p-freeze) | changed | Instant. | Ice spreads over the shop from the Freeze button's side, card by card, with a white glint; unfreezing melts it all at once. | Freeze 0.18 s per card, 35 ms apart (0.4 s); unfreeze 0.15 s. |
| 26 | [Tier up](index.html#p-tierup) | changed | Instant redraw. | The button flashes and its tiers roll over; your gold counts down; a band of light sweeps across the shop. | 0.45 s. |
| 27 | [Not enough gold](index.html#p-poor) | changed | Words only. | Let go over the hand, the card flies home; the gold shakes and flashes red, and the reason shows on the transom. | Flight home 0.25 s (keep); shake 0.24 s; words hold 1.5 s. |
| 28 | [Duplicate and triple light, as the hand and board change](index.html#p-dupes) | changed | Marks snap on each redraw. | A shop copy of a unit you own has a soft glow. When one more buy would make a triple, all three copies flare to the strong glow and breathe; when that stops being true it fades back. | Flare 0.15 s, fade 0.25 s; the triple breath 1.4 s, as now. |
| 29 | [A triple forms, and its Triple Reward](index.html#p-triple) | keep | As built (recruit_triple_motion.gd). | As built: the three copies lift, gather, charge and flash; the golden unit is revealed, lands in the hand, and the Triple Reward comes out under it and follows. | 2.25 s (the build's beats: lift 14, gather 22, charge 14, flash 8, reveal 20, land 20, reward 27, tail 10 frames). A press finishes it. Re-created here roughly. |
| 30 | [Triple Reward with a full hand](index.html#p-rewardwait) | new | Reward is lost when the hand is full (card_lost, unseen). | The golden unit fills the hand's last place, so the Triple Reward goes to the waiting stack instead of being lost. | As the triple's reward beat (0.45 s), into the stack instead of the hand. |
| 31 | [Pick up and carry a card](index.html#p-carry) | keep | As built. | As built: lifts 1.2x and rises in 9 frames, then hangs from the pointer, leaning into its travel; every slot it can go to lights. | Lift 0.15 s; lean follows a spring. Re-created roughly; the build's own feel is the reference. |
| 32 | [Play a unit from the hand](index.html#p-playunit) | keep | As built. | As built: let go over a lit slot, it drops in and hops; the hand closes the gap. | Drop 4 to 6 frames, hop 0.2 s, hand closes in 0.2 s. |
| 33 | [A Recruit effect (Harvest Piper)](index.html#p-whenplayed) | new | The targets' numbers just pop. | On dev, Recruit fires on buy. The bought card lands in the hand and stands up, lights, and its +5 flies to every other Mouse at once, then their numbers rise. | 0.6 s after the land, however many targets. |
| 34 | [Choose a target (Master-at-Arms)](index.html#p-aim) | changed | Still rims, then numbers pop. | Buy it: "Choose a unit" shows and its targets' rims breathe while it stands in the hand; pick one and it lights, its Fury flies there and stamps onto the Fury mark (1 to 2). | Rims breathe 1.4 s; the effect 0.55 s after the click. |
| 35 | [Cast a spell on a unit (Sharpen)](index.html#p-spell) | changed | The spell fades and the numbers pop. | Let go over its target, the spell flashes and breaks into glass that flies into the unit; the unit lights and its numbers rise. | 0.55 s from let-go. |
| 36 | [Use an Active (Lance Corporal)](index.html#p-order) | changed | The slot pills redraw and numbers pop. | Click its round coin button: it dips and pays, the unit lights, and a +2 star flies to each slot in front; each slot's Renown pill pops and the unit there gains +2/+2. | 0.65 s from the click. |
| 37 | [Rearrange the board](index.html#p-reorder) | keep | As built. | As built: let go on another unit, they swap; the other slides over. | Drop 4 to 6 frames and hop; the other slides in 0.2 s. |
| 38 | [Take a board unit back into the hand](index.html#p-tohand) | keep | As built. | As built: let go over the hand, it flies into the fan and hops; the hand opens for it. | Flight 0.25 s, hop 0.2 s. |
| 39 | [Swap a hand card with a board unit](index.html#p-swap) | new | Refused with "choose an empty slot". | Carry a hand card over an occupied slot: that unit lifts a little to show it will move. Let go: the new unit drops in and the old one arcs into the hand where the new one was. | The two cross in 0.28 s, then each hops. |
| 40 | [A card arrives with a full hand: it waits](index.html#p-towait) | new | The card is lost and nothing says so. | Instead of being lost, the card flies to a small waiting stack beside the hand and the stack's count pops. | Same flight as into the hand (0.43 s) and a small hop. |
| 41 | [Room frees: the waiting card slides into the hand](index.html#p-fromwait) | new | Nothing: a card that would wait is lost. | Play a card out of a full hand and the waiting card slides from its stack into the hand at once; the stack's count goes. | Starts as the played card lands; slide 0.32 s and hop. The hand count dips and comes back. |
| 42 | [Discover opens (Seek)](index.html#p-discover) | changed | Veil and options appear at once. | Cast the spell: the room dims and the options rise out of where the spell was, spreading into a row. | Veil 0.18 s; options 0.28 s each, 60 ms apart. |
| 43 | [Discover: pick one](index.html#p-pick) | changed | The picked card fades into the hand. | The one you pick flies into the hand and hops; the others sink away and the room brightens. | 0.32 s flight, others out in 0.15 s, veil off in 0.15 s. |
| 44 | [End-of-turn effects, grouped](index.html#p-endfx) | new | They happen unseen before the fight. | Press End turn and your end-of-turn effects play on the board first, in board order, each sooner than the last: Sentry spends a Supply crate and its slot gains 1 Renown; Colour Sergeant (row full of Pigeons) sends one wave of +2 Renown along the row with a rising ×N, not four separate beats; Prophet of the Dust raises the Tide. | About 2 s here (gaps 0.38, 0.5 s; the wave 35 ms a slot). |
| 45 | [End turn: into the fight](index.html#p-tofight) | new | An instant swap to the fight screen. | The shop lifts away and the hand drops out of sight; your board slides to its fight place while the opponent's board drops in above. The fight half takes over from here. | 0.6 s. |
| 46 | [A player is knocked out](index.html#p-elim) | new | Next redraw shows a dimmed "out" portrait. | On the leaderboard, their Health runs down to 0 with a shake, their portrait greys and cracks, and they slide to the bottom as the others close up. | 0.9 s. |
| 47 | [Game over: the result](index.html#p-gameover) | new | Instant swap to the result. | The game fades through dark; your place stamps in, the standings fill in from first place down, and your row lights. | 1.4 s to the buttons. When you're out early, the same plays after the others finish. |

## Needs a person to judge

1. **Feel and speed of every motion.** All timings are first guesses, set from the build's existing beats (lift 0.15 s, flight 0.25 s, hop 0.2 s, triple 2.25 s) where one exists.
2. **The start-of-turn queue (17) and end-of-turn queue (44).** Each beat starts sooner than the last (gaps 0.42, 0.36, 0.31 s), per the owner note on fight timing and grouping. Whether that reads as "faster" or as "rushed", and where the floor should be, needs watching.
3. **Grouped beats.** Grudge (12) lights every Grudge unit in one beat; Lance Corporal's Active (36) sends both stars at once; the Renown wave (44) shows one wave with a rising x N counter instead of four beats. Whether x N reads at game speed needs a person.
4. **Order of start-of-turn effects.** I used income, new shop, then effects in board order. The owner may want another order.
5. **Can the player act during a queue?** Proposed: yes, and a press finishes the queue at once. Not prototyped as an interaction, only stated.
6. **The waiting stack (40, 41, 30).** Placed right of the hand, cards at 70% size with a count. Another item this round may decide its place and look; this only shows the motion.
7. **Glow strength.** The "source lights up" glow (lift 14 px, the fight's trigger style) and the triple flare may be too strong or too weak on real screens.
8. **Into the fight (45).** Only the recruit side is shown; the fight half owns what happens after. The handoff needs the two halves checked together.
9. **Sound.** None anywhere; much of the clarity in Battlegrounds comes from sound.
10. **Re-created "keep" items** (carry, triple, play, reorder, to hand) are rough copies; the build's own motion is the reference, not these.

## Choices and why

- **Every gain starts at its source.** A unit that causes a change lights first (the fight's trigger style, so it means the same in both places), then the gain flies to its target: the owner asked for each effect "shown with its source unit lighting up and the gain flying to the target". This also replaces the static "+N gold from the last fight" words (16), per the owner's rule that animation shows play, not reminders.
- **Numbers count, not jump.** Gold counts up or down as coins land, so the eye follows the change.
- **Start-of-turn effects replace end-of-fight ones (12 to 15).** They play when the turn opens, after income and the new shop, so the player sees them on their own board.
- **Nothing is lost silently.** A card arriving with a full hand goes to a waiting stack (40) and slides in when room frees (41); the Triple Reward does the same (30).
- **New actions reuse existing motion.** Buy onto the board (19) and swap (39) use the build's drop and hop, so they feel like moves the player already knows.

## In-game text used

All short, following the `ux-copy` rule. Existing words were kept where the build has them.

- Notices: "Not enough gold.", "Choose a unit", "Choose a shop unit", "Discover a unit".
- Buttons and labels: "Sell for" (with the coin), the Active's round button (its price coin only), "Bury", "Renown N" (the slot pill), "Next turn +16", "Hand N/7", "Turn 6", "You placed 3rd", "Round 14", "Play again", "Start screen", "Quit".
- Gain pills: "+2/+3", "+1/+1", "+1/+0", "+5", "Tide +1", "+2" and "+1" (Renown stars), "x4" (Renown wave), the waiting stack's count.

## Per action: page link, still and PNGs

PNGs are in `scratchpad/after/anim-recruit/` (72, one or two key frames each, 1920 x 1080, all drawn with dev cards). I looked at every one.

### Start, menus and the game frame

- **1. Game opens to the start screen** (changed). `index.html#p-boot`; still: `index.html?shot=boot&t=900`. PNGs: `anim-01-boot-900ms.png`.
- **2. Toggle a tribe, or play only one** (changed). `index.html#p-tribes`; still: `index.html?shot=tribes&t=1050`. PNGs: `anim-02-tribes-1050ms.png`, `anim-03-tribes-2450ms.png`.
- **3. Play: into the first recruit turn** (new). `index.html#p-play`; still: `index.html?shot=play&t=1150`. PNGs: `anim-04-play-1150ms.png`.
- **4. Open and close the card browser** (changed). `index.html#p-browser`; still: `index.html?shot=browser&t=1250`. PNGs: `anim-05-browser-1250ms.png`.
- **5. Pause and resume** (changed). `index.html#p-pause`; still: `index.html?shot=pause&t=850`. PNGs: `anim-06-pause-850ms.png`.
- **6. Hover a card** (changed). `index.html#p-hover`; still: `index.html?shot=hover&t=800`. PNGs: `anim-07-hover-800ms.png`, `anim-08-hover-3050ms.png`.
- **7. Open the leaderboard (Tab or your portrait)** (changed). `index.html#p-board`; still: `index.html?shot=board&t=700`. PNGs: `anim-09-board-700ms.png`.
- **8. Open the Compost (click its plate)** (changed). `index.html#p-compost`; still: `index.html?shot=compost&t=1300`. PNGs: `anim-10-compost-1300ms.png`.

### Start of your turn

- **9. Turn starts: turn number and income** (changed). `index.html#p-income`; still: `index.html?shot=income&t=900`. PNGs: `anim-11-income-900ms.png`.
- **10. Turn starts: a new shop** (changed). `index.html#p-newshop`; still: `index.html?shot=newshop&t=800`. PNGs: `anim-12-newshop-800ms.png`.
- **11. Turn starts: a frozen shop thaws** (new). `index.html#p-thaw`; still: `index.html?shot=thaw&t=560`. PNGs: `anim-13-thaw-560ms.png`.
- **12. Grudge pays, at the start of your turn** (new). `index.html#p-grudge`; still: `index.html?shot=grudge&t=650`. PNGs: `anim-14-grudge-650ms.png`, `anim-15-grudge-1150ms.png`.
- **13. Relic Seeker's gold, at the start of your turn** (new). `index.html#p-relic`; still: `index.html?shot=relic&t=820`. PNGs: `anim-16-relic-820ms.png`.
- **14. Old Campaigner gives its slot Renown** (new). `index.html#p-campaigner`; still: `index.html?shot=campaigner&t=700`. PNGs: `anim-17-campaigner-700ms.png`, `anim-18-campaigner-1310ms.png`.
- **15. Horde Runner gets a Hopper** (changed). `index.html#p-hopper`; still: `index.html?shot=hopper&t=850`. PNGs: `anim-19-hopper-850ms.png`.
- **16. Gold from the last fight (Shrew Cutpurse)** (changed). `index.html#p-cutpurse`; still: `index.html?shot=cutpurse&t=820`. PNGs: `anim-20-cutpurse-820ms.png`.
- **17. Start of turn, all together** (new). `index.html#p-queue`; still: `index.html?shot=queue&t=1500`. PNGs: `anim-21-queue-1500ms.png`, `anim-22-queue-3300ms.png`.

### The shop

- **18. Buy a unit into your hand** (changed). `index.html#p-buy`; still: `index.html?shot=buy&t=1300`. PNGs: `anim-23-buy-1300ms.png`, `anim-24-buy-1700ms.png`.
- **19. Buy straight onto the board** (new). `index.html#p-buyboard`; still: `index.html?shot=buyboard&t=1300`. PNGs: `anim-25-buyboard-1300ms.png`, `anim-26-buyboard-1650ms.png`.
- **20. Sell a unit** (changed). `index.html#p-sell`; still: `index.html?shot=sell&t=1300`. PNGs: `anim-27-sell-1300ms.png`, `anim-28-sell-1650ms.png`.
- **21. Sell to an eater (Gorger)** (changed). `index.html#p-eat`; still: `index.html?shot=eat&t=1700`. PNGs: `anim-29-eat-1700ms.png`, `anim-30-eat-2050ms.png`.
- **22. Sell a Seed into the Compost** (keep). `index.html#p-compostsell`; still: `index.html?shot=compostsell&t=1650`. PNGs: `anim-31-compostsell-1650ms.png`.
- **23. Bury a shop unit (Hedge-layer)** (changed). `index.html#p-bury`; still: `index.html?shot=bury&t=1150`. PNGs: `anim-32-bury-1150ms.png`, `anim-33-bury-2450ms.png`.
- **24. Refresh the shop** (changed). `index.html#p-refresh`; still: `index.html?shot=refresh&t=1000`. PNGs: `anim-34-refresh-1000ms.png`.
- **25. Freeze and unfreeze** (changed). `index.html#p-freeze`; still: `index.html?shot=freeze&t=950`. PNGs: `anim-35-freeze-950ms.png`.
- **26. Tier up** (changed). `index.html#p-tierup`; still: `index.html?shot=tierup&t=1050`. PNGs: `anim-36-tierup-1050ms.png`.
- **27. Not enough gold** (changed). `index.html#p-poor`; still: `index.html?shot=poor&t=2000`. PNGs: `anim-37-poor-2000ms.png`.
- **28. Duplicate and triple light, as the hand and board change** (changed). `index.html#p-dupes`; still: `index.html?shot=dupes&t=1250`. PNGs: `anim-38-dupes-1250ms.png`, `anim-39-dupes-3050ms.png`, `anim-40-dupes-7300ms.png`.
- **29. A triple forms, and its Triple Reward** (keep). `index.html#p-triple`; still: `index.html?shot=triple&t=2250`. PNGs: `anim-41-triple-2250ms.png`, `anim-42-triple-2860ms.png`.
- **30. Triple Reward with a full hand** (new). `index.html#p-rewardwait`; still: `index.html?shot=rewardwait&t=1300`. PNGs: `anim-43-rewardwait-1300ms.png`.

### Hand and board

- **31. Pick up and carry a card** (keep). `index.html#p-carry`; still: `index.html?shot=carry&t=1700`. PNGs: `anim-44-carry-1700ms.png`.
- **32. Play a unit from the hand** (keep). `index.html#p-playunit`; still: `index.html?shot=playunit&t=1300`. PNGs: `anim-45-playunit-1300ms.png`, `anim-46-playunit-1700ms.png`.
- **33. A Recruit effect (Harvest Piper)** (new). `index.html#p-whenplayed`; still: `index.html?shot=whenplayed&t=2250`. PNGs: `anim-47-whenplayed-2250ms.png`, `anim-48-whenplayed-2850ms.png`.
- **34. Choose a target (Master-at-Arms)** (changed). `index.html#p-aim`; still: `index.html?shot=aim&t=2400`. PNGs: `anim-49-aim-2400ms.png`, `anim-50-aim-3910ms.png`.
- **35. Cast a spell on a unit (Sharpen)** (changed). `index.html#p-spell`; still: `index.html?shot=spell&t=1720`. PNGs: `anim-51-spell-1720ms.png`, `anim-52-spell-2150ms.png`.
- **36. Use an Active (Lance Corporal)** (changed). `index.html#p-order`; still: `index.html?shot=order&t=1100`. PNGs: `anim-53-order-1100ms.png`, `anim-54-order-1910ms.png`.
- **37. Rearrange the board** (keep). `index.html#p-reorder`; still: `index.html?shot=reorder&t=1650`. PNGs: `anim-55-reorder-1650ms.png`.
- **38. Take a board unit back into the hand** (keep). `index.html#p-tohand`; still: `index.html?shot=tohand&t=1700`. PNGs: `anim-56-tohand-1700ms.png`.
- **39. Swap a hand card with a board unit** (new). `index.html#p-swap`; still: `index.html?shot=swap&t=1450`. PNGs: `anim-57-swap-1450ms.png`, `anim-58-swap-1720ms.png`.
- **40. A card arrives with a full hand: it waits** (new). `index.html#p-towait`; still: `index.html?shot=towait&t=900`. PNGs: `anim-59-towait-900ms.png`, `anim-60-towait-1150ms.png`.
- **41. Room frees: the waiting card slides into the hand** (new). `index.html#p-fromwait`; still: `index.html?shot=fromwait&t=1720`. PNGs: `anim-61-fromwait-1720ms.png`, `anim-62-fromwait-2050ms.png`.
- **42. Discover opens (Seek)** (changed). `index.html#p-discover`; still: `index.html?shot=discover&t=1850`. PNGs: `anim-63-discover-1850ms.png`.
- **43. Discover: pick one** (changed). `index.html#p-pick`; still: `index.html?shot=pick&t=1150`. PNGs: `anim-64-pick-1150ms.png`.

### End of turn

- **44. End-of-turn effects, grouped** (new). `index.html#p-endfx`; still: `index.html?shot=endfx&t=1500`. PNGs: `anim-65-endfx-1500ms.png`, `anim-66-endfx-2970ms.png`.
- **45. End turn: into the fight** (new). `index.html#p-tofight`; still: `index.html?shot=tofight&t=1150`. PNGs: `anim-67-tofight-1150ms.png`, `anim-68-tofight-1500ms.png`.

### Knock-outs and game over

- **46. A player is knocked out** (new). `index.html#p-elim`; still: `index.html?shot=elim&t=800`. PNGs: `anim-69-elim-800ms.png`, `anim-70-elim-1400ms.png`.
- **47. Game over: the result** (new). `index.html#p-gameover`; still: `index.html?shot=gameover&t=1250`. PNGs: `anim-71-gameover-1250ms.png`, `anim-72-gameover-2200ms.png`.

## Limits of what was checked

- Every prototype loads with no console errors in headless Chrome; loops run 1 to 7.4 s.
- Key frames were checked for: the right pieces at the right place, numbers adding up across effects, nothing hidden behind another piece, text readable.
- Not checked: motion between key frames, frame rate, how it looks on the owner's screen, or the real Godot build. The page is HTML and Web Animations, not the game.
