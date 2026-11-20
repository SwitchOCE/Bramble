"""Old Brock costing: constructed fights on dev's Rust fight engine (bramble-fight).

Each scenario has a board with an X slot and an opponent board. X is filled with Old Brock,
a plain 8/20 (Old Brock's body with no text) or a plain unit scaled m x (8m/20m). Every
variant fights the same opponent over the same seeds, half with X's side as seat 0, half as
seat 1. Score = X side's wins + half its draws.
"""
import json, subprocess, sys, os, copy

S = os.path.dirname(os.path.abspath(__file__))
BIN = f"{S}/target/release/bramble-fight"
ROOT = f"{S}/repo"
EMPTY_SLOTS = [{"keywords": []} for _ in range(7)]
STANDING = [{"id": i, "granted": False,
             "params": {"golden": False, "_ints": {}, "_texts": {}, "_kinds": {}, "_golden_ints": {}}}
            for i in ("badger_grudge_pay", "pigeon_guard_post")]


def P(a, h, kw=None):
    """Plain unit a/h, optional keyword grants."""
    u = {"def": "plain-unit", "stats": {"set_attack": a, "set_health": h}}
    if kw:
        u["grants"] = [[k] for k in kw]
    return u


def R(card, plus=0, golden=False):
    """Real card with +plus/+plus permanent."""
    u = {"def": card, "golden": golden}
    if plus:
        u["stats"] = {"perm_attack": plus, "perm_health": plus}
    return u


X = "X"


def variant_unit(v):
    kind, m = v
    if kind == "brock":
        return {"def": "old-brock"}
    if kind == "gbrock":
        return {"def": "old-brock", "golden": True}
    if kind == "plain":
        return {"def": "plain-brock", "stats": {"set_attack": round(8 * m), "set_health": round(20 * m)}}
    if kind == "gplain":
        return {"def": "plain-brock", "golden": True,
                "stats": {"set_attack": round(16 * m), "set_health": round(40 * m)}}
    raise ValueError(kind)


def player(pid, board, uid):
    out = []
    for u in board:
        if u is None:
            out.append(None)
            continue
        u = copy.deepcopy(u)
        u.setdefault("golden", False)
        u["uid"] = uid[0]
        uid[0] += 1
        out.append(u)
    return {"id": pid, "tier": 6, "board": out, "hand": [], "slots": EMPTY_SLOTS,
            "counters": {}, "heaps": {}, "standing": STANDING}


def cases(scn, v, seeds, rnd=12):
    mine = [variant_unit(v) if u == X else u for u in scn["a"]]
    opp = scn["b"]
    if opp == "mirror":
        opp = [variant_unit(("plain", 1.0)) if u == X else u for u in scn["a"]]
    if opp == "gmirror":
        opp = [variant_unit(("gplain", 1.0)) if u == X else u for u in scn["a"]]
    out = []
    for i, seed in enumerate(seeds):
        for side in (0, 1):
            uid = [1]
            if side == 0:
                a, b = player(0, mine, uid), player(1, opp, uid)
            else:
                a, b = player(0, opp, uid), player(1, mine, uid)
            out.append({"id": len(out), "game_seed": str(seed), "round": rnd, "a": a, "b": b,
                        "mutations": [], "_x_seat": side})
    return out


def run(cs, tag):
    path = f"{S}/work/{tag}.jsonl"
    outp = f"{S}/work/{tag}.out"
    os.makedirs(f"{S}/work", exist_ok=True)
    with open(path, "w") as f:
        for c in cs:
            f.write(json.dumps({k: v for k, v in c.items() if not k.startswith("_")}) + "\n")
    subprocess.run([BIN, "--repo-root", ROOT, "--cases", path, "--out", outp], check=True,
                   stderr=subprocess.DEVNULL, timeout=600)
    score = 0.0
    n = 0
    errors = 0
    with open(outp) as f:
        for c, line in zip(cs, f):
            d = json.loads(line)
            if "winner" not in d:
                errors += 1
                continue
            w = d.get("winner")
            n += 1
            if w == c["_x_seat"]:
                score += 1
            elif w is None or w == -1:
                score += 0.5
    os.remove(outp)
    os.remove(path)
    return (score / n if n else float("nan")), n, errors


CARDS = {}
for _t in ("badger", "locust", "mouse", "pigeon", "thorn"):
    for _c in json.load(open(f"{ROOT}/src/content/{_t}/units.json"))["cards"]:
        CARDS[_c["id"]] = _c


def scale_unit(u, f):
    """The same unit with its stats times f (plain: set values; real card: permanent buffs)."""
    if u is None or f == 1.0:
        return u
    u = copy.deepcopy(u)
    st = u.get("stats", {})
    c = CARDS[u["def"]]
    g = 2 if u.get("golden") else 1
    if "set_attack" in st:
        a, h = st["set_attack"], st["set_health"]
    else:
        a = c["attack"] * g + st.get("perm_attack", 0)
        h = c["health"] * g + st.get("perm_health", 0)
    if u["def"].startswith("plain"):
        u["stats"] = {"set_attack": max(0, round(a * f)), "set_health": max(1, round(h * f))}
    else:
        u["stats"] = {"perm_attack": round(a * f) - c["attack"] * g, "perm_health": round(h * f) - c["health"] * g}
    return u


def fill(board, v):
    return [variant_unit(v) if u == X else u for u in board]


def pair_cases(mine, opp, seeds, rnd=12):
    """mine vs opp over seeds, both seat orders; _x_seat marks mine."""
    out = []
    for seed in seeds:
        for side in (0, 1):
            uid = [1]
            if side == 0:
                a, b = player(0, mine, uid), player(1, opp, uid)
            else:
                a, b = player(0, opp, uid), player(1, mine, uid)
            out.append({"id": len(out), "game_seed": str(seed), "round": rnd, "a": a, "b": b,
                        "mutations": [], "_x_seat": side})
    return out
