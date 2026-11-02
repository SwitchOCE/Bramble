"""Build the mechanics library from the designers' and reviewers' JSON files.

The master copy is the input folder, docs/design/mechanics-library-src/: change
those files and rerun. Inputs: design-batch*.json, rules-review*.json,
budget-review*.json. Outputs:
  docs/design/mechanics-library.md     the library as Markdown, for agents
  docs/design/mechanics-library.html   the formatted page for the owner

Usage: python -I tools/research/build_mechanics_library.py [input folder]
The input folder defaults to docs/design/mechanics-library-src/.
"""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DESIGN = ROOT / "docs" / "design"
ARCHETYPES = ["ECO", "WIDE", "TALL", "MEDIUM", "STICKY", "SCAM", "BURST"]


def load(folder):
    mechs = []
    for p in sorted(folder.glob("design-batch*.json")):
        for m in json.loads(p.read_text(encoding="utf-8")):
            mechs.append(m)
    for m in mechs:
        # New mechanics carry a fixed number and an "added" note in the source files.
        m["is_new"] = bool(m.get("added"))

    def index(pattern):
        rows = []
        for p in sorted(folder.glob(pattern)):
            rows += json.loads(p.read_text(encoding="utf-8"))
        out = {}
        for r in rows:
            out[(str(r.get("num")), r.get("name", "").strip().lower())] = r
            out.setdefault(("name", r.get("name", "").strip().lower()), r)
        return out

    rules, budget = index("rules-review*.json"), index("budget-review*.json")
    missing = []
    for m in mechs:
        for key, table in (("rules_review", rules), ("budget_review", budget)):
            r = (table.get((str(m["num"]), m["name"].strip().lower()))
                 or table.get(("name", m["name"].strip().lower()))
                 or table.get(("name", (m.get("old_name") or "").strip().lower())))
            # new mechanics: reviewers saw num "new"
            if r is None and m["is_new"]:
                r = table.get(("new", m["name"].strip().lower()))
            m[key] = r
            if r is None:
                missing.append(f"{key} for {m['num']} {m['name']}")
    mechs.sort(key=lambda m: m["num"])
    return mechs, missing


def questions():
    src = (DESIGN / "mechanics-ideas.md").read_text(encoding="utf-8").replace("\r\n", "\n")
    sec = src[src.index("## Questions for the owner"):]
    sec = sec.split("\n", 1)[1]
    items, cur = [], None
    for ln in sec.split("\n"):
        m = re.match(r"^(\d+)\. (.*)", ln)
        if m:
            cur = {"text": m.group(2), "sub": []}
            items.append(cur)
        elif ln.startswith("   - ") and cur:
            cur["sub"].append(ln[5:])
    tail = [ln for ln in sec.split("\n") if ln.startswith("Not asked here")]
    return items, (tail[0] if tail else "")


def inline(s):
    s = html.escape(s or "")
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*(.+?)\*", r"<em>\1</em>", s)
    s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
    return s


def group_key(g):
    m = re.match(r"([A-O])\.", g or "")
    return m.group(1) if m else "New"


def label_kind(label):
    l = (label or "").upper()
    return "variant" if l.startswith("VARIANT") else "reskin" if l.startswith("RESKIN") else "new"


# ---------- Markdown ----------

