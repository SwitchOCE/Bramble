# Portal (archived 12 Nov 2026)

The first Bramble portal: a self-hosted website on the Optiplex (port 8780) for the owner's devices. It showed each workstream's status, the builds to download, and 36 decision cards with answer boxes, written on 4 Nov 2026. Its code and cards are on the `portal/main` branch and the `archive/portal-2026-11-12` tag. These docs are history, not rules.

## Why it was archived

The owner's words, 12 Nov 2026:

> "the issue was that it was hard for me to leave the kind of comments I wanted at the granularity I wanted. And the rules for like the entire life cycle of content there and what content made it there and what didn't and alerting me about it is problematic. But I actually do still want to make the portal work. So we can archive it for now, I guess."

What went wrong, from the evidence on 12 Nov:
- **Comments.** The only input was one answer box per card; the free-form form was never built. The inbox got 0 messages in 8 days. The owner's input went elsewhere instead: inline comments on a doc (2 Nov), long dictations (8 Nov), and messages in the ideation session (9–11 Nov).
- **What got on and off.** A portal session wrote the cards by hand for other workstreams, and no one kept them current. A card came off only when a repo marker was set, so answers given in chat never removed it. Build 9's playtest, the thing that needed the owner most, never became a card. The builds page stayed correct because it read the build folder directly.
- **Alerts.** None. The owner saw what needed them only by opening the site.

Where each card stood on 12 Nov: [CARDS.md](CARDS.md).

## What replaces it

On 12 Nov 2026 the owner approved a new method, to be piloted on one review page (build 9's playtest) before anything else is built:
- The home page stays on the Optiplex and shows only what it can read for itself: builds, where each active workstream stands, and one "needs you" line each, marked stale after 3 days.
- Each thing to review is a Claude page the owner can comment on line by line and on pictures. The owning session answers in the thread.
- A scheduled check twice a day passes any unanswered thread to the owning workstream.
- An item comes off when the owner answers it anywhere; whichever session hears the answer strikes it.
- Phone notifications only for a build to play or a question that blocks work.

The owner-approved wording rules stay in force from `docs/portal/WORDING.md` on `portal/main`; the copy here is history.

## Files

- [PLAN.md](PLAN.md): the plan and the owner's answers of 4 Nov.
- [WORDING.md](WORDING.md): how things shown to the owner are worded.
- [LEARNINGS.md](LEARNINGS.md): technical gotchas from building it.
- [workstream-rules.md](workstream-rules.md): the 4 Nov status-block, answered-question and inbox rules, as they stood (was `docs/workstreams/README.md` on `portal/main`).
- [CARDS.md](CARDS.md): the 36 cards, sorted into answered, superseded and still open.

The service on the Optiplex keeps running for now, because build 9's playtest guide points to its builds page. Its home page still lists the old cards as waiting.
