import gzip, hashlib, json, subprocess
from pathlib import Path

r = Path.cwd()
v = r / "tools/sim/evidence/wave1-rebase-verification.json"
paths = [
    r / "docs/ideation/evidence/wave1-rebase.md",
    r / "docs/ideation/evidence/wave1-rebase-C.md",
    r / "tools/sim/evidence/wave1-rebase-comparison.json",
    v,
]
before = {str(p.relative_to(r)): p.read_text() for p in paths}
a = r / "tools/sim/evidence/wave1-rebase-original-labels.json.gz"
assert not a.exists(), "original labels already preserved; do not overwrite history"
with a.open("wb") as raw, gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as z:
    z.write(json.dumps(before).encode())
subprocess.run(
    [
        "python3",
        "tools/sim/wave1_rebase_compare.py",
        "--b",
        "tools/sim/evidence/wave1-rebase-B.json",
        "--c",
        "tools/sim/evidence/wave1-rebase-C.json",
        "--out",
        "tools/sim/evidence/wave1-rebase-comparison.json",
        "--markdown",
        "docs/ideation/evidence/wave1-rebase.md",
    ],
    check=True,
)
p = paths[1]
s = p.read_text()
s += "\nC Birds rows in this historical run are superseded: they measured provisional 4× homecoming, now being replaced by paper C at 2.5× on wave2a. B Birds remain unchanged. Aggregate C figures describe the measured 4× build.\n"
p.write_text(s)
# Keep the recorded runtime/validation footer when rebuilding the report.
p = paths[0]
old = before[str(p.relative_to(r))]
footer = old[old.index("\n## Runtime and validation") :]
p.write_text(p.read_text() + footer)
d = json.loads(v.read_text())
changed = {}
for p in paths[:-1]:
    key = str(p.relative_to(r))
    changed[key] = {
        "before_sha256": hashlib.sha256(before[key].encode()).hexdigest(),
        "after_sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
    }
    d["artifact_sha256"][key] = changed[key]["after_sha256"]
d["artifact_sha256"][str(a.relative_to(r))] = hashlib.sha256(a.read_bytes()).hexdigest()
d["editorial_revision"] = {
    "reason": "User superseded old provisional C Birds4x rows with forthcoming paperC2.5x; numeric measurements unchanged",
    "original_labels_archive": str(a.relative_to(r)),
    "changed": changed,
}
v.write_text(json.dumps(d, indent=2) + "\n")
