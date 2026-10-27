# Once Upon a Galaxy: design notes for Bramble

What Galaxy does that matters most for Bramble, and what to borrow. Rules and sources are in [rules.md](rules.md), the dated record of changes in [patch-history.md](patch-history.md), and the cards in [content-library.md](content-library.md). Researched 27 Oct 2026.

**Bramble's board, as decided.** Fixed slots on a 4–3 grid: front F1–F4, back B1–B3. Each back slot sits between two front slots: B1 between F1 and F2, B2 between F2 and F3, B3 between F3 and F4. Players may leave gaps. Units never slide or pack when others die. The back row can't be targeted while any front unit lives. Attack order is the front row left to right, then the back row left to right, repeating, with empty slots skipped.

---

## 1. Galaxy's board is a smaller version of Bramble's

- **Same geometry, one size down.** Galaxy has 3 front slots and 2 back, with each back slot centred between two front slots ([Board](https://guide.galaxy.fun/board/), checked against the guide's board image). Bramble's 4–3 is the same brick pattern at Battlegrounds' 7-unit size.
- **Galaxy does not pack.** Slots are fixed objects. The rules that show it:
  - "First slot" means slot 1 "regardless of whether or not the slot has a character in it".
  - Summons take the KO'd source's slot and fail if there's no space.
  - A Farewell's first summon goes in the dead character's slot.
  - A summon inherits the slot's place in the attack order.
  - Slot buffs and Paint stay on slots when characters change.
  - Sources: [Summon](https://guide.galaxy.fun/summon/), [Farewell](https://guide.galaxy.fun/farewell/), [Slot Buffs](https://guide.galaxy.fun/slot-buffs/).
  - No sentence says "units don't slide" outright, but all of the above depend on it. The owner's belief is correct.
- **Empty slots.** They exist early in every game, since you get 2 picks a turn for 5 slots. Characters can be moved between slots in the shop phase. Whether you can leave a front slot empty on purpose while the back is filled is UNVERIFIED. With no front-row characters, attacks go to the back row.
- **Same attack order.** Left to right, front to back, from slot 1 ([Attack Order](https://guide.galaxy.fun/attack-order/)).
- **Targeting differs in one way.** Galaxy attacks a random front-row enemy if possible, so the back row is safe while any front character lives. The exception is **Sneak**, which goes for the back row first. Bramble has the same protection rule; the open question is whether Bramble wants a Sneak-style exception.
- **Position vocabulary in use** (card text, [card database](https://guide.galaxy.fun/cards/)):
  - "in front of me": the two diagonal front slots.
  - "behind me".
  - "neighbors" and "adjacent".
  - "front row" and "back row".
  - "first slot" and "first character".
  - "the enemy across from me".
  - "the slots behind where I attack" (splash damage).
- **Stagger asymmetry.** Galaxy's middle front slot is the only one with two supporters behind it. Bramble's F2 and F3 each have two back slots behind; F1 and F4 have one. Every back slot in both games has exactly two front slots in front.

## 2. Position and adjacency effects worth studying

Each line gives the card, its text from the [card database](https://guide.galaxy.fun/cards/), and the design pattern it shows.

| Card | Text | Pattern |
|---|---|---|
| Puck, Pix | "Support — +2 Attack / +2 Health" | Back-row aura to the two front slots |
| Oberon, Titania | "Support — Each fight, give characters in front of me +20 Attack / Health" | Back-row engine that grows the front permanently |
| Tink | "When a character in front of me attacks, give it +1/+1" | Back unit reacts to a front unit's action |
| Prickles | "When a character in front of me is attacked, give it +1/+1" | Back unit reacts to the front taking hits |
| Mephisto | "When a character in front of me is KO'd, it is gone for good and I steal its Attack and Health" | The owner's "when the unit in front of this dies…" |
| Sleeping Giant | "When I'm attacked, give the characters behind me +1/+1" | Front unit feeds the back |
| Huntsman's Axe (treasure) | "Your front row characters have 'Hunt — Trigger the hunt abilities of the characters behind me.'" | Relay: a front action fires a back ability |
| Daisy Jones | "Hunt — +2/+2 and trigger the Farewell abilities of the characters behind me" (now inactive) | Relay |
| Snapping Hydra | "I also damage one of the characters in the slots behind where I attack" | Splash through to the back row |
| Wicked Witch | "After I attack, reduce that enemy and the ones next to it to 1 Health" | Adjacency splash |
| Sapphire (captain), Gingerbread House, Greenbeard | buff "adjacent" characters or "neighbors" on KO or Hunt | Row neighbours |
| Mirror Mirror, Viscount Chocolat, Mix-O Match-O | "the enemy across from me" | Column duel between facing slots |
| Boon Willow, Daedalus | "Give my slot buff to the characters in front of me" / "Double the slot buffs in front of me" | Back unit amplifies the slots in front |
| Crow's Nest, Witches III, The Kraken, Down Came the Rain | buff back-row or front-row slots | Row-wide slot buffs |
| Parting Gift, Osiris, Bounty Contract | "Double the Farewell abilities of your front row"; "trigger all … Farewell abilities in your front row"; "Your front row has Hunt…" | Rule modifiers scoped to a row |
| Chip on the Ship | "Each fight, I break your Toys that are in front of me" | Sacrifice the front to power the back |
| Master Artisan | "transform a character behind me into a Secret Rare" | Shop-phase position payoff |

**How the developers tuned position**
- Supports are "so lowly statted" that payoff cards for them needed help ([20 Nov 2025](https://galaxy.fun/articles/patch-mid-november-2025/)).
- Early supports (Pix, Puck) caused "more full heart losses than we prefer early in games" and were cut to +2 ([16 Mar 2026](https://galaxy.fun/articles/patch-mid-march-2026/)).
- Being "attacked first" is a known cost of front units: Big Bad Wolf got more Health ([15 Jan 2026](https://galaxy.fun/articles/patch-mid-january-2026/)).
- Parting Gift was nerfed by restricting it to the front row ([18 Sep 2025](https://galaxy.fun/articles/patch-mid-september-2025/)). Position works as a balance dial.

## 3. Economy and anti-infinite limits

**Economy without gold.** Galaxy has no gold, rerolls or selling. You get 2 shops a turn and take one card from each. Galaxy's economy is entirely about **shop count**: Silvers, spells, losses and captains give bonus shops ([Shop](https://guide.galaxy.fun/shop/)). Captains mostly bend this rule:
- extra shops with fewer cards in each;
- shops of treasures instead of characters;
- one shop one rarity higher.

**Limits Galaxy added, each after a real problem**
| Limit | Date | Source |
|---|---|---|
| Resummons capped at 5 per character | Jul 2024 | [link](https://galaxy.fun/articles/patch-early-july/) |
| Escalating abilities stop at Legendary (Sir Francis Drake) | Nov 2024 | [link](https://galaxy.fun/articles/patch-early-november/) |
| "Double" means +1 trigger, not ×2 | Aug 2025 | [link](https://galaxy.fun/articles/patch-early-september-2025/) |
| An abandoned or looping async fight counts as a win for the active player | Aug and Nov 2025 | [Aug](https://galaxy.fun/articles/patch-early-september-2025/), [Nov](https://galaxy.fun/articles/patch-mid-november-2025/) |
| Repeated triggers play one animation with a multiplier, to stop it "clogging up your screen, memory, and time" | Jul 2025 | [link](https://galaxy.fun/articles/patch-mid-july-2025/) |
| Shop cap: at 30 shops a turn you get a consolation treasure (Limit Breaker, +10/+10) and no further bonus shops; one-off rewards (quests, goldens) still resolve | Apr–May 2026 | [link](https://galaxy.fun/articles/patch-mid-may-2026/) |
| Boons check at the start of the fight, so they can't be completed twice in a turn | May 2026 | [link](https://galaxy.fun/articles/patch-mid-may-2026/) |
| Exponential combos removed (Pixie Dust + Wyrmscale Tinkerer) "to give other finishers a chance to shine" | Apr 2026 | [link](https://galaxy.fun/articles/mythbound-release/) |

**Scaling philosophy.** Galaxy accepts huge numbers. All buffs are permanent, including buffs gained in a fight, and Legendaries start at 20–30 stats but grow "into the hundreds or thousands" ([Janson](https://www.beaconofcreation.com/2025/10/01/design-crossover-once-upon-a-galaxy/)). What the team polices is *loops and pace*, not big numbers. Its main pacing measure is "full heart damage … in the early turns".

## 4. What players and reviewers say

Sources: Steam reviews ([top rated](https://steamcommunity.com/app/3062740/reviews/?browsefilter=toprated), [recent](https://steamcommunity.com/app/3062740/reviews/?browsefilter=mostrecent&filterLanguage=english)), [Notebookcheck](https://www.notebookcheck.net/Easily-one-of-my-new-favorite-games-free-release-on-Steam-earns-praise-but-still-flies-under-the-radar.1090991.0.html), the [Pocket Tactics preview](https://www.pockettactics.com/once-upon-a-galaxy/review), [Steam discussions](https://steamcommunity.com/app/3062740/discussions/2/769679119154682589/) and the [App Store](https://apps.apple.com/us/app/once-upon-a-galaxy/id6504776189). Reddit was not reachable, so its opinions are not represented (UNVERIFIED).

**Numbers.** Steam: 77% of 762 reviews positive all-time, but 35% of 14 in the last 30 days (27 Oct 2026). Peak concurrent players on Steam were 382; the monthly average was about 98 in Sep 2026 ([SteamCharts](https://steamcharts.com/app/3062740)). iOS: 4.8 stars from about 1.4K ratings. Most players are on mobile (INFERRED from the roadmap's "few minutes every day" note).

**Praised**
- Fast games of 10–20 minutes. No timers, and you can play async at your own pace.
- "Positioning, timing, and synergy matter greatly."
- Distinct captains.
- Hand-made art.
- A surprising skill ceiling in a slim ruleset.
- Called a "spiritual successor to Storybook Brawl".

**Criticised**
- Only 3 hearts, with full-heart losses possible by turn 2.
- Swingy shops: early Silvers, Goldens and bonus-shop chains let some boards run away. With 2 picks and no gold, a bad shop can't be fixed by spending.
- Distrust of async ghost boards at high MMR.
- Power creep in new captains. Chromaria's start-of-game effects decide games by turns 4–5.
- Collection cost (a full collection is estimated at about $1,730) and paid rerolls, seen as pay-to-win.
- A thin tutorial and opaque targeting.

**Takeaways for Bramble**
- Galaxy's tight rules give it speed and positional depth. Its pain points are swingy copy and bonus-shop chains, early blowouts, and too little player control over a bad shop.
- Bramble's gold, rerolls and Battlegrounds-style health already answer the control complaint.
- Bramble should copy Galaxy's slot model and position keywords, not its no-gold economy.

## 5. Ideas Bramble could adapt to the fixed-slot 4–3 board

Each idea is written for: fixed slots F1–F4 and B1–B3, gaps allowed, no packing, the back row untargetable while any front unit lives, and the attack order front left to right, then back left to right, repeating.

1. **Support (back to front diagonals) as the signature back-row keyword.** "Support — +X/+Y" gives an aura to the two front slots a back unit sits between.
   - On 4–3, F2 and F3 each take two supports. They become premium "keystone" slots, and F1 and F4 become flank slots with one supporter each. That gives players a real placement decision for free.
   - Keep auras non-permanent, as Galaxy does and as fits Battlegrounds. The back unit's survival then matters, and back-row protection makes auras stable until the front collapses.

2. **Reaction support: "When a unit in front of me attacks / is attacked / dies…"** (Galaxy: Tink, Prickles, Mephisto). These are the owner's own examples, and they give back units something to do before their own attack. Because nothing packs, "in front of me" always means the same two slots for the whole fight, even after they empty. Pair this with idea 7.

3. **"Behind me" payoffs for front units.** Examples: Sleeping Giant's "When I'm attacked, give units behind me +1/+1", and relay effects like Huntsman's Axe ("…trigger the abilities of units behind me").
   - F2 and F3 relay to two back units; F1 and F4 to one. This mirrors idea 1, giving the flanks a different job from the centre.

4. **A Sneak equivalent as the one exception to back-row protection.** Something like a "Pounce" or "Swoop" keyword for owls, bats or fairies. Galaxy needed Sneak; without it, back-row engines are untouchable until the front dies.
   - Recommended rule: target a random back-row unit if any exist, otherwise any unit.
   - This is the main counterplay lever to tune how strong back rows are. Consider letting it ignore protection only on its *first* attack each fight.

5. **Ranged gated by row.** Galaxy's Ranged means no retaliation when attacking. In Bramble, back-row units attack after the whole front row.
   - Option: Ranged works only from the back row ("archer" Squirrels and Owls). A back-row Ranged unit is safe twice over (untargetable and no retaliation), so give it low Attack or few charges.
   - Galaxy's counter-card pattern is worth copying: Mirror Mirror reflects Ranged damage onto the unit it supports.

6. **Splash "through" the line.** Snapping Hydra: "I also damage one of the characters in the slots behind where I attack." With staggered rows, a front-row defender has one or two back slots behind it.
   - This is the gentle way to pressure the back row without breaking protection: it is damage, not a target choice.
   - "Trample" (excess damage carries to a unit behind) is a stronger variant.

7. **Explicit movement: "Step Up".** Because Bramble never packs, a unit that *chooses* to move is distinctive.
   - Example: "Step Up: when a front slot in front of me becomes empty, move into it (keeping my attack turn)."
   - Galaxy has no movement keyword. This is new design space that only a no-packing board creates. Use Galaxy's summon rule (a unit entering a slot inherits that slot's attack priority) to keep attack order deterministic.

8. **Summons fill the dead unit's slot.** Adopt Galaxy's rules directly:
   - the first summon goes into the dying unit's slot;
   - further summons go into empty slots by a fixed priority (to decide; for example, nearest in the same row, then the other row);
   - a summon fails if the board is full;
   - a summon inherits the slot's attack priority.
   - This keeps Deathrattle/Farewell-style effects positional, and lets gaps act as "summon space", a cost to leaving no gaps. Oozes splitting into adjacent empty slots is a natural fit.

9. **Slots as persistent objects ("habitats").** Galaxy's slot buffs and Paint attach to a position and survive unit swaps, and several captains key off them.
   - Woodland versions: a fairy ring, a burrow or a mossy stump on a slot, giving "+1/+1 to the unit here" or "the unit here has Sneak".
   - Fixed slots make this cheap to implement.
   - It is a scaling outlet that doesn't grow a single unit to infinity. It also gives the game-warping modifier layer (see [architecture-notes.md](../../design/architecture-notes.md)) a natural target: modifiers that attach to slots or rows.

10. **Row-scoped rule modifiers.** Galaxy tunes treasures and captains by row:
    - Parting Gift: double front-row Farewells;
    - Osiris: trigger front-row Farewells at the start of the fight;
    - Crow's Nest: back-row slots +10/+10.
    - For Bramble's trinket-, anomaly- or quest-style modifiers, "front row" and "back row" are clean, readable scopes. Restricting a modifier to one row is also a nerf lever that doesn't need new rules text.

11. **Facing columns: "the enemy across from me".** Galaxy uses mirrored slots for duel effects (Mirror Mirror copies the facing enemy's keywords; Viscount Chocolat steals stats each fight).
    - On a 4–3 board, F1–F4 face enemy F1–F4 and B1–B3 face enemy B1–B3. That is clean, because both boards share the geometry.
    - Decide what "across" means when the facing slot is empty: probably "no effect", which makes gaps a defensive tool against duel effects.

12. **Make the gap itself a mechanic.** Since gaps are allowed and don't change targeting (the back row stays protected while any front unit lives), a gap costs only a body. Give gaps value:
    - "If the slot beside me is empty, I have +2 Attack";
    - summon space (idea 8);
    - Step Up targets (idea 7).
    - Galaxy's Underdog ("If you have fewer characters than the enemy when I attack…") rewards fielding fewer units; adapt it as a fairy or ooze tribe identity.

13. **A soft landing for the reroll cap.** Galaxy's Limit Breaker doesn't silently wall off bonus shops: at 30 it hands over a consolation reward, lets queued one-off rewards (quests, goldens) finish, and only then stops. For Bramble's escalating reroll costs (1, then 2, then 3):
    - consider a final threshold that grants a small fixed reward and ends cheap generation for the turn;
    - make sure "free" reroll and refresh effects count toward the thresholds.
    - Galaxy found that chained free shops, not paid ones, made the loops.

14. **Write the loop guards in from day one.** Each of Galaxy's guards came after a real exploit:
    - cap resummons per unit per fight (Galaxy: 5);
    - define "double" as "+1 trigger";
    - decide what an over-long or looping combat resolves to (Galaxy gives the active player the win; Battlegrounds-style would be a draw);
    - collapse repeated triggers into one animation with a counter.
    - These belong in the combat engine's base rules, not on cards.

15. **Watch early pace through back-row auras.** Galaxy's most-cited balance problem is early full-heart losses, and two of its culprits were cheap supports (Pix, Puck) and a tanky early wall. With back-row auras protected by the front row, Bramble's tier-1 and tier-2 support numbers should be conservative. Track an early "lethal-swing" metric the way Galaxy tracks early full-heart damage.

## 6. Things Bramble should *not* copy

- **No gold and only 2 picks.** This makes Galaxy fast, but players report it as swingy and uncontrollable. Bramble's owner has chosen gold, carry-over and rerolls.
- **Permanent combat buffs and summon buffs.** They drive Galaxy's numbers into the thousands and make async ghost boards hard to read. Battlegrounds' rule (combat buffs are temporary unless a card says otherwise) is the better default; make permanence an explicit keyword.
- **Collectible decks feeding personal pools.** This is a monetization structure, and it drew the "pay-to-win" criticism. Bramble's plan of a lobby-level tribe subset is simpler and fairer.
