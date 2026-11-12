#!/usr/bin/env python3
"""Large files (screenshots, video, art masters) kept in Cloudflare R2 instead of Git.

The repo keeps only tools/assets/manifest.tsv: one line per file with its SHA-256,
size and repo path. The files themselves live in the R2 bucket under their hash,
so nothing is ever overwritten. Pulled files land at their repo paths, which must
be gitignored.

  python tools/assets/assets.py push PATH...      upload files or folders, record them
  python tools/assets/assets.py pull [PREFIX...]  download what the list names
  python tools/assets/assets.py status [PREFIX...] show what is missing or changed
  python tools/assets/assets.py prune [--delete]   remove stored files no branch or tag lists

Two ways in, picked automatically:
  - S3 keys: set R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and R2_ACCOUNT_ID
    (needs `pip install boto3`). For agents away from the owner's PC.
  - Otherwise wrangler, using the Cloudflare login on this machine
    (`npx wrangler login`), or CLOUDFLARE_API_TOKEN if set.
The bucket name is in tools/assets/bucket; ASSETS_BUCKET overrides it.
Files over 25 MB are refused unless pushed with --allow-large.
"""
import argparse
import concurrent.futures as cf
import datetime
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Files over LARGE_MB are refused unless pushed with --allow-large; files over NOTICE_MB, and PNGs,
# get a reminder to shrink them. Large files should be rare: only when they clearly improve the result.
LARGE_MB = 25
NOTICE_MB = 5
HEADER = "# sha256\tbytes\tpath   (files kept in Cloudflare R2; see tools/assets/README.md)\n"


def repo_root() -> Path:
    out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
    return Path(out.stdout.strip()).resolve()


ROOT = repo_root()
HERE = ROOT / "tools" / "assets"
MANIFEST = HERE / "manifest.tsv"
MANIFEST_REL = "tools/assets/manifest.tsv"


def bucket_name() -> str:
    name = os.environ.get("ASSETS_BUCKET")
    if not name and (HERE / "bucket").exists():
        name = (HERE / "bucket").read_text(encoding="utf-8").strip()
    if not name:
        sys.exit("No bucket named: put its name in tools/assets/bucket, or set ASSETS_BUCKET.")
    return name


BUCKET = None  # set by backend(), so commands that don't touch the bucket don't need it


def wrangler_version() -> str:
    env = ROOT / "tools" / "versions.env"
    if env.exists():
        for line in env.read_text(encoding="utf-8").splitlines():
            key, _, value = line.strip().partition("=")
            if key == "WRANGLER_VERSION" and value:
                return value
    sys.exit("Pin wrangler first: add WRANGLER_VERSION=<version> to tools/versions.env.")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def key_for(digest: str, path: str) -> str:
    return f"sha256/{digest[:2]}/{digest}{Path(path).suffix.lower()}"


def read_manifest() -> dict:
    entries = {}
    if MANIFEST.exists():
        for line in MANIFEST.read_text(encoding="utf-8").splitlines():
            if not line or line.startswith("#"):
                continue
            digest, size, path = line.split("\t", 2)
            entries[path] = (digest, int(size))
    return entries


def write_manifest(entries: dict) -> None:
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"{d}\t{s}\t{p}\n" for p, (d, s) in sorted(entries.items())]
    MANIFEST.write_text(HEADER + "".join(lines), encoding="utf-8", newline="\n")


# ---- storage backends ---------------------------------------------------------

class S3:
    def __init__(self):
        try:
            import boto3  # noqa: F401
        except ImportError:
            sys.exit("R2 keys are set but boto3 is missing: pip install boto3")
        import boto3
        account = os.environ["R2_ACCOUNT_ID"]
        self.client = boto3.client(
            "s3",
            endpoint_url=f"https://{account}.r2.cloudflarestorage.com",
            aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
            aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
            region_name="auto",
        )

    def put(self, key, path):
        self.client.upload_file(str(path), BUCKET, key)

    def get(self, key, path):
        self.client.download_file(BUCKET, key, str(path))

    def delete(self, key):
        self.client.delete_object(Bucket=BUCKET, Key=key)


class Wrangler:
    def __init__(self):
        npx = shutil.which("npx")
        if not npx:
            sys.exit("Needs Node's npx for wrangler, or R2 keys (see tools/assets/README.md)")
        self.cmd = [npx, "-y", f"wrangler@{wrangler_version()}"]

    def _run(self, args):
        # Wrangler prints UTF-8 (with emoji); Windows' default code page can't decode it.
        env = dict(os.environ, NO_COLOR="1", FORCE_COLOR="0")
        r = subprocess.run(self.cmd + args, capture_output=True, text=True, encoding="utf-8", errors="replace", env=env)
        if r.returncode != 0:
            raise RuntimeError(wrangler_error(r.stderr + "\n" + r.stdout))

    def put(self, key, path):
        self._run(["r2", "object", "put", f"{BUCKET}/{key}", f"--file={path}", "--remote"])

    def get(self, key, path):
        self._run(["r2", "object", "get", f"{BUCKET}/{key}", f"--file={path}", "--remote"])

    def delete(self, key):
        self._run(["r2", "object", "delete", f"{BUCKET}/{key}", "--remote"])


