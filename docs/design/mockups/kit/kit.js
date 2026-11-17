// Mock-up kit for the 17 Nov backlog briefs: the gold coin, keyword marks and the keyword tooltip.
// Agent-drawn proposals for the owner to react to. Nothing here is decided.

// ---- the gold coin (brief 1): one set of gradients in the page, the coin drawn anywhere at 1em ----
(function () {
  const defs = `<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
<radialGradient id="coinG" cx="38%" cy="32%" r="75%"><stop offset="0" stop-color="#fff8c9"/><stop offset=".35" stop-color="#ffd84a"/><stop offset=".75" stop-color="#e59f12"/><stop offset="1" stop-color="#9a5a06"/></radialGradient>
<radialGradient id="coinI" cx="60%" cy="68%" r="70%"><stop offset="0" stop-color="#ffe680"/><stop offset=".6" stop-color="#f3b623"/><stop offset="1" stop-color="#b8700a"/></radialGradient>
<linearGradient id="coinH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
</defs></svg>`;
  document.addEventListener("DOMContentLoaded", () => document.body.insertAdjacentHTML("afterbegin", defs));
})();
const COIN = `<svg class="coin" viewBox="0 0 32 32" aria-label="gold">
<circle cx="16" cy="16" r="14.6" fill="url(#coinG)" stroke="#16120e" stroke-width="2.6"/>
<circle cx="16" cy="16" r="10.4" fill="url(#coinI)" stroke="#7a4a06" stroke-width="1.5"/>
<path d="M16 9.2 17.9 14.1 22.8 16 17.9 17.9 16 22.8 14.1 17.9 9.2 16 14.1 14.1Z" fill="#fff1a8" stroke="#8a5408" stroke-width="1.1" stroke-linejoin="round"/>
<path d="M7.2 12.4A9.6 9.6 0 0 1 16 5.6" fill="none" stroke="url(#coinH)" stroke-width="2.6" stroke-linecap="round"/>
<path d="M25.6 4.2v4.6M23.3 6.5h4.6" stroke="#fff" stroke-width="1.5" stroke-linecap="round"/></svg>`;