def to_md(mechs, qs, tail):
    out = ["# Mechanics library", "",
           "**Status: ideas, 2 November 2026. Nothing is adopted.** Built by `tools/research/build_mechanics_library.py` "
           "from the designer and review files in `mechanics-library-src/`; change those and rerun the build, not this file. Four goldfish designers rewrote "
           "the 65 mechanics of [mechanics-ideas.md](mechanics-ideas.md) (the first-round record) with example units, a play "
           "scene and variations, following the owner's directions ([02h](owner-notes/2026-11-02h-checkpoint-read-through.md), "
           "[02i](owner-notes/2026-11-02i-reactions-are-directions.md)). A rules reviewer and a budget reviewer then checked "
           "them; budget flags use only the tier curve and tolerance bands "
           "([02g](owner-notes/2026-11-02g-stage-2-checkpoint-scope.md)). The owner reads the formatted page, "
           "mechanics-library.html.", ""]
    group = None
    for m in mechs:
        g = m["group"] if not m["is_new"] else "New mechanics: " + m["group"]
        if g != group:
            out += [f"## {g}", ""]
            group = g
        title = f"### {m['num']}. {m['name']} — {m['label']}"
        if m.get("old_name"):
            title += f" *(was {m['old_name']})*"
        out += [title, "", m["summary"], "",
                f"- **Rules.** {m['rules']}",
                f"- **Bends.** {m['bends']}",
                f"- **Creatures.** {m['creatures']}. **Archetypes.** {', '.join(m.get('archetypes', []))}"]
        out.append("- **Example units.**")
        for u in m.get("units", []):
            out.append(f"  - *{u['name']}*, Tier {u['tier']}, {u['attack']}/{u['health']}, {u['tribe']}. {u['text']}")
        out += [f"- **How they play.** {m['how_they_play']}",
                f"- **Why run it.** {m['why_run_it']}",
                f"- **Scene.** {m['scene']}",
                f"- **Good against.** {m['good_against']} **Weak against.** {m['weak_against']}"]
        if m.get("variations"):
            out.append("- **Variations.**")
            for v in m["variations"]:
                out.append(f"  - **{v['name']}.** {v['text']}")
        if m.get("similar_to"):
            out.append(f"- **Similar to.** {m['similar_to']}")
        if m.get("owner_direction"):
            out.append(f"- **Owner's direction.** {m['owner_direction']}")
        if m.get("designer_response"):
            out.append(f"- **Designer's response.** {m['designer_response']}")
        for q in m.get("open_questions", []):
            out.append(f"- **Open.** {q}")
        r = m.get("rules_review")
        if r:
            out.append(f"- **Rules review ({r.get('verdict', '')}).** {r.get('review', '')}")
        b = m.get("budget_review")
        if b:
            out.append(f"- **Budget review.** {b.get('line', '')}")
            for u in b.get("units", []):
                fix = f" Change: {u['fix']}" if u.get("fix") else ""
                out.append(f"  - *{u['name']}*: {u['verdict']}. {u.get('estimate', '')}{fix}")
        out += [f"- **From.** {m.get('source', '')}", ""]
    out += ["## Questions for the owner", ""]
    for i, q in enumerate(qs, 1):
        out.append(f"{i}. {q['text']}")
        out += [f"   - {s}" for s in q["sub"]]
    if tail:
        out += ["", tail]
    return "\n".join(out) + "\n"


# ---------- HTML ----------

