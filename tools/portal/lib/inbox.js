'use strict';
// The owner's answers, kept outside the repo in one folder
// (/data/bramble-portal/inbox, or PORTAL_INBOX_DIR). This is the portal's
// only write.
//
// Each answer is one JSON file, written to a temp name and renamed, so a
// reader never sees half a record:
//   <time>-<kind>-<decision id>-<random>.json
//   { id, time, kind: "answer" | "accept-small", decisionId, choice, note, userAgent }
//
// An agent that acts on a record marks it handled by writing
//   <same name without .json>.handled.json   { handledAt, by, summary }
// next to it. The portal never changes or deletes either file.

const fsp = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');

const KINDS = new Set(['answer', 'accept-small']);
const LIMITS = { choice: 200, note: 4000, userAgent: 300, decisionId: 64 };

function stamp(d) {
  return d.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
}

function createInbox(dir) {
  let cache = null; // { key, state }

  async function ensureDir() {
    await fsp.mkdir(dir, { recursive: true });
  }

  async function write({ kind, decisionId, choice = '', note = '', userAgent = '' }, now = new Date()) {
    if (!KINDS.has(kind)) throw new Error(`unknown record kind ${kind}`);
    if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(decisionId)) throw new Error('bad decision id');
    await ensureDir();
    const id = `${stamp(now)}-${kind}-${decisionId}-${crypto.randomBytes(3).toString('hex')}`;
    const record = {
      id,
      time: now.toISOString(),
      kind,
      decisionId,
      choice: String(choice).slice(0, LIMITS.choice),
      note: String(note).slice(0, LIMITS.note),
      userAgent: String(userAgent).slice(0, LIMITS.userAgent),
    };
    const final = path.join(dir, `${id}.json`);
    const tmp = path.join(dir, `.${id}.tmp`);
    const fh = await fsp.open(tmp, 'wx', 0o644);
    try {
      await fh.writeFile(JSON.stringify(record, null, 2) + '\n');
      await fh.sync();
    } finally {
      await fh.close();
    }
    await fsp.rename(tmp, final);
    cache = null;
    return record;
  }

  // Every record, newest last, with its handled note if an agent wrote one.
  // Re-read only when the folder changes (a new file changes its mtime).
  async function read() {
    let st;
    try {
      st = await fsp.stat(dir);
    } catch (e) {
      if (e.code === 'ENOENT') return { records: [], problems: [] };
      throw e;
    }
    const key = `${st.mtimeMs}:${st.size}`;
    if (cache && cache.key === key) return cache.state;
    const names = await fsp.readdir(dir);
    const set = new Set(names);
    const records = [];
    const problems = [];
    for (const n of names) {
      if (n.startsWith('.') || !n.endsWith('.json') || n.endsWith('.handled.json')) continue;
      let rec;
      try {
        rec = JSON.parse(await fsp.readFile(path.join(dir, n), 'utf8'));
      } catch {
        problems.push(`${n} couldn't be read.`);
        continue;
      }
      if (!rec || typeof rec.decisionId !== 'string' || !KINDS.has(rec.kind)) {
        problems.push(`${n} isn't an answer record.`);
        continue;
      }
      const stem = n.slice(0, -'.json'.length);
      const handledName = [`${stem}.handled.json`, `${n}.handled.json`].find((h) => set.has(h));
      if (handledName) {
        try {
          const h = JSON.parse(await fsp.readFile(path.join(dir, handledName), 'utf8'));
          rec.handled = { handledAt: h.handledAt || null, by: h.by || null, summary: typeof h.summary === 'string' ? h.summary : '' };
        } catch {
          rec.handled = { handledAt: null, by: null, summary: '' };
          problems.push(`${handledName} couldn't be read; the answer still counts as handled.`);
        }
      }
      rec.file = n;
      records.push(rec);
    }
    records.sort((a, b) => String(a.time).localeCompare(String(b.time)) || a.file.localeCompare(b.file));
    const state = { records, problems };
    cache = { key, state };
    return state;
  }

  return { dir, write, read, ensureDir };
}

// Where a decision stands, from its newest inbox record and its source
// questions:
//   waiting: the newest answer has no handled note yet
//   done:    an agent handled the newest answer, or every source question is
//            marked answered on its branch (and no newer answer is waiting)
//   open:    otherwise
function decisionState(card, records) {
  const mine = records.filter((r) => r.decisionId === card.id);
  const latest = mine[mine.length - 1] || null;
  if (latest && !latest.handled) return { state: 'waiting', answer: latest };
  if (latest && latest.handled) return { state: 'done', answer: latest, summary: latest.handled.summary, handled: latest.handled };
  if (card.sourcesAnswered) return { state: 'done', answer: null, summary: null, bySource: true };
  return { state: 'open', answer: null };
}

// A form body, at most `limit` bytes; rejects with .status 413 or 415.
function readForm(req, limit = 16 * 1024) {
  return new Promise((resolve, reject) => {
    const type = String(req.headers['content-type'] || '').split(';')[0].trim().toLowerCase();
    if (type !== 'application/x-www-form-urlencoded') {
      const e = new Error('unsupported form type');
      e.status = 415;
      req.resume();
      return reject(e);
    }
    const declared = Number(req.headers['content-length'] || 0);
    if (declared > limit) {
      const e = new Error('form too large');
      e.status = 413;
      req.resume();
      return reject(e);
    }
    const chunks = [];
    let size = 0;
    let done = false;
    req.on('data', (c) => {
      if (done) return;
      size += c.length;
      if (size > limit) {
        done = true;
        const e = new Error('form too large');
        e.status = 413;
        req.resume();
        return reject(e);
      }
      chunks.push(c);
    });
    req.on('end', () => {
      if (done) return;
      done = true;
      resolve(new URLSearchParams(Buffer.concat(chunks).toString('utf8')));
    });
    req.on('error', (e) => {
      if (!done) {
        done = true;
        reject(e);
      }
    });
  });
}

module.exports = { createInbox, decisionState, readForm, LIMITS, stamp };
