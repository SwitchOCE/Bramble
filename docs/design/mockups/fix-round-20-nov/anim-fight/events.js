// Every fight event, each a small scene on the real fight screen. PROPOSAL: agent-drawn, not decided.
// Each entry: id, section, title, tag (new / changed / keep), now (what the build does), prop (what this
// shows), nowS and propS (rough seconds, for the timing chart), and build(p), which draws the boards and
// lays out the motions on p's timeline (anim.js). Unit stats are the build's (src/content); a few are
// raised by the effects named in the scene. Cards, stats and text are the dev branch's (dev-cards.js), which
// the owner plays: no Medals, Orders or Stiff Upper Lip; Renown on slots, Hand-me-down, Charge pips instead.

const YOU = { p: "dame_farthing", name: "Dame Farthing", hp: 34 };
const OPP = { p: "brother_bracken", name: "Brother Bracken", hp: 36 };
function scene(p, you, opp, o = {}) {
  p.window();
  p.board("opp", opp); p.board("you", you);
  p.heroes({ turn: o.turn, you: { ...YOU, ...(o.you || {}) }, opp: { ...OPP, ...(o.opp || {}) } });
}
const U = (p, side, i) => p.u[side][i];
// the Health disc's centre on a card (tier 1 roundel; close enough for every tier)
const hpDisc = Uu => v2(Uu.x + 448.8 / 560 * W, Uu.y + 778.5 / 1000 * H);
const atkDisc = Uu => v2(Uu.x + 110.8 / 560 * W, Uu.y + 778.5 / 1000 * H);
// swap a card's whole row of keyword marks at t (a keyword gained)
function remark(p, t, Uu, marks) {
  const old = Uu.el.querySelector(".cm"), tmp = document.createElement("div");
  cardMarks(tmp, marks, H, "border");
  const nw = tmp.querySelector(".cm"); nw.style.opacity = 0; Uu.el.append(nw);
  if (old) p.at(t, old, [{ opacity: 1 }, { opacity: 0 }], 40);
  p.at(t, nw, [{ opacity: 1 }, { opacity: 1 }], 1);
}

// a Charge pip is used: it flashes and dims (card_pips.gd: a spent pip at 40%)
function spendPip(p, t, Uu, kind = "charge") {
  const left = [...Uu.el.querySelectorAll(".pip." + kind + ":not(.spent)")], q = left[left.length - 1]; if (!q) return;
  q.classList.add("spent");
  p.at(t, q, [{ opacity: 1, scale: 1, filter: "brightness(1)" }, { opacity: 1, scale: 1.9, filter: "brightness(1.6)", offset: .3 }, { opacity: .4, scale: 1, filter: "brightness(1)" }], 380, "ease-out");
}
// a unit's Renown pill pops to a new number
function renownTo(p, t, Uu, n) {
  const old = Uu.el.querySelector(".renown"); if (!old) return;
  const nw = old.cloneNode(true); nw.querySelector("b").textContent = n; nw.style.opacity = 0; Uu.el.append(nw);
  p.at(t, old, [{ opacity: 1 }, { opacity: 0 }], 30);
  p.at(t, nw, [{ opacity: 1, scale: 1.7, filter: "brightness(1.6)" }, { opacity: 1, scale: 1, filter: "brightness(1)" }], 320, "ease-out");
}