CSS = r"""
:root{
  /* Layout: a field guide. A slim group index on the left, one plate per mechanic,
     example units drawn as small cards. Tokens follow the Woodland Folio. */
  --paper:#F1EFE6; --paper-2:#E5E3D6; --card:#FAF9F4;
  --ink:#23261F; --ink-soft:#5B5F52; --rule:#CFCCBC;
  --moss:#2F5A3C; --ochre:#A97818; --rose:#9C3B2E;
  --display:"IM Fell English","Iowan Old Style",Georgia,serif;
  --body:"Alegreya","Iowan Old Style",Georgia,serif;
  --label:"Alegreya Sans SC","Gill Sans","Segoe UI",sans-serif;
}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){
  --paper:#161914; --paper-2:#1F231C; --card:#1B1F18;
  --ink:#E7E4D6; --ink-soft:#A6A999; --rule:#353B31;
  --moss:#8DBB8F; --ochre:#D9A84E; --rose:#E08A78; color-scheme:dark}}
:root[data-theme="dark"]{
  --paper:#161914; --paper-2:#1F231C; --card:#1B1F18;
  --ink:#E7E4D6; --ink-soft:#A6A999; --rule:#353B31;
  --moss:#8DBB8F; --ochre:#D9A84E; --rose:#E08A78; color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font-family:var(--body);font-size:18px;line-height:1.55}
.wrap{max-width:1180px;margin:0 auto;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));padding-block:40px 80px}
h1,h2,h3{font-family:var(--display);font-weight:400;line-height:1.12;text-wrap:balance;margin:0}
h1{font-size:clamp(34px,5vw,52px)}
h2{font-size:30px}
h3{font-size:28px}
.label{font-family:var(--label);font-weight:500;letter-spacing:.06em;font-size:14px;color:var(--ink-soft)}
.lede{max-width:66ch;margin:14px 0 0;color:var(--ink)}
.lede+.lede{margin-top:10px}
code{font-size:.9em}
.layout{display:grid;grid-template-columns:220px minmax(0,1fr);gap:40px;margin-top:32px}
nav.toc{position:sticky;top:calc(env(safe-area-inset-top,0px) + 16px);align-self:start;display:flex;flex-direction:column;gap:2px;max-height:calc(100vh - 32px);overflow:auto}
.toc button{all:unset;cursor:pointer;font-family:var(--label);font-weight:500;letter-spacing:.04em;font-size:14px;color:var(--ink-soft);padding:5px 0 5px 10px;border-left:2px solid transparent;line-height:1.3}
.toc button:hover{color:var(--ink)}
.toc button[aria-pressed="true"]{color:var(--moss);border-left-color:var(--moss)}
.toc button:focus-visible{outline:2px solid var(--ochre);outline-offset:2px}
.toc .n{font-variant-numeric:tabular-nums;opacity:.7;margin-left:4px}
main{min-width:0;display:flex;flex-direction:column;gap:28px}
.ghead{display:flex;align-items:baseline;gap:12px;padding-top:12px;border-top:1px solid var(--rule)}
.ghead .label{color:var(--ochre)}
article.mech{background:var(--card);border:1px solid var(--rule);border-radius:3px;padding:24px 26px;display:flex;flex-direction:column;gap:16px;min-width:0}
.mhead{display:flex;flex-wrap:wrap;align-items:baseline;gap:8px 14px}
.mhead .num{font-family:var(--label);font-weight:700;font-size:15px;color:var(--ink-soft);font-variant-numeric:tabular-nums}
.badge{font-family:var(--label);font-weight:700;letter-spacing:.06em;font-size:12.5px;padding:2px 8px;border:1px solid currentColor;border-radius:2px}
.badge.new{color:var(--moss)} .badge.variant{color:var(--ochre)} .badge.reskin{color:var(--ink-soft)}
.badge.added{color:var(--rose)}
.chips{display:flex;flex-wrap:wrap;gap:6px}
.chip{font-family:var(--label);font-size:13px;letter-spacing:.04em;padding:2px 8px;background:var(--paper-2);border-radius:2px;color:var(--ink)}
.was{font-style:italic;color:var(--ink-soft);font-size:16px}
.summary{font-size:21px;line-height:1.4;max-width:60ch;margin:0}
.rules{border-left:3px solid var(--moss);padding:6px 0 6px 14px;margin:0}
.rules .label{display:block;margin-bottom:2px}
.units{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
.unit{background:var(--paper);border:1px solid var(--rule);border-radius:6px;padding:12px 14px 14px;display:flex;flex-direction:column;gap:6px;min-width:0}
.unit .top{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.unit .uname{font-family:var(--display);font-size:20px;line-height:1.15}
.tier{font-family:var(--label);font-weight:700;font-size:13px;letter-spacing:.05em;color:var(--ochre);white-space:nowrap}
.unit .tribe{font-family:var(--label);font-size:13px;letter-spacing:.04em;color:var(--ink-soft)}
.unit .text{font-size:16px;line-height:1.45;flex:1}
.stats{display:flex;gap:8px;font-family:var(--label);font-weight:700;font-size:15px;font-variant-numeric:tabular-nums}
.stats span{padding:1px 8px;border-radius:2px;background:var(--paper-2)}
.stats .a{color:var(--rose)} .stats .h{color:var(--moss)}
.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px 28px}
.blk{min-width:0}
.blk p{margin:2px 0 0;max-width:66ch}
.scene{background:var(--paper);border-radius:3px;padding:12px 16px}
.scene p{margin:2px 0 0;font-style:italic}
.vs{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:10px 24px;margin:4px 0 0;padding:0;list-style:none}
.vs li{border-top:1px solid var(--rule);padding-top:6px}
.vs b{font-family:var(--label);letter-spacing:.04em;font-size:15px;color:var(--moss)}
.owner{border:1px solid var(--rule);border-left:3px solid var(--rose);border-radius:3px;padding:10px 14px;display:flex;flex-direction:column;gap:6px}
.owner .label{color:var(--rose)}
.owner p{margin:0}
.oq{margin:0;padding-left:20px}
details.rev{border-top:1px solid var(--rule);padding-top:10px}
details.rev summary{cursor:pointer;font-family:var(--label);font-weight:500;letter-spacing:.05em;font-size:14px;color:var(--ink-soft)}
details.rev summary:focus-visible{outline:2px solid var(--ochre);outline-offset:2px}
.verdict{font-family:var(--label);font-weight:700;letter-spacing:.05em;font-size:12.5px;padding:1px 7px;border-radius:2px;margin-left:6px;background:var(--paper-2)}
.v-flag{color:var(--rose)} .v-edge{color:var(--ochre)} .v-ok{color:var(--moss)}
.revbody{display:flex;flex-direction:column;gap:8px;margin-top:8px;font-size:16px}
.revbody p{margin:0}
.revbody ul{margin:0;padding-left:20px}
.src{font-size:14px;color:var(--ink-soft)}
.qs{background:var(--card);border:1px solid var(--rule);border-radius:3px;padding:24px 26px}
.qs ol{margin:12px 0 0;padding-left:22px;display:flex;flex-direction:column;gap:10px;max-width:72ch}
.qs ul{margin:6px 0 0;padding-left:20px}
@media (max-width:820px){
  .layout{grid-template-columns:1fr;gap:20px}
  nav.toc{position:static;flex-direction:row;flex-wrap:wrap;gap:6px;max-height:none}
  .toc button{border-left:0;border:1px solid var(--rule);border-radius:2px;padding:4px 10px}
  .toc button[aria-pressed="true"]{border-color:var(--moss)}
  article.mech{padding:18px 16px}
  .summary{font-size:19px}
}
@media (prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
"""