def wrangler_error(text: str) -> str:
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)  # colour codes
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    errors = [l for l in lines if "ERROR" in l or "error" in l.lower().split(":")[0]]
    if errors:
        msg = errors[0]
    else:
        useful = [l for l in lines if "Logs were written" not in l]
        msg = useful[-1] if useful else "wrangler failed with no message"
    if any(w in text.lower() for w in ("authentication", "not logged in", "unauthorized", "code: 10000")):
        msg += "  (the Cloudflare login may have lapsed: run `npx wrangler login`, or use R2 keys)"
    return msg


def backend():
    global BUCKET
    BUCKET = bucket_name()
    if all(os.environ.get(k) for k in ("R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_ACCOUNT_ID")):
        return S3()
    return Wrangler()


# ---- commands -----------------------------------------------------------------

def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def files_under(args) -> list:
    out = []
    for a in args:
        p = Path(a).resolve()
        if p != ROOT and ROOT not in p.parents:
            sys.exit(f"Not inside this repo: {a}")
        if p.is_dir():
            out += sorted(f for f in p.rglob("*") if f.is_file() and ".git" not in f.relative_to(ROOT).parts)
        elif p.is_file():
            out.append(p)
        else:
            sys.exit(f"No such file or folder: {a}")
    return out


def not_ignored(paths: list) -> list:
    if not paths:
        return []
    # Bytes, not text: on Windows text mode would send "\r\n" and git would read the "\r" as part of the path.
    r = subprocess.run(["git", "check-ignore", "--stdin", "-z"], input="\0".join(paths).encode() + b"\0",
                       capture_output=True, cwd=ROOT)
    ignored = set(r.stdout.decode().split("\0"))
    return [p for p in paths if p not in ignored]


def norm_prefixes(prefixes) -> list:
    """Accept Windows separators, ./ and paths relative to the current folder."""
    out = []
    for p in prefixes:
        full = (Path.cwd() / p.replace("\\", "/")).resolve()
        try:
            out.append(full.relative_to(ROOT.resolve()).as_posix().rstrip("/"))
        except ValueError:
            sys.exit(f"Not inside this repo: {p}")
    return out


def matches(path: str, prefixes) -> bool:
    return not prefixes or any(p in ("", ".") or path == p or path.startswith(p + "/") for p in prefixes)


def listed(prefixes) -> dict:
    prefixes = norm_prefixes(prefixes)
    entries = {p: v for p, v in read_manifest().items() if matches(p, prefixes)}
    if prefixes and not entries:
        sys.exit("No listed files under: " + ", ".join(prefixes))
    return entries


def cmd_push(a):
    entries = read_manifest()
    todo = []
    for f in files_under(a.paths):
        r = rel(f)
        d = sha256(f)
        if entries.get(r, (None,))[0] != d:
            todo.append((r, d, f.stat().st_size, f))
    big = [(r, s) for r, _, s, _ in todo if s > LARGE_MB * 1024 * 1024]
    if big and not a.allow_large:
        print(f"These files are over {LARGE_MB} MB:")
        for r, s in big:
            print(f"  {s / 1048576:.0f} MB  {r}")
        sys.exit("Keep large files rare: shrink them (lower resolution, JPEG/WebP, shorter or re-encoded video), "
                 "or pass --allow-large if they clearly improve the result.")
    loose = not_ignored([t[0] for t in todo])
    if loose:
        print(f"{len(loose)} file(s) are not gitignored, so Git would also pick them up:")
        for p in loose[:10]:
            print("  " + p)
        sys.exit("Add a .gitignore rule for them first.")
    total = sum(t[2] for t in todo)
    if todo:
        print(f"{len(todo)} file(s) to push, {total / 1048576:.1f} MB.")
    over = [(r, s) for r, _, s, _ in todo if s > NOTICE_MB * 1024 * 1024]
    pngs = [r for r, _, _, _ in todo if r.lower().endswith(".png")]
    if over or pngs:
        print("Reminder: keep large files rare and small (tools/assets/README.md).")
        if over:
            print(f"  {len(over)} file(s) over {NOTICE_MB} MB, the largest {max(s for _, s in over) / 1048576:.0f} MB:"
                  f" {max(over, key=lambda t: t[1])[0]}")
        if pngs:
            print(f"  {len(pngs)} PNG file(s): JPEG or WebP is usually far smaller for screenshots.")
    known = {key_for(d, p) for p, (d, _) in entries.items()}
    be = backend()
    failed = 0
    uploaded = {}

    def up(t):
        r, d, s, f = t
        k = key_for(d, r)
        if k not in known:
            be.put(k, f)
            uploaded[k] = s
        return t

    with cf.ThreadPoolExecutor(a.jobs) as pool:
        futs = {pool.submit(up, t): t for t in todo}
        for i, fut in enumerate(cf.as_completed(futs), 1):
            r, d, s, _ = futs[fut]
            try:
                fut.result()
                entries[r] = (d, s)
                print(f"[{i}/{len(todo)}] up  {r}")
            except Exception as e:  # keep going; report at the end
                failed += 1
                print(f"[{i}/{len(todo)}] FAILED {r}: {e}")
            if i % 20 == 0:
                write_manifest(entries)
    write_manifest(entries)
    if uploaded:
        try:
            index = read_index(be)
            today = datetime.date.today().isoformat()
            for k, s in uploaded.items():
                index.setdefault(k, (s, today))
            write_index(be, index)
        except Exception as e:
            print(f"Warning: could not update the bucket's index ({e}). prune may miss these files.")
    print(f"Pushed {len(todo) - failed} file(s), {failed} failed. Commit tools/assets/manifest.tsv.")
    sys.exit(1 if failed else 0)


