// Storybook Ink, journey round: the game is a storybook lying open in the
// painted wood. Each area is a chapter; travelling turns the page. The market is
// the left page, your band walks a trail on the right page, the hand is tucked
// under the book, and a fight is the two bands facing across the spine.
(function () {
  const stage = document.getElementById('stage');
  const P = J.params;
  const S = { stop: Math.max(0, (+P.get('stop') || 1) - 1), mode: P.get('mode') || 'recruit' };
  let G, fightRun;
  const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI'];

  // Trail positions on the right page (page is 740 x 640 inside its margins).
  const TRAIL = [[34, 70, -3], [208, 40, 2], [382, 78, -2], [556, 46, 3], [470, 352, -2], [296, 384, 2], [122, 350, -3]];
  const TRAIL_PATH = 'M60 210 C 150 120, 220 260, 300 190 S 450 120, 470 210 S 620 120, 680 200 C 760 300, 700 420, 600 470 S 420 560, 380 500 S 220 440, 180 520 S 60 600, 40 560';

  const STAR = (n) => `<span class="star"><svg viewBox="0 0 40 40"><path d="M20 2l5.3 11.6 12.7 1.4-9.5 8.6 2.7 12.5L20 29.8 8.8 36.1l2.7-12.5L2 15l12.7-1.4z"/></svg><b>${n}</b></span>`;
  const HEART = (n) => `<span class="heart"><svg viewBox="0 0 40 36"><path d="M20 34S2 23 2 11.5C2 5.6 6.6 2 11.3 2c4 0 6.8 2.4 8.7 5.4C21.9 4.4 24.7 2 28.7 2 33.4 2 38 5.6 38 11.5 38 23 20 34 20 34z"/></svg><b data-hp>${n}</b></span>`;
  const ATK = (n) => `<span class="paw"><b data-atk>${n}</b></span>`;

  function card(u, where, i) {
    const t = J.TRIBE[u.tribe] || J.TRIBE.Neutral;
    const small = where !== 'shop';
    const pos = where === 'board' || where === 'mine' || where === 'enemy' ? TRAIL[i] : null;
    const style = pos ? `left:${pos[0]}px;top:${pos[1]}px;--rot:${pos[2]}deg;` : '';
    return `<div class="card ${small ? 'small' : ''} ${u.golden ? 'golden' : ''} ${u.frozen ? 'frozen' : ''}" data-uid="${u.uid}" data-where="${where}" style="${style}--tc:${t.c}">
      <div class="window"><img src="${J.por(u.id)}" alt="" draggable="false"></div>
      <div class="name">${J.esc(u.name.replace(/,.*$/, ''))}</div>
      ${small ? '' : `<p class="text">${J.rich(u)}</p><div class="tribe">${u.tribe}</div>`}
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
  function chapter() {
    return `<div class="chapter"><small>Chapter ${ROMAN[S.stop] || S.stop + 1}</small><b>${G.area.name}</b><i>${G.area.sub} · turn ${G.turn}</i></div>`;
  }
  function trail(units, where, emptyN) {
    const slots = Array.from({ length: emptyN }, (_, k) => { const p = TRAIL[units.length + k]; return `<div class="spot" style="left:${p[0]}px;top:${p[1]}px;--rot:${p[2]}deg"></div>`; }).join('');
    return `<div class="trail"><svg class="path" viewBox="0 0 740 640"><path d="${TRAIL_PATH}"/></svg>${slots}${units.map((u, i) => card(u, where, i)).join('')}</div>`;
  }

  function recruit() {
    return `${chapter()}${lobby()}
    <div class="book">
      <div class="page left">
        <h2>The Market <span class="hint">Tier ${G.tier}</span></h2>
        <div class="shop">${G.shop.map((u) => card(u, 'shop')).join('')}</div>
        <div class="actions">
          <div class="coin"><b>${G.gold}</b><small>gold</small></div>
          <button class="btn mustard">Tier up <em>${Math.max(0, 7 - G.stop)}</em></button>
          <button class="btn" data-act="refresh">Refresh <em>1</em></button>
          <button class="btn sky">Freeze</button>
        </div>
        <span class="folio">${S.stop * 2 + 1}</span>
      </div>
      <div class="page right">
        <h2>Your band <span class="hint">${G.board.length} of 7 on the road</span></h2>
        ${trail(G.board, 'board', 7 - G.board.length)}
        <span class="folio">${S.stop * 2 + 2}</span>
      </div>
      <div class="satchel">${G.hand.map((u) => card(u, 'hand')).join('')}</div>
    </div>
    <button class="turnpage" data-act="end"><b>Turn the page</b><span>fight ${J.esc(G.enemyHero.name)}</span><i>→</i></button>`;
  }

  function fight() {
    const foe = G.enemyHero;
    return `${chapter()}${lobby()}
    <div class="book fightbook">
      <div class="page left">
        <h2><img class="hero" src="${J.por(foe.id)}" alt="">${J.esc(foe.name)}'s band <span class="hint">${foe.hp} hearts</span></h2>
        ${trail(G.enemy, 'enemy', 0)}
      </div>
      <div class="page right">
        <h2>Your band <span class="hint">${G.lobby.find((p) => p.you).hp} hearts</span></h2>
        ${trail(G.board, 'mine', 0)}
      </div>
      <div class="versus">versus</div>
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

  const find = (uid) => [...G.shop, ...G.board, ...G.hand, ...G.enemy].find((u) => u.uid === uid);
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
    else if (c.dataset.where === 'hand' && G.board.length < 7) { G.hand = G.hand.filter((x) => x !== u); G.board.push(u); render(); }
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
