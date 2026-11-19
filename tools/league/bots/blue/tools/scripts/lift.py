#!/usr/bin/env python3
"""Card placement lift from match dirs, and an updater for src/lift.rs.

lift.py <out lift.rs> <alpha> <dir>...  : new = (1 - alpha) * old + alpha * measured, where measured is the
mean final placement of seats holding the card on a round 4/6/9/12 board minus the mean
(needs n >= 200 per round). Cards with no data keep their old value.
"""
import json, os, re, sys
BOT = os.environ.get('LIFT_BOT')
from collections import defaultdict

def measure(dirs):
    res = {}
    for R in (4, 6, 9, 12):
        stat = defaultdict(lambda: [0, 0.0]); tot = [0, 0.0]
        for d in dirs:
            try:
                for l in open(d + '/games.jsonl'):
                    g = json.loads(l)
                    for s in g['seats']:
                        if BOT and s.get('bot') != BOT: continue
                        for r in s['rounds']:
                            if r['round'] != R: continue
                            tot[0] += 1; tot[1] += s['place']
                            for c in set(u['card'] for u in r['board']):
                                stat[c][0] += 1; stat[c][1] += s['place']
            except Exception:
                pass
        avg = tot[1] / max(1, tot[0])
        for c, v in stat.items():
            if v[0] >= 200:
                res.setdefault(c, []).append((v[1] / v[0] - avg, v[0]))
    return {c: sum(d * n for d, n in l) / sum(n for _, n in l) for c, l in res.items()}

def main():
    out, alpha, dirs = sys.argv[1], float(sys.argv[2]), sys.argv[3:]
    old = {}
    for m in re.finditer(r'"([^"]+)" => (-?[0-9.]+),', open(out).read()):
        old[m.group(1)] = float(m.group(2))
    resid = measure(dirs)
    new = dict(old)
    for c, r in resid.items():
        new[c] = (1 - alpha) * old.get(c, r) + alpha * r
    lines = ["//! Placement lift of each card (negative is good): measured in blue self-play and refined",
             "//! by policy iteration (tools/scripts/lift.py). Used as -lift_w * lift in card values.",
             "pub fn lift(id: &str) -> f64 {", "    match id {"]
    lines += [f'        "{c}" => {new[c]:.3f},' for c in sorted(new)]
    lines += ["        _ => 0.0,", "    }", "}", ""]
    open(out, 'w').write("\n".join(lines))
    big = sorted(resid.items(), key=lambda x: x[1])
    print("residual best:", [(c, round(v, 2)) for c, v in big[:8]])
    print("residual worst:", [(c, round(v, 2)) for c, v in big[-8:]])
    print("mean |residual|:", round(sum(abs(v) for v in resid.values()) / max(1, len(resid)), 3))

main()
