# Bot league, phase 0: the owner stop

18 Nov 2026. Branch `league/engine` (pin: `dev` at `c0d7db79`). The details and every figure are
in [run-notes.md](run-notes.md).

## Second update: the three fixes and the data layer

You asked for three fixes, and whether the data is good enough for the analysis you want. All
three fixes are in: fight results each round, a switch to turn the decision log off, and a way for a
team to play its old bot against its new one. The Fable reviewer then designed a fuller log
(schema 1), and a worker built it. Each round now records every seat's board, hand, heaps,
counters and gold. Ghost fights are marked, and so is the round each seat died. Each match also
writes a card list and a manifest that says which build, seeds and bots it used. Every field is
listed in [tools/league/league/LOGS.md](../../../tools/league/league/LOGS.md).

None of it changes play: the game records are byte-identical before and after. Every port check
and `scripts/check.sh` pass again on the new code. The scope review checked this with its own
runs. It found two traps, which are fixed: a draw and a ghost win were both written as -1, and
in swapped games the red-seat list named the blue seats.

**Still to build: the analysis.** The data is now recorded, but nothing reads the new fields
yet. Per the brief (5b.9), the referee writes the section 9 analysis during round 1. The Fable
reviewer's plan for it is a few small scripts over these logs: card pick rates, tribes,
behaviours and the ladder.

## Update after your answer ("Yes, take all four")

All four picks are built, recorded in the brief with your words, and reviewed:
- **Clock:** 1 s.
- **Seats:** 4 red and 4 blue, shuffled each seed pair by the secret.
- **TribeBot:** tribe by seat, as in the balance pass. It is now **proved against GDScript**:
  200/200 games equal line for line, 145,408 actions. Running the wrong bots against those
  records fails all 200.
- **Team folders:** `bots/red` and `bots/blue` are ready. Each holds a stub bot, a `data/`
  folder and a `tools/` crate. The referee never builds or runs a team's tools.

All port checks pass again on the new code.

**A/A, redone.** TribeBot is now deterministic, so it plays both games of a pair the same, and
its A/A gap is 0 by construction: all 500 pairs end in the same placements with the colours
swapped. That shows the colour labels change nothing in play. For a test with noise, RandomBot
on both colours gives **−0.10 ± 0.11**, inside the bar.

**Seat order, with identical bots.** With FlowBot on every seat, seats 0–2 average 4.1 places
and seats 6–7 average 4.8. It shows only when all eight bots are the same. The likely reason is
that identical bots want the same cards, and they shop in seat order from one shared pool. That
isn't proved, and it may not happen with mixed bots. The league stays fair, because each seat is
red exactly once per pair.

The questions and the clock below are answered. What follows is the stop as it was written.

## Does the port match? Yes, on everything checked

| Check (brief 5b step 2) | Result |
|---|---|
| 1,000 GDScript games replayed in Rust | **1,000/1,000**, every one of 45,900 state hashes equal |
| 50 Rust games replayed in GDScript | **50/50**, no Godot errors |
| 100,000 mutated fights, full state compared | **100,000/100,000** byte for byte |
| Planted bugs | **caught every time**: a changed Attack changed 4,012 of 10,000 fights; refresh +1 gold failed 1,000/1,000 replays and GDScript rejected 4/4 Rust games, both at turn 1 |
| Baseline bots (Simple, Flow, Random) | **1,000/1,000** games equal to GDScript's, 909,806 actions |

All of it was rerun after the speed pass, with one command (`tools/league/proof/recheck.sh`):
all PASS. `scripts/check.sh` passes, and `src/` is unchanged.

**Speed-up:** a whole game runs about **13×** faster than GDScript (0.15 s against 1.9 s), and a
late fight about **40×** (0.33 ms against 13.6 ms).

**A/A** (TribeBot on both colours, 1,000 games): red minus blue **+0.06 ± 0.11**, so no winner, as
it should be. Seat averages are 4.41 to 4.61. There were no clock-outs, crashes or illegal moves.

**Logs:** every game is recorded in full. At your ask, each match now also writes every decision
with all its legal choices and their cards, and which one was taken (about 40 MB a match).

## Your pick: the thinking clock

These figures were measured on all five tribes, with test bots that use their whole clock:

| | 250 ms a game | 1 s a game |
|---|---|---|
| Per decision (about 110 a game) | 2.3 ms, about 4 late lookahead fights | 9 ms, about 15 fights |
| A 1,000-game match on 4 cores | about 6 min | about 23 min |
| A practice match: 1,000 games on 2 cores (brief 7a) | about 12 min | about 43 min |

**Recommendation: 1 s.** Lookahead is the main way a bot can get better than a rule of thumb, and
4 fights a decision is thin. A 23-minute official match is fine. The cost is in practice
matches: about 43 minutes each on 2 cores, against about 12 at 250 ms. The brief's own guess
was 35 and 70 minutes.

## Three questions from the scope review (needed before the teams start)

1. **Teammates are guessable from the seat number.** Colours alternate by seat (brief 5b.4.4), so
   a bot knows its teammates are the seats with the same odd or even number. Brief section 6 bans
   detecting teammates. *Recommendation:* shuffle the 4 red and 4 blue seats per game with the
   match secret, still swapped in each pair, so seat balance holds. It's a small change; then
   rerun the A/A (3 min).
2. **TribeBot picks its tribe at random from its seed.** The balance pass gave the seats
   different tribes in turn (`(seat + seed) % 5`), so all five tribes are in every lobby. So the
   A/A's "naive column" isn't set up like the 455 lobbies it will sit next to. *Recommendation:*
   copy the balance pass's rule. TribeBot was also ported by reading, with no GDScript check:
   the balance pass's script could be run as one.
3. **A team can't add its bot without editing shared files.** Bots enter the binary through the
   registry and the workspace file, both outside the team folder, which section 6 bans. The crate
   check also scans every Rust file in the folder, so a team's own self-play tools fail it.
   *Recommendation:* at the engine tag, put a stub bot crate in `bots/red` and `bots/blue`,
   already registered. Add a separate tools crate in `bots/<colour>/tools/` that may use files and
   threads, is never run in a match, and is out of the bot's reach.

## What nothing could see

- **Real teams using the harness.** The gate bots are test bots. Ease of use is untested.
- **TribeBot against GDScript:** see question 2.
- **Fight endings:** all 100,000 proof fights ended with a board empty. The attack-limit and
  trigger-limit endings never came up in that set.
- **HashMap order:** a bot that loops over a standard `HashMap` plays differently each run.
  That breaks replays of its own games, and its random seeds are a faint signal between seats.
  It isn't banned. Teams should be told to use `BTreeMap` or a fixed hasher.
- **The clock figures use test bots that burn their whole clock.** Real bots will use less or
  more, unevenly.

## Calls made without you

All are listed in [run-notes.md](run-notes.md#rulings-and-calls-made-without-the-owner). The ones
that matter most:
- a hung bot call **aborts the match** (exit 3), because a thread can't be stopped safely;
- after a clock-out, **SimpleBot** plays on;
- the "sleeping bot" gate is a **busy** bot, because the clock is CPU time;
- the engine is **22,500 lines**, not the brief's "about 10,000" (section 12.8), plus about
  7,000 lines of harness and tools.

## Not done, by design

The engine isn't frozen or tagged. No team or match has started, no card numbers changed, and
nothing was merged into `dev` or `main`. On your go, after the three questions and the clock:
1. I make the changes;
2. I rerun the A/A and the checks;
3. I freeze, tag `league-engine-v1`, and start the teams.
