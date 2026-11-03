'use strict';
// Server-rendered pages. Every value from git or disk goes through esc() or
// the Markdown renderer, which escapes too.

const { renderMarkdown, inline, escapeHtml: esc } = require('./markdown');
const { stripStatusBlock } = require('./status');
const { GROUPS, groupTitle, bodyParts } = require('./decisions');
const { gitUrl } = require('./images');
const { LIMITS } = require('./inbox');

let assetVersion = '0';
function setAssetVersion(v) {
  assetVersion = v;
}

// ---------- small helpers ----------

const STATUS = {
  active: { label: 'Active', cls: 'active', icon: 'active' },
  'waiting on you': { label: 'Waiting on you', cls: 'waiting', icon: 'waiting' },
  paused: { label: 'Paused', cls: 'paused', icon: 'paused' },
  done: { label: 'Done', cls: 'done', icon: 'done' },
};

const ICONS = {
  active: '<circle cx="12" cy="12" r="5" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="9"/>',
  waiting: '<circle cx="12" cy="12" r="9"/><path d="M12 7v6"/><circle cx="12" cy="16.5" r="1.2" fill="currentColor" stroke="none"/>',
  paused: '<circle cx="12" cy="12" r="9"/><path d="M10 8.5v7M14 8.5v7"/>',
  done: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.8 2.8L16.5 9.5"/>',
  unknown: '<circle cx="12" cy="12" r="9" stroke-dasharray="3 3"/><path d="M9.6 9.6a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.6"/><circle cx="12" cy="16.6" r="1.1" fill="currentColor" stroke="none"/>',
  leaf: '<path d="M5 19c0-8 5-13 14-14-1 9-6 14-14 14Z"/><path d="M5 19 13 11"/>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2.2"/><path d="M11 18.5h2"/>',
  windows: '<path d="M3.5 5.5 10.5 4.5v7h-7zM12.5 4.2 20.5 3v8.5h-8zM3.5 12.5h7v7l-7-1zM12.5 12.5h8V21l-8-1.2z"/>',
  download: '<path d="M12 4v11M7 10.5l5 5 5-5M5 20h14"/>',
  arrow: '<path d="M9 5.5 15.5 12 9 18.5"/>',
  back: '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
  question: '<circle cx="12" cy="12" r="9"/><path d="M9.6 9.6a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.6"/><circle cx="12" cy="16.6" r="1.1" fill="currentColor" stroke="none"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  branch: '<circle cx="7" cy="5.5" r="2"/><circle cx="7" cy="18.5" r="2"/><circle cx="17" cy="8" r="2"/><path d="M7 7.5v9M17 10c0 4-4 4.5-9.2 7"/>',
  book: '<path d="M4 5.5C4 4.7 4.7 4 5.5 4H11v16H5.5c-.8 0-1.5-.7-1.5-1.5zM20 5.5c0-.8-.7-1.5-1.5-1.5H13v16h5.5c.8 0 1.5-.7 1.5-1.5z"/>',
  check: '<path d="m5 12.5 4.2 4.2L19 7"/>',
  eye: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z"/><circle cx="12" cy="12" r="3"/>',
  dice: '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="9" cy="9" r="1.2" fill="currentColor" stroke="none"/><circle cx="15" cy="15" r="1.2" fill="currentColor" stroke="none"/><circle cx="15" cy="9" r="1.2" fill="currentColor" stroke="none"/><circle cx="9" cy="15" r="1.2" fill="currentColor" stroke="none"/>',
  paw: '<circle cx="7" cy="10" r="1.8"/><circle cx="10.5" cy="6.5" r="1.8"/><circle cx="14.5" cy="6.5" r="1.8"/><circle cx="18" cy="10" r="1.8"/><path d="M12 11.5c-3 0-5.5 3.5-5.5 5.8 0 1.6 1.4 2.2 2.8 2.2 1.1 0 1.8-.6 2.7-.6s1.6.6 2.7.6c1.4 0 2.8-.6 2.8-2.2 0-2.3-2.5-5.8-5.5-5.8Z"/>',
  send: '<path d="M4 12 20 4l-6 16-2.5-6.5z"/><path d="m11.5 13.5 3-3"/>',
  alert: '<path d="M12 3.5 21.5 20h-19z"/><path d="M12 10v4.5"/><circle cx="12" cy="17.3" r="1.1" fill="currentColor" stroke="none"/>',
};

function icon(name, cls = '') {
  return `<svg class="icon ${cls}" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICONS[name] || ''}</svg>`;
}

function statusMeta(st) {
  if (st && st.status && STATUS[st.status]) return STATUS[st.status];
  if (st && st.state === 'missing') return { label: 'No status', cls: 'unknown', icon: 'unknown' };
  return { label: 'Status unreadable', cls: 'unknown', icon: 'unknown' };
}

function pill(st, size = '') {
  const m = statusMeta(st);
  return `<span class="pill pill-${m.cls} ${size}">${icon(m.icon)}<span>${esc(m.label)}</span></span>`;
}