// ---- keywords (brief 2): family colour + icon + word. The reminder lines are the build's own. ----
const IC = {
  shield: '<path d="M12 3 19 6v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/>',
  post: '<path d="M12 2.5 17.5 5v4c0 3.4-2.3 6-5.5 7.5C8.8 15 6.5 12.4 6.5 9V5z"/><path d="M12 16.5V22M8.5 22h7"/>',
  bubble: '<circle cx="12" cy="12" r="8.5"/><path d="M8 9.5a5 5 0 0 1 4-2.5"/>',
  lip: '<path d="M3 13c2.5 2.2 5.5 2 9-1 3.5 3 6.5 3.2 9 1-1.2-3.5-4-5-6-4-1.2.6-2 1.3-3 2.5-1-1.2-1.8-1.9-3-2.5-2-1-4.8.5-6 4z"/>',
  eye: '<path d="M3 12c2.5 3 5.5 4.5 9 4.5s6.5-1.5 9-4.5"/><path d="M6 15.5 4.5 18M12 16.5V19.5M18 15.5l1.5 2.5"/>',
  flame: '<path d="M12 21c-3.6 0-6-2.5-6-6 0-3.5 3-5.5 3.5-9 2 1.5 3 3.3 3 5 1-1 1.5-2.3 1.5-3.5 2.5 2 4 4.5 4 7.5 0 3.5-2.4 6-6 6z"/>',
  cleave: '<path d="M4 15c4-5 12-5 16 0"/><path d="M12 9.5V4M5.5 12 3 9.5M18.5 12 21 9.5"/>',
  overrun: '<path d="M4 6l6 6-6 6M12 6l6 6-6 6"/>',
  dagger: '<path d="M18.5 3.5 9 13l2 2 9.5-9.5zM9 13l-2.5.5 4 4L11 15M6.5 15.5 3.5 20.5"/>',
  pile: '<path d="M6 9l6-5 6 5M6 14l6-5 6 5M6 19l6-5 6 5"/>',
  sortie: '<path d="M4 19c1-8 6-13 14-13"/><path d="M14.5 3 18 6l-3.5 3.5"/>',
  twice: '<path d="M6 19 15 5M11 19 20 5"/>',
  drop: '<path d="M12 3c3.5 4.5 6 7.8 6 11a6 6 0 0 1-12 0c0-3.2 2.5-6.5 6-11z"/>',
  thorns: '<path d="M3 17h18M5 17l2-6 2 6M10 17l2-8 2 8M15 17l2-6 2 6"/>',
  grudge: '<path d="M12 20V5M6.5 10.5 12 5l5.5 5.5"/><path d="M8 20h8"/>',
  medal: '<circle cx="12" cy="15" r="5.5"/><path d="M8.5 3 12 9.5 15.5 3"/>',
  decorated: '<circle cx="12" cy="15" r="5.5"/><path d="M8.5 3 12 9.5 15.5 3"/><path d="M12 12.5v5M9.5 15h5"/>',
  sprout: '<path d="M12 21V11"/><path d="M12 13c-4 0-6.5-2.5-6.5-6 4 0 6.5 2.5 6.5 6zM12 11c0-3.5 2.5-6 6.5-6 0 3.5-2.5 6-6.5 6z"/>',
  wave: '<path d="M3 10c3-3 6 3 9 0s6 3 9 0M3 16c3-3 6 3 9 0s6 3 9 0"/>',
  hopbonus: '<path d="M4 18c2-7 6-10 8-10s6 3 8 10"/><path d="M12 3v4M10 5h4"/>',
  lends: '<path d="M12 20v-7M12 13 6 6M12 13l6-7M4 7.5 6 6l.5 2.5M20 7.5 18 6l-.5 2.5"/>',
  slot: '<path d="M12 2.5 19.5 7v10L12 21.5 4.5 17V7z"/><path d="M12 8.5v7M8.5 12h7"/>',
  bite: '<path d="M20 12a8 8 0 1 1-2.3-5.6L12 12z"/>',
  mouse: '<circle cx="12" cy="14" r="6"/><circle cx="6.5" cy="7.5" r="3"/><circle cx="17.5" cy="7.5" r="3"/>',
  hopper: '<path d="M3 18c3-1 5-4 6-8l4 5 3-9 5 12"/>',
  feather: '<path d="M5 19C8 9 13 5 20 4c-1 7-5 12-15 15z"/><path d="M5 19l8-8"/>',
  seedling: '<circle cx="12" cy="16" r="4.5"/><path d="M12 11.5V4M12 7c2-2 4-2.5 6-2"/>',
  reborn: '<path d="M19 12a7 7 0 1 1-2.1-5"/><path d="M19 4v4h-4"/><path d="M12 9.5v5M9.5 12h5"/>',
  molt: '<path d="M8 4c-3 3-3 13 0 16M16 4c3 3 3 13 0 16"/><path d="M12 7v10"/>',
  root: '<path d="M12 3v9M12 12l-5 7M12 12l5 7M12 15v6"/>',
  reserve: '<path d="M6 21V8h9v13"/><path d="M14 9l5-5M15 4h4v4"/>',
  joins: '<path d="M14 4h5v16h-5"/><path d="M3 12h11M10 8l4 4-4 4"/>',
  copies: '<path d="M9 3.5 15 7v8l-6 3.5L3 15V7z"/><path d="M15 9.5l6 3.5v7l-6 3.5"/>',
  order: '<path d="M5 21V3"/><path d="M5 4h12l-3 4 3 4H5"/>',
  shovel: '<path d="M14 10 20 4M18.5 2.5 21.5 5.5"/><path d="M14 10c-2.5-.5-5 0-7 2l-3 6.5L10.5 15c2-2 2.5-4.5 2-7"/>',
  heap: '<path d="M2.5 19h19c-1-5-4-8-6-8-1 0-2 .7-2.5 1.5C12 10 10 8 8 8c-3 0-5 5-5.5 11z"/>',
  seed: '<path d="M12 3c4 3.5 5.5 8 3.5 12.5-1.3 3-5.7 3-7 0C6.5 11 8 6.5 12 3z"/><path d="M12 7v10"/>',
  outnum: '<circle cx="5" cy="8" r="2"/><circle cx="5" cy="16" r="2"/><circle cx="11" cy="12" r="2"/><path d="M15 12h4"/><circle cx="20" cy="12" r="1.2"/>',
  pawn: '<circle cx="12" cy="7" r="3.2"/><path d="M9 20h6l-1-6h-4zM7 21h10"/>',
  hit: '<path d="M4 20 15 9"/><path d="M13 4l7 7M16.5 4.5l3 3"/>',
};
// name: [family, icon, the build's reminder line]
const KW = {
  "Guard": ["ward", "shield", "Enemies must attack this first."],
  "Guard post": ["ward", "post", "The unit here has Guard. You have one Guard post."],
  "Divine Shield": ["ward", "bubble", "The first damage this takes is prevented."],
  "Stiff Upper Lip": ["ward", "lip", "The first time damage would kill this each fight, it stays on 1 Health."],
  "Stealth": ["ward", "eye", "Can't be attacked until it attacks."],
  "Fury": ["strike", "flame", "Whenever this attacks or is attacked, gain +N Attack for each unit you're Outnumbered by."],
  "Cleave": ["strike", "cleave", "Also damages the units next to its target."],
  "Overrun": ["strike", "overrun", "Damage beyond what kills its target carries on to another enemy."],
  "Hit": ["strike", "hit", "Deal this unit's Attack as damage. It takes none back."],
  "Pile on": ["strike", "pile", "Whenever a neighbour attacks, this hits the target first."],
  "Sortie": ["strike", "sortie", "Attacks the enemy back row while it has units."],
  "Attacks twice": ["strike", "twice", "Attacks twice, back to back."],
  "Venomous": ["strike", "drop", "Destroys any unit it damages."],
  "Thorns": ["strike", "thorns", "Whenever this is attacked, deal N damage to the attacker first."],
  "Grudge": ["growth", "grudge", "After each fight, gain +1/+1 for each unit you were Outnumbered by."],
  "Medal": ["growth", "medal", "+2/+2 permanently."],
  "Decorated": ["growth", "decorated", "Has 3 or more Medals."],
  "Grow": ["growth", "sprout", "Start of fight: gain +N/+N for every 2 units in your Compost."],
  "Tide": ["growth", "wave", "Your Locusts have +N Attack for the rest of the game."],
  "Hopper bonus": ["growth", "hopbonus", "Your Hoppers have this much extra Attack and Health for the rest of the game."],
  "Lends": ["growth", "lends", "The units in front have that much extra while this is on the board."],
  "Slot buff": ["growth", "slot", "Stays on the slot. Any unit standing there has it."],
  "Eat": ["growth", "bite", "This gains the sold unit's stats. The sold unit's death effect triggers."],
  "Cousin": ["kin", "mouse", "A 2/2 Mouse with Pile on."],
  "Hopper": ["kin", "hopper", "A 2/2 Locust. In a fight, a Hopper with no room waits for a slot."],
  "Private": ["kin", "feather", "A 2/2 Pigeon."],
  "Pip": ["kin", "seedling", "A 3/3 Briar with Seed."],
  "Reborn": ["kin", "reborn", "Comes back with 1 Health the first time it dies."],
  "Molt": ["kin", "molt", "The first time this dies each fight, it returns as a plain copy with 1 Health, then gains +2/+2 permanently."],
  "Root": ["kin", "root", "The first time this dies each fight, spend N Compost to return it."],
  "Reserve": ["kin", "reserve", "In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first."],
  "Joins the fight": ["kin", "joins", "Is summoned, or steps in from Reserve."],
  "Copy from the Compost": ["kin", "copies", "A plain copy for this fight. Each unit in your Compost comes out once a fight."],
  "Order": ["shop", "order", "Once a turn, pay N gold to use this."],
  "Bury": ["shop", "shovel", "Once a turn, put a shop unit in your Compost, then do what follows."],
  "Compost": ["shop", "heap", "Your heap. Units you bought go here when you sell them."],
  "Seed": ["shop", "seed", "When this dies, add a copy of it to your Compost."],
  "Outnumbered": ["count", "outnum", "Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted."],
  "Squire": ["count", "pawn", "In the back row, this isn't counted for Outnumbered."],
};
const FAMILY = {
  strike: ["Strike", "Attacks and damage"], ward: ["Ward", "Protection"], growth: ["Growth", "Stats that stay"],
  kin: ["Kin", "Extra bodies and returns"], shop: ["Shop", "Recruit-phase and the Compost"], count: ["Count", "What gets counted"],
};
function kwMark(name, num, cls = "", label = name) {
  const k = KW[name]; if (!k) return name;
  return `<span class="kw f-${k[0]} ${cls}" data-kw="${name}"><i><svg viewBox="0 0 24 24">${IC[k[1]]}</svg></i><b>${label}</b>${num != null && num !== "" ? `<em>${num}</em>` : ""}</span>`;
}
// card text to HTML with keyword marks; "Fury 1", "Thorns 4", "Order (1)", "Tide +2" carry their number
const KW_RE = new RegExp("\\b(" + Object.keys(KW).sort((a, b) => b.length - a.length).map(s => s.replace(/ /g, "\\s")).join("|") +
  ")(s)?\\b(?:\\s(\\+?\\d+)\\b|\\s\\((\\d+)\\))?", "g");