const EVENTS = [
// ---------------------------------------------------------------- 01 into the fight
{ id: "enter", sec: 1, title: "Moving into the fight", tag: "new", nowS: 0.7, propS: 1.0,
  now: "Instant screen swap, then the whole board holds 0.7 s.",
  prop: "The shop lifts away and the hand drops, your board glides down into place, the opponent's board deals in from the top, front row first, and their portrait slides into the right light.",
  timing: "1.0 s, replacing the 0.7 s hold",
  build(p) {
    const rStone = p.window(RG);
    const fStone = p.window(FG, false); fStone.style.opacity = 0;
    p.at(120, rStone, [{ opacity: 1 }, { opacity: 0 }], 300);
    const dy = FG.boardTop - RG.boardTop;
    // your board, drawn where the fight puts it, starting where the recruit screen had it
    const you = ["brock-cub", "hedge-knight", "pip", "territorial", "sett-shield-bearer", null, "relic-seeker"];
    const opp = ["needle-page", "cousin", "hedgerow-scout", "fencing-master", "harvest-piper", "dormouse-cook", null];
    p.board("you", you);
    p.slots.you.forEach(s => p.at(0, s, [{ translate: `0px ${-dy}px` }, { translate: `0px ${-dy}px`, offset: .38 }, { translate: "0px 0px" }], 420, "ease-in-out"));
    p.u.you.forEach(u => u && p.at(0, u.el, [{ translate: `0px ${-dy}px` }, { translate: `0px ${-dy}px`, offset: .38 }, { translate: "0px 0px" }], 420, "ease-in-out"));
    p.at(120, fStone, [{ opacity: 0 }, { opacity: 1 }], 300);
    // the opponent's board: its empty panes fade in, the units drop in from above, front row first
    p.board("opp", opp);
    p.slots.opp.forEach(s => { s.style.opacity = 0; p.at(250, s, [{ opacity: 0 }, { opacity: 1 }], 200); });
    [0, 1, 2, 3, 4, 5, 6].forEach((i, k) => { const u = p.u.opp[i]; if (!u) return; u.el.style.opacity = 0;
      p.at(300 + k * 35, u.el, [{ opacity: 0, translate: "0px -130px" }, { opacity: 1, translate: "0px 6px", offset: .8 }, { opacity: 1, translate: "0px 0px" }], 240, "ease-out"); });
    // the recruit screen's shop, buttons and hand leave
    const shop = ["hedge-lancer", "gate-warden", "pip", "husk-sentry", "lance-corporal"];
    shop.forEach((id, k) => { const c = p.card(id, RG.shopL + k * (W + GAP), RG.shopTop);
      p.at(k * 25, c.el, [{ opacity: 1, translate: "0px 0px" }, { opacity: 0, translate: "0px -60px" }], 240, "ease-in"); });
    const bw = 150, bxL = RG.shopL - 18 - bw, bxR = RG.shopL + RG.shopW + 18, by1 = RG.shopTop + H / 2 - 66, by2 = by1 + 76;
    [[`<div class="btn gold" style="width:${bw}px">${ICON.gold}<b>0</b></div>`, bxL, by1], [`<div class="btn" style="width:${bw}px">${ICON.tier}3→4<span class="pip">6</span></div>`, bxL, by2],
     [`<div class="btn" style="width:${bw}px">${ICON.refresh}<span class="pip">1</span></div>`, bxR, by1], [`<div class="btn freeze" style="width:${bw}px">${ICON.freeze}</div>`, bxR, by2]]
      .forEach(([h, x, y]) => { const b = place(html(h), x, y); p.st.append(b); p.at(0, b, [{ opacity: 1 }, { opacity: 0 }], 180); });
    const hand = ["brood-mother", "crab-apple", "bugler"];
    hand.forEach((id, k) => { const kk = k - 1, c = p.card(id, 960 - W / 2 + kk * W * .74, RG.handTop + kk * kk * 4);
      c.el.style.rotate = (kk * 2.5) + "deg"; c.el.style.transformOrigin = "50% 100%";
      p.at(k * 20, c.el, [{ translate: "0px 0px" }, { translate: "0px 260px" }], 260, "ease-in"); });
    p.heroes({ opp: { hidden: true }, you: YOU });
    // End turn portrait (the next opponent) leaves the bottom right; they appear at the top right
    const eX = 1904 - 16 - 128 - 26;
    const et = place(html(`<div class="port endturn" style="width:128px;height:128px;background-image:url(assets/portraits/brother_bracken.jpg)"></div>`), eX, 1080 - 150);
    const el = place(html(`<div class="lbl endlbl" style="font-size:22px">End turn</div>`), eX - 6, 1080 - 188);
    p.st.append(et, el);
    p.at(0, et, [{ opacity: 1, scale: 1 }, { opacity: 0, scale: .8 }], 200); p.at(0, el, [{ opacity: 1 }, { opacity: 0 }], 150);
    const op = place(html(`<div class="port opphero" style="width:128px;height:128px;background-image:url(assets/portraits/brother_bracken.jpg);opacity:0"></div>`), OPP_X, 96);
    const oh = place(html(`<div class="hp" style="opacity:0">36</div>`), OPP_X + 78, 180);
    const on = place(html(`<div class="lbl oppname" style="font-size:22px;opacity:0">Brother Bracken</div>`), OPP_X - 30, 238);
    p.st.append(op, oh, on);
    [op, oh, on].forEach((e, k) => p.at(380 + k * 40, e, [{ opacity: 0, translate: "180px 0px" }, { opacity: 1, translate: "0px 0px" }], 300, "cubic-bezier(.22,.61,.36,1)"));
    p.at(1000, p.st, [{ opacity: 1 }, { opacity: 1 }], 1);
  } },

// ---------------------------------------------------------------- 02 start of fight
{ id: "lancer", sec: 2, title: "Start of fight: Hedge Lancer's free attack", tag: "changed", nowS: 1.37, propS: 1.1,
  now: "The lancer lifts and glows for 0.3 s, then a normal attack. Its \"takes no damage\" shows only as a 0 burst.",
  prop: "The lancer lifts with a gold ward light round it (it takes no damage), then attacks at once: the blue 0 on the lancer, Fury flares and its Attack rises, the target falls.",
  timing: "0.25 s lift into a 0.77 s attack",
  build(p) {
    scene(p, ["hedge-knight", "hedge-lancer", "brock-cub", null, "relic-seeker", "grudge-keeper", null],
      ["cousin", "needle-page", "harvest-piper", "hedgerow-scout", "shrew-cutpurse", "dormouse-cook", null]);
    const L = U(p, "you", 1), T = U(p, "opp", 1);
    p.glow(100, L, 330);
    p.ring(140, L.cx, L.cy, "#ffe7a6", 70, 150, 380, 8);
    const c = p.attack(380, L, T, { dealt: 6, taken: 0, takenBlocked: true, blocked: false, tHp: -3 });
    p.at(c, L.el, [{ filter: F_BLOCK }, { filter: F_BASE }], 250);
    p.flare(c, L, "Fury"); p.num(c + 40, L, "atk", 7, "up");
    p.die(c + 250, T);
  } },
{ id: "grow", sec: 2, title: "Start of fight: Grow", tag: "changed", nowS: 1.8, propS: 0.9,
  now: "Each Grow unit is its own 0.3 s glow plus a 0.3 s number change, one after another.",
  prop: "One moment for every Grow unit: the Compost plate lights, a green sprout flies from it to each Grow unit, and their numbers count up together.",
  timing: "0.9 s for any number of Grow units",
  build(p) {
    scene(p, [{ id: "blackberry-sprawl" }, { id: "bramble-runner", marks: ["Seed", "Grow 1"] }, { id: "nettle-sprout", marks: ["Thorns 2", "Grow 1"] }, "hawthorn-warden",
      "sweetbriar", "ivy-climber", "old-stump"],
      ["brock-cub", "hedge-knight", "gate-warden", "hedge-lancer", "armsbearer", "sett-shield-bearer", null],
      { you: { plates: [["bog", "Compost", 6]] } });
    const from = p.plateXY("Compost");
    p.plate(80, "Compost", 6);
    [[0, 6], [1, 3], [2, 3]].forEach(([i, n], k) => {
      const u = U(p, "you", i), land = p.shard(160 + k * 60, from, v2(u.cx, u.cy), 300, { colour: "#c8f2a6", cls: "sprout", size: 30, bend: .18 });
      p.flare(land, u, i === 0 ? "Grow" : "Grow");
      p.ring(land, u.cx, u.cy, "#c8f2a6", 50, 120, 300);
      p.count(land + 20, u, "atk", u.atk + n, 240, "up"); p.count(land + 20, u, "hp", u.hp + n, 240, "up");
      p.float(land + 40, u.cx, u.y + H * .45, `+${n}/+${n}`, { cls: "gain" });
    });
  } },
{ id: "wingco", sec: 2, title: "Start of fight: Wing Commander", tag: "changed", nowS: 2.3, propS: 1.3,
  now: "Its 0.3 s glow, then each Sortie Pigeon's attack as a full separate step (0.77 s each, 0.14 s between).",
  prop: "The Commander glows and sends a pulse along the row; each Sortie Pigeon flies over the front row at the back row, the next one leaving as the one before strikes.",
  timing: "0.3 s, then attacks 0.3 s apart",
  build(p) {
    scene(p, [{ id: "sentry", atk: 5, marks: ["Sortie"], up: ["atk"] }, { id: "wing-commander", atk: 13, up: ["atk"] }, "colour-sergeant", "lance-corporal", "squadron-leader", "padre", "recruiting-sergeant"],
      [{ id: "husk-sentry" }, "hopper", "wheat-raider", "green-recruit", "prophet-of-the-dust", "gorger", "granary-glutton"]);
    const WC = U(p, "you", 1), S = U(p, "you", 0);
    p.glow(80, WC, 360);
    p.ring(140, WC.cx, WC.cy, "#ffb7a4", 60, 260, 420);
    const t1 = 360, t2 = 660;
    p.flare(t1, S, "Sortie");
    const c1 = p.attack(t1, S, U(p, "opp", 4), { arc: 70, travel: 200, dealt: 5, taken: 2, tHp: 2, aHp: 3 });
    p.flare(t2, WC, "Sortie");
    const c2 = p.attack(t2, WC, U(p, "opp", 5), { arc: 70, travel: 200, dealt: 13, taken: 5, tHp: -6, aHp: 3 });
    p.die(c2 + 250, U(p, "opp", 5));
  } },

// ---------------------------------------------------------------- 03 attacks and damage
{ id: "attack", sec: 3, title: "An attack", tag: "keep", nowS: 0.77, propS: 0.77,
  now: "Wind-up 4 frames (back 12 px, lean 6°), travel to contact in 8, hold 2, home in 11; the target recoils 16 px. 0.22 s + 0.55 s steps.",
  prop: "Unchanged. It already reads well in stills; the owner judges its feel in play.",
  timing: "0.77 s from one attack to the next",
  build(p) {
    scene(p, ["hedge-knight", "territorial", "sentry", "lance-corporal", "bugler", "padre", "old-campaigner"],
      ["pip", "sweetbriar", "nettle-sprout", "blackberry-sprawl", "bramble-runner", "hedge-layer", "crab-apple"]);
    p.attack(150, U(p, "you", 1), U(p, "opp", 1), { dealt: 5, taken: 3, tHp: 2, aHp: 4 });
  } },
{ id: "damage", sec: 3, title: "Damage numbers", tag: "changed", nowS: 0.55, propS: 0.55,
  now: "The red burst with -N pops and rises; the Health number changes when the next step redraws the card.",
  prop: "The same burst. The Health number changes at the moment of contact, with a red flash on its disc, so the number and the hit read as one.",
  timing: "No extra time",
  build(p) {
    scene(p, ["sentry", "old-campaigner", "lance-corporal", "private", "padre", "bugler", null],
      ["hopper", "gleaner", "green-recruit", "wheat-raider", "prophet-of-the-dust", "brood-mother", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    const c = p.attack(150, A, T, { dealt: 6, taken: 2, tHp: 2, aHp: 7 });
    const d1 = hpDisc(T), d2 = hpDisc({ x: A.contact.x - W / 2, y: A.contact.y - H / 2 });
    p.ring(c, d1.x, d1.y, "#ff6a4a", 14, 40, 260, 5); p.ring(c, d2.x, d2.y, "#ff6a4a", 14, 40, 260, 5);
  } },
{ id: "guard", sec: 3, title: "Guard choosing the target", tag: "new", nowS: 0.77, propS: 0.77,
  now: "Nothing shows why the attacker went for that unit.",
  prop: "As the attacker winds up, the Guard's shield mark flares and a gold ward ring pulses from it: that is why it is the target.",
  timing: "No extra time: it plays during the wind-up",
  build(p) {
    scene(p, ["sentry", "lance-corporal", "old-campaigner", "private", "padre", "bugler", "territorial"],
      ["hedge-knight", "brock-cub", "hedge-lancer", "armsbearer", "sett-shield-bearer", "relic-seeker", null]);
    const A = U(p, "you", 2), G = U(p, "opp", 0);
    p.flare(120, G, "Guard", 460);
    p.ring(140, G.cx, G.cy, "#ffe7a6", 60, 150, 420, 7);
    const c = p.attack(150, A, G, { windup: 110, dealt: 6, taken: 2, tHp: 2, aHp: 7 });
    p.flare(c, G, "Fury"); p.num(c + 40, G, "atk", 3, "up");
  } },
{ id: "again", sec: 3, title: "Attacks again: The Oakfeller", tag: "changed", nowS: 2.3, propS: 1.3,
  now: "A second full attack after the first one's splash and death steps and a 0.14 s home step.",
  prop: "After The Oakfeller's kill, its second strike leaves from part-way home with a short wind-up, and a ×2 pops as it goes.",
  timing: "1.3 s for both strikes",
  build(p) {
    scene(p, ["hedge-knight", "the-oakfeller", "brock-cub", "gate-warden", null, "armsbearer", null],
      ["hopper", "mother-of-thousands", "dirge-singer", "husk-sentry", null, "prophet-of-the-dust", null]);
    const A = U(p, "you", 1), T1 = U(p, "opp", 1), T2 = U(p, "opp", 2);
    // "After this attacks and kills a unit, it attacks once more." 12 kills Mother of Thousands exactly (no Overrun left)
    const c1 = p.attack(100, A, T1, { dealt: 12, taken: 5, tHp: 0, aHp: 17, stay: .45, back: 150 });
    p.die(c1 + 250, T1);
    const from = v2((A.contact.x - A.cx) * .45, (A.contact.y - A.cy) * .45);
    const t2 = 100 + M.windup + M.travel + M.hold + 150;
    p.glow(t2 - 60, A, 300, false);
    p.float(t2 + 30, A.cx + 118, A.cy - 40 + from.y, "×2", { cls: "combo", fs: 54 });
    p.attack(t2, A, T2, { from, windup: 50, dealt: 12, taken: 3, tHp: 2, aHp: 14 });
  } },
{ id: "cleave", sec: 3, title: "Cleave", tag: "new", nowS: 0.77, propS: 0.85,
  now: "The neighbour just gets a burst in the same splash step; nothing links it to the attack.",
  prop: "At contact a red arc sweeps from the target to the unit beside it, which takes its burst a moment later and recoils sideways.",
  timing: "+0.08 s",
  build(p) {
    scene(p, ["sentry", { id: "flying-ace", atk: 11, hp: 10, renown: 3, up: ["atk", "hp"] }, "lance-corporal", "private", "padre", "bugler", null],
      ["pip", "the-old-hedge", "briar-king", "bramble-runner", "sweetbriar", "hedge-layer", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1), N = U(p, "opp", 2);
    const c = p.attack(150, A, T, { dealt: 11, taken: 9, tHp: 5, aHp: 1 });
    p.flare(c - 40, A, "Cleave");
    p.path(c + 10, `M${T.cx} ${T.cy + 30} Q${(T.cx + N.cx) / 2} ${T.cy - 70} ${N.cx} ${N.cy + 10}`, { colour: "#ff8a6a", w: 8, draw: 90, hold: 160 });
    p.recoil(c + 90, N, v2(1, 0));
    p.burst(c + 90, N.cx, N.y + H * .48, 11); p.num(c + 90, N, "hp", 5, "hurt");
  } },
{ id: "overrun", sec: 3, title: "Overrun", tag: "new", nowS: 1.07, propS: 1.2,
  now: "A trigger step, then the extra damage lands as one more burst. Nothing shows it carrying on.",
  prop: "The Overrun mark flares at contact; red chevrons run on from the dead target to the next enemy, which takes the rest of the damage.",
  timing: "+0.15 s",
  build(p) {
    scene(p, [{ id: "old-campaigner", marks: ["Overrun"] }, "hedge-knight", "brock-cub", "sentry", "greatsword-bearer", "armsbearer", null],
      ["needle-page", "hedgerow-scout", "cousin", "fencing-master", "dormouse-cook", "harvest-piper", null]);
    const A = U(p, "you", 0), T = U(p, "opp", 0), N = U(p, "opp", 1);
    const c = p.attack(150, A, T, { dealt: 6, taken: 4, tHp: -3, aHp: 5 });
    p.flare(c, A, "Overrun");
    p.line(c + 60, v2(T.cx + 30, T.cy + 20), v2(N.cx - 20, N.cy + 20), { colour: "#ff8a6a", draw: 150, hold: 120, w: 7 });
    p.shard(c + 60, v2(T.cx, T.cy + 20), v2(N.cx, N.cy + 20), 150, { cls: "chev", size: 44, bend: 0, colour: "#ff8a6a", easing: "linear" });
    p.recoil(c + 210, N, v2(1, -.2));
    p.burst(c + 210, N.cx, N.y + H * .48, 3); p.num(c + 210, N, "hp", 7, "hurt");
    p.die(c + 250, T);
  } },
{ id: "pileon", sec: 3, title: "Pile on, four neighbours", tag: "changed", nowS: 0.99, propS: 1.05,
  now: "The attacker winds up and waits; the pilers jab out towards the target and hold, then the attacker lunges. All the bursts land in one splash step, on top of each other.",
  prop: "Each piler darts in and strikes first, 70 ms apart, its burst stacking higher like a hit marker with a rising ×2, ×3, ×4; then the attacker lands.",
  timing: "+0.28 s however many pile on",
  build(p) {
    scene(p, ["needle-page", "hedgerow-scout", "shrew-cutpurse", "cousin", "shrew-cutpurse", "needle-pikeman", "king-speck"],
      ["pip", "the-old-hedge", "briar-king", "bramble-runner", "sweetbriar", "hedge-layer", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    // Hedgerow Scout's neighbours with Pile on: Needle Page 4, Shrew Cutpurse 2, Needle Pikeman 6, Shrew Cutpurse 2
    const pilers = [[0, 4], [4, 2], [5, 6], [2, 2]];
    let hp = T.hp, k = 0;
    for (const [i, n] of pilers) {
      const P = U(p, "you", i), t = 100 + k * 70, d = norm(sub(v2(T.cx, T.cy), v2(P.cx, P.cy)));
      const reach = Math.max(0, len(sub(v2(T.cx, T.cy), v2(P.cx, P.cy))) - M.contact * 1.15);
      const end = v2(d.x * reach, d.y * reach);
      p.flare(t, P, "Pile on", 300);
      p.at(t, P.el, [{ translate: "0px 0px", scale: 1, zIndex: 6 }, { translate: px(end), scale: 1.05, offset: .35, zIndex: 6 }, { translate: px(end), scale: 1.05, offset: .45, zIndex: 6 }, { translate: "0px 0px", scale: 1, zIndex: 6 }], 330, "ease-out");
      p.at(t, P.el, [{ filter: F_GLOW }, { filter: F_GLOW, offset: .7 }, { filter: F_BASE }], 330);
      const hitT = t + 115; hp -= n;
      p.burst(hitT, T.cx + (k % 2 ? 28 : -28), T.y + H * .5 - k * 34, n, { r: 34, fs: 28, read: 420 - k * 50 });
      p.num(hitT, T, "hp", hp, "hurt");
      if (k > 0) p.float(hitT + 10, T.cx + 92, T.y + 40 - k * 6, `×${k + 1}`, { cls: "combo", fs: 40 + k * 8, dur: 360, rise: 10, hold: .7 });
      p.recoil(hitT, T, d, false);
      k++;
    }
    const c = p.attack(100 + 3 * 70 + 115 - 160, A, T, { dealt: 3, taken: 9, tHp: -1, aHp: 1 });
    p.die(c + 250, T);
  } },
{ id: "sortie", sec: 3, title: "Sortie hitting the back row", tag: "new", nowS: 0.77, propS: 0.84,
  now: "A straight lunge that passes through the front row; nothing says why it chose the back row.",
  prop: "The Sortie mark flares and the unit arcs up and over the enemy front row, bigger at the top as if flying, onto its back-row target.",
  timing: "+0.07 s (a longer flight)",
  build(p) {
    scene(p, ["sentry", "lance-corporal", "wing-commander", "private", "padre", "bugler", null],
      ["green-recruit", "hopper", "husk-sentry", "wheat-raider", "gleaner", "prophet-of-the-dust", "horde-runner"]);
    const A = U(p, "you", 2), T = U(p, "opp", 5);
    p.flare(130, A, "Sortie", 420);
    const c = p.attack(150, A, T, { arc: 80, travel: 200, dealt: 10, taken: 2, tHp: -3, aHp: 6 });
    p.die(c + 250, T);
  } },
{ id: "thorns", sec: 3, title: "Thorns", tag: "new", nowS: 0.77, propS: 0.82,
  now: "The Thorns damage is one more burst on the attacker in the same splash; it isn't shown coming first or from the Thorns.",
  prop: "As the attacker arrives, the Thorns mark flares and green thorns jab out of the defender into it: the Thorns burst lands first, then the normal trade.",
  timing: "+0.05 s",
  build(p) {
    scene(p, ["hedge-knight", "gate-warden", "brock-cub", "hedge-lancer", "armsbearer", "sett-shield-bearer", null],
      ["pip", "nettle-skirmisher", "bramble-runner", "sweetbriar", "ivy-climber", "hedge-layer", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    const tc = 150 + M.windup + M.travel + 50;   // the strike lands 50 ms after the thorns
    p.flare(tc - 140, T, "Thorns", 360);
    const ax = A.cx, ay = A.cy - (len(sub(v2(T.cx, T.cy), v2(A.cx, A.cy))) - M.contact);
    [-40, 0, 40].forEach((dx, k) => p.spike(tc - 110 + k * 18, v2(T.cx + dx * .5, T.y + H * .62), v2(ax + dx, ay + 20 + Math.abs(dx) * .4), { w: 18, dur: 300 }));
    p.burst(tc - 50, ax - 24, ay - H * .08, 4, { r: 40, cls: "thorn" });
    p.num(tc - 50, A, "hp", 7, "hurt");
    p.attack(150, A, T, { travel: M.travel + 50, dealt: 3, tHp: 7 });
    p.burst(tc + 10, ax + 30, ay - H * .02, 4, { r: 40 });
    p.num(tc + 10, A, "hp", 3, "hurt");
  } },
{ id: "strike", sec: 3, title: "Damage from an effect: Gleaner", tag: "new", nowS: 1.15, propS: 0.8,
  now: "The source glows, then a burst on the target. No line or bolt between them, so the source is a guess.",
  prop: "A friendly Hopper falls; Gleaner lifts and glows; a lead line with a lit core draws from it to the enemy with the most Health and a bolt flies along it; the target takes its burst. Gleaner never moves.",
  timing: "0.8 s",
  build(p) {
    scene(p, ["hopper", "gleaner", "wheat-raider", "green-recruit", "prophet-of-the-dust", "skin-shedder", null],
      ["needle-page", "fencing-master", "cousin", "hedgerow-scout", "harvest-piper", "dormouse-cook", null]);
    const D = U(p, "you", 0), B = U(p, "you", 1), T = U(p, "opp", 5);
    p.burst(20, D.cx, D.y + H * .48, 3); p.num(20, D, "hp", -1, "hurt"); p.die(80, D);
    // "After a friendly unit dies, deal 5 damage to the highest-Health enemy": Dormouse Cook, 24 Health
    p.glow(200, B, 520);
    const a = v2(B.cx, B.y + 40), b = v2(T.cx, T.cy + 30);
    p.line(320, a, b, { colour: "#ff8a6a", draw: 120, hold: 220 });
    const land = p.shard(320, a, b, 140, { cls: "bolt", size: 30, bend: 0, colour: "#ffd2a0", easing: "ease-in" });
    p.recoil(land, T, norm(sub(b, a)));
    p.burst(land, T.cx, T.y + H * .48, 5); p.num(land, T, "hp", 19, "hurt");
  } },

// ---------------------------------------------------------------- 04 growth, buffs and counters
{ id: "fury", sec: 4, title: "Fury gains", tag: "changed", nowS: 1.07, propS: 0.77,
  now: "A separate 0.3 s glow step after the attack, then the Attack number pops.",
  prop: "No extra step: at contact the flame mark flares, an orange +3 rises off the Attack disc and the number counts up in green.",
  timing: "No extra time",
  build(p) {
    scene(p, ["hedge-knight", "brock-cub", "gate-warden", null, null, null, null],
      ["hopper", "hopper", "green-recruit", "wheat-raider", "gleaner", null, null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    const c = p.attack(150, A, T, { dealt: 2, taken: 2, tHp: 0, aHp: 4 });
    p.flare(c, A, "Fury");
    const d = atkDisc({ x: A.contact.x - W / 2, y: A.contact.y - H / 2 });
    p.float(c + 20, d.x, d.y - 20, "+3", { cls: "fury", fs: 46 });
    p.count(c + 80, A, "atk", 5, 220, "up");
    p.die(c + 250, T);
  } },
{ id: "lends", sec: 4, title: "Lends, and an aura ending", tag: "new", nowS: 0.6, propS: 0.75,
  now: "When the lender dies, the units in front just lose the numbers at the next redraw.",
  prop: "As the lender (Sett Shield-bearer) falls, gold threads show the Health it was lending to the units in front, then snap back into it; their Health counts down from green to plain.",
  timing: "0.45 s inside the death",
  build(p) {
    scene(p, [{ id: "brock-cub", hp: 14, up: ["hp"] }, { id: "hedge-knight", hp: 16, up: ["hp"] }, "gate-warden", "hedge-lancer", "sett-shield-bearer", "grudge-keeper", null],
      ["sentry", "private", "wing-commander", "lance-corporal", "padre", "bugler", null]);
    // Wing Commander (Sortie) flies over the front row at the lender in the back row
    const L = U(p, "you", 4), B = U(p, "opp", 2);
    p.flare(80, B, "Sortie", 380);
    const land = p.attack(100, B, L, { arc: 70, travel: 200, dealt: 10, taken: 2, tHp: -2, aHp: 6 });
    p.flare(land + 60, L, "Lends", 420);
    [0, 1].forEach(i => { const f = U(p, "you", i);
      const g = p.path(land + 80, `M${L.cx} ${L.cy - 20} L${f.cx} ${f.cy + 60}`, { colour: "#ffe08a", w: 5, draw: 120, hold: 120, fade: 120 });
      p.count(land + 330, f, "hp", f.hp - 8, 220, ""); });
    p.die(land + 360, L);
  } },
{ id: "buffs", sec: 4, title: "Buffs to many at once: Parish Standard-bearer", tag: "changed", nowS: 0.6, propS: 0.55,
  now: "Its 0.3 s glow, then every Mouse's Attack pops in a 0.3 s change step, with nothing linking them.",
  prop: "Start of fight: the Standard-bearer glows and a pulse runs out across your board; each Mouse it reaches shows +15 (5 Mice, +3 each) and its Attack turns green.",
  timing: "0.55 s for any number of units",
  build(p) {
    scene(p, ["needle-page", "cousin", "parish-standard-bearer", "hedgerow-scout", "sentry", "shrew-cutpurse", null],
      ["pip", "bramble-runner", "nettle-sprout", "blackberry-sprawl", "sweetbriar", "hedge-layer", "crab-apple"]);
    // "Start of fight: Give your Mice +3 Attack this fight for each Mouse you have."
    const Bg = U(p, "you", 2), mice = [0, 1, 2, 3, 5];
    p.glow(60, Bg, 520);
    p.ring(120, Bg.cx, Bg.cy, "#ffb7a4", 60, 520, 520, 8);
    mice.forEach(i => { const u = U(p, "you", i), d = len(sub(v2(u.cx, u.cy), v2(Bg.cx, Bg.cy))), t = 120 + d * .9;
      p.float(t, u.cx, u.y + H * .42, "+15", { cls: "gain", fs: 34 });
      p.num(t, u, "atk", u.atk + 15, "up"); });
  } },
{ id: "tide", sec: 4, title: "Counters: the Tide", tag: "changed", nowS: 0.9, propS: 0.9,
  now: "The Tide plate pops, and the Locusts' Attack changes in a later change step.",
  prop: "The dying Famine-caller sends a wave of glass to the Tide plate, which pops 3 to 5; a ripple then runs along your Locusts and each one's Attack ticks up.",
  timing: "0.6 s inside the death",
  build(p) {
    scene(p, [{ id: "hopper", atk: 5, up: ["atk"] }, { id: "famine-caller", atk: 9, up: ["atk"] }, { id: "wheat-raider", atk: 7, up: ["atk"] }, { id: "green-recruit", atk: 5, up: ["atk"] },
      { id: "prophet-of-the-dust", atk: 5, up: ["atk"] }, { id: "skin-shedder", atk: 6, up: ["atk"] }, null],
      ["hedge-knight", "master-at-arms", "brock-cub", "gate-warden", null, "armsbearer", null], { you: { plates: [[null, "Tide", 3]] } });
    const A = U(p, "opp", 1), F = U(p, "you", 1);
    const c = p.attack(100, A, F, { dealt: 5, taken: 9, tHp: -1, aHp: 0 });
    p.die(c + 250, A);
    const end = p.die(c + 250, F, { linger: 160 });
    p.at(c + 250, F.el, [{ filter: F_GLOW }, { filter: F_GLOW, offset: .7 }, { filter: F_BASE }], 300);
    const land = p.shard(c + 330, v2(F.cx, F.cy), p.plateXY("Tide"), 320, { cls: "wave", size: 34, colour: "#c8f2a6", bend: -.2 });
    p.plate(land, "Tide", 5);
    p.float(land + 10, p.plateXY("Tide").x + 70, p.plateXY("Tide").y - 30, "+2", { cls: "gain", fs: 36 });
    [0, 2, 3, 4, 5].forEach((i, k) => { const u = U(p, "you", i); p.num(land + 140 + k * 45, u, "atk", u.atk + 2, "up");
      p.ring(land + 140 + k * 45, atkDisc(u).x, atkDisc(u).y, "#c8f2a6", 12, 36, 240, 4); });
  } },
{ id: "renown", sec: 4, title: "Counters: Renown earned in a fight (Flying Ace)", tag: "changed", nowS: 0.6, propS: 0.7,
  now: "The slot's Renown changes in a later change step; the Charge pip just dims.",
  prop: "Flying Ace kills; one of its Charge pips flashes and dims; a gold star flies off the unit it killed onto its Renown pill, which pops 3 to 4. Its numbers stay: Renown earned in a fight counts from the next fight.",
  timing: "0.45 s inside the death",
  build(p) {
    scene(p, ["sentry", { id: "flying-ace", atk: 11, hp: 10, renown: 3, up: ["atk", "hp"] }, "lance-corporal", "private", "padre", "bugler", null],
      ["green-recruit", "hopper", "cousin", "wheat-raider", "prophet-of-the-dust", "husk-sentry", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    // "Charge 2: After this kills, give this slot 1 Renown."
    const c = p.attack(120, A, T, { dealt: 11, taken: 2, tHp: -9, aHp: 8 });
    p.die(c + 250, T);
    spendPip(p, c + 180, A);
    const land = p.shard(c + 200, v2(T.cx, T.cy), v2(A.cx, A.y + 6), 300, { cls: "star", size: 34, colour: "#ffe08a", bend: .3 });
    renownTo(p, land, A, 4);
    p.ring(land, A.cx, A.y + 6, "#ffe7a6", 14, 60, 300, 5);
  } },

// ---------------------------------------------------------------- 05 deaths and returns
{ id: "deaths", sec: 5, title: "Deaths", tag: "keep", nowS: 1.07, propS: 0.77,
  now: "Drops 48 px away from the fight, turns 16°, shrinks to 0.72 and fades in 15 frames, in its own 0.3 s step after the splash.",
  prop: "The same motion, started while the burst is still being read, so a trade with a death costs no more time than one without.",
  timing: "Same 0.25 s motion; 0.3 s less per death",
  build(p) {
    scene(p, ["green-recruit", "hopper", "wheat-raider", "prophet-of-the-dust", "skin-shedder", "brood-mother", null],
      ["husk-sentry", "hopper", "wheat-raider", "skin-shedder", "prophet-of-the-dust", "gorger", null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    const c = p.attack(150, A, T, { dealt: 2, taken: 2, tHp: 0, aHp: 0 });
    p.die(c + 250, T); p.die(c + 250, A, { dir: v2(0, 1) });
  } },
{ id: "seed", sec: 5, title: "Death effect: Seed into the Compost", tag: "changed", nowS: 0.85, propS: 0.9,
  now: "The dead unit's own effect has no glow (its trigger is dropped). The Compost plate pops on its own.",
  prop: "The dying unit pauses a beat with its Seed mark flaring, then falls; a seed of glass flies from its slot into the Compost plate, which pops 4 to 5.",
  timing: "+0.16 s on that death",
  build(p) {
    scene(p, ["pip", "bramble-runner", "nettle-sprout", "blackberry-sprawl", "holly-knight", "hedge-layer", "crab-apple"],
      ["hopper", "gorger", "husk-sentry", "granary-glutton", null, "prophet-of-the-dust", null], { you: { plates: [["bog", "Compost", 4]] } });
    const A = U(p, "opp", 1), D = U(p, "you", 1);
    const c = p.attack(100, A, D, { dealt: 5, taken: 4, tHp: 0, aHp: 3 });
    p.flare(c + 220, D, "Seed", 380);
    p.at(c + 220, D.el, [{ filter: F_GLOW }, { filter: F_GLOW, offset: .7 }, { filter: F_BASE }], 380);
    p.die(c + 220, D, { linger: 160 });
    const land = p.shard(c + 400, v2(D.cx, D.cy + 40), p.plateXY("Compost"), 340, { cls: "seed", size: 30, colour: "#d9b26a", bend: -.15 });
    p.plate(land, "Compost", 5);
  } },
{ id: "hoppers", sec: 5, title: "Death effect: Brood Mother's Hopper", tag: "changed", nowS: 1.0, propS: 1.0,
  now: "No glow for the dying unit's effect; the Hopper fades in (0.18 s) in a 0.35 s step and the numbers pop.",
  prop: "Brood Mother glows as she falls; a Hopper drops into her slot with a violet ring; the Hopper plate pops 1 to 2 and every Hopper gets +1/+1 together.",
  timing: "1.0 s from the hit",
  build(p) {
    scene(p, [{ id: "hopper", atk: 3, hp: 3, up: ["atk", "hp"] }, "wheat-raider", "brood-mother", "green-recruit", "skin-shedder", "prophet-of-the-dust", null],
      ["hedge-knight", "brock-cub", "old-brock", "gate-warden", "armsbearer", "sett-shield-bearer", null], { you: { plates: [[null, "Hopper bonus", 1]] } });
    const A = U(p, "opp", 2), D = U(p, "you", 2);
    const c = p.attack(100, A, D, { dealt: 8, taken: 3, tHp: -2, aHp: 17 });
    p.at(c + 200, D.el, [{ filter: F_GLOW }, { filter: F_GLOW, offset: .7 }, { filter: F_BASE }], 380);
    const end = p.die(c + 200, D, { linger: 160 });
    const N = p.later("you", 2, { id: "hopper", atk: 3, hp: 3, up: ["atk", "hp"] });
    const t = p.arrive(end - 60, N);
    p.plate(t + 40, "Hopper bonus", 2);
    [U(p, "you", 0), N].forEach(u => { p.float(t + 80, u.cx, u.y + H * .42, "+1/+1", { cls: "gain", fs: 34 });
      p.num(t + 80, u, "atk", u.atk + 1, "up"); p.num(t + 80, u, "hp", u.hp + 1, "up"); });
  } },
{ id: "summon", sec: 5, title: "Summons: Sky-darkener and Mother of Thousands", tag: "changed", nowS: 1.7, propS: 0.65,
  now: "Each summon fades in (0.18 s) in its own 0.35 s step: four Hoppers take 1.4 s after the 0.3 s glow.",
  prop: "Both sources glow together and the four Hoppers drop into their slots in one wave, 50 ms apart, each with a violet ring.",
  timing: "0.65 s for any number of summons",
  build(p) {
    scene(p, ["wheat-raider", "sky-darkener", null, null, null, "mother-of-thousands", null],
      ["hedge-knight", "brock-cub", "hedge-lancer", "gate-warden", "armsbearer", "sett-shield-bearer", null]);
    p.glow(80, U(p, "you", 1), 400); p.glow(80, U(p, "you", 5), 400);
    [2, 3, 4, 6].forEach((i, k) => { const h = p.later("you", i, "hopper"); p.arrive(260 + k * 50, h); });
  } },
{ id: "reserve", sec: 5, title: "Reserve stepping in", tag: "changed", nowS: 0.65, propS: 0.75,
  now: "The unit fades in (0.18 s) in the empty slot, taking the slot's Renown in the same step; nothing says it came from your hand.",
  prop: "The slot empties and shows its Renown; the Reserve unit rises from below the screen (your hand) into it, its Reserve mark flaring as it lands, and takes the slot's Renown: +2/+2 in green.",
  timing: "0.45 s after the death",
  build(p) {
    scene(p, [{ id: "private", atk: 4, hp: 4, renown: 2, up: ["atk", "hp"] }, "lance-corporal", "old-campaigner", "sentry", "colour-sergeant", "grenadier-guard", null],
      ["hedge-knight", "hedge-lancer", "brock-cub", "gate-warden", "armsbearer", "sett-shield-bearer", null]);
    const A = U(p, "opp", 1), D = U(p, "you", 0);
    const c = p.attack(100, A, D, { dealt: 6, taken: 4, tHp: -2, aHp: 6 });
    p.flare(c, A, "Fury"); p.num(c + 40, A, "atk", 7, "up");
    p.die(c + 250, D);
    // the empty slot's own Renown pill shows while it is empty (dev's fight screen)
    const sp = renownPill(2, H); p.st.append(sp); place(sp, slotX(0) + (W - sp.offsetWidth) / 2, slotY("you", 0) - 4); sp.style.opacity = 0; sp.style.zIndex = 4;
    const R = p.later("you", 0, { id: "territorial", atk: 7, hp: 9, renown: 2, up: ["atk", "hp"] });
    const t = c + 450, rise = 1080 + 40 - R.y;
    p.at(c + 400, sp, [{ opacity: 0 }, { opacity: 1 }], 100);
    p.at(t + 300, sp, [{ opacity: 1 }, { opacity: 0 }], 60);
    p.at(t, R.el, [{ opacity: 1, translate: `60px ${rise}px`, rotate: "-8deg", scale: 1.15 }, { opacity: 1, translate: "0px -18px", rotate: "0deg", scale: 1.05, offset: .75 }, { opacity: 1, translate: "0px 0px", rotate: "0deg", scale: 1 }], 380, "cubic-bezier(.22,.61,.36,1)");
    p.flare(t + 300, R, "Reserve", 380);
    p.ring(t + 300, R.cx, R.cy, FAM.kin[1], 60, 130, 300);
    p.float(t + 340, R.cx, R.y + H * .42, "+2/+2", { cls: "gain", fs: 34 });
  } },
{ id: "molt", sec: 5, title: "Molt returning", tag: "changed", nowS: 0.65, propS: 0.95,
  now: "The death motion, then the copy fades in with the +2/+2 merged into the same step; the Molt mark dims.",
  prop: "The unit doesn't fall: it pales into a husk that splits down the middle, and the copy pushes out of it with 1 Health, then +2/+2 in green. The Molt mark dims.",
  timing: "0.95 s from the hit",
  build(p) {
    scene(p, ["hopper", "husk-sentry", "wheat-raider", "green-recruit", "skin-shedder", "prophet-of-the-dust", null],
      ["hopper", "gorger", "husk-sentry", "granary-glutton", null, "prophet-of-the-dust", null]);
    const A = U(p, "opp", 1), D = U(p, "you", 1);
    const c = p.attack(100, A, D, { dealt: 5, taken: 3, tHp: -2, aHp: 4 });
    const t = c + 220;
    const halves = [["inset(0 50% 0 0)", -26, -6], ["inset(0 0 0 50%)", 26, 6]].map(([clip, dx, rot]) => {
      const h = D.el.cloneNode(true); h.style.clipPath = clip; h.style.opacity = 0; h.style.zIndex = 4; p.st.append(h);
      p.at(t, h, [{ opacity: 1, filter: "grayscale(1) sepia(.5) brightness(.9)", translate: "0px 0px", rotate: "0deg" },
        { opacity: 1, filter: "grayscale(1) sepia(.5) brightness(.9)", translate: "0px 0px", rotate: "0deg", offset: .25 },
        { opacity: 0, filter: "grayscale(1) sepia(.5) brightness(.7)", translate: `${dx}px 30px`, rotate: rot + "deg" }], 420, "ease-in");
      return h; });
    p.at(t, D.el, [{ opacity: 1 }, { opacity: 0 }], 30);
    const N = p.later("you", 1, { id: "husk-sentry", hp: 1, max: 3, spent: ["Molt"] });
    p.at(t + 110, N.el, [{ opacity: 0, scale: .82, filter: "brightness(1.6) " + F_BASE.slice(14) }, { opacity: 1, scale: 1.04, offset: .7 }, { opacity: 1, scale: 1, filter: F_BASE }], 300, "ease-out");
    p.ring(t + 200, N.cx, N.cy, FAM.kin[1], 60, 130, 300);
    p.float(t + 520, N.cx, N.y + H * .42, "+2/+2", { cls: "gain", fs: 34 });
    p.num(t + 520, N, "atk", 5, "up"); p.num(t + 520, N, "hp", 3, "hurt");
  } },
{ id: "root", sec: 5, title: "Root returning", tag: "changed", nowS: 0.65, propS: 1.1,
  now: "The death motion, then the unit fades in again; the Compost plate isn't updated by the payment.",
  prop: "The unit falls; roots grow up the slot; the Compost plate dips 6 to 5 as it pays and a green shard runs to the slot; the unit regrows from the roots up at full Health. The Root mark dims.",
  timing: "1.1 s from the hit",
  build(p) {
    scene(p, ["pip", "blackthorn-sapling", "nettle-sprout", "blackberry-sprawl", "sweetbriar", "hedge-layer", "crab-apple"],
      ["hedge-knight", "hedge-lancer", "brock-cub", "gate-warden", "armsbearer", "sett-shield-bearer", null], { you: { plates: [["bog", "Compost", 6]] } });
    const A = U(p, "opp", 1), D = U(p, "you", 1);
    const c = p.attack(100, A, D, { dealt: 6, taken: 5, tHp: 0, aHp: 5 });
    p.flare(c, A, "Fury"); p.num(c + 40, A, "atk", 7, "up");
    const t = p.die(c + 250, D);
    const bx = D.cx, by = D.y + H - 18;
    [`M${bx} ${by} C${bx - 10} ${by - 60} ${bx + 20} ${by - 110} ${bx} ${by - 170}`, `M${bx - 8} ${by - 20} C${bx - 50} ${by - 50} ${bx - 40} ${by - 90} ${bx - 55} ${by - 130}`,
     `M${bx + 8} ${by - 30} C${bx + 50} ${by - 60} ${bx + 40} ${by - 100} ${bx + 52} ${by - 140}`]
      .forEach((d, k) => p.path(t - 40 + k * 30, d, { colour: "#a3c56a", w: 5, draw: 200, hold: 240, fade: 200 }));
    p.at(t, p.plates.Compost.el, [{ scale: 1 }, { scale: .85, offset: .4 }, { scale: 1 }], 300);
    p.plate(t + 40, "Compost", 5);
    p.shard(t + 40, p.plateXY("Compost"), v2(bx, by - 40), 260, { cls: "sprout", size: 26, colour: "#c8f2a6", bend: .2 });
    const N = p.later("you", 1, { id: "blackthorn-sapling", spent: ["Root"] });
    p.at(t + 300, N.el, [{ opacity: 1, clipPath: "inset(100% 0 0 0)" }, { opacity: 1, clipPath: "inset(0% 0 0 0)" }], 340, "ease-out");
    p.float(t + 720, N.cx, N.y + H * .42, "+2/+2", { cls: "gain", fs: 34 });
    p.num(t + 720, N, "atk", 7, "up"); p.num(t + 720, N, "hp", 8, "up");
  } },
{ id: "hmd", sec: 5, title: "Death effect: Hand-me-down", tag: "new", nowS: 0.6, propS: 0.75,
  now: "As other death effects: no glow for the dying unit; the nearest Mouse's Attack changes in a later 0.3 s change step.",
  prop: "The Cousin's Hand-me-down mark flares as it falls; a gold shard carries its Attack to the nearest Mouse (Needle Page), whose mark-less Attack counts up in green with +2 over it: it lasts this fight.",
  timing: "0.45 s inside the death",
  build(p) {
    scene(p, ["cousin", "needle-page", "hedgerow-scout", "king-speck", "shrew-cutpurse", "fencing-master", null],
      ["hedge-knight", "brock-cub", "gate-warden", "armsbearer", "sett-shield-bearer", "relic-seeker", null]);
    const A = U(p, "opp", 0), D = U(p, "you", 0), N = U(p, "you", 1);
    const c = p.attack(100, A, D, { dealt: 2, taken: 2, tHp: 0, aHp: 6 });
    // "When this dies, the nearest friendly Mouse gains its Attack this fight." Nearest: one neighbour step; ties in reading order
    p.flare(c + 200, D, "Hand-me-down", 380);
    p.at(c + 200, D.el, [{ filter: F_GLOW }, { filter: F_GLOW, offset: .7 }, { filter: F_BASE }], 380);
    p.die(c + 200, D, { linger: 160 });
    const land = p.shard(c + 300, v2(D.cx, D.cy), atkDisc(N), 280, { cls: "seed", size: 30, colour: "#ffe08a", bend: .25 });
    p.ring(land, atkDisc(N).x, atkDisc(N).y, "#c8f2a6", 12, 40, 260, 4);
    p.float(land + 10, atkDisc(N).x, atkDisc(N).y - 24, "+2", { cls: "gain", fs: 40 });
    p.count(land + 30, N, "atk", 6, 160, "up");
  } },

// ---------------------------------------------------------------- 06 grouping
{ id: "combo", sec: 6, title: "The same trigger 10 times", tag: "new", nowS: 8.5, propS: 2.0,
  now: "Ten separate 0.3 s glow steps, each with a 0.55 s splash: about 8.5 s of one unit firing.",
  prop: "Gleaner fires the first two at full speed, then faster and faster; a ×N counter beside it grows with each one, the bursts stack on the targets like hit markers, and ×10 holds a beat at the end.",
  timing: "About 2 s instead of 8.5 s",
  build(p) {
    scene(p, ["hopper", "gleaner", "dirge-singer", null, null, "mother-of-thousands", null],
      ["hawthorn-warden", "lone-hawthorn", "old-brock", "nettle-sprout", "sweetbriar", "ivy-climber", null]);
    const G = U(p, "you", 1), foes = [0, 1, 2, 3, 4, 5].map(i => U(p, "opp", i));
    const hp = new Map(foes.map(u => [u, u.hp])), hitsOn = new Map();
    let t = 120, gap = 380;
    const times = [];
    for (let k = 0; k < 10; k++) { times.push(t); t += gap; if (k >= 1) gap = Math.max(70, gap * .7); }
    const total = times[9] + 300;
    p.glow(60, G, total);
    times.forEach((tk, k) => {
      const alive = foes.filter(u => hp.get(u) > 0), T = alive.reduce((a, b) => hp.get(b) > hp.get(a) ? b : a);
      const n = hitsOn.get(T) || 0; hitsOn.set(T, n + 1);
      const fast = k >= 2, a = v2(G.cx, G.y + 30), b = v2(T.cx, T.cy + 30);
      p.line(tk, a, b, { colour: "#ff8a6a", draw: fast ? 60 : 110, hold: fast ? 70 : 200, w: fast ? 5 : 6 });
      const land = p.shard(tk, a, b, fast ? 70 : 130, { cls: "bolt", size: 26, bend: 0, colour: "#ffd2a0" });
      hp.set(T, hp.get(T) - 5);
      p.burst(land, T.cx + (n % 2 ? 26 : -26), T.y + H * .5 - n * 30, 5, { r: 34, fs: 28, read: fast ? 160 : 290 });
      p.num(land, T, "hp", hp.get(T), "hurt");
      if (!fast) p.recoil(land, T, norm(sub(b, a)));
      if (hp.get(T) <= 0) p.die(land + 120, T);
      if (k > 0) {
        const last = k === 9, fs = 40 + k * 5;
        p.float(land, G.cx + 108, G.y + 30, `×${k + 1}`, { cls: "combo", fs, dur: last ? 760 : Math.max(120, times[k + 1] - tk + 40), rise: last ? 16 : 4, hold: last ? .85 : .9 });
      }
    });
  } },
{ id: "lieut", sec: 6, title: "Several strikes in one moment: Lieutenant", tag: "new", nowS: 1.15, propS: 0.85,
  now: "One glow step, then the damage merges into one splash with no lines, so you can't tell who hit what.",
  prop: "Start of fight, with its row full: Lieutenant glows; each unit in the row draws its line to the enemy across from it, 90 ms after the one before, and deals half its Renown, so the four strikes read separately in under a second.",
  timing: "0.85 s for the whole row",
  build(p) {
    // each front-row unit carries its slot's Renown (Sentry 4, Lieutenant 6, Colour Sergeant 2, Lance Corporal 4)
    scene(p, [{ id: "sentry", atk: 6, hp: 9, renown: 4, up: ["atk", "hp"] }, { id: "lieutenant", atk: 15, hp: 17, renown: 6, up: ["atk", "hp"] },
      { id: "colour-sergeant", atk: 6, hp: 11, renown: 2, up: ["atk", "hp"] }, { id: "lance-corporal", atk: 7, hp: 10, renown: 4, up: ["atk", "hp"] }, "padre", "bugler", "recruiting-sergeant"],
      ["brock-cub", "hedge-knight", "armsbearer", "relic-seeker", "gate-warden", "grudge-keeper", "sword-heir"]);
    const L = U(p, "you", 1);
    p.glow(60, L, 320);
    p.ring(100, L.cx, L.cy, "#ffb7a4", 60, 220, 360);
    [[0, 2], [1, 3], [2, 1], [3, 2]].forEach(([i, n], k) => {
      const S = U(p, "you", i), T = U(p, "opp", i), t = 300 + k * 90, a = v2(S.cx, S.y + 40), b = v2(T.cx, T.cy + 30);
      p.glow(t - 60, S, 360);
      p.line(t, a, b, { colour: "#ff8a6a", draw: 100, hold: 200 });
      const land = p.shard(t, a, b, 120, { cls: "bolt", size: 28, bend: 0, colour: "#ffd2a0" });
      p.recoil(land, T, norm(sub(b, a))); p.burst(land, T.cx, T.y + H * .48, n); p.num(land, T, "hp", T.hp - n, "hurt");
    });
  } },

// ---------------------------------------------------------------- 07 the end of the fight
{ id: "tie", sec: 7, title: "A tie", tag: "changed", nowS: 1.5, propS: 1.4,
  now: "\"Draw\" in 72 px text over the transom for 1.5 s, no motion.",
  prop: "The last two units trade and fall; a slate-blue leaded plate saying Draw settles onto the transom; neither portrait is hit.",
  timing: "1.2 s hold, as now",
  build(p) {
    scene(p, [null, "hopper", null, null, null, null, null], [null, null, "cousin", null, null, null, null]);
    const A = U(p, "you", 1), T = U(p, "opp", 2);
    const c = p.attack(100, A, T, { dealt: 2, taken: 2, tHp: 0, aHp: 0 });
    p.die(c + 250, T); p.die(c + 250, A, { dir: v2(0, 1) });
    banner(p, c + 520, "Draw", "draw");
  } },
{ id: "result", sec: 7, title: "The result", tag: "changed", nowS: 1.5, propS: 1.2,
  now: "\"Victory\" or \"Defeat\" in 72 px text on the transom, held 1.5 s, no motion.",
  prop: "The last enemy falls; your survivors hop once in turn; a leaded amber plate saying Victory drops onto the transom with a light sweeping across it. Defeat: the same plate in dark red, and their survivors hop.",
  timing: "1.2 s, then the hero damage",
  build(p) {
    scene(p, ["sentry", "lance-corporal", null, "old-campaigner", null, "bugler", null], [null, "hopper", null, null, null, null, null]);
    const A = U(p, "you", 1), T = U(p, "opp", 1);
    const c = p.attack(100, A, T, { dealt: 3, taken: 2, tHp: -1, aHp: 4 });
    p.die(c + 250, T);
    [0, 1, 3, 5].forEach((i, k) => p.at(c + 480 + k * 60, U(p, "you", i).el, [{ translate: "0px 0px" }, { translate: "0px -16px", offset: .4 }, { translate: "0px 0px" }], 220, "ease-out"));
    banner(p, c + 600, "Victory", "win");
  } },
{ id: "herodmg", sec: 7, title: "Damage to the loser's hero", tag: "changed", nowS: 1.5, propS: 1.1,
  now: "A static burst with the damage on the loser's portrait; Health and leaderboard change at once with no tween.",
  prop: "A bolt of glass leaves your portrait and arcs to theirs: -2 lands and the portrait shakes; for a big loss a second, heavier bolt adds the 3 and the burst becomes -5; their Health counts down.",
  timing: "1.1 s",
  build(p) {
    scene(p, ["sentry", "lance-corporal", null, "old-campaigner", null, "bugler", null], [null, null, null, null, null, null, null]);
    banner(p, 0, "Victory", "win", true);
    heroStrike(p, 200, 36, 2, 3);
  } },
{ id: "elim", sec: 7, title: "Elimination", tag: "new", nowS: 0, propS: 1.5,
  now: "Nothing in the fight. The out player later shows a dimmed portrait on the leaderboard.",
  prop: "The strike takes their last Health; lead cracks run across the portrait, the glass falls out in pieces, and their name dims. If it's you, the same happens to your portrait.",
  timing: "1.5 s",
  build(p) {
    scene(p, ["sentry", "lance-corporal", null, "old-campaigner", null, "bugler", null], [null, null, null, null, null, null, null], { opp: { hp: 4 } });
    banner(p, 0, "Victory", "win", true);
    const t = heroStrike(p, 150, 4, 5, 0);
    shatter(p, t + 120);
  } },
{ id: "skip", sec: 8, title: "Skip: fast-forward, not a jump cut", tag: "new", nowS: 0, propS: 0.7,
  now: "Space, Enter or any click jumps straight to the result.",
  prop: "The Skip button presses in and lights; the rest of the fight plays at 6× (you still see who killed whom), then the result plays at normal speed.",
  timing: "Whatever was left, at 6×; most fights under 0.7 s",
  gap: 1200,
  build(p) {
    scene(p, ["sentry", "lance-corporal", "old-campaigner", "colour-sergeant", null, "grenadier-guard", null],
      ["hopper", "private", "prophet-of-the-dust", "prophet-of-the-dust", "hopper", null, null]);
    const btn = place(html(`<div class="btn skip" style="width:150px">${FF}<span>Skip</span></div>`), 1904 - FG.sideW / 2 - 75, 1080 - 108);
    p.st.append(btn);
    const tp = 1300, fast = 6;
    // [side, slot, target side, slot, dealt, taken]
    const plan = [["you", 0, "opp", 0, 2, 2], ["opp", 1, "you", 1, 2, 3], ["you", 2, "opp", 2, 6, 2], ["opp", 2, "you", 3, 2, 4], ["you", 3, "opp", 3, 4, 2],
      ["opp", 3, "you", 0, 2, 2], ["you", 0, "opp", 3, 2, 2], ["opp", 4, "you", 1, 2, 3]];
    // the timeline after the press runs 6x: the same motions, only faster
    p.warp = x => x < tp ? x : tp + (x - tp) / fast;
    let t = 150;
    const hp = {};
    plan.forEach(([s, i, ts, j, dealt, taken]) => {
      const A = U(p, s, i), T = U(p, ts, j);
      const th = (hp[ts + j] ?? T.hp) - dealt, ah = (hp[s + i] ?? A.hp) - taken; hp[ts + j] = th; hp[s + i] = ah;
      const c = p.attack(t, A, T, { dealt, taken, tHp: th, aHp: ah });
      if (th <= 0) p.die(c + 250, T); if (ah <= 0) p.die(c + 250, A);
      t += 770;
    });
    const tr = p.warp(t);
    p.warp = null;
    p.at(tp - 120, btn, [{ scale: 1, filter: "brightness(1)" }, { scale: .9, filter: "brightness(1.5)", offset: .4 }, { scale: 1, filter: "brightness(1.25)" }], 260, "ease-out");
    p.at(tp, btn, [{ boxShadow: "inset 0 0 0 2px rgba(255,255,255,.08),0 0 0 3px #ffb24a,0 0 26px 6px rgba(255,170,70,.55)" }, { boxShadow: "inset 0 0 0 2px rgba(255,255,255,.08),0 0 0 3px #ffb24a,0 0 26px 6px rgba(255,170,70,.55)" }], tr - tp);
    p.at(tr, btn, [{ opacity: 1 }, { opacity: 0 }], 200);
    const sweep = html(`<div class="ffsweep" style="opacity:0"></div>`); p.fx().append(sweep);
    p.at(tp, sweep, [{ opacity: 0, backgroundPosition: "0px 0px" }, { opacity: 1, offset: .15 }, { opacity: 1, offset: .85 }, { opacity: 0, backgroundPosition: "1200px 0px" }], tr - tp);
    p.float(tp, 960, (FG.T0 + FG.T1) / 2, "6×", { cls: "combo", fs: 52, dur: tr - tp, rise: 0, hold: .9 });
    banner(p, tr + 150, "Victory", "win");
  } },
];

const FF = '<svg viewBox="0 0 24 24"><path d="M4 6l7 6-7 6zM12 6l7 6-7 6z"/></svg>';

// the result plate: leaded glass over the transom (stand-ins.html put plain 72 px words there)
function banner(p, t, words, kind, already) {
  const el = html(`<div class="banner ${kind}"><span>${words}</span><i class="sweep"></i></div>`);
  p.fx().append(el);
  const w = 520, h = 112; place(el, 960 - w / 2, (FG.T0 + FG.T1) / 2 - h / 2);
  el.style.width = w + "px"; el.style.height = h + "px";
  if (already) { el.style.opacity = 1; return; }
  el.style.opacity = 0;
  p.at(t, el, [{ opacity: 0, scale: 1.35, translate: "0px -30px" }, { opacity: 1, scale: .97, translate: "0px 0px", offset: .7 }, { opacity: 1, scale: 1, translate: "0px 0px" }], 300, "cubic-bezier(.3,.7,.4,1)");
  p.at(t + 250, el.querySelector(".sweep"), [{ translate: "-560px 0px", opacity: 1 }, { translate: "560px 0px", opacity: 1 }], 520, "ease-in-out");
  p.at(t + 1200, el, [{ opacity: 1 }, { opacity: 1 }], 1);
}
// the winner's strike at the loser's portrait; extra: the big-loss bonus, landing as a second bolt
function heroStrike(p, t, hp, base, extra) {
  const a = v2(HERO.you.x + 64, HERO.you.y + 64), b = v2(HERO.opp.x + 64, HERO.opp.y + 64);
  p.at(t, p.youPort, [{ filter: "brightness(1)", scale: 1 }, { filter: "brightness(1.4)", scale: 1.06, offset: .4 }, { filter: "brightness(1)", scale: 1 }], 360);
  const d = sub(b, a), cp = v2(a.x + d.x / 2 + 2 * d.y * .22, a.y + d.y / 2 - 2 * d.x * .22);
  p.path(t + 80, `M${a.x} ${a.y} Q${cp.x} ${cp.y} ${b.x} ${b.y}`, { colour: "#ffcf8a", w: 6, draw: 380, hold: 120, fade: 200 });
  const land = p.shard(t + 80, a, b, 380, { cls: "bolt big", size: 44, bend: -.22, colour: "#ffd2a0", grow: .3, easing: "linear" });
  p.burst(land, b.x, b.y, base, { r: 54 });
  p.shake(land, p.oppPort, 8, 280);
  const hpNum = (tt, v) => { const e = p.oppHp.cloneNode(true); e.textContent = Math.max(0, v); e.style.opacity = 0; p.st.append(e);
    p.at(tt, p.oppHp, [{ opacity: 1 }, { opacity: 0 }], 20); p.at(tt, e, [{ opacity: 1, scale: 1.4 }, { opacity: 1, scale: 1 }], 200, "ease-out"); p.oppHp = e; };
  let end = land;
  for (let k = 1; k <= base; k++) hpNum(land + 40 + k * 50, hp - k);
  if (extra) {
    const l2 = p.shard(land + 160, a, b, 340, { cls: "bolt big", size: 52, bend: -.28, colour: "#ffb24a", grow: .4 });
    p.burst(l2, b.x, b.y, base + extra, { r: 64, fs: 44, read: 420 });
    p.shake(l2, p.oppPort, 12, 320);
    for (let k = 1; k <= extra; k++) hpNum(l2 + 40 + k * 50, hp - base - k);
    end = l2;
  }
  return end + 300;
}
// a portrait cracks along lead lines and its glass falls out
function shatter(p, t) {
  const P = p.oppPort, x = HERO.opp.x, y = HERO.opp.y, s = 128, cx = x + s / 2, cy = y + s / 2;
  const cracks = [[cx - 8, cy - 4, x + 6, y + 40], [cx - 8, cy - 4, cx + 10, y - 2], [cx + 4, cy + 2, x + s + 2, cy + 18], [cx - 2, cy + 6, cx - 24, y + s + 4], [cx + 4, cy + 2, cx + 44, y + s - 6]];
  cracks.forEach(([x1, y1, x2, y2], k) => p.path(t + k * 25, `M${x1} ${y1} L${(x1 + x2) / 2 + 6} ${(y1 + y2) / 2 - 5} L${x2} ${y2}`, { colour: "#e9dfc8", w: 3, draw: 120, keep: true }));
  const pieces = ["polygon(0 0,60% 0,45% 45%,0 30%)", "polygon(60% 0,100% 0,100% 60%,45% 45%)", "polygon(0 30%,45% 45%,35% 100%,0 100%)", "polygon(45% 45%,100% 60%,100% 100%,35% 100%)"];
  pieces.forEach((clip, k) => {
    const q = P.cloneNode(true); q.style.clipPath = clip; q.style.opacity = 0; q.style.zIndex = 21; p.fx().append(q);
    const dx = [-30, 26, -18, 34][k], rot = [-24, 30, -40, 22][k];
    p.at(t + 300, q, [{ opacity: 1, translate: "0px 0px", rotate: "0deg" }, { opacity: 1, translate: `${dx * .3}px 20px`, rotate: rot * .3 + "deg", offset: .3 },
      { opacity: 0, translate: `${dx}px ${180 + k * 30}px`, rotate: rot + "deg" }], 600 + k * 60, "ease-in");
  });
  p.at(t + 300, P, [{ opacity: 1 }, { opacity: 0 }], 30);
  const sock = place(html(`<div class="port socket" style="width:128px;height:128px;opacity:0"></div>`), x, y); p.st.insertBefore(sock, P);
  p.at(t + 300, sock, [{ opacity: 0 }, { opacity: 1 }], 200);
  p.svg && p.at(t + 330, p.svg, [{ opacity: 1 }, { opacity: 0 }], 150);
  [p.oppHp, p.oppName].forEach(e => p.at(t + 380, e, [{ opacity: 1, filter: "grayscale(0)" }, { opacity: .45, filter: "grayscale(1)" }], 400));
}

const SECTIONS = { 1: "Into the fight", 2: "Start of fight", 3: "Attacks, damage and fight keywords", 4: "Growth, buffs and counters",
  5: "Deaths, death effects and returns", 6: "Grouping repeated triggers", 7: "The end of the fight", 8: "Skipping" };

// key frames (ms) for still pictures and for anyone who asks for reduced motion
const KEYS = { enter: [200, 600], lancer: [250, 620], grow: [400, 760], wingco: [560, 960], attack: [300, 380], damage: [380], guard: [200, 420],
  again: [330, 700], cleave: [430], overrun: [470, 600], pileon: [380, 520], sortie: [300, 450], thorns: [360, 450], strike: [420], fury: [420],
  lends: [380, 600], buffs: [450], tide: [700, 1200], renown: [600, 900], deaths: [400, 700], seed: [600, 900], hoppers: [650, 1200],
  summon: [420], reserve: [800, 1150], molt: [700, 1100], root: [1000, 1300], hmd: [700, 1000], combo: [1200, 1900], lieut: [560],
  tie: [1300], result: [1000, 1350], herodmg: [450, 700, 1250], elim: [1150, 1700], skip: [1240, 1500] };
EVENTS.forEach(e => e.keys = KEYS[e.id]);
