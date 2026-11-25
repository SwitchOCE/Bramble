// Remakes buy-screen-l1.rects.json: loads the L1 mock-up page, screen.html?view=polish&room=zones, in headless Chrome
// (the Playwright headless shell in ~/.cache/ms-playwright) over the DevTools protocol and reads out the
// rectangle of every element the page draws, by the part name the page tags it with.
//
//   node docs/design/look-l1/make-rects.mjs <screen.html> [scratch folder]
//
// The page is not in this repo: it is docs/workstreams/ui-ideation/looks/L1/screen.html on the branch
// ideation/ui-ux, and it reads its painted pieces from the Optiplex (buy-screen-l1.md, section 3), so run this
// there, from a checkout of that branch. The scratch folder (default $TMPDIR/spec-l1) holds Chrome's throwaway profile.
import { spawn } from "node:child_process";
import { readdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
if (!process.argv[2]) { console.error("usage: node make-rects.mjs <screen.html> [scratch folder]"); process.exit(2); }
const PAGE = resolve(process.argv[2]);
const OUT = resolve(HERE, "buy-screen-l1.rects.json");
const SCRATCH = process.argv[3] || (process.env.TMPDIR || "/tmp") + "/spec-l1";
const base = process.env.HOME + "/.cache/ms-playwright/chromium_headless_shell-1254/";
const CHROME = base + readdirSync(base).find(d => d.startsWith("chrome-")) + "/chrome-headless-shell";
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function read(query) {
  const port = 9300 + Math.floor(Math.random() * 500);
  const ch = spawn("timeout", ["60", CHROME, "--no-sandbox", "--hide-scrollbars", "--allow-file-access-from-files",
    "--window-size=1920,1080", `--remote-debugging-port=${port}`, `--user-data-dir=${SCRATCH}/prof`, "about:blank"], { stdio: "ignore" });
  let targets;
  for (let i = 0; i < 50 && !targets; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch { await sleep(200); } }
  const ws = new WebSocket(targets.find(x => x.type === "page").webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);
  let id = 0; const pend = {};
  ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id]; } };
  const call = (method, params = {}) => new Promise(r => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method, params })); });
  await call("Emulation.setDeviceMetricsOverride", { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });
  await call("Page.navigate", { url: `file://${PAGE}?${query}` });
  await sleep(4000);
  const expr = `JSON.stringify([...document.querySelectorAll('#screen > *')].map(n => {
    const b = n.getBoundingClientRect(), cs = getComputedStyle(n), r = v => Math.round(v * 10) / 10;
    const img = n.querySelector('img'), blur = cs.filter.match(/blur\\(([\\d.]+)px\\)/);
    return { part: n.dataset.part || '', cls: n.className.replace('abs', '').trim(), rect: [r(b.left), r(b.top), r(b.width), r(b.height)],
      piece: (cs.backgroundImage.match(/pieces\\/([^"')]+)/) || [])[1] || null,
      art: img ? img.getAttribute('src').split('/').slice(-2).join('/') : null,
      text: (n.innerText || '').trim().replace(/\\n/g, ' / ').slice(0, 20) || null,
      z: cs.zIndex === 'auto' ? null : +cs.zIndex, blur: blur ? +blur[1] : null };
  }))`;
  const res = await call("Runtime.evaluate", { expression: expr, returnByValue: true });
  ws.close(); ch.kill();
  return JSON.parse(res.result.result.value);
}

// what kind of thing each element is
function role(e) {
  const lit = /^(shop|spell|level)-/.test(e.part) || (e.part.startsWith("board-") && e.rect[2] > 170);
  if (e.cls === "glow" || e.blur) return lit ? "light" : "shadow";
  if (e.piece) return "piece";
  if (e.cls.includes("card")) return "card";
  if (e.cls === "spell") return "spell disc";
  if (e.art) return "picture";
  if (e.text) return "text";
  return "drawn";
}
const clean = list => list.map(e => Object.fromEntries(Object.entries({ part: e.part, role: role(e), rect: e.rect, piece: e.piece,
  art: e.art, text: e.text, blur: e.blur, z: e.z }).filter(([, v]) => v !== null && v !== "")));

const Q = "view=polish&room=zones";
const all = await read(Q);
const h2 = (await read(Q + "&hover=2")).filter(e => e.part === "hand-2");
const h6 = (await read(Q + "&hover=6")).filter(e => e.part === "hand-spell");
writeFileSync(OUT, JSON.stringify({
  about: "Every element the L1 mock-up page screen.html?view=polish&room=zones (on ideation/ui-ux) draws, as the browser laid it out: [x, y, width, height] on the " +
    "1920 x 1080 stage, in drawing order (later is on top). Made by make-rects.mjs beside this file. The page's default render is " +
    "pixel-identical to the mock-up's picture c7-chosen.png (checked 25 Nov). 'part' is the name the page tags each element " +
    "with as it draws it. 'role': piece = a painted piece (the spec's section 3); light = a stand-in glow (an engine " +
    "effect in the game: see the spec's Light section); shadow = a stand-in shadow; card, spell disc, picture, text, drawn = drawn in " +
    "code. A blurred element's rect is its shape plus two blur radii on every side.",
  query: Q,
  defaults: { layout: "c", room: "zones", end: "a", lvl: "lantern", level: 5, counters: "medallion", refresh: "pips", hover: -1, gold: 4 },
  elements: clean(all),
  hover: { about: "What changes when a hand card is pointed at: hover=2 (a unit), hover=6 (the spell). Only that card's elements.",
    "hover=2": clean(h2), "hover=6": clean(h6) },
}, null, 1) + "\n");
console.log(`${OUT}: ${all.length} elements`);
process.exit(0);
