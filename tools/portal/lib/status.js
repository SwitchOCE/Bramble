'use strict';
// Parses the status block at the top of a workstream plan
// (format: docs/workstreams/README.md). Never guesses: anything missing or
// out of format is reported as a problem.

const STATUS_WORDS = ['active', 'waiting on you', 'paused', 'done'];
const LABELS = [
  ['status', 'Status'],
  ['lastDone', 'Last step done'],
  ['next', 'Next step'],
  ['waiting', 'Waiting on you'],
];

const OPEN = /<!--\s*status\s*-->/i;
const CLOSE = /<!--\s*\/status\s*-->/i;

function parseStatusBlock(text) {
  if (typeof text !== 'string') {
    return { state: 'missing', status: null, problems: ['The plan file could not be read.'], fields: {} };
  }
  const src = text.replace(/\r\n?/g, '\n');
  const open = src.search(OPEN);
  if (open === -1) {
    return { state: 'missing', status: null, problems: ['The plan has no status block.'], fields: {} };
  }
  const afterOpen = src.slice(open).replace(OPEN, '');
  const closeAt = afterOpen.search(CLOSE);
  if (closeAt === -1) {
    return { state: 'malformed', status: null, problems: ['The status block has no closing <!-- /status --> marker.'], fields: {} };
  }
  const body = afterOpen.slice(0, closeAt);

  const fields = {};
  const problems = [];
  const seen = new Set();
  for (const raw of body.split('\n')) {
    const line = raw.trim();
    if (!line) continue;
    const m = /^[-*]\s+\*\*([^*]+?):\*\*\s*(.*)$/.exec(line);
    if (!m) {
      problems.push(`Unrecognised line in the status block: "${truncate(line, 60)}".`);
      continue;
    }
    const label = m[1].trim().toLowerCase();
    const entry = LABELS.find(([, l]) => l.toLowerCase() === label);
    if (!entry) {
      problems.push(`Unknown label "${m[1].trim()}".`);
      continue;
    }
    const [key, nice] = entry;
    if (seen.has(key)) {
      problems.push(`"${nice}" appears more than once.`);
      continue;
    }
    seen.add(key);
    const value = m[2].trim();
    if (!value) {
      problems.push(`"${nice}" is empty.`);
      continue;
    }
    fields[key] = value;
  }

  for (const [key, nice] of LABELS) {
    if (!seen.has(key)) problems.push(`"${nice}" is missing.`);
  }

  let status = null;
  if (fields.status !== undefined) {
    const word = fields.status.toLowerCase().replace(/[.\s]+$/, '').replace(/\s+/g, ' ');
    if (STATUS_WORDS.includes(word)) status = word;
    else {
      problems.push(`Status "${truncate(fields.status, 30)}" is not one of: ${STATUS_WORDS.join(', ')}.`);
      delete fields.status;
    }
  }

  return { state: problems.length ? 'malformed' : 'ok', status, fields, problems };
}

// True when the "waiting on you" text says there is nothing to do.
function isNothingWaiting(text) {
  if (!text) return true;
  return /^(nothing|none|no)\b[^.]*\.?$/i.test(text.trim()) && text.trim().length < 40;
}

// Strips the status block from a plan so the body can be rendered below it.
function stripStatusBlock(text) {
  const src = String(text).replace(/\r\n?/g, '\n');
  return src.replace(/<!--\s*status\s*-->[\s\S]*?<!--\s*\/status\s*-->\n?/i, '');
}

function truncate(s, n) {
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
}

module.exports = { parseStatusBlock, isNothingWaiting, stripStatusBlock, STATUS_WORDS };
