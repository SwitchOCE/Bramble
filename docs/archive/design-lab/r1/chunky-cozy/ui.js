// Chunky Cozy: shared components. Pages call these with fixture data from data.js.
(function () {
  const starPts = (cx, cy, R, r) => Array.from({ length: 10 }, (_, i) => {
    const a = -Math.PI / 2 + i * Math.PI / 5, rad = i % 2 ? r : R;
    return (cx + rad * Math.cos(a)).toFixed(1) + ',' + (cy + rad * Math.sin(a)).toFixed(1);
  }).join(' ');
  const STAR = starPts(32, 35, 27, 13);

  const I = {
    coin: `<svg viewBox="0 0 64 64"><circle cx="32" cy="34" r="27" fill="#D99A12"/><circle cx="32" cy="30" r="27" fill="#FFCB3D"/><circle cx="32" cy="30" r="20" fill="#FFDB6E"/><path d="M20 27c0-7 5-11 12-11s12 4 12 11z" fill="#8A5A2B"/><path d="M23 27h18c0 9-4 15-9 17-5-2-9-8-9-17z" fill="#C27A4B"/><path d="M31 16c0-3 1-5 3-6" stroke="#8A5A2B" stroke-width="3" fill="none" stroke-linecap="round"/><ellipse cx="22" cy="16" rx="6" ry="3" fill="#fff" opacity=".7" transform="rotate(-30 22 16)"/></svg>`,
    star: `<svg viewBox="0 0 64 64"><polygon points="${STAR}" fill="#D99A12" stroke="#D99A12" stroke-width="8" stroke-linejoin="round" transform="translate(0 3)"/><polygon points="${STAR}" fill="#FFCB3D" stroke="#FFCB3D" stroke-width="8" stroke-linejoin="round"/><ellipse cx="24" cy="22" rx="5" ry="2.6" fill="#fff" opacity=".75" transform="rotate(-35 24 22)"/></svg>`,
    heart: `<svg viewBox="0 0 64 64"><path d="M32 58C14 45 4 35 4 22 4 13 11 6 19.5 6 25 6 29.5 9 32 13.5 34.5 9 39 6 44.5 6 53 6 60 13 60 22c0 13-10 23-28 36z" fill="#F0435E" stroke="#B52640" stroke-width="3"/><ellipse cx="17" cy="18" rx="6" ry="3.5" fill="#fff" opacity=".6" transform="rotate(-35 17 18)"/></svg>`,
    atk: `<svg viewBox="0 0 64 64"><rect x="11" y="11" width="42" height="42" rx="12" transform="rotate(45 32 32)" fill="#FF8A2A" stroke="#C85A0A" stroke-width="3"/><ellipse cx="22" cy="20" rx="6" ry="3" fill="#fff" opacity=".6" transform="rotate(-45 22 20)"/></svg>`,
    sword: `<svg viewBox="0 0 64 64"><path d="M46 6l12 0 0 12-26 26-12-12z" fill="#fff" stroke="#4A2E2A" stroke-width="4" stroke-linejoin="round"/><path d="M14 30l20 20M10 54l10-10" stroke="#4A2E2A" stroke-width="7" stroke-linecap="round"/><path d="M14 30l20 20" stroke="#FF8A2A" stroke-width="3.5" stroke-linecap="round"/></svg>`,
    refresh: `<svg viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"><path d="M50 26A19 19 0 0 0 16 20"/><path d="M14 38a19 19 0 0 0 34 6"/><path d="M50 12v14H36" /><path d="M14 52V38h14"/></svg>`,
    snow: `<svg viewBox="0 0 64 64" fill="none" stroke="#2A6F95" stroke-width="6" stroke-linecap="round"><path d="M32 6v52M9.5 19l45 26M9.5 45l45-26"/><path d="M24 10l8 7 8-7M24 54l8-7 8 7" stroke-width="5"/></svg>`,
    snowW: `<svg viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round"><path d="M32 6v52M9.5 19l45 26M9.5 45l45-26"/><path d="M24 10l8 7 8-7M24 54l8-7 8 7" stroke-width="5"/></svg>`,
    berry: `<svg viewBox="0 0 64 64"><path d="M32 8c-6 4-9 10-8 16 8-1 12-6 13-14z" fill="#3DBB63"/><circle cx="22" cy="38" r="11" fill="#3B1A66"/><circle cx="42" cy="38" r="11" fill="#3B1A66"/><circle cx="32" cy="52" r="10" fill="#3B1A66"/><circle cx="19" cy="34" r="3" fill="#fff" opacity=".8"/><circle cx="39" cy="34" r="3" fill="#fff" opacity=".8"/><circle cx="29" cy="48" r="2.6" fill="#fff" opacity=".8"/></svg>`,
    sparkle: `<svg viewBox="0 0 64 64"><path d="M32 2C35 22 42 29 62 32 42 35 35 42 32 62 29 42 22 35 2 32 22 29 29 22 32 2z" fill="#fff" stroke="#F4A30F" stroke-width="3" stroke-linejoin="round"/></svg>`,
    play: `<svg viewBox="0 0 64 64"><path d="M18 10l36 22-36 22z" fill="#fff" stroke="#fff" stroke-width="6" stroke-linejoin="round"/></svg>`,
    skip: `<svg viewBox="0 0 64 64" fill="#4A2E2A" stroke="#4A2E2A" stroke-width="5" stroke-linejoin="round"><path d="M8 14l22 18-22 18zM32 14l22 18-22 18z"/><path d="M58 12v40" stroke-width="7" stroke-linecap="round"/></svg>`,
    gear: `<svg viewBox="0 0 64 64"><g fill="#4A2E2A"><circle cx="32" cy="32" r="18"/>${[0,45,90,135,180,225,270,315].map(a=>`<rect x="27" y="4" width="10" height="14" rx="4" transform="rotate(${a} 32 32)"/>`).join('')}</g><circle cx="32" cy="32" r="8" fill="#FFF8EC"/></svg>`,
    book: `<svg viewBox="0 0 64 64"><path d="M8 14c8-4 17-4 24 2v38c-7-6-16-6-24-2z" fill="#FF8FC8" stroke="#4A2E2A" stroke-width="4" stroke-linejoin="round"/><path d="M56 14c-8-4-17-4-24 2v38c7-6 16-6 24-2z" fill="#4D8EF0" stroke="#4A2E2A" stroke-width="4" stroke-linejoin="round"/></svg>`,
    trophy: `<svg viewBox="0 0 64 64"><path d="M18 8h28v14c0 9-6 16-14 16s-14-7-14-16z" fill="#FFCB3D" stroke="#4A2E2A" stroke-width="4"/><path d="M18 14H8c0 8 4 12 10 12M46 14h10c0 8-4 12-10 12" fill="none" stroke="#4A2E2A" stroke-width="4"/><path d="M28 38h8v8h6v8H22v-8h6z" fill="#C27A4B" stroke="#4A2E2A" stroke-width="4" stroke-linejoin="round"/></svg>`,
    swords: `<svg viewBox="0 0 64 64" stroke-linecap="round"><path d="M12 12l34 34M52 12L18 46" stroke="#4A2E2A" stroke-width="9"/><path d="M12 12l34 34M52 12L18 46" stroke="#fff" stroke-width="4"/><path d="M40 52l12-12M12 40l12 12" stroke="#4A2E2A" stroke-width="7"/></svg>`
  };

  // Codex-made portraits (assets/). Anything not listed falls back to a soft blob with initials.
  const P = window.PORTRAITS || {};

  const KW = ['Start of Combat', 'Nightshade', 'Peck 2', 'Mire', 'Shell 4', 'Shell 8', 'Shoulder', 'Hunker', 'Curl', 'Rival'];
  function kwText(t) {
    let s = t;
    KW.forEach(k => {
      const cls = k === 'Nightshade' ? 'kw ns' : k === 'Start of Combat' ? 'kw soc' : 'kw';
      s = s.replace(k, `\u0000${cls}\u0001${k}\u0002`);
    });
    return s.replace(/\u0000([^\u0001]*)\u0001([^\u0002]*)\u0002/g, '<span class="$1">$2</span>');
  }
  const initials = n => n.split(' ').map(w => w[0]).join('').slice(0, 2);
  function pic(name) {
    if (P[name]) return `<img src="${P[name]}" alt="">`;
    return `<div style="width:100%;height:100%;display:grid;place-items:center;font-family:var(--font-display);font-weight:700;font-size:3em;color:var(--tc)">${initials(name)}</div>`;
  }
  const stat = (k, v, cls = '') => `<div class="stat ${k}">${k === 'atk' ? I.atk : I.heart}<span class="num ${cls}">${v}</span></div>`;

  function card(u, o = {}) {
    const size = o.size || 'shop';
    const golden = u.golden || o.golden, frozen = u.frozen || o.frozen;
    const long = u.name.length > 15;
    return `<div class="card ${size} ${golden ? 'golden' : ''} ${frozen ? 'frozen' : ''}" data-tribe="${u.tribe || ''}">
      <div class="tier">${I.star}<span class="num">${u.tier ?? ''}</span></div>
      <div class="art">${pic(u.name)}</div>
      <div class="name ${long ? 'long' : ''}">${u.name}</div>
      <div class="meta">${u.type_line ? `<span class="chip" style="background:#fff">${u.type_line}</span> ` : ''}<span class="chip">${u.tribe}</span></div>
      <div class="text ${(u.text || '').length > 70 && size !== 'full' ? 'dense' : ''}"><span>${kwText(u.text || '')}</span></div>
      ${stat('atk', u.attack)}${stat('hp', u.health)}
      ${golden ? `<div class="sparkle" style="top:2em;right:.6em">${I.sparkle}</div><div class="sparkle" style="top:7em;left:.3em;width:1.4em;height:1.4em">${I.sparkle}</div>` : ''}
      ${frozen ? `<div class="ice"></div><div class="badge-ice">${I.snow}</div>` : ''}
    </div>`;
  }

  function token(u, o = {}) {
    const cls = ['token', u.golden ? 'golden' : '', o.ns ? 'ns' : '', o.cls || ''].join(' ');
    const kwm = (u.text || '').match(/^(Peck 2|Mire|Shell \d|Shoulder|Hunker|Curl|Rival)/);
    return `<div class="${cls}" data-tribe="${u.tribe || ''}" ${o.style ? `style="${o.style}"` : ''}>
      <div class="ring"><div class="pic">${pic(u.name)}</div></div>
      ${u.tier ? `<div class="tierpip">${I.star}<span class="num">${u.tier}</span></div>` : ''}
      ${o.ns ? `<div class="nsbubble">${I.berry}Nightshade</div>` : (kwm && !o.nokw ? `<div class="kwtag">${kwm[1]}</div>` : '')}
      ${stat('atk', u.attack)}${stat('hp', o.hp ?? u.health, o.hpcls || '')}
      ${o.noname ? '' : `<div class="tname">${o.label || u.name}</div>`}
      ${u.golden ? `<div class="sparkle" style="top:4px;right:16px;width:30px;height:30px">${I.sparkle}</div><div class="sparkle" style="bottom:40px;left:0;width:20px;height:20px">${I.sparkle}</div>` : ''}
    </div>`;
  }
  const empty = (sid, row) => `<div class="slot empty"><span class="sid">${sid}<small>${row === 'F' ? 'front' : 'back'}</small></span></div>`;

  function fit() {
    const st = document.getElementById('stage');
    const s = Math.min(innerHeight / 720, innerWidth / 1280);
    st.style.width = (innerWidth / s) + 'px';
    st.style.height = (innerHeight / s) + 'px';
    st.style.transform = `scale(${s})`;
  }
  addEventListener('resize', fit);
  window.CZ = { I, card, token, empty, kwText, fit, stat };
})();