function marksIn(text) {
  return text.replace(KW_RE, (m, name, pl, n1, n2) => kwMark(name.replace(/\s/g, " "), n1 || n2, "", name.replace(/\s/g, " ") + (pl || "")));
}
function fillText(c) {
  // the content's {placeholders} with the card's own numbers where it has them, else 1
  return (c.text || "").replace(/\{(\w+)\}/g, (m, k) => {
    for (const e of c.effects || []) if (e[k] != null) return e[k];
    return "1";
  });
}
const TRIBE_NAME = { badger: "Badger", mouse: "Mouse", pigeon: "Pigeon", locust: "Locust", thorn: "Briar" };
// the card tooltip pane; frozen = Alt held
function tipPane(c, frozen) {
  const tribe = c.tribe ? TRIBE_NAME[c.tribe] : (c.types || [])[0] || "";
  const kind = c.spell ? `Spell · Tier ${c.tier || 1} · costs <span style="font-size:24px;vertical-align:-6px">${coinN(c.cost)}</span>` : `Tier ${c.tier} · ${(c.types || [tribe]).join(" ")}`;
  return `<div class="ktp${frozen ? " frozen" : ""}"><div class="n">${c.name}</div><div class="m">${kind}</div>
<div class="r">${marksIn(c.textFilled || fillText(c))}</div>
<div class="hint">${frozen ? `<span class="key">Alt</span> Point at a keyword` : `Hold <span class="key">Alt</span> for keyword details`}</div></div>`;
}
// a keyword's own tooltip: its mark, its line (with any keyword in it marked too), its family
function kwPane(name, num) {
  const k = KW[name];
  const line = (num != null ? k[2].replace(/\bN\b/g, num) : k[2]);
  return `<div class="kd"><div class="h">${kwMark(name, num)}</div><div class="t">${marksIn(line).replace(kwMark(name, null), name)}</div>
<div class="x">${FAMILY[k[0]][0]}: ${FAMILY[k[0]][1].toLowerCase()}</div></div>`;
}
const POINTER = `<svg class="ptr" viewBox="0 0 30 40"><path d="M3 2v30l8-8 5 12 6-3-5-11h11z" fill="#fff" stroke="#111" stroke-width="2.2" stroke-linejoin="round"/></svg>`;

