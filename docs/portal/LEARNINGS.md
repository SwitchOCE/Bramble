# Portal learnings

Gotchas found while building the portal. Newest at the bottom.

## Step 1 (4 Nov 2026)

- **Status-block commits hide real activity.** The commit that added the status blocks touched every plan file at 09:18, so "latest commit touching the plan" made every workstream look active today. `workstreams.json` therefore excludes status-only files (the plan file, `docs/workstreams/`, `CLAUDE.md`) from "last activity", using git's `:(exclude)` pathspec. When a workstream's real work lives in its plan (the portal's own plan, for now), leave the plan in.
- **Shared branches need explicit activity paths.** Rules-and-budget and mechanics-library share `design/tribes-and-budget`; art-and-folio and architecture share `main`. Without paths, each card shows the branch's newest commit, whoever made it.
- **Activity spans several branches.** Art-and-folio's plan file lives on `portal/main`, but its newest folio commit is only on `origin/main`. Architecture's newest work is on `proto/core`. `activity.branches` lists every branch to look on; `git log -1 A B C -- paths` gives the newest across them.
- **Local `main` is behind `origin/main`.** Branch resolution uses `origin/<name>` only when it is a descendant of the local head (`git merge-base --is-ancestor`), so a diverged or behind origin never wins.
- **Questions files have no answer convention.** Neither `OWNER-QUESTIONS.md` nor `review-queue.md` marks answered items. The portal counts numbered items and bold-ID bullets (`- **B1. …**`) and treats `**Answer`, `Answered`, `Answer:` or a `~~struck~~` start as answered. Answered *sections* in the review queue are plain bullets, so they don't count; but B1–B7 sit under a heading that says "answered", so a heading-based rule would have been wrong.
- **One read of all heads.** `git for-each-ref refs/heads refs/remotes` is a single cheap call that changes whenever any branch moves; it beats one `rev-parse` per branch. Throttled to once per 3 s, and concurrent requests share one check.
- **`GIT_OPTIONAL_LOCKS=0`** keeps read commands from ever taking the index lock in a repo other agents are writing to.
- **IPv4 only (owner's decision, 4 Nov).** One listener on `0.0.0.0`; nothing listens on IPv6. A `0.0.0.0` socket only ever reports plain IPv4 client addresses, so the allow-list has no IPv6 or `::ffff:`-mapped handling: any non-IPv4 string is refused.
- **This machine has global IPv6 addresses** (`2403:5810:…`), and the plan's "no public address" is true only for IPv4. With no IPv6 listener this doesn't matter for the portal; a device that tries the hostname over IPv6 gets a refused connection and should use `http://192.168.4.56:8780` or the Tailscale address.
- **Testing the allow-list from the host proves little.** A connection from this machine to its own `172.17.0.1` arrives with source `192.168.4.56`, so it is allowed. The unit tests cover the address logic; real refusals need another device.
- **Downloads get a build-specific name.** `Bramble.apk` from build 4 saves as `Bramble-build4.apk`, so a phone's Downloads folder doesn't fill with `Bramble (3).apk`.
- **Playwright's full-page phone shots are huge** (780 × 9000 px at 2×). Crop them to look at the top.
- **A `<summary>` with `display: flex` loses its disclosure triangle** in Chromium; draw one with `::before`.
- **The journey downloads nothing large.** It reads the APK's headers and cancels the body, then fetches 1 KB with a Range request.
- **Don't pin tests to live data.** Unit tests read questions files at fixed commits (`3062811`, `0e482fd`); server tests compare a card's count with the file on the live branch; the journey takes its expected card, build and question counts from `workstreams.json` and `/healthz`. An answered question or a new build no longer fails the gate.
- **A strict CSP blocks `style=` attributes.** Table alignment uses classes. The 403 page can't load `/static` (the client is refused), so it is bare semantic HTML with no styles.
- **On a phone, the download sat 5,000 px down**, below all seven cards. A latest-build strip with the APK button now sits under the headline below 900 px; desktop keeps the full card under the grid.

## Revision 3, step 1: the decisions pass (4 Nov 2026)

- **`Referrer-Policy: no-referrer` makes Chromium send `Origin: null` on form posts.** A same-origin check on `Origin` refused every real answer. The POST check uses `Sec-Fetch-Site` (`same-origin` or `none`), and compares `Origin` only when it names a real origin.
- **Branch names have slashes,** so `/git/design-lab/main/docs/x.jpg` is ambiguous. The route takes the longest branch in `images.branches` that the path starts with; nothing outside that list is served.
- **The URL parser resolves `..` and `%2e%2e` before routing,** so dot-segment traversal never reaches the handler. A decoded `%2F` does: it puts a slash inside one segment. Paths are checked after splitting every segment on `/`.
- **No new git subcommands were needed.** `git show <commit>:<dir>/` prints `tree …`, a blank line, then the names, so the cards folder is listed without `ls-tree`. Blobs are read with `git show --no-textconv <blob id>` into a buffer; the blob id comes from `rev-parse <commit>:<path>` and is the ETag, so revisits are a 304.
- **The gallery has no doctype** (it was written as an artifact body), so it rendered in quirks mode. The portal prepends a doctype, charset and viewport, and a "Back to Bramble" link after its `<style>`. Its CSP, on `/design-lab/` only: the inline script allowed by sha256 hash, `style-src 'unsafe-inline'` for its one `style=` attribute and Google Fonts, `font-src fonts.gstatic.com`. Setting `el.style.width` from script is CSSOM and isn't blocked.
- **Clicking every gallery tab in one go requests only the last picture per `<img>`.** The journey reads each `<img src>` after each click instead, then HEADs the 138 URLs, with no downloads.
- **Fixture cards point at live questions files.** If the owner answers question 16, `look-direction` would read as done. A newer unhandled answer beats a source marker (the owner changed their mind, so an agent must act), which also keeps the journey stable.
- **The journey refuses to run unless `PORTAL_INBOX_DIR` is under the temp folder,** because it clears the inbox between sizes.
- **A source with no `#n` is a document, not a question.** The first version looked it up as a question item with no number, so it always read "not found", even for files that exist. Such sources are now background reading, checked with `rev-parse`. A test covers both real paths, which are on branches with slashes in their names.
- **The real cards are part of the gate.** `test/real-cards.test.js` copies the cards from `portal/main` (or, until merge, `portal/decisions-content`) into a temp folder. It checks that every card parses cleanly, every page renders, and every picture is a real image.
- **A plain `#<n>` is ambiguous in long docs.** `power-budget.md` numbers its changelog, its validation plan and its owner questions, so `#1` finds the changelog's first item. Cards use `#9.1` to mean "numbered item 1 under `## 9.`". `#B8` also finds a `### B8.` heading, at any level. The heading's block runs to the next heading of the same or a higher level, and an `**Answered` marker inside it counts. Heading items are used only for lookup, so the open-question counts don't change.

## Pilot: one commentable review page (12–13 Nov 2026)

The pilot from `PLAN.md`: build 9's playtest as one Claude page (https://claude.ai/artifact/9SpEW6zxTviux5GrdTHR8a), to be commented on sentence by sentence and on pictures. The owner closed it on 13 Nov, after step 1, with the page published and no comments left on it.

### What the owner said

> "I think the big issue with this model, and I guess these models in general, is that I can't dictate. But I don't know a way of solving that really without like installing like first-party Whisper or something. Maybe that's what I have to do. Because yeah, like I typing is too slow when interacting with agents. I have so much stuff to do that I need to be able to dictate and just get my thoughts out immediately."

Offered Windows voice typing (Win+H): "Windows h is so bad, I consider it to be a virus. I'm never pressing that key ever again." Then: "Close the pilot."

### Is the grain right?

- **Untested by the owner, and not the bottleneck.** Comments at any grain have to be typed, and typing is too slow. The first portal failed partly for the same reason: everything the owner actually said since 4 Nov came by dictation or chat, not by typing into a box (see the diagnosis in the archive).
- **So the input mode comes before the grain.** Any review surface, a Claude page or the Optiplex site, is only useful once the owner can dictate into it. A desktop dictation tool (local Whisper or similar, not Win+H) is being looked at in its own session. Phone keyboards can already dictate, but this pilot didn't test commenting from a phone.
- **Don't build the rest of the method yet** (home page changes, the twice-daily check, notifications). Retry the pilot, unchanged, once desktop dictation works.

### What was checked

- **Publishing and watching work.** On publish, the watch connected with comment replies armed.
- **A restarted session got its watch back.** The session was restarted overnight; on 13 Nov the watch listed "re-armed when this session was resumed, auto-replies armed". So a session that comes back keeps listening. Not tested: a comment sent while the session was stopped, or a fresh session finding the page from a plan link. Those still decide whether the twice-daily check is needed.
- **Not tested at all:** a sentence comment, a picture comment, a reply in a thread, whether Claude can read a comment that wasn't sent to it, and whether comments survive a republish.

### Gotchas for whoever retries

- **Build 9 already had screen captures**, made by the ideation workstream at its final hex-arena code: on the Optiplex under `~/code/Bramble-ideation/.worktrees/ui-arena/build/loop1/arena/` (`recruit_*`, `scouting-*`, `fight-*` and `reader-*` at 1920×1080 and 1688×780, plus `recruit-turn.mp4` and `fight.mp4`). After them, the only code change before the build was the card reader, and its shots were redone after that fix. Look for the newest workstream's own captures before rendering new ones. The shots in `build/screens/` are older (10 Nov).
- **The tag `ideation-build-9` exists only in the Optiplex checkout**; it isn't on GitHub. Cite the commit, `a232314a`.
- **The page's pictures go in as published files** (`files: {"img/recruit.jpg": …}`); a 1600-pixel JPEG at quality 82 is about 280 KB.
- **The owner's playtest answer came in chat, not on the page:** "I am happy with the where things are at. Build 9 is good for now, right? We can improve the UI more later and make changes again later, but this is a good spot to be in for now." That belongs to the ideation workstream, and was handed back to the session that started the pilot to pass on.
