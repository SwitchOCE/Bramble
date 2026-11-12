import json, re, sys, markdown

SRC = sys.argv[1]  # blind dir
OUT = sys.argv[2]

def md(s):
    return markdown.markdown(s, extensions=["tables"])

def inline(s):
    h = markdown.markdown(s.strip())
    return re.sub(r"^<p>|</p>$", "", h.strip())

def split_sections(text):
    parts = re.split(r"^## ", text, flags=re.M)
    secs = {}
    for p in parts[1:]:
        head, _, body = p.partition("\n")
        secs[head.strip()] = body
    return secs

def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]

STAT = re.compile(r"^\s*(\d+)\s*/\s*(\d+)\s*[.,]?\s*")

tribes = {}
for i in range(1, 6):
    text = open(f"{SRC}/Tribe-{i}.md").read()
    secs = split_sections(text)
    keys = list(secs)
    ident = secs[keys[0]]
    sec2 = secs[keys[1]]
    lines = sec2.split("\n")
    # first table
    start = next(n for n, l in enumerate(lines) if l.startswith("|"))
    end = start
    while end < len(lines) and lines[end].startswith("|"):
        end += 1
    header = [h.lower() for h in cells(lines[start])]
    col = {}
    for n, h in enumerate(header):
        if h == "name": col["name"] = n
        elif h == "tier": col["tier"] = n
        elif h in ("stats", "a/h", "attack/health") or "stat" in h and "golden" not in h: col["stats"] = n
        elif h == "text": col["text"] = n
        elif h.startswith("golden"): col["golden"] = n
    cards = []
    for l in lines[start + 2:end]:
        c = cells(l)
        if len(c) < len(header):
            continue
        name = re.sub(r"\*", "", c[col["name"]]).strip()
        tier_m = re.search(r"\d+", c[col["tier"]])
        tier = int(tier_m.group()) if tier_m else 0
        sm = re.search(r"(\d+)\s*/\s*(\d+)", c[col["stats"]])
        atk, hp = (int(sm.group(1)), int(sm.group(2))) if sm else (0, 0)
        g = c[col["golden"]] if "golden" in col else ""
        gm = STAT.match(g)
        if gm:
            gatk, ghp = int(gm.group(1)), int(gm.group(2))
            g = g[gm.end():]
        else:
            gatk, ghp = atk * 2, hp * 2
        cards.append({"name": name, "tier": tier, "atk": atk, "hp": hp,
                      "text": inline(c[col["text"]]), "gatk": gatk, "ghp": ghp,
                      "golden": inline(g) if g.strip() else ""})
    extras = "\n".join(lines[:start] + lines[end:]).strip()
    rest = {k: md(secs[k]) for k in keys[2:]}
    tribes[str(i)] = {
        "identity": md(ident),
        "cards": cards,
        "extras": md(extras) if extras else "",
        "sections": [{"title": re.sub(r"^\d+\.\s*", "", k), "html": v} for k, v in rest.items()],
    }
    print(i, len(cards), "cards", "extras" if extras else "")

json.dump(tribes, open(OUT, "w"))