// a cost: one gold coin with its number inside (owner, round 1: "a gold piece that has a number inside of it")
function coinN(n, poor = false) {
  const s = String(n), fs = s.length > 1 ? 15 : 19;
  return `<svg class="coin coinn${poor ? " poor" : ""}" viewBox="0 0 32 32" aria-label="${n} gold">
<circle cx="16" cy="16" r="14.6" fill="url(#coinG)" stroke="#16120e" stroke-width="2.4"/>
<circle cx="16" cy="16" r="11.2" fill="url(#coinI)" stroke="#7a4a06" stroke-width="1.2"/>
<path d="M7.4 11.6A9.8 9.8 0 0 1 15 5.9" fill="none" stroke="url(#coinH)" stroke-width="2.2" stroke-linecap="round"/>
<text x="16" y="16.4" text-anchor="middle" dominant-baseline="central" font-family="Alegreya,Georgia,serif" font-weight="900" font-size="${fs}"
 fill="${poor ? "#8e0f08" : "#3a2204"}" stroke="#fff3b8" stroke-width="1.6" paint-order="stroke fill">${s}</text></svg>`;
}
// keyword marks on a card, never over the art (owner, round 1). mode "border": under Attack and Health, sitting on the
// frame's bottom border at the card's point; "band": a leaded band across the card's bottom section, under the two discs.
function cardMarks(el, pills, h, mode = "border") {
  el.querySelectorAll(".cm").forEach(e => e.remove());
  if (!pills || !pills.length) return;
  const w = h * 0.56, items = pills.map(p => { const m = /^(.+?)(?:\s\(?(\+?\d+)\)?)?$/.exec(p.replace(/ \((\d+)\)/, " $1")); return [m[1].replace(/\s\+$/, ""), m[2]]; })
    .filter(([n]) => KW[n] || KW[n.replace(/ \+?N$/, "")]);
  if (!items.length) return;
  let size, top, room;
  if (mode === "band") { room = w * 0.64; size = Math.min(h * 0.082, (room - 4 * (items.length - 1)) / items.length); top = h * 0.888 - size / 2; }
  else { room = w * 0.5; size = Math.min(h * 0.09, (room - 3 * (items.length - 1)) / items.length); top = h * 0.925 - size / 2; }
  const box = document.createElement("div");
  box.className = "cm " + mode;
  if (mode === "band") { box.style.clipPath = Cards.outlineClip; box.innerHTML = `<div class="cmband" style="top:${h * 0.836}px;height:${h * 0.2}px"></div>`; }
  const row = document.createElement("div");
  row.className = "cmrow"; row.style.cssText = `top:${top}px;height:${size}px;gap:${mode === "band" ? 4 : 3}px`;
  row.innerHTML = items.map(([n, num]) => { const k = KW[n]; return `<span class="kwc f-${k[0]}" style="width:${size}px;height:${size}px" title="${n}"><svg viewBox="0 0 24 24">${IC[k[1]]}</svg>${num ? `<em style="font-size:${Math.max(10, size * 0.5)}px">${num}</em>` : ""}</span>`; }).join("");
  box.append(row); el.append(box);
}
// a unit's own keywords from its card text: sentences that are only a keyword, as the build's pills are
function pillsFromText(text) {
  return (text || "").split(/\.\s*/).map(s => s.trim()).filter(s => { const m = /^(.+?)(?:\s\(?\+?\d+\)?)?$/.exec(s); return m && KW[m[1]]; });
}
const ALL_SPELLS = [
  { id: "sp_sharpen", name: "Sharpen", tier: 1, cost: 1, art: "assets/art/spell-1.jpg", text: "Give a friendly unit +2/+2.", spell: true },
  { id: "sp_seek", name: "Seek", tier: 2, cost: 3, art: "assets/art/spell-2.jpg", text: "Discover a unit.", spell: true },
  { id: "sp_forage", name: "Forage", tier: 3, cost: 5, art: "assets/art/spell-1.jpg", text: "Discover two units.", spell: true },
];

// a spell drawn large (tooltips): the hex, its price coin on the left shoulder
function spellBig(c, w) {
  const h = w / (Math.sqrt(3) / 2), el = Cards.make({ ...c, spell: "hex", h, cost: null });
  const k = document.createElement("div"); k.className = "hang"; k.style.cssText = "left:-18px;top:" + (h * 0.14) + "px"; k.innerHTML = coinN(c.cost);
  k.querySelector("svg").style.cssText = "width:56px;height:56px"; el.append(k); return el;
}
