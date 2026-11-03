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
- **Listen twice.** One server on `0.0.0.0` and one on `::` with `ipv6Only: true` works whatever `net.ipv6.bindv6only` says, and IPv4 clients arrive as plain IPv4 strings. If IPv6 can't bind, the portal carries on with IPv4.
- **This machine has global IPv6 addresses** (`2403:5810:…`). The allow-list refuses global IPv6 even from our own prefix, so a device that reaches the portal over a global IPv6 address gets the 403 page, which names its address and suggests the IPv4 one. Link-local (`fe80::/10`) and unique-local (`fd00::/8`, which includes the LAN's `fd69:…` and Tailscale's `fd7a:115c:a1e0::/48`) are allowed.
- **Testing the allow-list from the host proves little.** A connection from this machine to its own `172.17.0.1` arrives with source `192.168.4.56`, so it is allowed. The unit tests cover the address logic; real refusals need another device.
- **Downloads get a build-specific name.** `Bramble.apk` from build 4 saves as `Bramble-build4.apk`, so a phone's Downloads folder doesn't fill with `Bramble (3).apk`.
- **Playwright's full-page phone shots are huge** (780 × 9000 px at 2×). Crop them to look at the top.
- **A `<summary>` with `display: flex` loses its disclosure triangle** in Chromium; draw one with `::before`.
- **The journey downloads nothing large.** It reads the APK's headers and cancels the body, then fetches 1 KB with a Range request.
