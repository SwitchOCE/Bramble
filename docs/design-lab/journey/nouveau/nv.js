// Woodland Nouveau, journey round (second shot). The painting is the poster:
// a thin gilt frame holds the world, the market hangs from a gilt vine, and
// your band stands in a halo arc around your hero, as in a Mucha poster.
// Travel opens the next area through an arched wipe.
(function () {
  const stage = document.getElementById('stage');
  const P = J.params;
  const S = { stop: Math.max(0, (+P.get('stop') || 1) - 1), mode: P.get('mode') || 'recruit' };
  let G, fightRun;

  // Corner whiplash, drawn once and mirrored into the four corners.
  const CURL = `<svg viewBox="0 0 220 220"><g fill="none" stroke="url(#gilt)" stroke-linecap="round">
    <path d="M8 212 V60 C8 26 26 8 60 8 H212" stroke-width="5"/>
    <path d="M22 200 V78 C22 40 40 22 78 22 H200" stroke-width="2"/>
    <path d="M36 150 C36 90 60 50 110 44 C150 40 168 64 150 84 C134 100 110 88 118 70" stroke-width="3.2"/>
    <path d="M44 120 C70 112 84 96 82 76" stroke-width="2"/>
    <circle cx="118" cy="70" r="5" fill="url(#gilt)" stroke="none"/></g></svg>`;
  const DEFS = `<svg width="0" height="0" style="position:absolute"><defs>
    <linearGradient id="gilt" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff1b8"/><stop offset=".35" stop-color="#d7ad4f"/><stop offset=".7" stop-color="#9c7124"/><stop offset="1" stop-color="#f4d77f"/></linearGradient></defs></svg>`;

  function card(u, where, style) {
    const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
    return `<div class="card ${u.golden ? 'golden' : ''} ${u.frozen ? 'frozen' : ''}" data-uid="${u.uid}" data-where="${where}" style="${style || ''};--tc:${t.c}">
      <div class="arch"><div class="halo"></div><img src="${J.por(u.id)}" alt="" draggable="false"></div>
      <div class="tier">${u.tier}</div>
      ${u.trig ? '<div class="sigil" title="Has a trigger">✧</div>' : ''}
      <div class="name">${J.esc(u.name.replace(/,.*$/, '').replace(/^The /, ''))}</div>
      <div class="gem atk"><b data-atk>${u.atk}</b></div><div class="gem hp"><b data-hp>${u.hp}</b></div>
    </div>`;
  }

  // Units on an arc. up=true: a crown over the hero; false: hanging from the top.
  function arc(units, where, cx, cy, R, up, spread) {
    const n = units.length, span = spread || 144;
    return units.map((u, i) => {
      const a = (n === 1 ? 0 : -span / 2 + (span * i) / (n - 1));
      const rad = ((up ? -90 : 90) + a) * Math.PI / 180;
      const x = cx + R * Math.cos(rad), y = cy + R * Math.sin(rad);
      return card(u, where, `left:${x.toFixed(0)}px;top:${y.toFixed(0)}px;--r:${(up ? a : -a) * 0.35}deg`);
    }).join('');
  }

  function frame() { return `<div class="frame"><i class="c tl">${CURL}</i><i class="c tr">${CURL}</i><i class="c bl">${CURL}</i><i class="c br">${CURL}</i></div>`; }
  function title() { return `<div class="cartouche"><small>${['First', 'Second', 'Third', 'Fourth', 'Fifth'][S.stop]} Station of the Journey</small><b>${G.area.name}</b><i>${G.area.sub} · turn ${G.turn}</i></div>`; }
  function lobby() {
    return `<div class="lobby">${G.lobby.map((p) => `<div class="medal ${p.you ? 'you' : ''} ${p.next ? 'next' : ''} ${p.hp <= 0 ? 'out' : ''}" title="${J.esc(p.name)}"><img src="${J.por(p.id)}" alt=""><b>${p.hp}</b></div>`).join('')}</div>`;
  }

  function recruit() {
    const W = stage.offsetWidth || 1920, cx = W / 2;
    const me = G.lobby.find((p) => p.you);
    const shopW = G.shop.length * 196;
    return `${DEFS}${frame()}${title()}${lobby()}
      <div class="rail" style="width:${shopW + 120}px"><svg viewBox="0 0 400 40" preserveAspectRatio="none"><path d="M0 20 C 60 4, 100 36, 160 20 S 260 4, 320 20 S 380 34, 400 18" fill="none" stroke="url(#gilt)" stroke-width="4"/></svg><span>The Market</span></div>
      <div class="market" style="width:${shopW}px">${G.shop.map((u, i) => card(u, 'shop', `--r:${(i - (G.shop.length - 1) / 2) * 1.5}deg`)).join('')}</div>
      <div class="disc"></div>
      ${arc(G.board, 'board', cx, 1012, 512, true, 128)}
      <div class="hero"><div class="rings"></div><img src="${J.por(me.id)}" alt=""><b>${me.hp}</b></div>
      <div class="jewels left"><div class="jewel gold"><b>${G.gold}</b><small>Gold</small></div><button class="jewel btn"><b>${Math.min(6, G.tier + 1)}</b><small>Tier up · ${Math.max(0, 7 - G.stop)}</small></button></div>
      <div class="jewels right"><button class="jewel btn" data-act="refresh"><b>↻</b><small>Refresh · 1</small></button><button class="jewel btn ice"><b>❄</b><small>Freeze</small></button></div>
      <div class="hand"><span>In hand</span>${G.hand.map((u) => card(u, 'hand')).join('')}</div>
      <button class="door" data-act="end"><b>End Turn</b><small>to battle ${J.esc(G.enemyHero.name)}</small></button>`;
  }

  function fight() {
    const W = stage.offsetWidth || 1920, cx = W / 2;
    const me = G.lobby.find((p) => p.you), foe = G.enemyHero;
    return `${DEFS}${frame()}${lobby()}
      <div class="disc top"></div><div class="disc"></div>
      <div class="hero foe"><div class="rings"></div><img src="${J.por(foe.id)}" alt=""><b>${foe.hp}</b></div>
      ${arc(G.enemy, 'enemy', cx, 30, 400, false, 150)}
      ${arc(G.board, 'mine', cx, 1050, 400, true, 150)}
      <div class="hero"><div class="rings"></div><img src="${J.por(me.id)}" alt=""><b>${me.hp}</b></div>
      <div class="verdict" hidden></div>
      <button class="door" data-act="travel" hidden><b>${S.stop === J.STOPS.length - 1 ? 'Begin Again' : 'Journey On'}</b><small>${S.stop === J.STOPS.length - 1 ? J.STOPS[0].name : 'to ' + J.STOPS[S.stop + 1].name}</small></button>`;
  }

  function render() {
    if (fightRun) fightRun.stop();
    if (!G || G.stop !== S.stop) G = J.state(S.stop);
    document.documentElement.dataset.mode = S.mode;
    stage.innerHTML = (S.mode === 'fight' ? fight() : recruit()) + '<div class="reader" hidden></div>';
    J.labDock({ stop: S.stop, mode: S.mode, onStop: (i) => travel(i), onMode: (m) => { S.mode = m; G = null; render(); } });
    if (S.mode === 'fight') {
      const door = stage.querySelector('.door');
      if (J.static) { door.hidden = false; return; }
      fightRun = J.fight(G.board, G.enemy, {
        find: (uid) => stage.querySelector(`[data-uid="${uid}"]`),
        onEnd: (w) => {
          const v = stage.querySelector('.verdict');
          v.textContent = w === 'you' ? 'Victory' : w === 'them' ? 'Defeat' : 'Stalemate';
          v.className = 'verdict ' + w; v.hidden = false; door.hidden = false;
        },
      });
    }
  }

  function travel(i) {
    S.stop = (i + J.STOPS.length) % J.STOPS.length; S.mode = 'recruit'; G = null;
    stage.classList.add('leaving');
    J.setArea(S.stop);
    setTimeout(() => { stage.classList.remove('leaving'); render(); }, J.reduced ? 0 : 700);
  }

  const find = (uid) => [...G.shop, ...G.board, ...G.hand, ...G.enemy].find((u) => u.uid === uid);
  stage.addEventListener('click', (e) => {
    const a = e.target.closest('[data-act]');
    if (a) {
      if (a.dataset.act === 'end') { S.mode = 'fight'; G = J.state(S.stop); render(); }
      if (a.dataset.act === 'travel') travel(S.stop + 1);
      if (a.dataset.act === 'refresh') { const r = J.rng(Date.now() & 0xffff); G.shop = G.shop.map((u, k) => { const pool = UNITS.filter((x) => x.pool && x.tier <= G.tier); const n = pool[Math.floor(r() * pool.length)]; return Object.assign({}, n, { uid: 'r' + k + Date.now(), text: n.text || 'No text.' }); }); render(); }
      return;
    }
    const c = e.target.closest('.card'); if (!c || S.mode === 'fight') return;
    const u = find(c.dataset.uid);
    if (c.dataset.where === 'shop' && G.hand.length < 3) { G.shop = G.shop.filter((x) => x !== u); G.hand.push(u); render(); }
    else if (c.dataset.where === 'hand' && G.board.length < 7) { G.hand = G.hand.filter((x) => x !== u); G.board.push(u); render(); }
  });

  let t;
  stage.addEventListener('pointerover', (e) => {
    const c = e.target.closest('.card'); if (!c || c.contains(e.relatedTarget)) return;
    clearTimeout(t);
    t = setTimeout(() => {
      const u = find(c.dataset.uid); if (!u) return;
      const r = stage.querySelector('.reader');
      r.innerHTML = `<small>${u.tribe} · Tier ${u.tier}</small><b>${J.esc(u.name)}</b><p>${J.rich(u)}</p>`;
      const sr = stage.getBoundingClientRect(), k = sr.width / stage.offsetWidth, cr = c.getBoundingClientRect();
      let x = (cr.right - sr.left) / k + 16, y = (cr.top - sr.top) / k;
      if (x + 360 > stage.offsetWidth - 40) x = (cr.left - sr.left) / k - 376;
      r.style.left = x + 'px'; r.style.top = Math.min(stage.offsetHeight - 280, Math.max(20, y)) + 'px'; r.hidden = false;
    }, 200);
  });
  stage.addEventListener('pointerout', (e) => { const c = e.target.closest('.card'); if (c && !c.contains(e.relatedTarget)) { clearTimeout(t); stage.querySelector('.reader').hidden = true; } });

  J.keys({ ArrowRight: () => travel(S.stop + 1), ArrowLeft: () => travel(S.stop - 1), f: () => { S.mode = S.mode === 'fight' ? 'recruit' : 'fight'; G = null; render(); } });

  J.mountWorld({ ferns: false });
  J.fit(stage);
  addEventListener('resize', () => render());
  J.setArea(S.stop, 'instant');
  render();
})();
