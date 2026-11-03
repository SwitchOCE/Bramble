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
- **No new git subcommands were needed.** `git show <commit>:<dir>/` prints `tree …`, a blank line, then the names, so the cards folder is listed without `ls-tree`. Blobs are read with `git show --no-textconv <blob id>` into a buffer; the blob id comes from `rev-parse <commit>:<path>` and is the ETag. A URL carrying `?v=<blob id>` is cached for a year.
- **Image sizes are read once per blob** (JPEG SOF, PNG IHDR, WebP header) and cached for good, so `<img>` gets `width`/`height` without layout shift and the index rebuild stays cheap.
- **The gallery has no doctype** (it was written as an artifact body), so it rendered in quirks mode. The portal prepends a doctype, charset and viewport, and a "Back to Bramble" link after its `<style>`. Its CSP, on `/design-lab/` only: the inline script allowed by sha256 hash, `style-src 'unsafe-inline'` for its one `style=` attribute and Google Fonts, `font-src fonts.gstatic.com`. Setting `el.style.width` from script is CSSOM and isn't blocked.
- **Clicking every gallery tab in one go requests only the last picture per `<img>`.** The journey reads each `<img src>` after each click instead, then HEADs the 138 URLs, with no downloads.
- **Fixture cards point at live questions files.** If the owner answers question 16, `look-direction` would read as done. A newer unhandled answer beats a source marker (the owner changed their mind, so an agent must act), which also keeps the journey stable.
- **Inbox reads are cached on the folder's mtime.** A new record or `.handled.json` changes it, so an agent's mark shows on the next page load.
- **The journey refuses to run unless `PORTAL_INBOX_DIR` is under the temp folder,** because it clears the inbox between sizes.
