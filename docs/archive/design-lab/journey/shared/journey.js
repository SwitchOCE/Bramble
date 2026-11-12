// Bramble design lab, journey round: a shared engine for the three lab pages.
// It owns the world (painted areas you travel through), the stage scaling, the
// mock run (boards that grow along the journey) and a purely visual fight loop.
// Rules are ignored on purpose, except the board: 4 slots in front, 3 behind.
(function () {
  const J = (window.J = {});
  const qs = new URLSearchParams(location.search);
  J.params = qs;
  J.static = qs.has('static');
  J.reduced = J.static || matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (J.static) document.documentElement.classList.add('jy-static');

  const ROOT = (document.currentScript.src.replace(/shared\/journey\.js.*$/, ''));
  J.por = (id) => ROOT + 'portraits/' + id + '.jpg';
  J.world = (f) => ROOT + 'world/' + f;

  // ---- The journey: five painted areas, two turns each ----------------------
  J.STOPS = [
    { id: 'weald', name: 'Weald Glow', sub: 'The edge of the wood', img: 'weald.jpg', tint: '#ffd27a', hue: 38, turns: [1, 2] },
    { id: 'canopy', name: 'Highcrown Canopy', sub: 'Under the great oaks', img: 'canopy.jpg', tint: '#e9f0a8', hue: 70, turns: [3, 4] },
    { id: 'mosswood', name: 'Mosswood Mist', sub: 'Where the moss runs deep', img: 'mosswood.jpg', tint: '#a8f0d8', hue: 165, turns: [5, 6] },
    { id: 'rays', name: 'Highcrown Rays', sub: 'Light through the crowns', img: 'rays.jpg', tint: '#f4ffd0', hue: 95, turns: [7, 8] },
    { id: 'fen', name: 'Fen Wisplight', sub: 'The fen at dusk', img: 'fen.jpg', tint: '#d9c4ff', hue: 265, turns: [9, 11] },
  ];

  J.TRIBE = {
    'Birds': { c: '#d98b4a', icon: 'feather' },
    'Bog folk': { c: '#6f8f3e', icon: 'reed' },
    'Fairies': { c: '#a07ad6', icon: 'wing' },
    'Hedgerow folk': { c: '#c9a24d', icon: 'acorn' },
    'Hunters': { c: '#5d7f9e', icon: 'paw' },
    'Oozes': { c: '#4fb3a0', icon: 'drop' },
    'Neutral': { c: '#a8826e', icon: 'leaf' },
  };

  // ---- Seeded randomness so every screenshot is repeatable -------------------
  function rng(seed) {
    return function () {
      seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
      let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  J.rng = rng;
  const byId = {};
  (window.UNITS || []).forEach((u) => (byId[u.id] = u));
  J.unit = (id) => byId[id];
  let uidN = 1;
  function inst(u, buff, golden) {
    return Object.assign({}, u, {
      uid: 'u' + uidN++,
      atk: (u.atk + buff) * (golden ? 2 : 1),
      hp: (u.hp + buff) * (golden ? 2 : 1),
      golden: !!golden,
      text: u.text || 'No text. Just a sturdy pair of stats.',
    });
  }

  // A hand-picked run so the board tells a story: a Bog folk and Fairies band.
  const RUN = {
    board: [
      ['jenny_greenteeth', 'will_o_the_wisp', 'mrs_mallow'],
      ['nan_toadstool', 'bridge_toad', 'lamp_moth'],
      ['madame_bufo', 'old_brock'],
      ['lantern_man', 'fairy_monarch'],
      ['hedge_witch', 'changeling', 'grey_agnes'],
    ],
    enemy: ['mag_pye', 'barn_owl', 'cuckoo', 'mrs_jay', 'little_king_wren', 'chiffchaff', 'mother_goose', 'mr_redbreast', 'jack_daw'],
    heroes: ['dame_hoolet', 'brother_bracken', 'march_hare', 'dame_farthing', 'hob_mumblecrust', 'little_king_wren', 'jill_down_the_tree', 'pipkin'],
  };
  const boardSize = [2, 4, 5, 6, 7];
  const shopSize = [3, 4, 4, 5, 6];
  const tierAt = [1, 2, 3, 4, 6];

  function pickPool(r, maxTier, n, exclude) {
    const pool = (window.UNITS || []).filter((u) => u.tier <= maxTier && u.pool && !exclude.has(u.id));
    const out = [];
    while (out.length < n && pool.length) out.push(pool.splice(Math.floor(r() * pool.length), 1)[0]);
    return out;
  }
  function have(id) { return !!byId[id]; }

  // ---- The board: 7 fixed slots, 4 in front and 3 behind (rulebook 8.1) ------
  // This one rule holds in every lab look. A board is an array of 7, F1-F4 then
  // B1-B3, with null for an empty slot. Units never slide to fill a gap.
  J.SLOTS = ['F1', 'F2', 'F3', 'F4', 'B1', 'B2', 'B3'];
  // Where a mock band of n stands: front first, with a gap now and then.
  const LAYOUT = { 0: [], 1: [1], 2: [1, 2], 3: [1, 2, 5], 4: [0, 1, 2, 5], 5: [0, 1, 2, 3, 5], 6: [0, 1, 2, 3, 4, 6], 7: [0, 1, 2, 3, 4, 5, 6] };
  J.slotted = (units) => { const s = Array(7).fill(null); (LAYOUT[units.length] || []).forEach((k, i) => (s[k] = units[i])); return s; };
  // A hex unit's two layers: the frame (edge colour) and the art inside it.
  // The hit layer is clipped to the hex, so packed units overlap only visually:
  // the mouse always picks the unit you see under it.
  J.hex = (id) => `<i class="hx-frame"></i><i class="hx-art"><img src="${J.por(id)}" alt="" draggable="false"></i><i class="hx-hit"></i>`;
  J.count = (slots) => slots.filter(Boolean).length;
  J.firstEmpty = (slots) => slots.findIndex((u) => !u);
  // The brick: front row of 4, back row of 3 offset by half a slot.
  // cardFn(unit, slotIndex) and emptyFn(slotIndex) return HTML. cls: extra classes
  // ('foe' puts the back row on top so the two front rows face each other).
  J.brick = function (slots, cardFn, emptyFn, cls) {
    const cell = (k) => (slots[k] ? cardFn(slots[k], k) : emptyFn(k));
    return `<div class="brick ${cls || ''}"><div class="brow brow-f">${[0, 1, 2, 3].map(cell).join('')}</div><div class="brow brow-b">${[4, 5, 6].map(cell).join('')}</div></div>`;
  };

  J.state = function (stop) {
    stop = Math.max(0, Math.min(J.STOPS.length - 1, stop));
    const r = rng(4242 + stop * 97);
    const ids = [];
    for (let s = 0; s <= stop; s++) RUN.board[s].forEach((id) => have(id) && ids.push(id));
    // The oldest units carry buffs from the road behind them.
    const keep = ids.slice(-boardSize[stop]);
    const board = keep.map((id, i) => inst(byId[id], Math.max(0, stop * 2 - Math.floor(i / 2)), stop >= 3 && i === 1));
    const used = new Set(keep);
    const shop = pickPool(r, tierAt[stop], shopSize[stop], used).map((u) => inst(u, 0));
    if (shop[shop.length - 1]) shop[shop.length - 1].frozen = stop % 2 === 1;
    const hand = pickPool(r, tierAt[stop], stop === 0 ? 0 : stop > 2 ? 2 : 1, new Set([...used, ...shop.map((s) => s.id)])).map((u) => inst(u, 0));
    const er = rng(77 + stop * 13);
    const enemy = RUN.enemy.filter(have).slice(0, boardSize[stop]).map((id, i) => inst(byId[id], Math.floor(stop * 2.2 - i / 3), stop >= 2 && i === 0));
    const st = J.STOPS[stop];
    const turn = st.turns[0];
    const lobby = RUN.heroes.map((h, i) => {
      const lost = Math.round((stop * 6 + er() * stop * 5) * (i === 0 ? 0.8 : 1));
      return { id: h, name: (window.HEROES || []).find((x) => x.id === h)?.name || h, hp: Math.max(0, 40 - lost - (i === 7 ? stop * 6 : 0)), tier: Math.min(6, tierAt[stop] + (er() < 0.3 ? 1 : 0)), you: i === 0, next: i === 3 };
    });
    lobby.sort((a, b) => b.hp - a.hp);
    return { stop, area: st, turn, tier: tierAt[stop], gold: Math.min(10, 2 + turn), board: J.slotted(board), shop, hand, enemy: J.slotted(enemy), lobby, enemyHero: lobby.find((p) => p.next) };
  };

  // ---- Stage scaling: the UI is designed at 1080 tall and stretches sideways --
  J.fit = function (stage) {
    function go() {
      const w = innerWidth, h = innerHeight, a = w / h;
      let W, H;
      if (a >= 16 / 9) { H = 1080; W = Math.round(1080 * a); } else { W = 1920; H = Math.round(1920 / a); }
      stage.style.width = W + 'px'; stage.style.height = H + 'px';
      stage.style.transform = 'scale(' + w / W + ')';
      document.documentElement.style.setProperty('--stage-w', W + 'px');
      document.documentElement.classList.toggle('jy-phone', h < 820);
    }
    addEventListener('resize', go); go();
  };

  // ---- The world: backdrop layers, foreground ferns, motes, parallax ---------
  J.mountWorld = function (opts) {
    opts = opts || {};
    const w = document.createElement('div');
    w.className = 'jy-world';
    w.innerHTML = '<div class="jy-bg"></div><div class="jy-bg"></div><div class="jy-shade"></div><div class="jy-motes"></div>' +
      (opts.ferns === false ? '' : '<img class="jy-fern l" src="' + J.world('fern.png') + '"><img class="jy-fern r" src="' + J.world('fern.png') + '">');
    document.body.prepend(w);
    J.worldEl = w;
    const bgs = w.querySelectorAll('.jy-bg');
    J._bg = { a: bgs[0], b: bgs[1] };
    const motes = w.querySelector('.jy-motes');
    const r = rng(9);
    for (let i = 0; i < (J.reduced ? 0 : 26); i++) {
      const m = document.createElement('i');
      m.style.left = (r() * 100).toFixed(1) + '%';
      m.style.top = (20 + r() * 80).toFixed(1) + '%';
      m.style.setProperty('--d', (6 + r() * 10).toFixed(1) + 's');
      m.style.setProperty('--delay', (-r() * 12).toFixed(1) + 's');
      m.style.setProperty('--sz', (3 + r() * 6).toFixed(1) + 'px');
      motes.appendChild(m);
    }
    // Parallax. The variables live on the world layer only (setting them on the page
    // root restyled every unit on every mouse move), and update at most once a frame.
    if (!J.reduced) {
      let px = 0, py = 0, queued = false;
      addEventListener('pointermove', (e) => {
        px = e.clientX / innerWidth - 0.5; py = e.clientY / innerHeight - 0.5;
        if (queued) return;
        queued = true;
        requestAnimationFrame(() => { queued = false; w.style.setProperty('--px', px.toFixed(3)); w.style.setProperty('--py', py.toFixed(3)); });
      }, { passive: true });
    }
    return w;
  };

  J.setArea = function (stop, how) {
    const st = J.STOPS[stop];
    const { a, b } = J._bg;
    const cur = a.classList.contains('on') ? a : b.classList.contains('on') ? b : null;
    const nxt = cur === a ? b : a;
    nxt.style.backgroundImage = 'url(' + J.world(st.img) + ')';
    document.documentElement.style.setProperty('--tint', st.tint);
    document.documentElement.style.setProperty('--hue', st.hue);
    document.documentElement.dataset.area = st.id;
    if (!cur || how === 'instant' || J.reduced) {
      [a, b].forEach((x) => x.classList.remove('on', 'enter', 'leave'));
      nxt.classList.add('on');
      return Promise.resolve();
    }
    // Put the new layer at its start pose with no transition, then let it go:
    // it slides and fades in over the old one, which stays opaque underneath.
    nxt.classList.remove('leave'); nxt.classList.add('enter');
    void nxt.offsetWidth;
    nxt.classList.remove('enter');
    cur.classList.add('leave'); cur.classList.remove('on');
    nxt.classList.add('on');
    clearTimeout(J._areaT);
    return new Promise((res) => (J._areaT = setTimeout(() => { cur.classList.remove('leave'); res(); }, 1700)));
  };

  // ---- A tiny event helper and the card reader (hover details) -------------
  J.html = (s) => { const t = document.createElement('template'); t.innerHTML = s.trim(); return t.content.firstElementChild; };
  J.esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  // Bold the keywords in rules text.
  J.rich = (u) => {
    let t = J.esc(u.text);
    (u.kw || []).forEach((k) => { t = t.replace(new RegExp('\\b(' + k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')\\b'), '<b>$1</b>'); });
    t = t.replace(/^(Start of Combat|End of Turn|After [^:]+|When [^:]+|Whenever [^:]+):/, '<em>$1:</em>');
    return t;
  };

  // ---- A visual fight loop on the two bricks. Mostly not the rules: units take
  // turns in slot order (front row, then back), and hit the front row while it lives.
  // you/them are 7-slot boards. opts.find(uid) -> element; opts.onEnd(winner)
  J.fight = function (you, them, opts) {
    const r = rng(31 + J.count(you) * 7 + J.count(them));
    let turn = 0, stopped = false;
    const live = (u) => u && u.hp > 0;
    const ptr = [-1, -1];
    function nextAttacker(side, k) {
      for (let n = 1; n <= side.length; n++) { const i = (ptr[k] + n) % side.length; if (live(side[i])) { ptr[k] = i; return side[i]; } }
    }
    function target(side) {
      const front = side.slice(0, 4).filter(live), pool = front.length ? front : side.filter(live);
      return pool[Math.floor(r() * pool.length)];
    }
    function step() {
      if (stopped) return;
      const A = you.filter(live), B = them.filter(live);
      if (!A.length || !B.length) { opts.onEnd && opts.onEnd(A.length ? 'you' : B.length ? 'them' : 'draw'); return; }
      const k = turn++ % 2;
      const att = nextAttacker(k === 0 ? you : them, k);
      const def = target(k === 0 ? them : you);
      const ea = opts.find(att.uid), ed = opts.find(def.uid);
      if (!ea || !ed) return setTimeout(step, 50);
      const ra = ea.getBoundingClientRect(), rd = ed.getBoundingClientRect();
      const scale = ea.offsetWidth ? ra.width / ea.offsetWidth : 1;
      const dx = (rd.left + rd.width / 2 - (ra.left + ra.width / 2)) / scale;
      const dy = (rd.top + rd.height / 2 - (ra.top + ra.height / 2)) / scale;
      ea.style.setProperty('--dx', dx * 0.78 + 'px');
      ea.style.setProperty('--dy', dy * 0.78 + 'px');
      ea.classList.remove('jy-lunge'); void ea.offsetWidth; ea.classList.add('jy-lunge');
      setTimeout(() => {
        def.hp -= att.atk; att.hp -= Math.max(0, Math.floor(def.atk / 2));
        [[def, ed, att.atk], [att, ea, Math.floor(def.atk / 2)]].forEach(([u, el, dmg]) => {
          if (!dmg) return;
          el.querySelectorAll('[data-hp]').forEach((n) => (n.textContent = Math.max(0, u.hp)));
          el.classList.add('jy-hurt');
          const pop = document.createElement('div');
          pop.className = 'jy-dmg'; pop.textContent = '−' + dmg;
          el.appendChild(pop);
          setTimeout(() => { pop.remove(); el.classList.remove('jy-hurt'); if (u.hp <= 0) el.classList.add('jy-dead'); }, 700);
        });
        opts.onHit && opts.onHit(att, def);
      }, 260);
      setTimeout(step, J.static ? 0 : 1050);
    }
    setTimeout(step, J.static ? 0 : 900);
    return { stop() { stopped = true; } };
  };

  // ---- The lab dock: outside the game UI, so the owner can jump around -------
  // opts: { stop, mode, onStop(i), onMode(m), extra: [{label, options:[[v,text]], value, on(v)}] }
  J.labDock = function (opts) {
    let d = document.querySelector('.jy-dock');
    if (!d) { d = document.createElement('div'); d.className = 'jy-dock'; document.body.appendChild(d); }
    const seg = (items, cur, cb) => {
      const g = document.createElement('div'); g.className = 'jy-seg';
      items.forEach(([v, t]) => { const b = document.createElement('button'); b.textContent = t; if (v === cur) b.className = 'on'; b.onclick = () => cb(v); g.appendChild(b); });
      return g;
    };
    d.innerHTML = '<a class="jy-home" href="../index.html" title="Back to the journey round">Lab ↩</a>';
    d.appendChild(seg(J.STOPS.map((s, i) => [i, String(i + 1)]), opts.stop, opts.onStop));
    d.appendChild(seg([['recruit', 'Recruit'], ['fight', 'Fight']], opts.mode, opts.onMode));
    (opts.extra || []).forEach((x) => d.appendChild(seg(x.options, x.value, x.on)));
    if (J.static) d.style.display = 'none';
  };

  // ---- Keyboard: right arrow travels, F fights, R restarts ---------------------
  J.keys = function (map) {
    addEventListener('keydown', (e) => { const f = map[e.key] || map[e.key.toLowerCase()]; if (f) { e.preventDefault(); f(); } });
  };
})();
