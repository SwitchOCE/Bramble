# Large files in Cloudflare R2

Screenshots, video, art masters and other large files don't go in Git. They live in the Cloudflare R2 bucket `bramble-assets`, and the repo keeps only a list of them: [`manifest.tsv`](manifest.tsv), one line per file with its SHA-256, size and repo path. Each file is stored under its hash, so an upload never overwrites anything.

## Use

```bash
python tools/assets/assets.py pull                          # get every listed file
python tools/assets/assets.py pull docs/archive/design-lab  # or only those under a path
python tools/assets/assets.py status                        # what's missing or changed
python tools/assets/assets.py push docs/some/shots          # upload new or changed files
```

- `pull` puts each file at its repo path and checks its hash.
- `push` uploads, then updates `manifest.tsv`. Commit that file; the large files stay out of Git.
- `push` refuses files that aren't gitignored, so Git never picks up a large file by accident. Add a `.gitignore` rule for the folder first.

## Access

The script picks one of two ways in:

1. **The Cloudflare login on this machine** (the default). It runs `npx wrangler`, which needs Node. If the login has lapsed, run `npx wrangler login` and approve it in the browser. `CLOUDFLARE_API_TOKEN` also works here, if set.
2. **R2 keys**, for agents away from the owner's PC (the Optiplex, cloud sessions). Set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`, and run `pip install boto3`.

Making the R2 keys (the owner does this; agents don't create or handle keys):

1. Cloudflare dashboard → **R2 Object Storage** → **Manage API tokens** → **Create API token**.
2. Permission: **Object Read only** for agents that only pull, or **Object Read & Write** for ones that push. Apply it to the `bramble-assets` bucket only.
3. Put the **Access Key ID** and **Secret Access Key** it shows into the cloud environment's secrets as `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`, along with `R2_ACCOUNT_ID` (the account ID shown on the R2 overview page).

Set `BRAMBLE_ASSETS_BUCKET` to use the same script with another bucket, for example in another project.

## What's in it

| Path | What | Added |
|---|---|---|
| `docs/archive/design-lab/**/shots/` | Screenshots from the archived design lab (147 files, 42 MB) | 12 Nov 2026 |
