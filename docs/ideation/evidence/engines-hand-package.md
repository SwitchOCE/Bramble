# Line B: four Hard games on the engines package

Flags: last_blow, last_four, last_stand, kin_only, heirloom, supper3. Seeds 401–404.

**1. Supper rush: healthy.** As the March Hare I reached tier 3 by round 2 and played Fairies (401, 1st). Supper appeared only three times in rounds 4–10, so I hit the +3 cap on round 10. In 403 I cast it only twice. The shop's one spell slot limits it, so it is neither forced nor dominant. Committing pays: every unit gets +2 or +3, new ones included. The no-tribe board could aim it at 2 units.

**2. Last Stand / Last Four: healthy, two cracks.** One lead change in the last four per game. The one real comeback was 401, won from 3rd of 4. In 401 all three finalists used their save, so it cancelled out and only added rounds. In 403 it just delayed my loss (22, then 23 damage).
- *Cliff at 5 Health:* a hero on exactly 5 gets no save. The Hare died that way in 403.
- *Ghosts burn it:* a ghost fight spent my save in 404.

Fix: ghost fights don't trigger it, and it saves from any Health of 2 or more. Untested: with more than 5 Health in the last four, selling out for one turn is free.

**3. Hand-me-down funnel: weak, not broken.** My biggest gift was +3/+3, and no carrier got more than about +5 by round 12. Growth comes from Supper, Rings and goldens, which don't pass. The as-built rounding leaks: a +1/+1 gain passes whole (Mr Crumb gave Spitfire Sal +1/+1). The fixed text (round down, one sale feeds one play) closes it. Cut it first.

**4. Stay low, no tribe: dethroned late.** At tier 2 until round 10 with a golden Hedge Witch (Hex 16), I went 9–1 and led on 35 Health at four left. Then I lost four straight (12/15/18/17) and placed 3rd. Under the old 12 cap it lasts about a round longer. The outlier is the card: golden Hedge Witch's −16 Attack takes only 8 spells.

| Seed | Line | Place | Decisive fights | Biggest unit (source) |
|---|---|---|---|---|
| 401 | Hare, Supper rush Fairies | 1st | R12 lost 12 (Hoolet's Changelings stole my Reel-Mistresses); R13 lost 13 (saved); won R14/16/17, Jill and Hoolet each saved once | Golden Reel-Mistress 23/27 (triple, Supper, Last Orders) |
| 402 | Hob, Bog folk, funnel | 5th | R9 lost 10, down to 5; R11 lost 11, five left, no save | Prince Restored 11/12 (Crumb pass, Supper) |
| 403 | Bracken, Hunters, funnel | 2nd | R13 lost 12 (lead change); duel R15 22 (saved), R16 23 | Golden Laird 20/21 (two Hiring Fairs plus a triple, Ring); hers: Young Brock 22/21 (Ring +10/+10) |
| 404 | Pipkin, stay low | 3rd | R11–14 lost 12/15/18 (ghost, saved)/17 | Golden Hedge Witch 17/25 (triple, cheap spells) |

**Details**
- Last Blow never decided a fight I saw.
- Kin-only works as specified: Lamp Moth got 0 and Bridge Toad +2/+2.
- Moving units erases Rainbow bands, so dodging the Queen's Teind costs Attack.
- Hard bots lost most fights before round 10 to every line. They won late through Rings and goldens.

Notes: `/tmp/claude-0/lineB/notes.md`. Saves: `g401`–`g404.json`.
