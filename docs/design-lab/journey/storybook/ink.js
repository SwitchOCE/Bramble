// Storybook Ink, journey round: the game is a storybook lying open in the
// painted wood. Each area is a chapter; travelling turns the page. You are always
// the left page: your band stands 4 in front and 3 behind in a plot that never moves,
// and the turning page passes under it. The right page is the market, or the opponent.
(function () {
  const stage = document.getElementById('stage');
  const P = J.params;
  const S = { stop: Math.max(0, (+P.get('stop') || 1) - 1), mode: P.get('mode') || 'recruit' };
  let G, fightRun;
  const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI'];

  // A slight hand-placed tilt per slot, F1-F4 then B1-B3: inked, not gridded.
  const TILT = [-2, 1.5, -1, 2, 1.5, -2, 1];

  const STAR = (n) => `<span class="star"><svg viewBox="0 0 40 40"><path d="M20 2l5.3 11.6 12.7 1.4-9.5 8.6 2.7 12.5L20 29.8 8.8 36.1l2.7-12.5L2 15l12.7-1.4z"/></svg><b>${n}</b></span>`;
  const HEART = (n) => `<span class="heart"><svg viewBox="0 0 40 36"><path d="M20 34S2 23 2 11.5C2 5.6 6.6 2 11.3 2c4 0 6.8 2.4 8.7 5.4C21.9 4.4 24.7 2 28.7 2 33.4 2 38 5.6 38 11.5 38 23 20 34 20 34z"/></svg><b data-hp>${n}</b></span>`;
  const ATK = (n) => `<span class="paw"><b data-atk>${n}</b></span>`;

  // A unit is an inked hex (owner's pick, 11 Nov), points left and right so the
  // two columns of a sideways band pack together. Rules text lives in the hover note.
  function card(u, where, k) {
    const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
    const small = where !== 'shop';
    const style = where === 'hand' && k != null ? `--rot:${TILT[k]}deg;` : '';
    return `<div class="card ${small ? 'small' : ''} ${u.golden ? 'golden' : ''} ${u.frozen ? 'frozen' : ''}" data-uid="${u.uid}" data-where="${where}" style="${style}--tc:${t.c}">
      ${J.hex(u.id)}
      <div class="name">${J.esc(u.name.replace(/,.*$/, ''))}</div>
      ${STAR(u.tier)}${ATK(u.atk)}${HEART(u.hp)}
      ${u.trig ? '<span class="quill" title="Has a trigger">✦</span>' : ''}
    </div>`;
  }

  function lobby() {
    return `<div class="lobby"><div class="lobby-h">Fellow travellers</div>${G.lobby.map((p) => `
      <div class="pl ${p.you ? 'you' : ''} ${p.next ? 'next' : ''} ${p.hp <= 0 ? 'out' : ''}">
        <img src="${J.por(p.id)}" alt=""><span>${p.you ? 'You' : J.esc(p.name.replace(/^The /, '').replace(/-/g, ' '))}</span><b>${p.hp}</b>
      </div>`).join('')}</div>`;
  }
  // A paper tab on the book's top edge: the chapter, or "versus" in a fight.
  function tab(text) { return `<div class="tabmark">${text}</div>`; }
  // The band: 4 in front, 3 behind, standing sideways in an inked clearing.
  // Yours is always on the left page, front row towards the spine.
  function band(slots, where, cls) {
    return J.brick(slots, (u, k) => card(u, where, k), (k) => `<div class="spot"><i class="hx-frame"></i><i class="hx-art"></i><span>${J.SLOTS[k]}</span></div>`, 'hex ' + cls);
  }
  const portrait = (p, label) => `<div class="portrait"><img src="${J.por(p.id)}" alt=""><b>${p.hp}</b><span>${label}</span></div>`;

  // Left page: you (portrait, satchel, your band). Right page: the market stall.
  function recruit() {
    const me = G.lobby.find((p) => p.you);
    return `${lobby()}
    <div class="book">
      ${tab(`Chapter ${ROMAN[S.stop] || S.stop + 1} · ${G.area.name}`)}
      <div class="page left">
        <h2>Your band <span class="hint">${J.count(G.board)} of 7 · turn ${G.turn}</span></h2>
        ${portrait(me, 'hearts')}
        <div class="satchel"><i>In your satchel</i>${G.hand.map((u, i) => card(u, 'hand', i)).join('') || '<em>empty</em>'}</div>
        <div class="clearing pin">${band(G.board, 'board', 'side faces-right')}</div>
        <span class="folio">${S.stop * 2 + 1}</span>
      </div>
      <div class="page right stall">
        <div class="awning"></div>
        <h2>The Market <span class="hint">Tier ${G.tier}</span></h2>
        <div class="shop">${G.shop.map((u) => card(u, 'shop')).join('')}</div>
        <div class="actions">
          <div class="coin"><b>${G.gold}</b><small>gold</small></div>
          <button class="btn mustard">Tier up <em>${Math.max(0, 7 - G.stop)}</em></button>
          <button class="btn" data-act="refresh">Refresh <em>1</em></button>
          <button class="btn sky">Freeze</button>
        </div>
        <span class="folio">${S.stop * 2 + 2}</span>
      </div>
    </div>
    <button class="turnpage" data-act="end"><b>Turn the page</b><span>fight ${J.esc(G.enemyHero.name)}</span><i>→</i></button>`;
  }

  // Left page: you, as in the recruit. Right page: the opponent, facing you across the spine.
  function fight() {
    const foe = G.enemyHero, me = G.lobby.find((p) => p.you);
    return `${lobby()}
    <div class="book fightbook">
      ${tab('versus')}
      <div class="page left">
        <h2>Your band <span class="hint">${G.area.name} · turn ${G.turn}</span></h2>
        ${portrait(me, 'hearts')}
        <div class="clearing pin">${band(G.board, 'mine', 'side faces-right')}</div>
      </div>
      <div class="page right">
        <h2>${J.esc(foe.name)}'s band</h2>
        ${portrait(foe, 'hearts')}
        <div class="clearing foe">${band(G.enemy, 'enemy', 'side')}</div>
      </div>
      <div class="stamp" hidden></div>
    </div>
    <button class="turnpage" data-act="travel" hidden><b>${S.stop === J.STOPS.length - 1 ? 'The end' : 'Next chapter'}</b><span>${S.stop === J.STOPS.length - 1 ? 'begin again' : J.STOPS[S.stop + 1].name}</span><i>→</i></button>`;
  }

  function render() {
    if (fightRun) fightRun.stop();
    if (!G || G.stop !== S.stop) G = J.state(S.stop);
    document.documentElement.dataset.mode = S.mode;
    stage.innerHTML = (S.mode === 'fight' ? fight() : recruit()) + '<div class="note" hidden></div>';
    J.labDock({ stop: S.stop, mode: S.mode, onStop: (i) => travel(i), onMode: (m) => { S.mode = m; G = null; render(); } });
    if (S.mode === 'fight' && !J.static) {
      fightRun = J.fight(G.board, G.enemy, {
        find: (uid) => stage.querySelector(`[data-uid="${uid}"]`),
        onEnd: (w) => {
          const s = stage.querySelector('.stamp');
          s.textContent = w === 'you' ? 'Won!' : w === 'them' ? 'Lost' : 'A draw';
          s.className = 'stamp ' + w; s.hidden = false;
          stage.querySelector('.turnpage').hidden = false;
        },
      });
    }
    if (S.mode === 'fight' && J.static) stage.querySelector('.turnpage').hidden = false;
  }

  // A page turns over the spine while the world changes behind the book.
  function travel(i) {
    const next = (i + J.STOPS.length) % J.STOPS.length;
    const book = stage.querySelector('.book');
    S.mode = 'recruit';
    if (J.reduced || !book) { S.stop = next; G = null; J.setArea(next, 'instant'); render(); return; }
    const leaf = document.createElement('div');
    leaf.className = 'leaf';
    leaf.innerHTML = '<div class="leaf-front"></div><div class="leaf-back"><div class="leaf-title"><small>Chapter ' + (ROMAN[next] || next + 1) + '</small><b>' + J.STOPS[next].name + '</b></div></div>';
    book.appendChild(leaf);
    J.setArea(next);
    requestAnimationFrame(() => leaf.classList.add('turn'));
    setTimeout(() => { S.stop = next; G = null; render(); const b = stage.querySelector('.book'); b.appendChild(leaf); leaf.classList.add('settle'); setTimeout(() => leaf.remove(), 700); }, 900);
  }

  const find = (uid) => [...G.shop, ...G.board, ...G.hand, ...G.enemy].find((u) => u && u.uid === uid);
  stage.addEventListener('click', (e) => {
    const a = e.target.closest('[data-act]');
    if (a) {
      if (a.dataset.act === 'end') { S.mode = 'fight'; G = J.state(S.stop); render(); }
      if (a.dataset.act === 'travel') travel(S.stop + 1);
      if (a.dataset.act === 'refresh') { G = J.state(S.stop); const r = J.rng(Date.now() & 0xffff); G.shop = G.shop.map((u, k) => { const pool = UNITS.filter((x) => x.pool && x.tier <= G.tier); const n = pool[Math.floor(r() * pool.length)]; return Object.assign({}, n, { uid: 'r' + k + Date.now(), text: n.text || 'No text.' }); }); render(); }
      return;
    }
    const c = e.target.closest('.card');
    if (!c || S.mode === 'fight') return;
    const u = find(c.dataset.uid);
    if (c.dataset.where === 'shop' && G.hand.length < 4) { G.shop = G.shop.filter((x) => x !== u); G.hand.push(u); render(); }
    else if (c.dataset.where === 'hand' && J.firstEmpty(G.board) >= 0) { G.hand = G.hand.filter((x) => x !== u); G.board[J.firstEmpty(G.board)] = u; render(); }
  });

  // Hover: a handwritten note pinned beside the card.
  let t;
  stage.addEventListener('pointerover', (e) => {
    const c = e.target.closest('.card'); if (!c || c.contains(e.relatedTarget)) return;
    clearTimeout(t);
    t = setTimeout(() => {
      const u = find(c.dataset.uid); if (!u) return;
      const n = stage.querySelector('.note');
      n.innerHTML = `<b>${J.esc(u.name)}</b><small>${u.tribe} · tier ${u.tier}</small><p>${J.rich(u)}</p>`;
      const sr = stage.getBoundingClientRect(), k = sr.width / stage.offsetWidth, cr = c.getBoundingClientRect();
      let x = (cr.right - sr.left) / k + 12, y = (cr.top - sr.top) / k - 6;
      if (x + 330 > stage.offsetWidth) x = (cr.left - sr.left) / k - 342;
      n.style.left = x + 'px'; n.style.top = Math.min(stage.offsetHeight - 260, Math.max(10, y)) + 'px'; n.hidden = false;
    }, 200);
  });
  stage.addEventListener('pointerout', (e) => { const c = e.target.closest('.card'); if (c && !c.contains(e.relatedTarget)) { clearTimeout(t); stage.querySelector('.note').hidden = true; } });

  J.keys({ ArrowRight: () => travel(S.stop + 1), ArrowLeft: () => travel(S.stop - 1), f: () => { S.mode = S.mode === 'fight' ? 'recruit' : 'fight'; G = null; render(); } });

  J.mountWorld();
  J.fit(stage);
  J.setArea(S.stop, 'instant');
  render();
})();
