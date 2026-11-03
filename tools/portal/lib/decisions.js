'use strict';
// Decision cards: one short Markdown file per decision the owner needs to
// make (docs/decisions/<id>.md on portal/main). The format:
//
//   ---
//   id: look-direction
//   group: looks                 # looks | plays | units | prototype | code
//   size: big                    # big | small
//   headline: Pick the look we'll build every screen and card on
//   source: proto/main:docs/prototype/OWNER-QUESTIONS.md#16   # repeatable
//   image: design-lab/main:docs/design-lab/game/x.jpg | Caption   # repeatable
//   option: Folk Print           # optional, repeatable, 2-4
//   suggested: Folk Print        # optional, matches an option
//   ---
//   <body; a line holding only {image:N} places picture N>
//
//   ## Detail
//   <detail>
//
// A card that is out of format is still shown, with its problems listed in
// plain words, rather than dropped or crashing the page.

const fsp = require('node:fs/promises');
const path = require('node:path');
const { parseQuestions } = require('./questions');
const { imageType, safeRepoPath } = require('./images');

const GROUPS = [
  ['looks', 'How it looks and feels'],
  ['plays', 'How it plays'],
  ['units', 'Units and tribes'],
  ['prototype', 'The prototype and tools'],
  ['code', 'How the code is built'],
];
const GROUP_IDS = new Set(GROUPS.map(([k]) => k));
const SINGLE = new Set(['id', 'group', 'size', 'headline', 'suggested']);
const REPEAT = new Set(['source', 'image', 'option']);
const ID_RE = /^[a-z0-9][a-z0-9-]{0,63}$/;
const IMAGE_LINE = /^\s*\{image:(\d+)\}\s*$/;

function groupTitle(id) {
  const g = GROUPS.find(([k]) => k === id);
  return g ? g[1] : 'Other decisions';
}

