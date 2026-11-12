#!/usr/bin/env python3
"""Large files (screenshots, video, art masters) kept in Cloudflare R2 instead of Git.

The repo keeps only tools/assets/manifest.tsv: one line per file with its SHA-256,
size and repo path. The files themselves live in the R2 bucket under their hash,
so nothing is ever overwritten. Pulled files land at their repo paths, which must
be gitignored.

  python tools/assets/assets.py push PATH...      upload files or folders, record them
  python tools/assets/assets.py pull [PREFIX...]  download what the list names
  python tools/assets/assets.py status [PREFIX...] show what is missing or changed

Two ways in, picked automatically:
  - S3 keys: set R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and R2_ACCOUNT_ID
    (needs `pip install boto3`). For agents away from the owner's PC.
  - Otherwise wrangler, using the Cloudflare login on this machine
    (`npx wrangler login`), or CLOUDFLARE_API_TOKEN if set.
Set BRAMBLE_ASSETS_BUCKET to use another bucket (default: bramble-assets).
"""
import argparse
import concurrent.futures as cf
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

BUCKET = os.environ.get("BRAMBLE_ASSETS_BUCKET", "bramble-assets")
WRANGLER_VERSION = "4.160.1"
HEADER = "# sha256\tbytes\tpath   (files kept in Cloudflare R2; see tools/assets/README.md)\n"


def repo_root() -> Path:
    out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
    return Path(out.stdout.strip())


ROOT = repo_root()
MANIFEST = ROOT / "tools" / "assets" / "manifest.tsv"


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


class Wrangler:
    def __init__(self):
        npx = shutil.which("npx")
        if not npx:
            sys.exit("Needs Node's npx for wrangler, or R2 keys (see tools/assets/README.md)")
        self.cmd = [npx, "-y", f"wrangler@{WRANGLER_VERSION}"]

    def _run(self, args):
        r = subprocess.run(self.cmd + args, capture_output=True, text=True)
        if r.returncode != 0:
            tail = (r.stderr or r.stdout).strip().splitlines()[-3:]
            raise RuntimeError(" / ".join(tail))

    def put(self, key, path):
        self._run(["r2", "object", "put", f"{BUCKET}/{key}", f"--file={path}", "--remote"])

    def get(self, key, path):
        self._run(["r2", "object", "get", f"{BUCKET}/{key}", f"--file={path}", "--remote"])


def backend():
    if all(os.environ.get(k) for k in ("R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_ACCOUNT_ID")):
        return S3()
    return Wrangler()


# ---- commands -----------------------------------------------------------------

def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def files_under(args) -> list:
    out = []
    for a in args:
        p = Path(a)
        if p.is_dir():
            out += sorted(f for f in p.rglob("*") if f.is_file())
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


def matches(path: str, prefixes) -> bool:
    return not prefixes or any(path.startswith(p.rstrip("/")) for p in prefixes)


def cmd_push(a):
    entries = read_manifest()
    todo = []
    for f in files_under(a.paths):
        r = rel(f)
        d = sha256(f)
        if entries.get(r, (None,))[0] != d:
            todo.append((r, d, f.stat().st_size, f))
    loose = not_ignored([t[0] for t in todo])
    if loose and not a.force:
        print("These files are not gitignored, so Git would also pick them up:")
        for p in loose[:10]:
            print("  " + p)
        sys.exit("Add a .gitignore rule for them first, or pass --force.")
    known = {d for d, _ in entries.values()}
    be = backend()
    failed = 0

    def up(t):
        r, d, s, f = t
        if d not in known:
            be.put(key_for(d, r), f)
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
    print(f"Pushed {len(todo) - failed} file(s), {failed} failed. Commit tools/assets/manifest.tsv.")
    sys.exit(1 if failed else 0)


def cmd_pull(a):
    entries = {p: v for p, v in read_manifest().items() if matches(p, a.prefixes)}
    todo = []
    for p, (d, s) in entries.items():
        f = ROOT / p
        if not (f.exists() and f.stat().st_size == s and sha256(f) == d):
            todo.append((p, d))
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
    print(f"{len(entries) - len(todo)} already here, {len(todo) - failed} pulled, {failed} failed.")
    sys.exit(1 if failed else 0)


def cmd_status(a):
    entries = {p: v for p, v in read_manifest().items() if matches(p, a.prefixes)}
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
    print(f"{len(entries)} listed, {len(entries) - missing - changed} here, {missing} missing, {changed} changed.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("push", help="upload files or folders and record them in the list")
    p.add_argument("paths", nargs="+")
    p.add_argument("--force", action="store_true", help="push files that are not gitignored")
    p.add_argument("-j", "--jobs", type=int, default=6)
    p.set_defaults(fn=cmd_push)
    p = sub.add_parser("pull", help="download listed files (all, or those under the prefixes)")
    p.add_argument("prefixes", nargs="*")
    p.add_argument("-j", "--jobs", type=int, default=6)
    p.set_defaults(fn=cmd_pull)
    p = sub.add_parser("status", help="compare the list with what is on disk")
    p.add_argument("prefixes", nargs="*")
    p.add_argument("-v", "--verbose", action="store_true")
    p.set_defaults(fn=cmd_status)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
