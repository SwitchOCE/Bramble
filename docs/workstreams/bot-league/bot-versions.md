# The league's bots: versions, strength and the fields made from them

As of 25 Nov 2026, with the league on hold. Written by the card power session from the referee's run notes and match verdicts. To bring it up to date, read the same sources (last section).

## The two bots that matter

| Bot | How it plays | Stopping test | Team lead |
|---|---|---|---|
| **red-c14** | Picks its tribe freely, from card values learned on games of every tribe. Ends on Locust in about 70% of games, on no single tribe in about 23%, on Badger in about 6%. | Passed, 23 Nov (27 small changes tried, none better) | Opus |
| **blue-c17** | Commits to Badger from turn one, every game. | Not passed (keeping three hand slots free beat it twice) | Codex, `gpt-6.2-astra` |

- **Head to head, live:** red averages 4.13 and blue 4.87 (lower is better). Blue comes first more often: 15.5% of seats against 9.5%.
- **Against the climbing field:** blue-c17 averages about 1.8 to 2.0 and red-c14 about 2.1 to 2.2. Both win most of their games there, so that field is too weak to test them on.
- **Held to one tribe, on a strong field:** blue-c13 (the first Badger bot) averaged Badger 4.63, Locust 5.77, Briar 6.70, Pigeon 6.96, Mouse 6.99. Blue only plays Badger well. No bot plays Mice or Briars as its main tribe.

## Every kept version

A version is kept when it beats the team's last kept version over 1,000 paired games. "Place" is its average place in that match, against the field as it stood then; lower is better.

### Red

| Version | What changed | Place | Gain over the last kept |
|---|---|---|---|
| red-m2 | The team's bot from the earlier league | 3.80 | |
| red-c1 | Holds Reserve units in hand on a full board | 2.89 | −0.91 |
| red-c2 | Card values refitted for the new cards, from its own ghost fights | 2.43 | −0.45 |
| red-c3 | Levels up one round later | 2.45 | −0.34 |
| red-c9 | Card values relearned from 5,000 games with each tribe played in turn | 2.23 | −0.65 |
| red-c10 | A second refit of the same kind | 2.24 | −0.24 |
| **red-c14** | Slower to swap a board unit for a shop unit | 2.06 | −0.24 |

Handed in and not kept: c4 to c8, c11 to c13, c15, c16.

### Blue

| Version | What changed | Place | Gain over the last kept |
|---|---|---|---|
| blue-m2 | The team's bot from the earlier league | 4.35 | |
| blue-c2 | Keeps reinforcements in hand for the fight | 3.26 | −1.09 |
| blue-c4 | Sells a weak hand unit before a board unit | 3.48 | −0.20 |
| blue-c6 | Buys and keeps by each card's measured fight value | 2.70 | −0.94 |
| blue-c7 | A hand-set bonus for Sword-heir, from its own replacement fights | 2.69 | −0.27 |
| blue-c8 | Reaches tier 2 a round later | 2.48 | −0.57 |
| blue-c9 | The Sword-heir bonus doubled. Mixed boards and Pigeons place best | 1.94 | −0.56 |
| blue-c13 | Commits to Badger from turn one | 1.63 | −0.83 |
| **blue-c17** | Slower to swap a board unit for a shop unit | 1.84 | −0.16 |

Handed in and not kept: c1, c3, c5, c10 to c12, c14 to c16, c19. Set aside for the owner, not rejected: c18.

The tags `m1`, `m2` and `s0` to `s3` on both teams are from the earlier league and its practice rounds.

## Fields

A field is a store of recorded games ("runs") that a bot plays against as ghosts.

| Field | Where | What is in it | Use |
|---|---|---|---|
| Climbing field | `/data/third-run/field-fa1d51ec` (the league's; read only) | 15,000 runs: 8,000 from the two starting bots and 500 from each of the 14 kept versions | Comparing a new version with the last. Too weak for whole-game card tests |
| Top-two field | `/data/card-power/ref-field` (the card power session's; made 25 Nov) | About 12,000 runs from 1,500 live games of red-c14 against blue-c17 | Whole-game card tests. Only two styles: about half Badger boards, most of the rest Locust |
| The league's reference fields (`ref-1` to `ref-3`) | Deleted after each stopping test | Live games of the two kept versions of the day | Stopping tests |

**Rule of thumb for any card test that reads final place:** check the bot's average place on the field first. A fair field gives about 4.5. Better than about 3.5 means the field is too weak and the test's numbers should not be trusted.

## Where this comes from

- Tags: `git -C /home/alex/league/red tag`, `git -C /home/alex/league/blue tag`. Each tag changes only the team's bot folder, `tools/league/bots/<colour>`.
- What each version changed and whether it was kept: `docs/workstreams/third-run/run-notes.md` in the referee's tree (`/data/third-run/referee-tree`), one line per version.
- Each match's result: `/data/third-run/matches/<new>-vs-<old>/verdict.jsonl` and `summary.json`.
- The field's make-up: the `label` of each line of `<field>/index.jsonl`.
- How the teams are set up: [brief.md](brief.md) and [the third run's brief](../third-run/third-run-brief.md).