def cmd_pull(a):
    entries = listed(a.prefixes)
    todo, kept = [], []
    for p, (d, s) in entries.items():
        f = ROOT / p
        if not f.exists():
            todo.append((p, d))
        elif f.stat().st_size != s or sha256(f) != d:
            (todo if a.force else kept).append((p, d))
    for p, _ in kept:
        print(f"kept     {p}  (changed here; push it, or pull --force to replace it)")
    loose = not_ignored([p for p, _ in todo])
    if loose:
        print(f"{len(loose)} listed file(s) are not gitignored, so Git would pick them up:")
        for p in loose[:10]:
            print("  " + p)
        sys.exit("Add a .gitignore rule for them first.")
    be = backend()
    failed = 0

    def down(t):
        p, d = t
        dest = ROOT / p
        dest.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=dest.parent, suffix=".part")
        os.close(fd)
        try:
            be.get(key_for(d, p), tmp)
            if sha256(Path(tmp)) != d:
                raise RuntimeError("downloaded file does not match its hash")
            os.replace(tmp, dest)
        finally:
            if os.path.exists(tmp):
                os.remove(tmp)

    with cf.ThreadPoolExecutor(a.jobs) as pool:
        futs = {pool.submit(down, t): t for t in todo}
        for i, fut in enumerate(cf.as_completed(futs), 1):
            p = futs[fut][0]
            try:
                fut.result()
                print(f"[{i}/{len(todo)}] down {p}")
            except Exception as e:
                failed += 1
                print(f"[{i}/{len(todo)}] FAILED {p}: {e}")
    print(f"{len(entries) - len(todo) - len(kept)} already here, {len(todo) - failed} pulled, "
          f"{len(kept)} kept (changed here), {failed} failed.")
    sys.exit(1 if failed else 0)


def cmd_status(a):
    entries = listed(a.prefixes)
    missing = changed = 0
    for p, (d, s) in sorted(entries.items()):
        f = ROOT / p
        if not f.exists():
            missing += 1
            if a.verbose:
                print("missing  " + p)
        elif f.stat().st_size != s or sha256(f) != d:
            changed += 1
            print("changed  " + p)
    stored = sum(dict((d, s) for d, s in entries.values()).values())
    print(f"{len(entries)} listed ({stored / 1048576:.1f} MB stored), "
          f"{len(entries) - missing - changed} here, {missing} missing, {changed} changed.")


def manifest_keys(text: str) -> dict:
    """Bucket keys named by one manifest's text, with their sizes."""
    keys = {}
    for line in text.splitlines():
        if line and not line.startswith("#"):
            digest, size, path = line.split("\t", 2)
            keys[key_for(digest, path)] = int(size)
    return keys


def git(*args) -> str:
    r = subprocess.run(["git", *args], capture_output=True, cwd=ROOT)
    if r.returncode != 0:
        sys.exit(f"git {' '.join(args)} failed: {r.stderr.decode(errors='replace').strip()}")
    return r.stdout.decode("utf-8", errors="replace")


INDEX_KEY = "index.tsv"  # every key ever pushed: key, bytes, date first pushed


