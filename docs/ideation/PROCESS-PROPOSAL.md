# Thinning the process for the next loop (proposal, 10 Nov 2026)

This is only a proposal (note 10g, item 4). None of it is done yet. It waits on your go-ahead after you've played build 8.

## 1. DECISIONS on one page

- Move today's `DECISIONS.md` (about 2,700 lines) to `docs/ideation/archive/DECISIONS-run1.md`, unchanged.
- The new `DECISIONS.md` holds only the calls still in force, one line each, grouped as rules, numbers, content, UI and process. Each line links to its full entry in the archive. Target: under 60 lines.
- New calls get one line there and a short entry below it. A call that's reversed is deleted from the page, and the archive keeps it.

## 2. "Done means" in a few lines

Replace the seven criteria and their three revisions with:

> A loop is done when you've played its build and said what's next.
> The build has passed: the cloud gate, a 200-game soak, a 4-game UI run, the memory check and the export checks.
> The playtest guide says what changed and what to try.

Numbers bars (the 900 target, the growth bands, three reviewers) become things to measure and report, not things that gate the build.

## 3. Restart reading list: design first

`RESTART.md` would open with this order, and the process docs move to the end:

1. Your notes, newest first (`docs/design/owner-notes/`), and `direction-summary.md`.
2. The rulebook and `bramble-design-guidance.md`.
3. `END-OF-RUN.md` (the game now and what's weakest) and `PLAYTEST.md`.
4. The one-page `DECISIONS.md`.
5. Last: tools and process (`CLOUD.md`, `ORCHESTRATION.md`, the gates, workers).

Cut `RESTART.md` itself from about 500 lines to about 100. The rest moves into the tool docs it points to.

## 4. End condition: you playing a build, with a time limit

> The next loop ends when you've played its build, or after N days, whichever comes first. N is yours to pick: I'd suggest 3. By day N, whatever is ready ships as the next build, and the run stops for your feedback.

Within the loop:
- Pick at most two things to work on, chosen from your play feedback.
- Give each step one review and the test gate.
- No new bars or measurement plans unless you ask for one.
