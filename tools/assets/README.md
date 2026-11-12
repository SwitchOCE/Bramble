# Large files in Cloudflare R2

Screenshots, video, art masters and other large files don't go in Git. They live in the Cloudflare R2 bucket `bramble-assets`, and the repo keeps only a list of them: [`manifest.tsv`](manifest.tsv), one line per file with its SHA-256, size and repo path. Each file is stored under its hash, so an upload never overwrites anything.

## Use

```bash
python tools/assets/assets.py pull                          # get every listed file
python tools/assets/assets.py pull docs/archive/design-lab  # or only those under a path
python tools/assets/assets.py status                        # what's missing or changed
python tools/assets/assets.py push docs/some/shots          # upload new or changed files
```

- `pull` puts each file at its repo path and checks its hash. It leaves alone a listed file you changed here (push it, or `pull --force` to replace it).
- `push` uploads, then updates `manifest.tsv`. Commit that file; the large files stay out of Git.
- `push` refuses files that aren't gitignored, so Git never picks up a large file by accident. Add a `.gitignore` rule for the folder first.
- Paths can be written Windows-style or relative to the current folder. A path with no listed files under it is an error.

## Keep it small

Large files cost space for every agent that pulls them. Use them when they clearly improve the result, and shrink them first: JPEG or WebP rather than PNG for screenshots, the smallest size that shows what matters, short re-encoded clips rather than raw video.

`push` refuses any file over 25 MB unless you pass `--allow-large`.

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
4. **The Optiplex:** set the same three variables in the shell profile of the account the agents run as, and install `boto3` there.

## Using it in another project

1. Copy the `tools/assets/` folder into that repo, and empty `manifest.tsv` down to its header line.
2. Create a bucket: `npx wrangler r2 bucket create <name>`.
3. Set `ASSETS_BUCKET=<name>` wherever the script runs. For remote agents, make an R2 key scoped to that bucket; a Bramble key only reaches `bramble-assets`.

## Free tier

R2's free allowance is per Cloudflare account, shared by every bucket in it: 10 GB stored, 1 million writes and 10 million reads a month, and downloads are free. Above that, storage is $0.015 per GB a month. Each pushed file is one write and each pulled file is one read. Check usage with `npx wrangler r2 bucket info <bucket>` (the numbers lag by up to an hour).

## What's in it

| Path | What | Added |
|---|---|---|
| `docs/archive/design-lab/**/shots/` | Screenshots from the archived design lab (147 files, 42 MB) | 12 Nov 2026 |