def read_index(be) -> dict:
    fd, tmp = tempfile.mkstemp(suffix=".tsv")
    os.close(fd)
    try:
        try:
            be.get(INDEX_KEY, tmp)
        except Exception as e:
            if any(w in str(e) for w in ("does not exist", "NoSuchKey", "404", "Not Found")):
                return {}
            raise
        index = {}
        for line in Path(tmp).read_text(encoding="utf-8").splitlines():
            if line and not line.startswith("#"):
                k, s, d = line.split("\t")
                index[k] = (int(s), d)
        return index
    finally:
        os.remove(tmp)


def write_index(be, index: dict) -> None:
    fd, tmp = tempfile.mkstemp(suffix=".tsv")
    os.close(fd)
    try:
        lines = [f"{k}\t{s}\t{d}\n" for k, (s, d) in sorted(index.items())]
        Path(tmp).write_text("# key\tbytes\tfirst pushed\n" + "".join(lines), encoding="utf-8", newline="\n")
        be.put(INDEX_KEY, tmp)
    finally:
        os.remove(tmp)


def show_manifest(rev: str) -> dict:
    r = subprocess.run(["git", "show", f"{rev}:{MANIFEST_REL}"], capture_output=True, cwd=ROOT)
    return manifest_keys(r.stdout.decode("utf-8", errors="replace")) if r.returncode == 0 else {}


def cmd_prune(a):
    if subprocess.run(["git", "fetch", "--quiet", "--prune", "--tags", "origin"], cwd=ROOT).returncode != 0:
        sys.exit("git fetch failed: prune needs every branch and tag on GitHub to know what is still listed.")
    # Keep everything a branch, tag or this working copy lists.
    keep = manifest_keys(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    for ref in sorted(set(git("for-each-ref", "--format=%(objectname)", "refs/heads", "refs/remotes",
                              "refs/tags").split())):
        keep.update(show_manifest(ref))
    # What's stored: the bucket's index of every push, plus anything a commit ever listed
    # (files pushed before the index existed). The index remembers them once a branch is deleted.
    be = backend()
    index = read_index(be)
    today = datetime.date.today()
    added = False
    for c in git("log", "--all", "--format=%H", "--", MANIFEST_REL).split():
        for k, s in show_manifest(c).items():
            if k not in index:
                index[k] = (s, today.isoformat())
                added = True
    if added:
        write_index(be, index)
    cutoff = (today - datetime.timedelta(days=a.older_than)).isoformat()
    unlisted = {k: v for k, v in index.items() if k not in keep}
    gone = {k: s for k, (s, d) in unlisted.items() if d <= cutoff}
    waiting = len(unlisted) - len(gone)
    note = (f" {waiting} more unlisted file(s) were pushed in the last {a.older_than} days and are left alone,"
            " in case they're about to be committed." if waiting else "")
    if not gone:
        print("Nothing to prune." + note)
        return
    if not a.delete:
        for k in sorted(gone)[:10]:
            print("  " + k)
        print(f"{len(gone)} stored file(s), {sum(gone.values()) / 1048576:.1f} MB, are no longer listed by any branch "
              "or tag. Old commits that list them could no longer pull them. Run with --delete to remove them." + note)
        return
    failed = 0
    deleted = []
    for i, k in enumerate(sorted(gone), 1):
        try:
            be.delete(k)
            deleted.append(k)
            print(f"[{i}/{len(gone)}] deleted {k}")
        except Exception as e:
            failed += 1
            print(f"[{i}/{len(gone)}] FAILED {k}: {e}")
    index = read_index(be)  # re-read, in case someone pushed meanwhile
    for k in deleted:
        index.pop(k, None)
    write_index(be, index)
    print(f"Deleted {len(deleted)} file(s), {failed} failed." + note)
    sys.exit(1 if failed else 0)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("push", help="upload files or folders and record them in the list")
    p.add_argument("paths", nargs="+")
    p.add_argument("--allow-large", action="store_true", help=f"push files over {LARGE_MB} MB")
    p.add_argument("-j", "--jobs", type=int, default=6)
    p.set_defaults(fn=cmd_push)
    p = sub.add_parser("pull", help="download listed files (all, or those under the prefixes)")
    p.add_argument("prefixes", nargs="*")
    p.add_argument("--force", action="store_true", help="also replace listed files that were changed here")
    p.add_argument("-j", "--jobs", type=int, default=6)
    p.set_defaults(fn=cmd_pull)
    p = sub.add_parser("status", help="compare the list with what is on disk")
    p.add_argument("prefixes", nargs="*")
    p.add_argument("-v", "--verbose", action="store_true")
    p.set_defaults(fn=cmd_status)
    p = sub.add_parser("prune", help="list (or with --delete, remove) stored files no branch or tag lists")
    p.add_argument("--delete", action="store_true", help="delete them from the bucket")
    p.add_argument("--older-than", type=int, default=7, metavar="DAYS",
                   help="leave alone files pushed in the last DAYS days (default 7)")
    p.set_defaults(fn=cmd_prune)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
