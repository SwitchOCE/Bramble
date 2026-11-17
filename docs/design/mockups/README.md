# Mock-ups

Live mock-ups the owner has approved, one folder per screen. Screens are designed here in HTML and then copied into Godot (owner, 16 Nov 2026). This page is the one place that says which mock-ups are live.

**The file in this folder is what agents match.** A mock-up may also be published as a claude.ai page for the owner to look at; that page is for viewing only. If the two differ, the file here wins and the page is republished from it.

This page covers only what is in this folder. The track's older mock-ups (`docs/ideation-track-2/mockups/`) and the owner's `design/glass-mockups` branch are not sorted by it.

## Life cycle

Agreed 17 Nov 2026 with the assurance session, on the owner's word: "As long as we've got a life cycle for them ... these kind of mock-ups that are going to age out after they've been built".

1. **Approved.** The owner approves a mock-up; it goes in its own folder here with a row below. Shared pieces (card styles, stage files) and card art are linked by relative path from where they already live, never copied. If a branch truly can't reach the originals, the row names every copied file and where it came from, and the copies go with the mock-up, or sooner once the originals are on the same branch.
2. **Agents never edit an approved mock-up.** Only the owner's feedback rounds change it (the `overnight-run` skill says the same).
3. **Built.** When the game matches it, the row says "built, waiting for the owner to play it".
4. **Deleted.** When the owner has played that build and says it's built (quoted with the date, like the approval), the next PR deletes the folder and its row; Git history keeps it. Before deleting, check that no test or tool still reads the folder (`tools/look` compares scenes with mock-ups; the track has fixtures under `tests/screens/`). If one does, that check moves to a saved screenshot of the approved build in the same PR, or the delete waits.
5. A mock-up the owner rejects or replaces is deleted in the same PR as its replacement.

## Live

| Mock-up | Brief | Drawn by | Approved | Status |
|---|---|---|---|---|
| Shop: coin, price tags, refresh counter, duplicates | [briefs 1, 3, 4](../../workstreams/backlog-briefs.md) | An agent, 17 Nov | 17 Nov: "I'm happy with the mock-ups ... There's tags in the shop are fine", with the coin addendum in brief 1 | Approved. Files arrive here once the game is on `dev`; until then the only copy is https://claude.ai/artifact/4FRga1xKcPB3FkBPkZBm71 |
| Keyword tooltips | [brief 2](../../workstreams/backlog-briefs.md) | An agent, 17 Nov | 17 Nov: "That's exactly how it should work. You've nailed it." | Approved. Same as above: https://claude.ai/artifact/9GecRBWrKymVjAYr9z8Lg8 |
| Card browser | [brief 9](../../workstreams/backlog-briefs.md) | An agent, 17 Nov | 17 Nov: "The card browser is great." | Approved. Same as above: https://claude.ai/artifact/G14uY4waTbGdGSFkR3uYkc |

The approved commit goes in each row when the files are committed.