const dayFmt = new Intl.DateTimeFormat('en-AU', { day: 'numeric', month: 'short' });
const dayYearFmt = new Intl.DateTimeFormat('en-AU', { day: 'numeric', month: 'short', year: 'numeric' });
const timeFmt = new Intl.DateTimeFormat('en-AU', { hour: '2-digit', minute: '2-digit', hour12: false });

function fmtDay(d, withYear = false) {
  return (withYear ? dayYearFmt : dayFmt).format(d);
}
function fmtDateTime(d) {
  return `${fmtDay(d, true)}, ${timeFmt.format(d)}`;
}
function relative(d, now = new Date()) {
  const s = Math.round((now - d) / 1000);
  if (s < 90) return 'just now';
  const m = Math.round(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h} h ago`;
  const days = Math.round(h / 24);
  if (days === 1) return 'yesterday';
  if (days < 14) return `${days} days ago`;
  return fmtDay(d, true);
}
function timeTag(d, { rel = true } = {}) {
  const date = new Date(d);
  const abs = fmtDateTime(date);
  return `<time datetime="${esc(date.toISOString())}" title="${esc(abs)}">${esc(rel ? relative(date) : abs)}</time>`;
}

function mb(bytes) {
  return bytes >= 1e6 ? `${(bytes / 1e6).toFixed(bytes >= 1e8 ? 0 : 1)} MB` : `${Math.max(1, Math.round(bytes / 1e3))} kB`;
}

function short(sha) {
  return sha ? String(sha).slice(0, 7) : '';
}

function plural(n, one, many) {
  return `${n} ${n === 1 ? one : many}`;
}

// ---------- layout ----------

function layout({ title, active, body, index, crumbs }) {
  const nav = [
    ['home', '/', 'Home'],
    ['builds', '/builds', 'Builds'],
    ['gallery', '/design-lab/', 'Gallery'],
  ]
    .map(([k, href, label]) => `<a href="${href}"${active === k ? ' aria-current="page"' : ''}>${label}</a>`)
    .join('');
  const stale = index && index.stale ? `<div class="banner banner-warn" role="status">${icon('alert')}<span>Couldn't re-read git just now, so this may be out of date: ${esc(index.stale)}</span></div>` : '';
  const regErr = index && index.registryError ? `<div class="banner banner-warn" role="status">${icon('alert')}<span>The workstream list couldn't be read: ${esc(index.registryError)}</span></div>` : '';
  const crumb = crumbs
    ? `<nav class="crumbs" aria-label="Breadcrumb">${crumbs.map(([href, label]) => (href ? `<a href="${href}">${icon('back')}<span>${esc(label)}</span></a>` : '')).join('')}</nav>`
    : '';
  const foot = index ? `<footer class="site-foot"><p>Updated ${timeTag(index.checkedAt || index.builtAt)}.</p></footer>` : '';
  return `<!doctype html>
<html lang="en-AU">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#f4f1e8" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#121a16" media="(prefers-color-scheme: dark)">
<title>${esc(title)}${title === 'Bramble' ? '' : ' · Bramble'}</title>
<link rel="icon" href="/static/icon.svg?v=${assetVersion}" type="image/svg+xml">
<link rel="stylesheet" href="/static/portal.css?v=${assetVersion}">
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<header class="site-head">
  <div class="wrap head-row">
    <a class="brand" href="/">${icon('leaf', 'brand-mark')}<span>Bramble</span></a>
    <nav class="site-nav" aria-label="Main">${nav}</nav>
  </div>
</header>
<main id="main" class="wrap">
${stale}${regErr}${crumb}
${body}
</main>
<div class="wrap">${foot}</div>
</body>
</html>`;
}

// ---------- home ----------

const STATE = {
  open: { label: 'Open', cls: 'open' },
  waiting: { label: 'Answered, waiting for an agent', cls: 'waiting' },
  done: { label: 'Done', cls: 'done' },
};