JS = r"""
(function(){
  var btns=[].slice.call(document.querySelectorAll('.toc button'));
  var items=[].slice.call(document.querySelectorAll('[data-g]'));
  function show(g){
    btns.forEach(function(b){b.setAttribute('aria-pressed', b.dataset.f===g?'true':'false');});
    items.forEach(function(el){el.hidden = !(g==='all' || el.dataset.g===g);});
    try{localStorage.setItem('mlib-group',g);}catch(e){}
  }
  btns.forEach(function(b){b.addEventListener('click',function(){show(b.dataset.f);window.scrollTo(0,document.querySelector('.layout').offsetTop-12);});});
  var start='all';
  try{start=localStorage.getItem('mlib-group')||'all';}catch(e){}
  if(!btns.some(function(b){return b.dataset.f===start;})) start='all';
  show(start);
})();
"""


def verdict_class(v):
    v = (v or "").lower()
    return "v-flag" if "flag" in v or "broken" in v else "v-edge" if "edge" in v or "ruling" in v else "v-ok"


def to_html(mechs, qs, tail):
    e = inline
    groups, order = {}, []
    for m in mechs:
        k = "New" if m["is_new"] else group_key(m["group"])
        if k not in groups:
            groups[k] = (m["group"] if not m["is_new"] else "New mechanics", [])
            order.append(k)
        groups[k][1].append(m)
    order = sorted([k for k in order if k != "New"]) + (["New"] if "New" in order else [])

    toc = ['<button type="button" data-f="all" aria-pressed="true">All mechanics'
           f'<span class="n">{len(mechs)}</span></button>']
    for k in order:
        title = groups[k][0]
        short = re.sub(r"^[A-O]\.\s*", "", title)
        toc.append(f'<button type="button" data-f="{k}">{e(short)}<span class="n">{len(groups[k][1])}</span></button>')
    toc.append('<button type="button" data-f="q">Questions for you</button>')

    body = []
    for k in order:
        title, ms = groups[k]
        body.append(f'<div class="ghead" data-g="{k}"><span class="label">Group {k if k != "New" else "+"}</span><h2>{e(re.sub(r"^[A-O]\.\s*", "", title))}</h2></div>')
        for m in ms:
            kind = label_kind(m["label"])
            chips = "".join(f'<span class="chip">{e(a)}</span>' for a in m.get("archetypes", []))
            was = f'<span class="was">was {e(m["old_name"])}</span>' if m.get("old_name") else ""
            added = ""
            if m["is_new"]:
                added = '<span class="badge added">YOUR IDEA</span>' if "owner" in m.get("added", "") else '<span class="badge added">ADDED THIS ROUND</span>'
            units = "".join(
                f'<div class="unit"><div class="top"><span class="uname">{e(u["name"])}</span><span class="tier">Tier {e(str(u["tier"]))}</span></div>'
                f'<span class="tribe">{e(u.get("tribe", ""))}</span><div class="text">{e(u["text"])}</div>'
                f'<div class="stats"><span class="a">{e(str(u["attack"]))} Attack</span><span class="h">{e(str(u["health"]))} Health</span></div></div>'
                for u in m.get("units", []))
            vs = "".join(f'<li><b>{e(v["name"])}</b><br>{e(v["text"])}</li>' for v in m.get("variations", []))
            sim = f'<div class="blk"><span class="label">Similar to</span><p>{e(m["similar_to"])}</p></div>' if m.get("similar_to") else ""
            owner = ""
            if m.get("owner_direction") or m.get("designer_response"):
                owner = '<div class="owner">'
                if m.get("owner_direction"):
                    owner += f'<span class="label">Your direction</span><p>{e(m["owner_direction"])}</p>'
                if m.get("designer_response"):
                    owner += f'<span class="label">Designer\'s response</span><p>{e(m["designer_response"])}</p>'
                owner += "</div>"
            oq = ""
            if m.get("open_questions"):
                oq = '<div class="blk"><span class="label">Open questions</span><ul class="oq">' + "".join(
                    f"<li>{e(q)}</li>" for q in m["open_questions"]) + "</ul></div>"
            r, b = m.get("rules_review") or {}, m.get("budget_review") or {}
            bverd = [u.get("verdict", "") for u in b.get("units", [])]
            worst = next((v for v in bverd if "flag" in v), next((v for v in bverd if "edge" in v), "in band" if bverd else ""))
            summ = "Review notes"
            if r:
                summ += f'<span class="verdict {verdict_class(r.get("verdict"))}">Rules: {e(r.get("verdict", ""))}</span>'
            if worst:
                summ += f'<span class="verdict {verdict_class(worst)}">Budget: {e(worst)}</span>'
            rev = f'<details class="rev"><summary>{summ}</summary><div class="revbody">'
            if r:
                rev += f'<p><strong>Rules.</strong> {e(r.get("review", ""))}</p>'
            if b:
                rev += f'<p><strong>Budget.</strong> {e(b.get("line", ""))}</p><ul>' + "".join(
                    f'<li><em>{e(u["name"])}</em>: {e(u.get("verdict", ""))}. {e(u.get("estimate", ""))}'
                    + (f' Change: {e(u["fix"])}' if u.get("fix") else "") + "</li>" for u in b.get("units", [])) + "</ul>"
            rev += f'<p><strong>Bends.</strong> {e(m.get("bends", ""))}</p><p class="src">From {e(m.get("source", ""))}. Creatures: {e(m.get("creatures", ""))}.</p></div></details>'
            body.append(
                f'<article class="mech" id="m{m["num"]}" data-g="{k}">'
                f'<div class="mhead"><span class="num">No. {m["num"]}</span><h3>{e(m["name"])}</h3>{was}'
                f'<span class="badge {kind}">{e(m["label"])}</span>{added}<div class="chips">{chips}</div></div>'
                f'<p class="summary">{e(m["summary"])}</p>'
                f'<div class="rules"><span class="label">Rules text</span>{e(m["rules"])}</div>'
                f'<div class="units">{units}</div>'
                f'<div class="cols"><div class="blk"><span class="label">How they play together</span><p>{e(m["how_they_play"])}</p></div>'
                f'<div class="blk"><span class="label">Why run it</span><p>{e(m["why_run_it"])}</p></div></div>'
                f'<div class="scene"><span class="label">A game where it shines</span><p>{e(m["scene"])}</p></div>'
                f'<div class="cols"><div class="blk"><span class="label">Good against</span><p>{e(m["good_against"])}</p></div>'
                f'<div class="blk"><span class="label">Weak against</span><p>{e(m["weak_against"])}</p></div>{sim}</div>'
                + (f'<div class="blk"><span class="label">Variations</span><ul class="vs">{vs}</ul></div>' if vs else "")
                + owner + oq + rev + "</article>")
    ql = "".join(f"<li>{e(q['text'])}" + ("<ul>" + "".join(f"<li>{e(s)}</li>" for s in q["sub"]) + "</ul>" if q["sub"] else "") + "</li>" for q in qs)
    body.append(f'<section class="qs" data-g="q"><span class="label">For later</span><h2>Questions for you</h2><ol>{ql}</ol>'
                + (f'<p class="src">{e(tail)}</p>' if tail else "") + "</section>")

    n_new = sum(m["is_new"] for m in mechs)
    lede = (f"{len(mechs)} mechanics: the 65 from the first round, rewritten with example units, a game where each one shines, "
            f"and variations, plus {n_new} new ones added this round, one of them yours. Nothing here is adopted, and your directions are "
            "marked on each card with the designer's response. Review notes are folded under each card.")
    return ("<title>Bramble mechanics library</title>\n"
            '<meta name="claude:viewport-fit-sides" content="cover">\n'
            '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
            '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
            '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IM+Fell+English:ital@0;1&family=Alegreya:ital,wght@0,400;0,500;0,700;1,400&family=Alegreya+Sans+SC:wght@500;700&display=swap">\n'
            f"<style>{CSS}</style>\n"
            '<div class="wrap"><header><span class="label">Bramble · Stage 2 · 2 November 2026</span>'
            '<h1>Mechanics library</h1>'
            f'<p class="lede">{e(lede)}</p>'
            '<p class="lede">Costs are rough guesses until simulated. Budget notes use only the tier curve and your tolerance bands.</p></header>'
            f'<div class="layout"><nav class="toc" aria-label="Groups">{"".join(toc)}</nav><main>{"".join(body)}</main></div></div>\n'
            f"<script>{JS}</script>\n")


def main():
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else DESIGN / "mechanics-library-src"
    mechs, missing = load(folder)
    qs, tail = questions()
    (DESIGN / "mechanics-library.md").write_text(to_md(mechs, qs, tail), encoding="utf-8")
    (DESIGN / "mechanics-library.html").write_text(to_html(mechs, qs, tail), encoding="utf-8")
    print(f"{len(mechs)} mechanics ({sum(m['is_new'] for m in mechs)} new); missing reviews: {len(missing)}")
    for x in missing:
        print("  missing", x)


if __name__ == "__main__":
    main()
