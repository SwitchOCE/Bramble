// Clean Arena, journey round: art first. A card is its picture plus Attack,
// Health and a bolt if it has a trigger. Click flips it for the details;
// hover shows a quick reader. The board floats on frosted glass over the world.
(function () {
  const stage = document.getElementById('stage');
  const P = J.params;
  const S = {
    stop: Math.max(0, (+P.get('stop') || 1) - 1),
    mode: P.get('mode') || 'recruit',
    details: P.get('details') || 'both',
    flip: P.get('flip') || '',
  };
  let G, fightRun;

  const BOLT = '<svg viewBox="0 0 24 24"><path d="M13.5 2 4 13.6h6.2L9 22l10-12.2h-6.4z"/></svg>';
  const AURA = '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="4.2"/><circle cx="12" cy="12" r="8.6" fill="none" stroke-width="2.2"/></svg>';
  const ACORN = '<svg viewBox="0 0 24 24"><path d="M4 10c0-3.3 3.6-6 8-6s8 2.7 8 6z"/><path d="M6 11h12c0 5-2.7 9-6 10-3.3-1-6-5-6-10z" opacity=".85"/><path d="M12 1.5v3" stroke-width="2" stroke="currentColor"/></svg>';

  function card(u, where) {
    const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
    const icon = u.trig ? '<span class="ico bolt" title="Trigger">' + BOLT + '</span>' : (u.kw && u.kw.length) || (u.text && !/^No text/.test(u.text)) ? '<span class="ico aura" title="Ability">' + AURA + '</span>' : '';
    const act = where === 'shop' ? 'Buy · 3' : where === 'board' ? 'Sell · 1' : where === 'hand' ? 'Play' : '';
    return `<div class="card ${u.golden ? 'golden' : ''} ${u.frozen ? 'frozen' : ''} ${S.flip === u.id ? 'flipped' : ''}" data-uid="${u.uid}" data-where="${where}" style="--tc:${t.c}">
      <div class="flip">
        <div class="face front">
          <img src="${J.por(u.id)}" alt="" draggable="false">
          <span class="tier">${u.tier}</span>${icon}
          <span class="atk" data-atk>${u.atk}</span><span class="hp" data-hp>${u.hp}</span>
        </div>
        <div class="face back">
          <img class="thumb" src="${J.por(u.id)}" alt="">
          <div class="b-name">${J.esc(u.name)}</div>
          <div class="b-tribe"><i style="background:${t.c}"></i>${u.tribe} · Tier ${u.tier}</div>
          <p class="b-text">${J.rich(u)}</p>
          <div class="b-foot"><span class="atk" data-atk>${u.atk}</span><span class="hp" data-hp>${u.hp}</span>${act ? `<button class="b-act">${act}</button>` : ''}</div>
        </div>
      </div>
    </div>`;
  }
  const slot = (k) => `<div class="slot"><span>${J.SLOTS[k]}</span></div>`;
  const brick = (slots, where, cls) => J.brick(slots, (u) => card(u, where), slot, cls);

  function route() {
    return `<div class="route">${J.STOPS.map((s, i) => `
      <div class="node ${i < S.stop ? 'past' : i === S.stop ? 'here' : 'ahead'}" style="background-image:url(${J.world(s.img)})" title="${s.name}"></div>${i < J.STOPS.length - 1 ? '<i class="path"></i>' : ''}`).join('')}
      <div class="route-label"><b>${G.area.name}</b> · turn ${G.turn}</div></div>`;
  }
  function lobby() {
    return `<div class="lobby">${G.lobby.map((p) => `
      <div class="pl ${p.you ? 'you' : ''} ${p.next ? 'next' : ''} ${p.hp <= 0 ? 'out' : ''}">
        <img src="${J.por(p.id)}" alt=""><span class="php">${p.hp}</span><span class="ptier">${p.tier}</span>
      </div>`).join('')}</div>`;
  }

  function recruit() {
    return `${route()}
      <div class="turnmark"><b>TURN ${G.turn}</b><span>RECRUIT</span></div>
      ${lobby()}
      <section class="arena">
        <div class="zone"><div class="row-label"><span>MARKET</span><span class="dim">TIER ${G.tier}</span></div>
          <div class="row shop">${G.shop.map((u) => card(u, 'shop')).join('')}</div></div>
        <div class="zone band"><div class="row-label"><span>YOUR BAND</span><span class="dim">${J.count(G.board)}/7</span></div>
          <div class="tags"><i>FRONT</i><i>BACK</i></div>
          ${brick(G.board, 'board')}</div>
      </section>
      <footer class="bar">
        <div class="gold"><span class="acorn">${ACORN}</span><b>${G.gold}</b></div>
        <button class="btn sq tierup" title="Tier up"><span>▲ ${Math.min(6, G.tier + 1)}</span><em>${ACORN}${Math.max(0, 7 - G.stop)}</em></button>
        <button class="btn sq refresh" data-act="refresh" title="Refresh"><span>⟳</span><em>${ACORN}1</em></button>
        <button class="btn sq freeze" title="Freeze"><span>❄</span><em>&nbsp;</em></button>
        <div class="hand">${G.hand.map((u) => card(u, 'hand')).join('')}</div>
        <button class="btn end" data-act="end"><span>END TURN</span><small>fight ${J.esc(G.enemyHero.name)}</small></button>
      </footer>`;
  }

  function fight() {
    const foe = G.enemyHero, me = G.lobby.find((p) => p.you);
    return `${route()}
      <div class="turnmark"><b>TURN ${G.turn}</b><span class="red">FIGHT</span></div>
      ${lobby()}
      <section class="arena fightpanel">
        <div class="hero foe"><img src="${J.por(foe.id)}" alt=""><b>${J.esc(foe.name)}</b><span class="php">${foe.hp}</span></div>
        ${brick(G.enemy, 'enemy', 'foe')}
        <div class="vs"></div>
        ${brick(G.board, 'mine')}
        <div class="hero me"><img src="${J.por(me.id)}" alt=""><b>You</b><span class="php">${me.hp}</span></div>
      </section>
      <div class="result" hidden></div>`;
  }

  function render(arrive) {
    if (fightRun) fightRun.stop();
    G = G && G.stop === S.stop && !arrive ? G : J.state(S.stop);
    document.documentElement.dataset.mode = S.mode;
    stage.innerHTML = (S.mode === 'fight' ? fight() : recruit()) + '<div class="reader" hidden></div>' +
      (arrive ? `<div class="arrive"><small>Area ${S.stop + 1} of ${J.STOPS.length}</small><b>${G.area.name}</b><span>${G.area.sub}</span></div>` : '');
    J.labDock({
      stop: S.stop, mode: S.mode,
      onStop: (i) => travel(i), onMode: (m) => { S.mode = m; G = null; render(); },
      extra: [{ options: [['both', 'Flip + hover'], ['flip', 'Flip'], ['hover', 'Hover']], value: S.details, on: (v) => { S.details = v; render(); } }],
    });
    if (S.mode === 'fight' && !J.static) {
      fightRun = J.fight(G.board, G.enemy, {
        find: (uid) => stage.querySelector(`[data-uid="${uid}"]`),
        onEnd: (w) => {
          const r = stage.querySelector('.result');
          const last = S.stop === J.STOPS.length - 1;
          r.innerHTML = `<b class="${w}">${w === 'you' ? 'WON' : w === 'them' ? 'LOST' : 'DRAW'}</b><button class="btn end" data-act="travel"><span>${last ? 'START OVER' : 'TRAVEL ON'}</span><small>${last ? 'back to ' + J.STOPS[0].name : 'to ' + J.STOPS[S.stop + 1].name}</small></button>`;
          r.hidden = false;
        },
      });
    }
    stage.classList.toggle('arriving', !!arrive && !J.static);
    if (arrive) setTimeout(() => { const a = stage.querySelector('.arrive'); a && a.classList.add('go'); stage.classList.remove('arriving'); }, 2900);
  }

  function travel(i) {
    if (i === S.stop && G) { S.mode = 'recruit'; G = null; render(); return; }
    S.stop = (i + J.STOPS.length) % J.STOPS.length; S.mode = 'recruit'; G = null;
    stage.classList.add('leaving');
    setTimeout(() => {
      J.setArea(S.stop);
      stage.classList.remove('leaving');
      render(true);
    }, J.reduced ? 0 : 380);
  }

  // ---- Interactions ----------------------------------------------------------
  const find = (uid) => [...G.shop, ...G.board, ...G.hand, ...G.enemy].find((u) => u && u.uid === uid);
  stage.addEventListener('click', (e) => {
    const act = e.target.closest('[data-act]');
    if (act) {
      const a = act.dataset.act;
      if (a === 'end') { S.mode = 'fight'; G = J.state(S.stop); render(); }
      if (a === 'travel') travel(S.stop + 1);
      if (a === 'refresh') { const r = J.rng(Date.now() & 0xffff); G.shop.forEach((u, k) => { const pool = UNITS.filter((x) => x.pool && x.tier <= G.tier); const n = pool[Math.floor(r() * pool.length)]; G.shop[k] = Object.assign({}, n, { uid: 'r' + k + Date.now(), text: n.text || 'No text.' }); }); render(); stage.querySelectorAll('.shop .card').forEach((c, k) => { c.style.animationDelay = k * 60 + 'ms'; c.classList.add('deal'); }); }
      return;
    }
    const b = e.target.closest('.b-act');
    const c = e.target.closest('.card');
    if (b && c) {
      const u = find(c.dataset.uid), w = c.dataset.where;
      if (w === 'shop' && G.hand.length < 4) { G.shop = G.shop.filter((x) => x !== u); G.hand.push(u); }
      const k = J.firstEmpty(G.board);
      if (w === 'hand' && k >= 0) { G.hand = G.hand.filter((x) => x !== u); G.board[k] = u; }
      if (w === 'board') G.board[G.board.indexOf(u)] = null;
      hideReader(); render(); return;
    }
    if (c && S.details !== 'hover') { c.classList.toggle('flipped'); hideReader(); }
  });

  const reader = () => stage.querySelector('.reader');
  let hoverT;
  function hideReader() { clearTimeout(hoverT); const r = reader(); if (r) r.hidden = true; }
  stage.addEventListener('pointerover', (e) => {
    if (S.details === 'flip' || e.pointerType === 'touch') return;
    const c = e.target.closest('.card');
    if (!c || c.classList.contains('flipped') || c.contains(e.relatedTarget)) return;
    clearTimeout(hoverT);
    hoverT = setTimeout(() => {
      const u = find(c.dataset.uid); if (!u) return;
      const r = reader(); const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
      r.innerHTML = `<div class="b-name">${J.esc(u.name)}</div><div class="b-tribe"><i style="background:${t.c}"></i>${u.tribe} · Tier ${u.tier}</div><p class="b-text">${J.rich(u)}</p>`;
      const sr = stage.getBoundingClientRect(), k = sr.width / stage.offsetWidth, cr = c.getBoundingClientRect();
      let x = (cr.right - sr.left) / k + 14, y = (cr.top - sr.top) / k;
      if (x + 340 > stage.offsetWidth) x = (cr.left - sr.left) / k - 354;
      r.style.left = x + 'px'; r.style.top = Math.max(10, y) + 'px'; r.hidden = false;
    }, 220);
  });
  stage.addEventListener('pointerout', (e) => { const c = e.target.closest('.card'); if (c && !c.contains(e.relatedTarget)) hideReader(); });

  J.keys({ ArrowRight: () => travel(S.stop + 1), ArrowLeft: () => travel(S.stop - 1), f: () => { S.mode = S.mode === 'fight' ? 'recruit' : 'fight'; G = null; render(); } });

  J.mountWorld();
  J.fit(stage);
  J.setArea(S.stop, 'instant');
  render(P.has('arrive'));
})();