// Drops a trailing "# comment". A "#" needs a space before it and a space or
// the line's end after it, so "OWNER-QUESTIONS.md#16" is kept whole.
function stripComment(v) {
  return v.replace(/\s+#(?:\s.*)?$/, '').trim();
}

function parseSource(v) {
  const m = /^([^\s:]+):([^\s#]+)(?:#([A-Za-z]{0,3}\d+))?$/.exec(v);
  if (!m) return null;
  return { branch: m[1], path: m[2], ref: m[3] || null, raw: v };
}

function parseImage(v, n, allowed, problems) {
  const bar = v.indexOf('|');
  const ref = (bar === -1 ? v : v.slice(0, bar)).trim();
  const caption = bar === -1 ? '' : v.slice(bar + 1).trim();
  const img = { n, raw: v, caption, branch: null, path: null, broken: null };
  const m = /^([^\s:]+):(\S+)$/.exec(ref);
  if (!m) {
    img.broken = 'not in the form branch:path';
  } else {
    img.branch = m[1];
    img.path = m[2];
    if (!safeRepoPath(img.path.split('/'))) img.broken = 'the path is not a plain file path';
    else if (!imageType(img.path)) img.broken = 'it is not a jpg, png, webp or svg file';
    else if (allowed && !allowed.includes(img.branch)) img.broken = `pictures aren't shared from the ${img.branch} branch`;
  }
  if (img.broken) problems.push(`Picture ${n} can't be shown: ${img.broken}.`);
  if (!caption) problems.push(`Picture ${n} has no caption.`);
  return img;
}

function parseCard(text, fileName, { imageBranches = null } = {}) {
  const stem = String(fileName).replace(/\.md$/i, '');
  const problems = [];
  const card = {
    id: stem,
    file: fileName,
    group: null,
    size: 'big',
    headline: '',
    sources: [],
    images: [],
    options: [],
    suggested: null,
    body: '',
    detail: '',
    problems,
  };
  if (typeof text !== 'string') {
    problems.push('The card could not be read.');
    card.headline = stem;
    return card;
  }
  let src = text.replace(/^﻿/, '').replace(/\r\n?/g, '\n');

  const fm = {};
  if (/^---\s*\n/.test(src)) {
    const rest = src.replace(/^---\s*\n/, '');
    const close = /^---\s*$/m.exec(rest);
    if (!close) {
      problems.push('The card header has no closing "---" line.');
      src = '';
    } else {
      const head = rest.slice(0, close.index);
      src = rest.slice(close.index + close[0].length).replace(/^\n/, '');
      for (const raw of head.split('\n')) {
        const line = raw.trim();
        if (!line || line.startsWith('#')) continue;
        const m = /^([A-Za-z_-]+)\s*:\s*(.*)$/.exec(line);
        if (!m) {
          problems.push(`The header has a line I can't read: "${short(line)}".`);
          continue;
        }
        const key = m[1].toLowerCase();
        const value = stripComment(m[2]);
        if (!SINGLE.has(key) && !REPEAT.has(key)) {
          problems.push(`The header has an unknown field "${m[1]}".`);
          continue;
        }
        if (!value) {
          problems.push(`"${key}" is empty.`);
          continue;
        }
        if (REPEAT.has(key)) (fm[key] = fm[key] || []).push(value);
        else if (key in fm) problems.push(`"${key}" appears more than once; the first one is used.`);
        else fm[key] = value;
      }
    }
  } else {
    problems.push('The card has no header (it should start with a "---" line).');
  }

  if (!ID_RE.test(stem)) problems.push(`The file name "${fileName}" should be the id: lower-case letters, digits and dashes.`);
  if (!fm.id) problems.push('The card has no id.');
  else if (fm.id !== stem) problems.push(`The id "${fm.id}" doesn't match the file name "${fileName}".`);

  if (!fm.group) problems.push('The card has no group.');
  else if (!GROUP_IDS.has(fm.group)) problems.push(`"${fm.group}" isn't one of the groups (${[...GROUP_IDS].join(', ')}).`);
  else card.group = fm.group;

  if (!fm.size) problems.push('The card has no size (big or small).');
  else if (fm.size !== 'big' && fm.size !== 'small') problems.push(`Size "${fm.size}" should be big or small.`);
  else card.size = fm.size;

  if (fm.headline) card.headline = fm.headline;
  else {
    problems.push('The card has no headline.');
    card.headline = stem;
  }

  for (const v of fm.source || []) {
    const s = parseSource(v);
    if (s) card.sources.push(s);
    else problems.push(`The source "${short(v)}" isn't in the form branch:path#number.`);
  }
  (fm.image || []).forEach((v, k) => card.images.push(parseImage(v, k + 1, imageBranches, problems)));

  card.options = [...new Set(fm.option || [])];
  if (card.options.length === 1) problems.push('There is only one option; a card needs two to four, or none.');
  if (card.options.length > 4) problems.push(`There are ${card.options.length} options; a card takes four at most.`);
  if (fm.suggested) {
    if (card.options.length) {
      const match = card.options.find((o) => o.toLowerCase() === fm.suggested.toLowerCase());
      if (match) card.suggested = match;
      else problems.push(`The suggested answer "${short(fm.suggested)}" isn't one of the options.`);
    } else card.suggested = fm.suggested;
  }
  if (card.size === 'small' && !card.suggested) problems.push('A small pick needs a suggested answer: the default we went with.');

  const lines = src.split('\n');
  const at = lines.findIndex((l) => /^##\s+Detail\s*$/i.test(l));
  card.body = (at === -1 ? lines : lines.slice(0, at)).join('\n').trim();
  card.detail = at === -1 ? '' : lines.slice(at + 1).join('\n').trim();
  if (!card.body) problems.push('The card has no text.');

  const placed = new Set();
  for (const l of card.body.split('\n')) {
    const m = IMAGE_LINE.exec(l);
    if (!m) continue;
    const n = Number(m[1]);
    if (n < 1 || n > card.images.length) problems.push(`The text places picture ${n}, but the card has ${card.images.length === 1 ? 'one picture' : `${card.images.length} pictures`}.`);
    else placed.add(n);
  }
  card.placed = placed;
  return card;
}

// Splits a card body into Markdown chunks and picture slots, in order.
// Pictures the body doesn't place go at the end.
function bodyParts(card) {
  const parts = [];
  let buf = [];
  const flush = () => {
    if (buf.join('').trim()) parts.push({ md: buf.join('\n') });
    buf = [];
  };
  for (const l of card.body.split('\n')) {
    const m = IMAGE_LINE.exec(l);
    if (m) {
      flush();
      const img = card.images[Number(m[1]) - 1];
      if (img) parts.push({ image: img });
    } else buf.push(l);
  }
  flush();
  for (const img of card.images) if (!card.placed.has(img.n)) parts.push({ image: img });
  return parts;
}

function short(s) {
  return s.length > 60 ? s.slice(0, 59) + '…' : s;
}

// Reads every card, from a folder on disk (fixtures) or a folder in git.
// Then resolves each picture's blob id and size, and whether each source
// question is already marked answered on its branch.
async function loadDecisions({ git, resolve, cfg, dir, images, imageBranches, questionFiles = [] }) {
  const out = { cards: [], problems: [], from: null };
  let files = [];
  if (dir) {
    out.from = { dir };
    try {
      const names = (await fsp.readdir(dir)).filter(isCardFile).sort();
      files = await Promise.all(names.map(async (n) => [n, await fsp.readFile(path.join(dir, n), 'utf8').catch(() => null)]));
    } catch (e) {
      out.problems.push(`The decisions folder couldn't be read: ${e.code || e.message}.`);
    }
  } else if (cfg) {
    const b = await resolve(cfg.branch);
    out.from = { branch: cfg.branch, path: cfg.path, sha: b && b.sha };
    if (!b) out.problems.push(`The ${cfg.branch} branch wasn't found.`);
    else {
      const names = await git.listDir(b.sha, cfg.path);
      if (names) {
        const list = names.filter(isCardFile).sort();
        files = await Promise.all(list.map(async (n) => [n, await git.showFile(b.sha, `${cfg.path}/${n}`)]));
      }
    }
  }

  const qCache = new Map();
  const questionsAt = (branchName, p) => {
    const key = `${branchName}:${p}`;
    if (!qCache.has(key)) {
      qCache.set(
        key,
        (async () => {
          const b = await resolve(branchName);
          if (!b) return null;
          const t = await git.showFile(b.sha, p);
          return t === null ? null : parseQuestions(t);
        })(),
      );
    }
    return qCache.get(key);
  };

  for (const [name, text] of files) {
    const card = parseCard(text, name, { imageBranches });
    for (const img of card.images) {
      if (img.broken) continue;
      const b = await resolve(img.branch);
      const id = b ? await images.blobId(b.sha, img.path) : null;
      if (!id) {
        img.broken = b ? `there's no file at ${img.path} on ${img.branch}` : `the ${img.branch} branch wasn't found`;
        card.problems.push(`Picture ${img.n} can't be shown: ${img.broken}.`);
        continue;
      }
      img.blobId = id;
      img.size = imageType(img.path) === 'image/svg+xml' ? null : await images.size(id);
    }
    for (const s of card.sources) {
      const q = await questionsAt(s.branch, s.path).catch(() => null);
      const w = questionFiles.find((f) => f.path === s.path && f.branch === s.branch);
      s.workstream = w ? { id: w.id, title: w.title } : null;
      if (!q) {
        s.found = false;
        continue;
      }
      const item = s.ref ? q.items.find((i) => i.id === s.ref) : null;
      s.found = !!item;
      s.answered = !!(item && item.answered);
      s.title = item ? item.title : null;
    }
    card.sourcesAnswered = card.sources.length > 0 && card.sources.every((s) => s.found && s.answered);
    out.cards.push(card);
  }
  return out;
}

function isCardFile(n) {
  return /\.md$/i.test(n) && !/^readme\.md$/i.test(n) && !n.startsWith('.');
}

module.exports = { GROUPS, groupTitle, parseCard, bodyParts, loadDecisions, isCardFile, ID_RE };
