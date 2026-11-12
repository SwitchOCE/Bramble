# Large files in Cloudflare R2

Screenshots, video, art masters and other large files don't go in Git. They live in a Cloudflare R2 bucket, named in [`bucket`](bucket) (`bramble-assets`), and the repo keeps only a list of them: [`manifest.tsv`](manifest.tsv), one line per file with its SHA-256, size and repo path. Each file is stored under its hash, so an upload never overwrites anything.

## Use

```bash
python tools/assets/assets.py pull                          # get every listed file
python tools/assets/assets.py pull docs/archive/design-lab  # or only those under a path
python tools/assets/assets.py status                        # what's missing or changed
python tools/assets/assets.py push docs/some/shots          # upload new or changed files
python tools/assets/assets.py prune                         # what's stored but no longer listed
```

- `pull` puts each file at its repo path and checks its hash. It leaves alone a listed file you changed here (push it, or `pull --force` to replace it).
- `push` uploads, then updates `manifest.tsv`. Commit that file; the large files stay out of Git.
- `push` refuses files that aren't gitignored, so Git never picks up a large file by accident. Add a `.gitignore` rule for the folder first. `pull` refuses the same way.
- Paths can be written Windows-style or relative to the current folder. A path outside the repo, or one with no listed files under it, is an error.

## Keep it small

Large files cost space for every agent that pulls them. Use them when they clearly improve the result, and shrink them first: JPEG or WebP rather than PNG for screenshots, the smallest size that shows what matters, short re-encoded clips rather than raw video.

- `push` refuses any file over 25 MB unless you pass `--allow-large`.
- It reminds you to shrink files over 5 MB, and PNGs, but still pushes them.

## Cleaning up

Each version of a file is stored once, under its hash, and stays until it's pruned. When a file is replaced or its line is removed from the list, the old copy stays in the bucket.

`prune` finds stored files that no branch or tag, nor this working copy, lists any more. It fetches every branch and tag first. The bucket also keeps an index of every file ever pushed (`index.tsv`), so files from a deleted branch are still found.

- `prune` only lists them; `prune --delete` removes them. After that, an old commit that lists them can't pull them.
- Files pushed in the last 7 days are left alone, because another agent may not have committed its list yet. `--older-than DAYS` changes that.
- Run it after deleting branches that had large files, or when usage grows.

## Access

The script picks one of two ways in:

1. **The Cloudflare login on this machine** (the default). It runs `npx wrangler`, which needs Node. If the login has lapsed, the error says so: run `npx wrangler login` and approve it in the browser. `CLOUDFLARE_API_TOKEN` also works here, if set. This needs a browser, so it suits the owner's PC, not a headless machine.
2. **R2 keys**, for agents away from the owner's PC (the Optiplex, cloud sessions). Set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`, and run `pip install boto3`.

Setting up R2 keys (the owner does this; agents don't create or handle keys):

1. Cloudflare dashboard → **R2 Object Storage** → **Manage API tokens** → **Create API token**.
2. Permission: **Object Read only** for agents that only pull, or **Object Read & Write** for ones that push. Apply it to the `bramble-assets` bucket only.
3. **Cloud sessions:**
   - Put the **Access Key ID** and **Secret Access Key** into the cloud environment's environment variables as `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`, along with `R2_ACCOUNT_ID` (shown on the R2 overview page).
   - Add `<account-id>.r2.cloudflarestorage.com` to the environment's **Allowed domains**, and to the list in [CLOUD_SETUP.md](../../docs/CLOUD_SETUP.md).
   - `boto3` comes from PyPI, which the default package-manager list already allows.
4. **The Optiplex:** add `export` lines for the same three variables to `~/.bashrc` of the account the agents run as. Put them at the top, above the line that returns early for non-interactive shells, because agents run commands over SSH without a login shell. Then run `pip install boto3` there.

## Using it in another project

1. Copy the `tools/assets/` folder into that repo, and empty `manifest.tsv` down to its header line.
2. Create a bucket: `npx wrangler r2 bucket create <name>`, and write its name into `tools/assets/bucket`. The script stops if that file is missing, so files never land in another project's bucket.
3. Pin wrangler: add `WRANGLER_VERSION=4.160.1` (or newer) to that repo's `tools/versions.env`.
4. For remote agents, make an R2 key scoped to that bucket; a Bramble key only reaches `bramble-assets`.

## Free tier

R2's free allowance is per Cloudflare account, shared by every bucket in it: 10 GB stored, 1 million writes and 10 million reads a month, and downloads are free. Each pushed file is one write and each pulled file is one read.

R2 doesn't stop at the limit; usage above it is billed. Storage is $0.015 per GB a month, so 10 GB over costs about $0.15 a month. Writes are $4.50 and reads $0.36 per extra million.

**How close we are (12 Nov 2026):** about 0.1 GB stored across the account, about 1% of the free 10 GB.
- **Storage** is the only limit we could plausibly reach. The design-lab screenshots are 42 MB, so 10 GB is over 200 sets like them. What would get there: video (a 10-minute 1080p recording is roughly 0.5 to 1 GB), many full-size art masters, or never pruning.
- **Writes and reads** are far off. A full pull of the design lab is 147 reads, so the read allowance covers about 68,000 of them a month.

**Checking usage:** `status` prints how much this branch's list stores. For the whole account, use the Cloudflare dashboard, **R2 Object Storage** → overview. `npx wrangler r2 bucket info <bucket>` was still showing 0 B 45 minutes after the first upload, so don't rely on it.

## What's in it

| Path | What | Added |
|---|---|---|
| `docs/archive/design-lab/**/shots/` | Screenshots from the archived design lab (147 files, 42 MB) | 12 Nov 2026 |
