// Woodland Nouveau, journey round (second shot). The painting is the poster:
// a thin gilt frame holds the world, the market hangs from a gilt vine, and
// your band stands sideways in a tall altar, centred top to bottom, that never
// moves between phases. The leaderboard is on the right.
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

  // A unit is a gilt-framed hex (owner's pick, 11 Nov), points left and right so
  // the two columns of a sideways band pack together. Jewels carry the numbers.
  function card(u, where, style) {
    const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
    return `<div class="card ${u.golden ? 'golden' : ''} ${u.frozen ? 'frozen' : ''}" data-uid="${u.uid}" data-where="${where}" style="${style || ''};--tc:${t.c}">
      ${J.hex(u.id)}
      <div class="tier">${u.tier}</div>
      ${u.trig ? '<div class="sigil" title="Has a trigger">✧</div>' : ''}
      <div class="name">${J.esc(u.name.replace(/,.*$/, '').replace(/^The /, ''))}</div>
      <div class="gem atk"><b data-atk>${u.atk}</b></div><div class="gem hp"><b data-hp>${u.hp}</b></div>
    </div>`;
  }

  // The band: 4 in front, 3 behind, packed. Empty slots are faint gilt hexes.
  const band = (slots, where, cls) => `<div class="band">${J.brick(slots, (u) => card(u, where), (k) => `<div class="slot"><i class="hx-frame"></i><i class="hx-art"></i><span>${J.SLOTS[k]}</span></div>`, 'hex ' + (cls || ''))}</div>`;

  function frame() { return `<div class="frame"><i class="c tl">${CURL}</i><i class="c tr">${CURL}</i><i class="c bl">${CURL}</i><i class="c br">${CURL}</i></div>`; }
  function title() { return `<div class="cartouche"><small>${['First', 'Second', 'Third', 'Fourth', 'Fifth'][S.stop]} Station of the Journey</small><b>${G.area.name}</b><i>${G.area.sub} · turn ${G.turn}</i></div>`; }
  function lobby() {
    return `<div class="lobby">${G.lobby.map((p) => `<div class="medal ${p.you ? 'you' : ''} ${p.next ? 'next' : ''} ${p.hp <= 0 ? 'out' : ''}" title="${J.esc(p.name)}"><img src="${J.por(p.id)}" alt=""><b>${p.hp}</b></div>`).join('')}</div>`;
  }

  // Left-right. Your altar is pinned on the left: same place, same size, in every
  // phase, your band standing sideways with the front column facing right.
  // To its right: the market cabinet (recruit) or the opponent's altar (fight).
  function myAltar(where) {
    return `<section class="altar me pin"><span class="count">Your band · ${J.count(G.board)} of 7</span>${band(G.board, where, 'side faces-right')}</section>`;
  }
  function myHero() {
    const me = G.lobby.find((p) => p.you);
    return `<div class="hero me"><div class="rings"></div><img src="${J.por(me.id)}" alt=""><b>${me.hp}</b><i>You</i></div>`;
  }

  function recruit() {
    return `${DEFS}${frame()}${lobby()}${title()}
      ${myAltar('board')}${myHero()}
      <section class="cabinet">
        <header><span>The Market</span><i>Tier ${G.tier}</i></header>
        <div class="rail"><svg viewBox="0 0 400 40" preserveAspectRatio="none"><path d="M0 20 C 60 4, 100 36, 160 20 S 260 4, 320 20 S 380 34, 400 18" fill="none" stroke="url(#gilt)" stroke-width="4"/></svg></div>
        <div class="market">${G.shop.map((u, i) => card(u, 'shop', `--r:${((i % 3) - 1) * 1.5}deg`)).join('')}</div>
        <div class="jewels">
          <div class="jewel gold"><b>${G.gold}</b><small>Gold</small></div>
          <button class="jewel btn"><b>${Math.min(6, G.tier + 1)}</b><small>Tier up · ${Math.max(0, 7 - G.stop)}</small></button>
          <button class="jewel btn" data-act="refresh"><b>↻</b><small>Refresh · 1</small></button>
          <button class="jewel btn ice"><b>❄</b><small>Freeze</small></button>
        </div>
      </section>
      <div class="hand"><span>In hand</span>${G.hand.map((u) => card(u, 'hand')).join('')}</div>
      <button class="door" data-act="end"><b>End Turn</b><small>to battle ${J.esc(G.enemyHero.name)}</small></button>`;
  }

  // The fight: the opponent's altar takes the cabinet's place, front columns facing.
  function fight() {
    const foe = G.enemyHero;
    return `${DEFS}${frame()}${lobby()}${title()}
      ${myAltar('mine')}${myHero()}
      <section class="altar foe"><span class="count">${J.esc(foe.name)}</span>${band(G.enemy, 'enemy', 'side')}</section>
      <aside class="heroes">
        <div class="hero foe"><div class="rings"></div><img src="${J.por(foe.id)}" alt=""><b>${foe.hp}</b><i>${J.esc(foe.name)}</i></div>
        <div class="verdict" hidden></div>
      </aside>
      <button class="door" data-act="travel" hidden><b>${S.stop === J.STOPS.length - 1 ? 'Begin Again' : 'Journey On'}</b><small>${S.stop === J.STOPS.length - 1 ? J.STOPS[0].name : 'to ' + J.STOPS[S.stop + 1].name}</small></button>`;
  }

  function render(swap) {
    if (fightRun) fightRun.stop();
    if (!G || G.stop !== S.stop) G = J.state(S.stop);
    document.documentElement.dataset.mode = S.mode;
    stage.classList.toggle('swap', !!swap && !J.static);
    stage.innerHTML = (S.mode === 'fight' ? fight() : recruit()) + '<div class="reader" hidden></div>';
    J.labDock({ stop: S.stop, mode: S.mode, onStop: (i) => travel(i), onMode: (m) => { S.mode = m; G = null; render(true); } });
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

  const find = (uid) => [...G.shop, ...G.board, ...G.hand, ...G.enemy].find((u) => u && u.uid === uid);
  stage.addEventListener('click', (e) => {
    const a = e.target.closest('[data-act]');
    if (a) {
      if (a.dataset.act === 'end') { S.mode = 'fight'; G = J.state(S.stop); render(true); }
      if (a.dataset.act === 'travel') travel(S.stop + 1);
      if (a.dataset.act === 'refresh') { const r = J.rng(Date.now() & 0xffff); G.shop = G.shop.map((u, k) => { const pool = UNITS.filter((x) => x.pool && x.tier <= G.tier); const n = pool[Math.floor(r() * pool.length)]; return Object.assign({}, n, { uid: 'r' + k + Date.now(), text: n.text || 'No text.' }); }); render(); }
      return;
    }
    const c = e.target.closest('.card'); if (!c || S.mode === 'fight') return;
    const u = find(c.dataset.uid);
    if (c.dataset.where === 'shop' && G.hand.length < 3) { G.shop = G.shop.filter((x) => x !== u); G.hand.push(u); render(); }
    else if (c.dataset.where === 'hand' && J.firstEmpty(G.board) >= 0) { G.hand = G.hand.filter((x) => x !== u); G.board[J.firstEmpty(G.board)] = u; render(); }
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

  J.keys({ ArrowRight: () => travel(S.stop + 1), ArrowLeft: () => travel(S.stop - 1), f: () => { S.mode = S.mode === 'fight' ? 'recruit' : 'fight'; G = null; render(true); } });

  J.mountWorld({ ferns: false });
  J.fit(stage);
  J.setArea(S.stop, 'instant');
  render();
})();