const WORDS = ['no', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
function count(n, one, many) {
  return `${n <= 10 ? WORDS[n] : n} ${n === 1 ? one : many}`;
}
function cap(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function stateChip(st) {
  const m = STATE[st.state];
  return `<span class="state state-${m.cls}">${esc(m.label)}</span>`;
}

function imgUrl(img) {
  return gitUrl(img.branch, img.path, img.blobId);
}

function sizeAttrs(img) {
  return img.size ? ` width="${img.size.width}" height="${img.size.height}"` : '';
}

// Cards in group order, each with its state; cards with no known group last.
function groupsOf(cards) {
  const out = GROUPS.map(([id, title]) => ({ id, title, cards: [] }));
  const other = { id: 'other', title: groupTitle(null), cards: [] };
  for (const c of cards) (out.find((g) => g.id === c.group) || other).cards.push(c);
  if (other.cards.length) out.push(other);
  return out;
}

function homePage(index, states) {
  const cards = index.decisions.cards;
  const st = (c) => states.get(c.id);
  const big = cards.filter((c) => c.size === 'big');
  const small = cards.filter((c) => c.size === 'small');
  const openBig = big.filter((c) => st(c).state === 'open').length;
  const openSmall = small.filter((c) => st(c).state === 'open').length;
  const waitingAny = cards.filter((c) => st(c).state === 'waiting').length;

  let lede;
  if (openBig && openSmall) lede = `${cap(count(openBig, 'decision needs', 'decisions need'))} you, and there ${openSmall === 1 ? 'is' : 'are'} ${count(openSmall, 'small pick', 'small picks')} to look over.`;
  else if (openBig) lede = `${cap(count(openBig, 'decision needs', 'decisions need'))} you.`;
  else if (openSmall) lede = `Nothing big needs you. There ${openSmall === 1 ? 'is' : 'are'} ${count(openSmall, 'small pick', 'small picks')} to look over.`;
  else if (waitingAny) lede = 'Nothing new needs you. Your answers are waiting for an agent to pick them up.';
  else lede = 'Nothing needs you right now.';

  const groups = groupsOf(cards)
    .map((g) => {
      const bigs = g.cards
        .filter((c) => c.size === 'big' && st(c).state !== 'done')
        .sort((a, b) => (st(a).state === 'open' ? 0 : 1) - (st(b).state === 'open' ? 0 : 1));
      const smalls = g.cards.filter((c) => c.size === 'small');
      const smallOpen = smalls.filter((c) => st(c).state === 'open').length;
      const smallWaiting = smalls.filter((c) => st(c).state === 'waiting').length;
      if (!bigs.length && !smallOpen && !smallWaiting) return '';
      const items = bigs.map((c) => decisionLine(c, st(c))).join('');
      let picks = '';
      if (smallOpen) picks = `<a class="picks-line" href="/picks/${esc(g.id)}">${icon('check')}<span>${esc(cap(count(smallOpen, 'small pick', 'small picks')))} already made for you</span>${icon('arrow', 'go')}</a>`;
      else if (smallWaiting) picks = `<a class="picks-line picks-quiet" href="/picks/${esc(g.id)}">${icon('check')}<span>Small picks accepted, waiting for an agent</span>${icon('arrow', 'go')}</a>`;
      return `<section class="d-group" data-group="${esc(g.id)}" aria-labelledby="g-${esc(g.id)}">
  <h2 class="group-title" id="g-${esc(g.id)}">${esc(g.title)}</h2>
  ${items ? `<ul class="d-list" role="list">${items}</ul>` : ''}
  ${picks}
</section>`;
    })
    .join('\n');

  const settled = cards.filter((c) => st(c).state === 'done');
  const settledHtml = settled.length
    ? `<details class="settled"><summary>${esc(cap(count(settled.length, 'decision', 'decisions')))} already settled</summary><ul class="d-list" role="list">${settled.map((c) => decisionLine(c, st(c))).join('')}</ul></details>`
    : '';
  const problems = index.decisions.problems.length
    ? `<div class="card-problem" role="note">${icon('alert')}<div><strong>Some decisions couldn't be read.</strong><span>${index.decisions.problems.map(esc).join(' ')}</span></div></div>`
    : '';

  const body = `
<section class="hero" aria-labelledby="h-home">
  <h1 id="h-home">What needs you</h1>
  <p class="lede">${esc(lede)}</p>
</section>
${problems}
<div class="decisions">
${groups}
${settledHtml}
</div>
${latestStrip(index.builds)}
<div class="lower lower-home">
${latestBuildCard(index.builds)}
${whereThingsAre(index.workstreams)}
</div>`;
  return layout({ title: 'Bramble', active: 'home', body, index });
}

function decisionLine(c, st) {
  const img = c.images.find((i) => !i.broken);
  const thumb = img
    ? `<img class="thumb" src="${esc(imgUrl(img))}"${sizeAttrs(img)} alt="" loading="lazy" decoding="async">`
    : `<span class="thumb thumb-none" aria-hidden="true">${icon(GROUP_ICON[c.group] || 'leaf')}</span>`;
  return `<li class="d-item d-${st.state}" data-decision="${esc(c.id)}"><a href="/d/${encodeURIComponent(c.id)}">${thumb}<span class="d-text"><span class="d-head">${esc(c.headline)}</span>${stateChip(st)}${c.problems.length ? '<span class="d-warn">Parts of this card are missing</span>' : ''}</span>${icon('arrow', 'go')}</a></li>`;
}

const GROUP_ICON = { looks: 'eye', plays: 'dice', units: 'paw', prototype: 'phone', code: 'branch' };

function whereThingsAre(ws) {
  const items = ws
    .map((w) => {
      const st = w.status || { state: 'missing', fields: {} };
      const m = statusMeta(st);
      const f = st.fields || {};
      const text = f.inShort ? inline(f.inShort) : esc(st.status ? `${m.label}.` : 'No status yet.');
      return `<li data-ws="${esc(w.id)}"><a href="/w/${esc(w.id)}"><span class="dot dot-${m.cls}" aria-hidden="true"></span><span class="w-body"><span class="w-title">${esc(w.title)}</span><span class="w-text">${text}</span></span>${icon('arrow', 'go')}</a></li>`;
    })
    .join('');
  return `<section class="panel where" aria-labelledby="h-where">
  <h2 id="h-where" class="panel-title">Where things are</h2>
  ${items ? `<ul class="where-list" role="list">${items}</ul>` : '<p class="muted">No workstreams to show.</p>'}
</section>`;
}

function downloadButtons(b, { big = false, quiet = false } = {}) {
  if (!b.files.length) return `<p class="muted">This build has no phone or Windows download.</p>`;
  return `<div class="dl-row${big ? ' dl-big' : ''}">${b.files
    .map(
      (f) =>
        `<a class="btn btn-dl ${f.key === 'apk' && !quiet ? 'btn-primary' : 'btn-secondary'}" href="/builds/${encodeURIComponent(b.name)}/${encodeURIComponent(f.file)}" data-kind="${f.key}" download>${icon(f.key === 'apk' ? 'phone' : 'windows')}<span class="btn-text"><span class="btn-label">${esc(f.label)}</span><span class="btn-sub">${esc(mb(f.size))}</span></span>${icon('download', 'btn-end')}</a>`,
    )
    .join('')}</div>`;
}

function newsList(b, { limit = 0 } = {}) {
  if (b.news && b.news.length) {
    const groups = limit ? b.news.slice(0, limit) : b.news;
    return groups
      .map(
        (g) =>
          `<div class="news"><p class="news-head">${esc(g.heading)}</p><ul>${g.items.map((i) => `<li>${esc(i)}</li>`).join('')}</ul></div>`,
      )
      .join('');
  }
  if (b.summary) return `<div class="news"><p class="news-head">In this build</p><ul><li>${esc(b.summary)}</li></ul></div>`;
  return '';
}

function sourceLine(b) {
  if (!b.source) return '';
  if (b.source.commit)
    return `<span class="meta">${icon('branch')}<span><code>${esc(b.source.branch)}</code> at <code>${esc(short(b.source.commit))}</code></span></span>`;
  return `<span class="meta">${icon('branch')}<span>${esc(b.source.text)}</span></span>`;
}

// Phone and tablet only: the latest build's APK right under the headline,
// so it isn't below every workstream card. Desktop shows the full card.
function latestStrip(builds) {
  const b = builds.latest || builds.builds[0];
  if (!b) return '';
  const apk = b.files.find((f) => f.key === 'apk');
  return `<section class="build-strip" aria-label="Latest build">
  <div class="strip-text"><span class="eyebrow">Latest build</span><span class="strip-name">${esc(b.label)} <span class="muted">· ${esc(fmtDateTime(new Date(b.date)))}</span></span></div>
  ${apk ? `<a class="btn btn-primary btn-dl" href="/builds/${encodeURIComponent(b.name)}/${encodeURIComponent(apk.file)}" data-kind="apk" download>${icon('phone')}<span class="btn-text"><span class="btn-label">${esc(apk.label)}</span><span class="btn-sub">${esc(mb(apk.size))}</span></span>${icon('download', 'btn-end')}</a>` : ''}
  <a class="text-link" href="/builds">Install help and Windows${icon('arrow')}</a>
</section>`;
}

function latestBuildCard(builds) {
  const b = builds.latest || builds.builds[0];
  if (!b) {
    return `<section class="panel build-panel" aria-labelledby="h-latest"><h2 id="h-latest" class="panel-title">Latest build</h2><p class="muted">${esc(builds.error || 'No builds yet.')}</p></section>`;
  }
  return `<section class="panel build-panel" aria-labelledby="h-latest">
  <div class="panel-head">
    <h2 id="h-latest" class="panel-title">Latest build</h2>
    <a class="text-link" href="/builds">All builds and install help${icon('arrow')}</a>
  </div>
  <p class="build-name">${esc(b.label)}${b.isLatest ? '' : ' <span class="tag">newest</span>'}</p>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(b.date, { rel: false })}</span></span></div>
  ${newsList(b, { limit: 1 })}
  ${downloadButtons(b, { big: true })}
</section>`;
}

// ---------- decision page ----------

// Links inside a card: site pages ("/design-lab/") and the web; nothing else.
function cardLink(href) {
  return /^\/(?!\/)/.test(href) ? href : null;
}

function figure(img, headline, { big = true } = {}) {
  if (img.broken) {
    return `<figure class="fig fig-missing"><div class="fig-missing-box">${icon('alert')}<span>This picture can't be shown.</span></div>${img.caption ? `<figcaption>${esc(img.caption)}</figcaption>` : ''}</figure>`;
  }
  const url = imgUrl(img);
  const alt = img.caption || headline;
  return `<figure class="fig${big ? ' fig-big' : ''}"><a class="fig-link" href="${esc(url)}" aria-label="Open full size: ${esc(alt)}"><img src="${esc(url)}"${sizeAttrs(img)} alt="${esc(alt)}" decoding="async"></a>${img.caption ? `<figcaption>${esc(img.caption)}</figcaption>` : ''}</figure>`;
}

function cardBody(c) {
  return bodyParts(c)
    .map((p) => (p.image ? figure(p.image, c.headline) : `<div class="prose">${renderMarkdown(p.md, { headingOffset: 1, resolveLink: cardLink })}</div>`))
    .join('\n');
}

function quote(text) {
  return text ? `<blockquote class="your-note">${esc(text).replace(/\n/g, '<br>')}</blockquote>` : '';
}

function answerStatus(c, st) {
  if (st.state === 'open') return '';
  const a = st.answer;
  const what = a ? (a.kind === 'accept-small' ? `You accepted <b>${esc(a.choice)}</b>.` : a.choice ? `You answered <b>${esc(a.choice)}</b>.` : 'You sent a note.') : '';
  if (st.state === 'waiting') {
    return `<section class="answered answered-waiting" id="answered" aria-labelledby="h-answered">
  <h2 id="h-answered" class="answered-title">${icon('clock')}<span>Answered, waiting for an agent</span></h2>
  <p>${what} ${a.time ? `Sent ${timeTag(a.time)}.` : ''} An agent picks it up when it next starts work, and this page will say what it did.</p>
  ${quote(a.note)}
</section>`;
  }
  if (st.bySource) {
    return `<section class="answered answered-done" id="answered" aria-labelledby="h-answered">
  <h2 id="h-answered" class="answered-title">${icon('done')}<span>Done</span></h2>
  <p>This one is settled: it's marked as answered where the question was first asked.</p>
</section>`;
  }
  return `<section class="answered answered-done" id="answered" aria-labelledby="h-answered">
  <h2 id="h-answered" class="answered-title">${icon('done')}<span>Done</span></h2>
  ${st.summary ? `<p class="done-summary">${inline(st.summary)}</p>` : '<p>An agent has acted on your answer.</p>'}
  ${what ? `<p class="fine">${what}</p>` : ''}
  ${quote(a.note)}
</section>`;
}

function answerForm(c, { error = '', note = '', choice = '' } = {}) {
  const opts = c.options.length
    ? `<fieldset class="opts"><legend>${c.size === 'small' ? 'Keep it, or pick another' : 'Pick one, or say it in your own words below'}</legend>${c.options
        .map((o, k) => {
          const sug = o === c.suggested;
          const checked = choice ? choice === o : false;
          return `<label class="opt${sug ? ' opt-suggested' : ''}"><input type="radio" name="choice" value="${esc(o)}"${checked ? ' checked' : ''}><span class="opt-body"><span class="opt-label">${esc(o)}</span>${sug ? `<span class="opt-hint">${c.size === 'small' ? 'What we went with' : "What we'd suggest"}</span>` : ''}</span></label>`;
        })
        .join('')}</fieldset>`
    : '';
  return `<form class="answer" method="post" action="/d/${encodeURIComponent(c.id)}/answer" id="answer">
  ${error ? `<p class="form-error" role="alert">${icon('alert')}<span>${esc(error)}</span></p>` : ''}
  ${opts}
  <label class="note-label" for="note">${c.options.length ? 'Anything to add? (optional)' : 'Your answer'}</label>
  <textarea id="note" name="note" rows="4" maxlength="${LIMITS.note}">${esc(note)}</textarea>
  <button class="btn btn-primary btn-send" type="submit">${icon('send')}<span>Send</span></button>
</form>`;
}

function sourceItem(s) {
  const where = s.workstream ? `${s.workstream.title} questions` : 'A questions file';
  const num = s.ref ? `, ${/^\d+$/.test(s.ref) ? `number ${s.ref}` : s.ref}` : '';
  const title = s.title ? `: ${esc(s.title)}` : '';
  const state = !s.found ? ' <span class="muted">(not found)</span>' : s.answered ? ' <span class="muted">(marked answered)</span>' : ' <span class="muted">(still open there)</span>';
  const label = `${esc(where)}${esc(num)}${title}`;
  const link = s.workstream ? `<a href="/w/${esc(s.workstream.id)}/questions">${label}</a>` : label;
  return `<li>${link}${state}<br><code>${esc(s.raw)}</code></li>`;
}

function decisionPage(index, c, st, form = {}) {
  const problems = c.problems.length
    ? `<div class="card-problem" role="note">${icon('alert')}<div><strong>Parts of this card are missing or out of shape, so it may read oddly.</strong><ul>${c.problems.map((p) => `<li>${esc(p)}</li>`).join('')}</ul></div></div>`
    : '';
  const sent = form.sent ? `<p class="sent" role="status">${icon('done')}<span>Thanks, that's sent.</span></p>` : '';
  const small = c.size === 'small' && c.suggested && st.state === 'open' ? `<p class="went-with">${icon('check')}<span>We went with <b>${esc(c.suggested)}</b> so work could carry on. Change it below if you'd like something else.</span></p>` : '';
  const formHtml =
    st.state === 'open' || form.error
      ? `<section class="answer-area" aria-labelledby="h-answer"><h2 id="h-answer" class="section-title">Your answer</h2>${answerForm(c, form)}</section>`
      : `<details class="change"><summary>Send a different answer</summary>${answerForm(c, form)}</details>`;
  const hasMore = c.detail || c.sources.length;
  const more = hasMore
    ? `<details class="more" id="more"><summary>More detail</summary>
  ${c.detail ? `<div class="prose">${renderMarkdown(c.detail, { headingOffset: 1, resolveLink: cardLink })}</div>` : ''}
  ${c.sources.length ? `<h2 class="more-title">Where this question comes from</h2><ul class="sources">${c.sources.map(sourceItem).join('')}</ul>` : ''}
</details>`
    : '';
  const body = `
<section class="hero hero-d" aria-labelledby="h-d">
  <p class="eyebrow">${esc(groupTitle(c.group))}${c.size === 'small' ? ' · small pick' : ''}</p>
  <h1 id="h-d">${esc(c.headline)}</h1>
</section>
${sent}
${problems}
${answerStatus(c, st)}
<article class="d-card">
${cardBody(c)}
</article>
${small}
${formHtml}
${more}`;
  const back = c.size === 'small' && c.group ? [`/picks/${c.group}`, 'Small picks'] : ['/', 'Home'];
  return layout({ title: c.headline, active: 'home', body, index, crumbs: [back] });
}

// ---------- small picks ----------

function picksPage(index, groupId, states, { accepted = 0 } = {}) {
  const g = groupsOf(index.decisions.cards).find((x) => x.id === groupId);
  const smalls = g ? g.cards.filter((c) => c.size === 'small') : [];
  const open = smalls.filter((c) => states.get(c.id).state === 'open' && c.suggested);
  const items = smalls
    .map((c) => {
      const st = states.get(c.id);
      const a = st.answer;
      const shown = a && a.choice ? a.choice : c.suggested;
      return `<li class="pick" data-decision="${esc(c.id)}">
  <div class="pick-head"><h2 class="pick-title">${esc(c.headline)}</h2>${st.state === 'open' ? '' : stateChip(st)}</div>
  <p class="pick-choice">${a ? (a.kind === 'accept-small' ? 'You accepted' : 'You answered') : 'We went with'} <b>${esc(shown || 'no default yet')}</b>.</p>
  <details class="pick-why"><summary>Why</summary><div class="prose">${renderMarkdown(c.body.replace(/^\s*\{image:\d+\}\s*$/gm, ''), { headingOffset: 2, resolveLink: cardLink })}</div></details>
  <a class="btn btn-secondary btn-change" href="/d/${encodeURIComponent(c.id)}">${st.state === 'open' ? 'Change this one' : 'Open'}${icon('arrow', 'btn-end')}</a>
</li>`;
    })
    .join('\n');
  const done = accepted ? `<p class="sent" role="status">${icon('done')}<span>Thanks: ${esc(count(accepted, 'pick', 'picks'))} accepted. An agent picks them up when it next starts work.</span></p>` : '';
  const acceptForm = open.length
    ? `<form class="accept-all" method="post" action="/picks/${esc(groupId)}/accept">${open.map((c) => `<input type="hidden" name="id" value="${esc(c.id)}">`).join('')}<button class="btn btn-primary" type="submit">${icon('check')}<span>${open.length === 1 ? 'Accept it' : 'Accept all'}</span></button></form>`
    : '';
  const lede = open.length
    ? "These are choices where we went with a sensible default so work could carry on. If they all look fine, accept them in one go. Tap any one to change it."
    : smalls.length
      ? "You've seen to all of these. Tap any one to look again or change it."
      : 'There are no small picks here.';
  const body = `
<section class="hero" aria-labelledby="h-picks">
  <p class="eyebrow">${esc(g ? g.title : groupTitle(null))}</p>
  <h1 id="h-picks">Small picks we made for you</h1>
  <p class="lede">${esc(lede)}</p>
  ${acceptForm}
</section>
${done}
${items ? `<ul class="picks" role="list">${items}</ul>` : ''}`;
  return layout({ title: 'Small picks', active: 'home', body, index, crumbs: [['/', 'Home']] });
}

// ---------- workstream (plan) page ----------

function workstreamPage(index, w) {
  const st = w.status;
  const f = st.fields || {};
  const facts = [];
  if (st.state !== 'ok') {
    facts.push(
      `<div class="card-problem wide" role="note">${icon('alert')}<div><strong>${st.state === 'missing' ? 'Missing status block' : 'Malformed status block'}</strong><span>${st.problems.map(esc).join(' ')}</span></div></div>`,
    );
  }
  const fact = (label, html, cls = '') => `<div class="fact ${cls}"><dt>${label}</dt><dd>${html}</dd></div>`;
  if (f.next) facts.push(fact('Next step', inline(f.next), 'fact-next'));
  if (f.lastDone) facts.push(fact('Last step done', inline(f.lastDone)));
  if (f.waiting) facts.push(fact('Waiting on you', inline(f.waiting), 'fact-waiting'));
  if (w.questions) {
    const q = w.questions;
    facts.push(
      fact(
        'Open questions',
        q.count === null
          ? `<a class="fact-link" href="/w/${esc(w.id)}/questions">No reliable count</a>`
          : `<a class="fact-link" href="/w/${esc(w.id)}/questions">${q.count ? plural(q.count, 'open question', 'open questions') : 'None open'}</a>`,
      ),
    );
  }
  if (w.activity) {
    facts.push(
      fact(
        'Last activity',
        `${timeTag(w.activity.date)} <span class="muted">· ${esc(fmtDateTime(new Date(w.activity.date)))}</span><br><span class="commit">${esc(w.activity.subject)}</span> <code>${esc(short(w.activity.sha))}</code>${w.activity.branches.length ? ` <span class="muted">on ${w.activity.branches.map((b) => `<code>${esc(b)}</code>`).join(', ')}</span>` : ''}`,
      ),
    );
  }

  let doc = '';
  if (w.planText) {
    doc = `<article class="doc" aria-labelledby="h-plan">
  <div class="doc-source">${icon('book')}<span id="h-plan">Plan: <code>${esc(w.planPath)}</code> on <code>${esc(w.branch.name)}</code>${w.branch.from === 'origin' ? ' (from origin, ahead of the local branch)' : ''} at <code>${esc(short(w.branch.sha))}</code></span></div>
  <div class="prose">${renderMarkdown(stripStatusBlock(w.planText), { headingOffset: 1 })}</div>
</article>`;
  } else {
    doc = `<p class="muted">No plan file to show: <code>${esc(w.planPath)}</code> wasn't found on ${w.branchesTried.map((b) => `<code>${esc(b)}</code>`).join(' or ')}.</p>`;
  }

  const body = `
<section class="hero hero-ws" aria-labelledby="h-ws-title">
  <div class="hero-row"><h1 id="h-ws-title">${esc(w.title)}</h1>${pill(st, 'pill-lg')}</div>
  ${f.inShort ? `<p class="lede">${inline(f.inShort)}</p>` : ''}
  ${w.blurb ? `<p class="${f.inShort ? 'fine' : 'lede'}">${esc(w.blurb)}</p>` : ''}
</section>
<dl class="panel facts facts-grid">${facts.join('')}</dl>
${doc}`;
  return layout({ title: w.title, active: 'home', body, index, crumbs: [['/', 'Home']] });
}

function questionsPage(index, w) {
  const q = w.questions;
  let summary;
  if (q.count === null) {
    summary = `<p class="lede">No reliable count: ${esc(q.reason || '')}</p>`;
  } else {
    const open = q.items.filter((i) => !i.answered);
    summary = `<p class="lede">${q.count ? plural(q.count, 'open question', 'open questions') : 'No open questions'}${q.answered ? `, ${q.answered} answered` : ''}.</p>
<ol class="q-index" role="list">${open
      .map((i) => `<li><span class="q-id">${esc(i.id)}</span><span>${inline(i.title)}</span></li>`)
      .join('')}</ol>
<p class="fine">Counted as: each numbered item, or bullet starting with a bold ID like <b>B1.</b>, that has no answer marker (“Answer:”, “Answered” or a struck-through start). Plain bullets are summaries, not questions.</p>`;
  }
  const doc = q.text
    ? `<article class="doc"><div class="doc-source">${icon('book')}<span><code>${esc(q.path)}</code> on <code>${esc(q.branch.name)}</code> at <code>${esc(short(q.branch.sha))}</code></span></div><div class="prose">${renderMarkdown(q.text, { headingOffset: 1 })}</div></article>`
    : '';
  const body = `
<section class="hero" aria-labelledby="h-q"><p class="eyebrow">${esc(w.title)}</p><h1 id="h-q">Open questions</h1>${summary}</section>
${doc}`;
  return layout({ title: `${w.title}: questions`, active: 'home', body, index, crumbs: [[`/w/${encodeURIComponent(w.id)}`, w.title]] });
}

// ---------- builds ----------

function section(md, heading) {
  if (!md) return null;
  const lines = md.replace(/\r\n?/g, '\n').split('\n');
  const start = lines.findIndex((l) => new RegExp(`^##\\s+${heading}\\s*$`, 'i').test(l));
  if (start === -1) return null;
  let end = lines.findIndex((l, k) => k > start && /^##?\s/.test(l));
  if (end === -1) end = lines.length;
  return lines.slice(start + 1, end).join('\n');
}

function buildsPage(index) {
  const { builds, error } = index.builds;
  const latest = index.builds.latest || builds[0];
  const older = builds.filter((b) => b !== latest);
  const pt = index.playtest;
  const tryMd = pt && pt.text ? section(pt.text, 'What to try') : null;

  const hero = latest
    ? `<section class="panel build-hero${latest.isLatest ? ' is-latest' : ''}" aria-labelledby="h-b-latest">
  <p class="eyebrow">${latest.isLatest ? 'Latest build' : 'Newest build (the <code>latest</code> link points elsewhere)'}</p>
  <h2 id="h-b-latest" class="build-name big">${esc(latest.label)}</h2>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(latest.date, { rel: false })}</span></span></div>
  ${downloadButtons(latest, { big: true })}
  <p class="fine install-hint">Phone: the APK is debug-signed, so Android asks you to allow installs from your browser. <a href="#install">Step-by-step install</a></p>
  ${newsList(latest, { limit: 1 })}
  ${readmeDetails(latest)}
</section>`
    : `<section class="panel"><p class="muted">${esc(error || 'No builds yet.')}</p></section>`;

  const install = `<section aria-labelledby="h-install" id="install">
  <h2 id="h-install" class="section-title">How to install</h2>
  <div class="install-grid">
    <div class="panel install">
      <h3>${icon('phone')}<span>Phone (Android)</span></h3>
      <ol class="steps">
        <li>On your phone, open this page and tap <b>APK for phone</b>.</li>
        <li>When the download finishes, tap it in the notification, or open it from <b>Files › Downloads</b>.</li>
        <li>If Android says your browser isn't allowed to install apps, tap <b>Settings</b>, turn on <b>Allow from this source</b>, and go back.</li>
        <li>Tap <b>Install</b>. The build is debug-signed, so Play Protect may warn you: tap <b>More details › Install anyway</b>.</li>
        <li>If Android won't install over an older build, uninstall the old Bramble first, then install again.</li>
      </ol>
    </div>
    <div class="panel install">
      <h3>${icon('windows')}<span>Windows</span></h3>
      <ol class="steps">
        <li>On your PC, click <b>Windows zip</b>.</li>
        <li>In Downloads, right-click the zip and choose <b>Extract All</b>. Don't run it from inside the zip.</li>
        <li>Open the extracted <code>windows</code> folder and run <code>bramble.exe</code>. Keep <code>bramble.pck</code> next to it: the game needs it to start.</li>
        <li>If SmartScreen says “Windows protected your PC”, click <b>More info › Run anyway</b>. The build isn't code-signed.</li>
      </ol>
    </div>
  </div>
  ${latest && latest.hasLinux ? `<p class="fine">Linux: on the Optiplex itself, run <code>linux/bramble.x86_64</code> in <code>/data/bramble-builds/${esc(latest.name)}/</code>.</p>` : ''}
</section>`;

  const tryIt = `<section aria-labelledby="h-try" class="panel">
  <div class="panel-head"><h2 id="h-try" class="panel-title">What to try</h2>${pt && pt.text ? `<a class="text-link" href="/playtest">Full playtest guide${icon('arrow')}</a>` : ''}</div>
  ${tryMd ? `<div class="prose">${renderMarkdown(tryMd)}</div><p class="fine">From <code>${esc(pt.path)}</code> on <code>${esc(pt.branchName)}</code>.</p>` : `<p class="muted">The playtest guide (<code>${esc(pt ? pt.path : 'PLAYTEST.md')}</code>) couldn't be read.</p>`}
</section>`;

  const list = older.length
    ? `<section aria-labelledby="h-older"><h2 id="h-older" class="section-title">Earlier builds</h2><ul class="build-list" role="list">${older.map(buildItem).join('')}</ul></section>`
    : '';

  const body = `
<section class="hero" aria-labelledby="h-builds">
  <p class="eyebrow">Builds</p>
  <h1 id="h-builds">${builds.length ? `${plural(builds.length, 'build', 'builds')}, newest first` : 'No builds yet'}</h1>
</section>
<div class="builds-top">${hero}${tryIt}</div>
${install}
${list}`;
  return layout({ title: 'Builds', active: 'builds', body, index });
}

function readmeDetails(b) {
  return `<details class="readme"><summary>README.txt and file sizes</summary>
  ${b.source ? `<div class="meta-row">${sourceLine(b)}</div>` : ''}
  <pre>${esc(b.readme)}</pre>
  <ul class="files">${b.files.map((f) => `<li><code>${esc(f.file)}</code><span>${esc(mb(f.size))}</span></li>`).join('')}</ul>
</details>`;
}

function buildItem(b) {
  return `<li class="panel build" data-build="${esc(b.name)}">
  <div class="build-head"><h3 class="build-name">${esc(b.label)}</h3>${b.isLatest ? '<span class="tag tag-latest">latest</span>' : ''}</div>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(b.date, { rel: false })}</span></span></div>
  ${newsList(b)}
  ${downloadButtons(b, { quiet: true })}
  ${readmeDetails(b)}
</li>`;
}

function playtestPage(index) {
  const pt = index.playtest;
  const body =
    pt && pt.text
      ? `<p class="callout">${icon('download')}<span>Downloads are on the <a href="/builds">Builds page</a>; you don't need <code>scp</code>.</span></p>
<article class="doc"><div class="doc-source">${icon('book')}<span><code>${esc(pt.path)}</code> on <code>${esc(pt.branch.name)}</code> at <code>${esc(short(pt.branch.sha))}</code></span></div><div class="prose">${renderMarkdown(pt.text)}</div></article>`
      : `<p class="muted">The playtest guide couldn't be read from git.</p>`;
  return layout({ title: 'Playtest guide', active: 'builds', body, index, crumbs: [['/builds', 'Builds']] });
}

function errorPage(status, message, index) {
  const titles = { 400: 'Bad request', 403: 'Not allowed', 404: 'Not found', 500: 'Something went wrong' };
  const body = `<section class="hero"><p class="eyebrow">${status}</p><h1>${esc(titles[status] || 'Error')}</h1><p class="lede">${esc(message)}</p><p><a class="btn btn-secondary" href="/">${icon('back')}<span>Back to home</span></a></p></section>`;
  return layout({ title: titles[status] || 'Error', body, index });
}

// Refused clients can't load /static, so this page is bare HTML.
function forbiddenPage(addr) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="light dark"><title>Not allowed</title></head><body><h1>Not allowed</h1><p>The Bramble portal only answers devices on the home network or Tailscale. This request came from <code>${esc(addr || 'an unknown address')}</code>.</p></body></html>`;
}

module.exports = { homePage, decisionPage, picksPage, workstreamPage, questionsPage, buildsPage, playtestPage, errorPage, forbiddenPage, setAssetVersion, relative, mb };
