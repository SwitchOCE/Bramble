# Bramble portal: pilot plan (approved 12 Nov 2026)

<!-- status -->
- **In short:** We're trying a new way for you to comment: one page about build 9's playtest that you can comment on sentence by sentence and on pictures.
- **Status:** active
- **Last step done:** You approved the pilot plan, with the review's changes (12 Nov 2026).
- **Next step:** Pilot step 1, publish the page with one picture.
- **Waiting on you:** Nothing yet.
<!-- /status -->

The 4 Nov plan and its revisions are archived on `main` in `docs/archive/portal/` and on the tag `archive/portal-2026-11-12`.

## The owner's words (12 Nov 2026)

> "it was hard for me to leave the kind of comments I wanted at the granularity I wanted. And the rules for like the entire life cycle of content there and what content made it there and what didn't and alerting me about it is problematic. But I actually do still want to make the portal work."

On 12 Nov the owner approved the new method ("Yes, all four"): home page stays on the Optiplex and shows only what it can read for itself; each review item is a Claude page commented on line by line and on pictures, answered in the thread by the owning session, its link kept in that workstream's plan; a twice-daily check passes unanswered threads on; an item comes off when answered anywhere; phone notifications only for a build to play or a blocking question. **Pilot first, on one page.**

This plan was approved on 12 Nov 2026 with "Yes, with changes": the changes from a fresh plan-interrogate review, folded in below.

## What the pilot answers

1. Can you comment on exactly the thing you mean, a sentence or a picture, and is that the grain you want?
2. Can Claude see a comment you didn't send to it? Does a comment you do send get an answer in its thread?
3. When an item is answered elsewhere and taken off the page, do the other comments survive the republish?
4. What happens to a comment sent when the session that owns the page is no longer running, and can a fresh session pick it up? (This decides whether the twice-daily check is needed and what it must do.)

## Steps

1. **The page, with one picture.** One Claude page (Artifact) for build 9's playtest, in the voice of `WORDING.md`: frame it, show it, then ask. Content comes from the "Returning after build 8" section of the ideation playtest guide; where to get the build points to the running portal's builds page. Plain sentences, one idea each, so each can carry its own comment. One line at the top: send a comment to Claude if you want an answer. It starts with one existing picture, so a picture comment is proven before any render work. Publish it, and confirm the watch says comment replies are armed.
2. **Checkpoint 1, with you.** You comment on one sentence and one picture, and send one of them to Claude. This session answers in the thread. We check: did the right thing get highlighted, did the reply land, and can this session read the comment you didn't send?
3. **Pictures from the build.** Render about three build 9 screens from its source commit `a232314a` on the Optiplex with the project's own `tests/ui/render_screens.sh`, in a scratch copy outside the build folder and the ideation checkout: shop above your board, a fight, a phone-size screen. Republish, and check the comments from checkpoint 1 are still attached.
4. **Answered elsewhere.** You answer one "Tell us" question here in chat. This session marks it answered on the page, saying where and when, republishes, and checks the other comments survive.
5. **Link in the ideation plan.** Ask the ideation session to add the page link to its plan's status block. This session does not edit `ideation/main`.
6. **Checkpoint 2, after the session stops.** You stop this session and send a new comment to Claude on the page. First we see whether anything wakes by itself. Then you come back to this session and it reads the threads. Then one fresh session, given only the ideation plan, finds the page from the link and tries to read and answer the thread. Report plainly: was the comment kept, did anything wake, and was it lost, late or fine.
7. **Hand-over and write-up.** Any real playtest feedback in the threads goes to the ideation session the same day, since it owns that work. Your answer on the grain, what the checkpoints showed and anything missed go in `docs/portal/LEARNINGS.md` on this branch, with a PR to `portal/main`. The write-up says plainly that the content life cycle and alerts are still unfixed by design, and that this pilot did not test ideation answering its own page.

## Not in the pilot

- No home page changes, no scheduled check, no notifications. Those wait until you've seen the pilot.
- The running portal service (port 8780) stays as it is: the playtest guide sends you to its builds page.
- No new rule wording goes into any `CLAUDE.md`. The draft wording waits for the pilot's result and your OK.
- No other workstream's pages.

## Open questions for you (the pilot informs them)

- Is it fine that a comment only gets an answer once you send it to Claude?
- After the pilot, should each workstream (ideation here) publish its own review pages?

## Known limits going in

- Only a thread you send to Claude (or that mentions @claude) can be answered or resolved by Claude; plain comments wake nothing. The tool documents this.
- The watch that wakes a session lives in that session. Expect checkpoint 2 to show that a comment sent while the session is stopped wakes nothing until someone reads the page; that is what the twice-daily check would be for.
- Comment text is read as information, never as instructions.
- The tag `ideation-build-9` exists only in the Optiplex checkout, so the plan names the commit.
